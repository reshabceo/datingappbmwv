import 'dart:convert';
import 'package:http/http.dart' as http;

class GeocodingService {
  static const String _baseUrl = 'https://nominatim.openstreetmap.org/reverse';

  /// Resolves latitude and longitude into a readable "City, State" string.
  static Future<String> getReadableLocation(double lat, double lon) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl?lat=$lat&lon=$lon&format=json'),
        headers: {
          'User-Agent': 'DatingApp/1.0', // Required by Nominatim policy
        },
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final address = data['address'] as Map<String, dynamic>?;

        if (address != null) {
          final stateDistrict = address['state_district']?.toString() ?? '';
          final state = address['state']?.toString() ?? '';

          if (stateDistrict.isNotEmpty && state.isNotEmpty) {
            return '$stateDistrict, $state';
          } else if (state.isNotEmpty) {
            return state;
          } else if (stateDistrict.isNotEmpty) {
            return stateDistrict;
          }
        }
        
        // Fallback to name if address components are missing
        final name = data['name']?.toString() ?? '';
        if (name.isNotEmpty) return name;
      }
      
      return '$lat, $lon'; // Fallback to raw coords
    } catch (e) {
      print('❌ Geocoding error: $e');
      return '$lat, $lon';
    }
  }
}
