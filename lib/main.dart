import 'package:lovebug/Language/all_languages.dart';
import 'package:lovebug/Screens/WelcomePage/welcome_screen.dart';
import 'package:lovebug/global_data.dart';
import 'package:lovebug/shared_prefrence_helper.dart';
import 'package:lovebug/services/supabase_service.dart';
import 'package:lovebug/services/analytics_service.dart';
import 'package:lovebug/services/payment_service.dart';
import 'package:lovebug/services/call_listener_service.dart';
import 'package:lovebug/services/callkit_listener_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'services/location_service.dart';

import 'ThemeController/theme_controller.dart';
// Firebase Analytics
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'Screens/BottomBarPage/bottombar_screen.dart';
import 'Screens/ProfileFormPage/multi_step_profile_form.dart';
import 'Screens/AuthPage/auth_ui_screen.dart';
import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Supabase
  await SupabaseService.initialize();
  
  // Initialize Payment Service
  await PaymentService.initialize();
  
  // Request camera, photo, and location permissions on app startup
  await _requestPermissions();
  
  // Initialize Firebase and Analytics for all platforms
  // TEMPORARILY DISABLED TO PREVENT CRASHES
  print('✅ Firebase Analytics temporarily disabled for debugging');
  
  // Initialize SharedPreferences
  await SharedPreferenceHelper.init();
  lanCode.value = SharedPreferenceHelper.getString(SharedPreferenceHelper.languageCode, defaultValue: 'en');
  lanName.value = SharedPreferenceHelper.getString(SharedPreferenceHelper.languageName, defaultValue: 'English');
  // Ensure ThemeController is registered before any widget requests it
  if (!Get.isRegistered<ThemeController>()) {
    Get.put(ThemeController(), permanent: true);
  }
  
  runApp(MyApp());
}

/// Request necessary permissions when app starts
Future<void> _requestPermissions() async {
  try {
    print('🔍 DEBUG: Requesting camera, photo, and location permissions on app startup...');
    
    // Request camera permission
    final cameraStatus = await Permission.camera.request();
    print('🔍 DEBUG: Camera permission status: $cameraStatus');
    
    // Request photo library permission
    final photosStatus = await Permission.photos.request();
    print('🔍 DEBUG: Photos permission status: $photosStatus');
    
    // Request location permission
    print('🔍 DEBUG: Requesting location permission...');
    final locationStatus = await Permission.locationWhenInUse.request();
    print('🔍 DEBUG: Location permission status: $locationStatus');
    
    if (cameraStatus.isGranted) {
      print('✅ Camera permission granted');
    } else {
      print('❌ Camera permission denied: $cameraStatus');
    }
    
    if (photosStatus.isGranted) {
      print('✅ Photos permission granted');
    } else {
      print('❌ Photos permission denied: $photosStatus');
    }
    
    if (locationStatus.isGranted) {
      print('✅ Location permission granted');
      // Automatically detect and update user location
      await LocationService.updateUserLocation();
    } else if (locationStatus.isPermanentlyDenied) {
      print('❌ Location permission permanently denied - user needs to enable in settings');
      // Show dialog to guide user to settings
      _showLocationPermissionDialog();
    } else {
      print('❌ Location permission denied: $locationStatus');
      // Try to get location anyway (might work with cached location)
      await LocationService.updateUserLocation();
    }
  } catch (e) {
    print('❌ Error requesting permissions: $e');
  }
}

/// Show dialog to guide user to enable location permission
void _showLocationPermissionDialog() {
  Get.dialog(
    AlertDialog(
      title: Text('Location Permission Required'),
      content: Text(
        'LoveBug needs location access to show you nearby profiles and help you find matches in your area.\n\n'
        'Please go to Settings > Privacy & Security > Location Services > LoveBug and enable location access.',
      ),
      actions: [
        TextButton(
          onPressed: () => Get.back(),
          child: Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            Get.back();
            // Open app settings
            openAppSettings();
          },
          child: Text('Open Settings'),
        ),
      ],
    ),
    barrierDismissible: false,
  );
}

// Track app launch events for UAC
Future<void> _trackAppLaunch() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final isFirstLaunch = prefs.getBool('is_first_launch') ?? true;
    final hasTrackedInstall = prefs.getBool('has_tracked_install') ?? false;
    
    if (isFirstLaunch) {
      // Track first open
      await AnalyticsService.trackFirstOpen();
      await prefs.setBool('is_first_launch', false);
    }
    
    if (!hasTrackedInstall) {
      // Track app install
      await AnalyticsService.trackAppInstall();
      await prefs.setBool('has_tracked_install', true);
    }
    
    // Always track session start
    await AnalyticsService.trackSessionStart();
  } catch (e) {
    print('❌ Failed to track app launch: $e');
  }
}

class MyApp extends StatelessWidget {
  MyApp({super.key});

  final ThemeController themeController = Get.find<ThemeController>();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: ScreenUtilInit(
        minTextAdapt: true,
        splitScreenMode: true,
        designSize: const Size(375, 812),
        builder: (_, child) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
              child: GetMaterialApp(
                title: 'Dating App',
                debugShowCheckedModeBanner: false,
                locale: Locale(lanCode.value),
                translations: AppTranslations(),
                theme: themeController.lightTheme,
                darkTheme: themeController.darkTheme,
                themeMode: themeController.isDarkMode.value ? ThemeMode.dark : ThemeMode.light,
                home: _AuthGate(),
                // home: BottombarScreen(),
              ),
            );
        },
      ),
    );
  }
}

class _AuthGate extends StatefulWidget {
  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> with WidgetsBindingObserver {
  bool _ready = false;
  bool _hasSession = false;
  bool _hasProfile = false;
  bool _checkingProfile = true;
  bool _didNavigateToMain = false;
  StreamSubscription<AuthState>? _authSub;

  @override
  void initState() {
    super.initState();
    // CRITICAL FIX: Add app lifecycle observer to handle OAuth redirects
    WidgetsBinding.instance.addObserver(this);
    _checkSessionAndProfile();
    // React to login/logout in real time
    _authSub = SupabaseService.authStateChanges.listen((authState) {
      print('🔄 DEBUG: Auth state changed - event: ${authState.event}, session: ${authState.session != null}');
      print('🔄 DEBUG: Auth event type: ${authState.event}');
      print('🔄 DEBUG: Session exists: ${authState.session != null}');
      
      if (authState.event == AuthChangeEvent.signedOut) {
        _didNavigateToMain = false; // reset guard on sign out
      }

      // CRITICAL FIX: Handle OAuth redirects immediately
      if (authState.event == AuthChangeEvent.signedIn) {
        print('✅ DEBUG: User signed in via OAuth, refreshing state immediately');
        // Force immediate state refresh for OAuth sign-ins
        Future.delayed(Duration(milliseconds: 100), () {
          _checkSessionAndProfile();
        });
        
        // AGGRESSIVE FIX: Force navigation immediately when signed in
        if (authState.session != null) {
          print('🔄 DEBUG: Session detected during sign-in, forcing immediate navigation...');
          Future.microtask(() {
            Get.offAll(() => BottombarScreen());
          });
        }
      } else {
        _checkSessionAndProfile();
      }
    });
  }

  Future<void> _checkSessionAndProfile() async {
    // Give Supabase a beat to hydrate session
    await Future.delayed(const Duration(milliseconds: 150));
    final session = SupabaseService.client.auth.currentSession;
    
    print('🔄 DEBUG: _AuthGate checking session - has session: ${session != null}');
    print('🔄 DEBUG: Session details: ${session?.user?.id}');
    print('🔄 DEBUG: Session email: ${session?.user?.email}');
    
    if (session != null) {
      // User is authenticated, check if they have a complete profile
      try {
        final user = SupabaseService.currentUser;
        if (user != null) {
          final profile = await SupabaseService.getProfile(user.id);
          
          // 🔍 DEBUG: Log profile data
          print('🔍 DEBUG: Profile data for user ${user.id}:');
          print('🔍 DEBUG: Profile exists: ${profile != null}');
          if (profile != null) {
            print('🔍 DEBUG: Profile is_active: ${profile['is_active']}');
            print('🔍 DEBUG: Profile email: ${profile['email']}');
            print('🔍 DEBUG: Profile created_at: ${profile['created_at']}');
          }
          
          // Check if profile is incomplete (regardless of is_active status)
          if (profile != null) {
            // Check if profile is incomplete (missing required fields for a complete profile)
            final hasIncompleteProfile = profile['name'] == null || 
                                       profile['name'].toString().trim().isEmpty ||
                                       profile['age'] == null || 
                                       profile['age'] == 0 ||
                                       profile['description'] == null ||
                                       profile['description'].toString().trim().isEmpty ||
                                       profile['hobbies'] == null ||
                                       (profile['hobbies'] as List).isEmpty ||
                                       profile['image_urls'] == null ||
                                       (profile['image_urls'] as List).isEmpty;
            
            if (hasIncompleteProfile) {
              // Incomplete profile - go to profile creation
              print('🆕 DEBUG: Incomplete profile detected, navigating to profile creation');
              print('🆕 DEBUG: Profile data: name=${profile['name']}, age=${profile['age']}, description=${profile['description']}, hobbies=${profile['hobbies']}, image_urls=${profile['image_urls']}');
              setState(() {
                _ready = true;
                _hasSession = true;
                _hasProfile = false;
                _checkingProfile = false;
              });
              _didNavigateToMain = false; // ensure we can navigate later when completed
              return;
            }
          }
          
          // Check if user account is deactivated (only for existing users with complete profiles)
          if (profile != null && profile['is_active'] == false) {
            // Check if this is a new user (recently created profile)
            final profileCreatedAt = DateTime.parse(profile['created_at']);
            final now = DateTime.now();
            final timeDifference = now.difference(profileCreatedAt).inMinutes;
            
            if (timeDifference < 5) {
              // New user - go to profile creation instead of showing deactivation
              print('🆕 DEBUG: New user detected, navigating to profile creation');
              setState(() {
                _ready = true;
                _hasSession = true;
                _hasProfile = false;
                _checkingProfile = false;
              });
              _didNavigateToMain = false;
              return;
            } else {
              // Existing user with deactivated account
              print('🚫 DEBUG: User account is deactivated');
              print('🚫 DEBUG: User ID: ${user.id}');
              print('🚫 DEBUG: User email: ${user.email}');
              // Store user ID before signing out
              final userId = user.id;
              // Sign out the user and show deactivation message
              await SupabaseService.signOut();
              _showAccountDeactivatedDialog(userId);
              setState(() {
                _ready = true;
                _hasSession = false;
                _hasProfile = false;
                _checkingProfile = false;
              });
              _didNavigateToMain = false;
              return;
            }
          }
          
          // Debug logging for profile validation
          print('🔍 DEBUG: Final profile validation:');
          print('🔍 DEBUG: profile != null: ${profile != null}');
          print('🔍 DEBUG: profile.isNotEmpty: ${profile != null ? profile.isNotEmpty : 'N/A'}');
          print('🔍 DEBUG: profile[name] != null: ${profile != null ? profile['name'] != null : 'N/A'}');
          print('🔍 DEBUG: profile[is_active] == true: ${profile != null ? profile['is_active'] == true : 'N/A'}');
          
          final hasValidProfile = profile != null && profile.isNotEmpty && profile['name'] != null && profile['is_active'] == true;
          print('🔍 DEBUG: hasValidProfile: $hasValidProfile');
          
          setState(() {
            _ready = true;
            _hasSession = true;
            _hasProfile = hasValidProfile;
            _checkingProfile = false;
          });
          
          print('🔍 DEBUG: _AuthGate state set - _hasSession: $_hasSession, _hasProfile: $_hasProfile');

          // Force navigation away from auth stack after successful login + valid profile
          if (hasValidProfile && !_didNavigateToMain) {
            _didNavigateToMain = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              // Pop all intermediate auth routes and show main app
              Get.offAll(() => BottombarScreen());
            });
          }
          
          // Detect and update location for authenticated user
          await LocationService.updateUserLocation();
          
          // Initialize call listener service for incoming calls
          print('📞 DEBUG: About to initialize CallListenerService...');
          // Ensure push notifications are set up so receiver gets invites
          await NotificationService.initialize();
          await CallListenerService.initialize();
          print('📞 DEBUG: CallListenerService initialization completed');
          
          // Initialize CallKit listener service for iOS CallKit events
          print('📞 DEBUG: About to initialize CallKitListenerService...');
          await CallKitListenerService.initialize();
          print('📞 DEBUG: CallKitListenerService initialization completed');
          
          // Start analytics session for authenticated user - Temporarily disabled
          // await AnalyticsService.startSession();
        } else {
          setState(() {
            _ready = true;
            _hasSession = false;
            _hasProfile = false;
            _checkingProfile = false;
          });
          _didNavigateToMain = false;
        }
      } catch (e) {
        print('Error checking profile: $e');
        setState(() {
          _ready = true;
          _hasSession = true;
          _hasProfile = false;
          _checkingProfile = false;
        });
        _didNavigateToMain = false;
        
        // Start analytics session even if profile check fails - Temporarily disabled
        // await AnalyticsService.startSession();
      }
    } else {
      setState(() {
        _ready = true;
        _hasSession = false;
        _hasProfile = false;
        _checkingProfile = false;
      });
      _didNavigateToMain = false;
    }
  }

  void _showAccountDeactivatedDialog(String userId) {
    Get.dialog(
      AlertDialog(
        title: Text('Account Deactivated'),
        content: Text('Your account has been deactivated. All your data is preserved and will be restored when you reactivate your account.'),
        actions: [
          TextButton(
            onPressed: () {
              Get.back();
              // Navigate to welcome screen
              setState(() {
                _ready = true;
                _hasSession = false;
                _hasProfile = false;
                _checkingProfile = false;
              });
            },
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Get.back();
              await _reactivateAccount(userId);
            },
            child: Text('Reactivate Account'),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  Future<void> _reactivateAccount(String userId) async {
    try {
      // Show loading
      Get.dialog(
        Center(
          child: Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: Colors.pink),
                SizedBox(height: 10),
                Text(
                  'Reactivating account...',
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
              ],
            ),
          ),
        ),
        barrierDismissible: false,
      );

      // Reactivate the user's account using the stored user ID
      print('🔄 Reactivating account for user: $userId');
      final response = await SupabaseService.client
          .from('profiles')
          .update({'is_active': true})
          .eq('id', userId);
      print('✅ Account reactivated successfully. Response: $response');
      
      // Wait a moment for the database to commit the change
      await Future.delayed(Duration(milliseconds: 500));

      // Close loading dialog
      Get.back();

      // Show success message
      Get.snackbar(
        'Account Reactivated',
        'Your account has been reactivated successfully! Please log in again.',
        backgroundColor: Colors.black,
        colorText: Colors.white,
        duration: Duration(seconds: 3),
      );

      // Navigate to welcome screen instead of main app
      // The user needs to log in again since they were signed out
      setState(() {
        _ready = true;
        _hasSession = false;
        _hasProfile = false;
        _checkingProfile = false;
      });
    } catch (e) {
      print('❌ Error reactivating account: $e');
      Get.back(); // Close loading dialog
      Get.snackbar(
        'Error',
        'Failed to reactivate account: $e',
        backgroundColor: Colors.black,
        colorText: Colors.white,
        duration: Duration(seconds: 3),
      );
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    print('🔄 DEBUG: App lifecycle state changed: $state');
    
    // CRITICAL FIX: Handle OAuth redirects when app resumes
    if (state == AppLifecycleState.resumed) {
      print('✅ DEBUG: App resumed, checking auth state for OAuth redirects');
      // Small delay to ensure OAuth redirect is processed
      Future.delayed(Duration(milliseconds: 1000), () {
        _checkSessionAndProfile();
      });
      
      // Refresh location when app resumes to keep filtering accurate
      print('📍 Location: Refreshing location after app resume');
      LocationService.updateUserLocation().catchError((e) {
        print('❌ Error refreshing location on resume: $e');
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _authSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print('🔍 DEBUG: _AuthGate build - _ready: $_ready, _checkingProfile: $_checkingProfile, _hasSession: $_hasSession, _hasProfile: $_hasProfile');
    
    if (!_ready || _checkingProfile) {
      print('🔍 DEBUG: Showing loading indicator');
      return Center(child: CircularProgressIndicator());
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        Widget child;
        if (!_hasSession) {
          print('🔍 DEBUG: Showing WelcomeScreen (no session)');
          child = WelcomeScreen();
        } else if (!_hasProfile) {
          print('🔍 DEBUG: Showing MultiStepProfileForm (no profile)');
          child = MultiStepProfileForm();
        } else {
          print('🔍 DEBUG: Showing BottombarScreen (has session and profile)');
          child = BottombarScreen();
        }
        
        print('🔍 DEBUG: About to return child widget: ${child.runtimeType}');
        
        if (constraints.maxWidth > 600) {
          return Center(
            child: Container(
              constraints: BoxConstraints(maxWidth: 400, maxHeight: constraints.maxHeight),
              child: child,
            ),
          );
        }
        return child;
      },
    );
  }
}

// Push init & handlers
// Future<void> _initPush() async {}
