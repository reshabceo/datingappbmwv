import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../shared_prefrence_helper.dart';
import 'supabase_service.dart';
import 'geocoding_service.dart';

class LocationService {
  static const String _lastLocationUpdateKey = 'last_location_update';
  static const Duration _locationUpdateInterval = Duration(hours: 1); // Update every hour
  
  /// Check if location permission is granted
  static Future<bool> hasLocationPermission() async {
    final status = await Permission.locationWhenInUse.status;
    return status.isGranted;
  }
  
  /// Get detailed permission status
  static Future<String> getPermissionStatus() async {
    final status = await Permission.locationWhenInUse.status;
    return status.toString();
  }
  
  /// Request location permission with proper error handling
  static Future<bool> requestLocationPermission() async {
    print('🔍 LocationService: Requesting location permission...');
    
    // Check current status first
    var status = await Permission.locationWhenInUse.status;
    print('🔍 LocationService: Current status: $status');
    
    // If already granted, return true
    if (status.isGranted) {
      print('✅ LocationService: Permission already granted');
      return true;
    }
    
    // If permanently denied, return false immediately
    // The caller should handle showing a dialog to open settings
    if (status.isPermanentlyDenied) {
      print('⚠️ LocationService: Permission permanently denied - caller should show settings dialog');
      return false;
    }
    
    // If denied but not permanently, request permission
    // This will show the native iOS permission dialog
    status = await Permission.locationWhenInUse.request();
    print('🔍 LocationService: Permission request result: $status');
    
    if (status.isGranted) {
      print('✅ LocationService: Permission granted');
      return true;
    } else if (status.isPermanentlyDenied) {
      print('⚠️ LocationService: Permission permanently denied after request');
      return false;
    }
    
    print('❌ LocationService: Permission denied');
    return false;
  }
  
  /// Open app settings for user to manually enable location
  static Future<void> openAppLocationSettings() async {
    print('🔍 LocationService: Opening app settings...');
    await openAppSettings();
  }
  
  /// Check if location services are enabled
  static Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }
  
  /// Get current location with high accuracy
  static Future<Position?> getCurrentLocation() async {
    try {
      // Check if location services are enabled
      final serviceEnabled = await isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('❌ Location services are disabled');
        return null;
      }
      
      // Check permission
      final hasPermission = await hasLocationPermission();
      if (!hasPermission) {
        print('❌ Location permission not granted');
        return null;
      }
      
      // Try multiple accuracy levels
      Position? position;
      
      // First try high accuracy
      try {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        );
        print('📍 LocationService: Got high accuracy location - Lat: ${position.latitude}, Lon: ${position.longitude}');
      } catch (e) {
        print('⚠️ High accuracy failed, trying medium accuracy: $e');
        
        // Fallback to medium accuracy
        try {
          position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.medium,
            timeLimit: Duration(seconds: 15),
          );
          print('📍 LocationService: Got medium accuracy location - Lat: ${position.latitude}, Lon: ${position.longitude}');
        } catch (e2) {
          print('⚠️ Medium accuracy failed, trying low accuracy: $e2');
          
          // Final fallback to low accuracy
          position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.low,
            timeLimit: Duration(seconds: 20),
          );
          print('📍 LocationService: Got low accuracy location - Lat: ${position.latitude}, Lon: ${position.longitude}');
        }
      }
      
      return position;
    } catch (e) {
      print('❌ LocationService: Error getting location: $e');
      return null;
    }
  }
  
  /// Update user location in database and local storage
  static Future<bool> updateUserLocation() async {
    try {
      // First try to request permission if not granted
      final hasPermission = await hasLocationPermission();
      if (!hasPermission) {
        print('🔍 LocationService: No permission, requesting...');
        final granted = await requestLocationPermission();
        if (!granted) {
          print('❌ LocationService: Permission denied');
          return false;
        }
      }
      
      final position = await getCurrentLocation();
      if (position == null) return false;
      
      // Update in database if user is logged in
      final user = SupabaseService.currentUser;
      if (user != null) {
        await _updateLocationInDatabase(user.id, position.latitude, position.longitude);
      }
      
      // Store in SharedPreferences
      await SharedPreferenceHelper.setDouble('user_latitude', position.latitude);
      await SharedPreferenceHelper.setDouble('user_longitude', position.longitude);
      await SharedPreferenceHelper.setString(_lastLocationUpdateKey, DateTime.now().toIso8601String());
      
      print('✅ LocationService: Location updated successfully');
      return true;
    } catch (e) {
      print('❌ LocationService: Error updating location: $e');
      return false;
    }
  }
  
  /// Check if location needs to be updated (based on time interval)
  static Future<bool> shouldUpdateLocation() async {
    try {
      final lastUpdate = SharedPreferenceHelper.getString(_lastLocationUpdateKey);
      if (lastUpdate.isEmpty) return true;
      
      final lastUpdateTime = DateTime.parse(lastUpdate);
      final now = DateTime.now();
      final timeDiff = now.difference(lastUpdateTime);
      
      return timeDiff > _locationUpdateInterval;
    } catch (e) {
      print('❌ LocationService: Error checking update interval: $e');
      return true; // Update if we can't determine
    }
  }
  
  /// Get cached location from SharedPreferences
  static Future<Map<String, double>?> getCachedLocation() async {
    try {
      final lat = SharedPreferenceHelper.getDouble('user_latitude');
      final lon = SharedPreferenceHelper.getDouble('user_longitude');
      
      if (lat != null && lon != null) {
        return {'latitude': lat, 'longitude': lon};
      }
      return null;
    } catch (e) {
      print('❌ LocationService: Error getting cached location: $e');
      return null;
    }
  }
  
  /// Update location in database
  static Future<void> _updateLocationInDatabase(String userId, double latitude, double longitude) async {
    try {
      print('📍 LocationService: Updating user location in database...');
      
      // Get location name from coordinates
      final locationName = await _getLocationNameFromCoordinates(latitude, longitude);
      
      await SupabaseService.client
          .from('profiles')
          .update({
            'latitude': latitude,
            'longitude': longitude,
            'location': locationName ?? 'Unknown Location',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId);
      
      print('✅ LocationService: User location updated in database - $locationName');
    } catch (e) {
      print('❌ LocationService: Error updating location in database: $e');
    }
  }
  
  /// Get location name from coordinates using reverse geocoding
  static Future<String?> _getLocationNameFromCoordinates(double latitude, double longitude) async {
    try {
      print('📍 LocationService: Reverse geocoding Lat: $latitude, Lon: $longitude');
      final readable = await GeocodingService.getReadableLocation(latitude, longitude);
      return readable;
    } catch (e) {
      print('❌ LocationService: Error getting location name: $e');
      return '${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}';
    }
  }
  
  /// Force location update (ignores time interval)
  static Future<bool> forceLocationUpdate() async {
    return await updateUserLocation();
  }
  
  /// Get location with automatic update if needed
  static Future<Map<String, double>?> getLocationWithAutoUpdate() async {
    try {
      // Check if we need to update location
      final shouldUpdate = await shouldUpdateLocation();
      
      if (shouldUpdate) {
        print('📍 LocationService: Location is stale, updating...');
        final updated = await updateUserLocation();
        if (!updated) {
          // Fallback to cached location
          return await getCachedLocation();
        }
      }
      
      // Return current location (either fresh or cached)
      return await getCachedLocation();
    } catch (e) {
      print('❌ LocationService: Error in getLocationWithAutoUpdate: $e');
      return await getCachedLocation();
    }
  }
}
