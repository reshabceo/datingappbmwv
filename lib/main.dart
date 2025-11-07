import 'dart:io';
import 'package:lovebug/Language/all_languages.dart';
import 'package:lovebug/services/app_state_service.dart';
import 'package:lovebug/services/android_background_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:lovebug/screens/call_screens/video_call_screen.dart';
import 'package:lovebug/screens/call_screens/audio_call_screen.dart';
import 'package:lovebug/models/call_models.dart';
import 'package:lovebug/Screens/WelcomePage/welcome_screen.dart';
import 'package:lovebug/global_data.dart';
import 'package:lovebug/shared_prefrence_helper.dart';
import 'package:lovebug/services/supabase_service.dart';
import 'package:lovebug/services/analytics_service.dart';
import 'package:lovebug/services/payment_service.dart';
import 'package:lovebug/services/call_listener_service.dart';
import 'package:lovebug/services/callkit_listener_service.dart';
import 'package:lovebug/services/webrtc_service.dart';
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
import 'services/local_notification_service.dart';
import 'services/call_debug_helper.dart';
import 'services/android_call_action_service.dart';
import 'services/notification_clearing_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Register the background message handler BEFORE runApp (critical for closed-app delivery)
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // CRITICAL FIX: Initialize AppStateService FIRST before any other services
  AppStateService.initialize();
  print('🔧 DEBUG: AppStateService initialized at app startup');
  
  // Initialize Supabase
  await SupabaseService.initialize();
  
  // Initialize Payment Service
  await PaymentService.initialize();
  
  // Request camera, photo, and location permissions on app startup
  await _requestPermissions();
  
  // Firebase is already initialized in AppDelegate.swift for iOS
  // No need to initialize again in Flutter
  
  // Initialize Notification Service
  await NotificationService.initialize();
  
  // Initialize Local Notification Service
  await LocalNotificationService.initialize();

  // Initialize Android call action handler (Accept/Decline from notification)
  if (Platform.isAndroid) {
    try {
      await AndroidCallActionService.initialize();
    } catch (e) {
      print('❌ Failed to initialize AndroidCallActionService: $e');
    }
  }
  
  print('✅ Firebase initialized successfully');
  
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
    print('🔍 DEBUG: Requesting camera, photo, location, and notification permissions on app startup...');
    
    // Request camera permission
    final cameraStatus = await Permission.camera.request();
    print('🔍 DEBUG: Camera permission status: $cameraStatus');
    
    // Request microphone permission (for voice messages and calls)
    final micStatus = await Permission.microphone.request();
    print('🔍 DEBUG: Microphone permission status: $micStatus');
    
    // Request photo library permission
    final photosStatus = await Permission.photos.request();
    print('🔍 DEBUG: Photos permission status: $photosStatus');
    
    // Request location permission
    print('🔍 DEBUG: Requesting location permission...');
    final locationStatus = await Permission.locationWhenInUse.request();
    print('🔍 DEBUG: Location permission status: $locationStatus');
    
    // Request notification permission (Android 13+ and iOS explicitly)
    if (Platform.isAndroid) {
      print('🤖 ANDROID: Requesting notification permission...');
      final notificationStatus = await Permission.notification.request();
      print('🤖 ANDROID: Notification permission status: $notificationStatus');
      
      if (notificationStatus.isGranted) {
        print('✅ ANDROID: Notification permission granted');
      } else if (notificationStatus.isPermanentlyDenied) {
        print('❌ ANDROID: Notification permission permanently denied - user needs to enable in settings');
        // Show dialog to guide user to settings
        _showNotificationPermissionDialog();
      } else {
        print('❌ ANDROID: Notification permission denied: $notificationStatus');
      }
    } else if (Platform.isIOS) {
      // iOS: explicitly request Firebase Messaging permission so alerts/sounds can be shown
      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: true,
        provisional: false,
        sound: true,
      );
      print('🍎 iOS: Notification permission settings: ${settings.authorizationStatus}');
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        _showNotificationPermissionDialog();
      }
    }
    
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
      // Automatically detect and update user location (non-blocking)
      LocationService.updateUserLocation().catchError((e) {
        print('❌ Location update failed: $e');
      });
    } else if (locationStatus.isPermanentlyDenied) {
      print('❌ Location permission permanently denied - user needs to enable in settings');
      // Show dialog to guide user to settings
      _showLocationPermissionDialog();
    } else {
      print('❌ Location permission denied: $locationStatus');
      // Try to get location anyway (non-blocking, might work with cached location)
      LocationService.updateUserLocation().catchError((e) {
        print('❌ Location update failed: $e');
      });
    }
  } catch (e) {
    print('❌ Error requesting permissions: $e');
  }
}

/// Show dialog to guide user to enable location permission
void _showLocationPermissionDialog() {
  Get.dialog(
    AlertDialog(
      title: Text('location_permission_required'.tr),
      content: Text('location_permission_message'.tr),
      actions: [
        TextButton(
          onPressed: () => Get.back(),
          child: Text('cancel'.tr),
        ),
        TextButton(
          onPressed: () {
            Get.back();
            // Open app settings
            openAppSettings();
          },
          child: Text('open_settings'.tr),
        ),
      ],
    ),
    barrierDismissible: false,
  );
}

/// Show dialog to guide user to enable notification permission
void _showNotificationPermissionDialog() {
  Get.dialog(
    AlertDialog(
      title: Text('notification_permission_required'.tr),
      content: Text('notification_permission_message'.tr),
      actions: [
        TextButton(
          onPressed: () => Get.back(),
          child: Text('cancel'.tr),
        ),
        TextButton(
          onPressed: () {
            Get.back();
            // Open app settings
            openAppSettings();
          },
          child: Text('open_settings'.tr),
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
              child: Obx(() => GetMaterialApp(
                title: 'dating_app'.tr,
                debugShowCheckedModeBanner: false,
                locale: lanCode.value.isNotEmpty ? Locale(lanCode.value) : const Locale('en'),
                fallbackLocale: const Locale('en'),
                translations: AppTranslations(),
                theme: themeController.lightTheme,
                darkTheme: themeController.darkTheme,
                themeMode: themeController.isDarkMode.value ? ThemeMode.dark : ThemeMode.light,
                home: _AuthGate(),
                // home: BottombarScreen(),
              )),
            );
        },
      ),
    );
  }
}

// NEW METHOD: Handle call notification action
void _handleCallNotificationAction(Map<String, dynamic> data) async {
  try {
    final callId = data['call_id'] as String?;
    final callerName = data['caller_name'] as String?;
    final callType = data['call_type'] as String?;
    final callerId = data['caller_id'] as String?;
    final matchId = data['match_id'] as String?;
    final callerImageUrl = data['caller_image_url'] as String?;
    
    if (callId == null || callerName == null || callType == null) {
      print('❌ Missing call data in push notification');
      return;
    }
    
    print('📱 ═══════════════════════════════════════════════');
    print('📱 HANDLING CALL NOTIFICATION ACTION (iOS Push)');
    print('📱 ═══════════════════════════════════════════════');
    print('📱 Call ID: $callId');
    print('📱 Caller: $callerName');
    print('📱 Call Type: $callType');
    print('📱 Match ID: $matchId');
    print('📱 Caller Image: $callerImageUrl');
    
    // CRITICAL FIX: Update call session state to connecting (same as CallKit does)
    try {
      await SupabaseService.client
          .from('call_sessions')
          .update({'state': 'connecting'})
          .eq('id', callId);
      print('✅ Call state updated to connecting');
    } catch (e) {
      print('❌ Failed to update call state: $e');
    }
    
    // CRITICAL FIX: Initialize WebRTC service if not registered (same as CallKit does)
    if (!Get.isRegistered<WebRTCService>()) {
      print('📱 Registering WebRTCService...');
      Get.put(WebRTCService());
    }
    
    // CRITICAL FIX: Get call session to check if BFF match
    bool isBffMatch = false;
    try {
      final callSession = await SupabaseService.client
          .from('call_sessions')
          .select()
          .eq('id', callId)
          .single();
      isBffMatch = callSession['is_bff_match'] as bool? ?? false;
      print('📱 Is BFF Match: $isBffMatch');
    } catch (e) {
      print('⚠️ Failed to fetch call session: $e');
    }
    
    // CRITICAL FIX: Initialize WebRTC and join the call as RECEIVER (same as CallKit does)
    final webrtcService = Get.find<WebRTCService>();
    await webrtcService.initializeCall(
      roomId: callId,
      callType: callType == 'video' ? CallType.video : CallType.audio,
      matchId: matchId ?? '',
      isBffMatch: isBffMatch,
      isInitiator: false, // RECEIVER role (accepting call via push notification)
    );
    
    print('✅ Joined call successfully via push notification');
    
    // CRITICAL FIX: Subscribe to call session updates to detect remote hangup (same as CallKit does)
    try {
      final updateChannel = SupabaseService.client.channel('call_session_updates_$callId');
      updateChannel.onPostgresChanges(
        event: PostgresChangeEvent.update,
        schema: 'public',
        table: 'call_sessions',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'id',
          value: callId,
        ),
        callback: (payload) {
          final newState = payload.newRecord['state'];
          print('📱 [Push] Call session state updated: $newState');
          if (newState == 'disconnected' || newState == 'failed' || newState == 'canceled' || 
              newState == 'declined' || newState == 'timeout' || newState == 'ended') {
            print('📱 [Push] Remote ended/canceled the call. State: $newState');
            webrtcService.endCall();
            if (Get.isOverlaysOpen) Get.back();
          }
        },
      ).subscribe();
    } catch (e) {
      print('❌ [Push] Failed to subscribe to call session updates: $e');
    }
    
    // Create call payload
    final payload = CallPayload(
      userId: callerId ?? '',
      name: callerName,
      username: callerName,
      imageUrl: callerImageUrl,
      callType: callType == 'video' ? CallType.video : CallType.audio,
      callAction: CallAction.join,
      notificationId: callId,
      webrtcRoomId: callId,
      matchId: matchId ?? '',
      isBffMatch: isBffMatch,
    );
    
    // CRITICAL FIX: Wait for WebRTC initialization before navigation
    print('📱 Waiting for WebRTC initialization to complete...');
    await Future.delayed(Duration(milliseconds: 500));
    
    // Navigate to appropriate call screen
    if (callType == 'video') {
      print('📱 Navigating to VideoCallScreen...');
      Get.to(() => VideoCallScreen(payload: payload));
    } else {
      print('📱 Navigating to AudioCallScreen...');
      Get.to(() => AudioCallScreen(payload: payload));
    }
    
    print('✅ Push notification call acceptance complete');
  } catch (e) {
    print('❌ Error handling call notification action: $e');
    Get.snackbar(
      'Error',
      'Failed to join call: $e',
      backgroundColor: Colors.red,
      colorText: Colors.white,
    );
  }
}

/// Normalize and detect if a push payload represents an incoming call
bool _isIncomingCallPayload(Map<String, dynamic> rawData) {
  try {
    // Some backends nest custom data inside a 'data' field (iOS/APNS patterns)
    final Map<String, dynamic> data = Map<String, dynamic>.from(rawData);
    if (data['data'] is Map) {
      data.addAll(Map<String, dynamic>.from(data['data'] as Map));
    }

    final String? action = (data['action'] ?? data['type'] ?? data['event'])?.toString();
    final String? category = data['category']?.toString();
    final bool hasCallIdentifiers = data.containsKey('call_id') || data.containsKey('webrtc_room_id');

    // Accept a few common variants used by our system and push providers
    const possibleActions = {
      'incoming_call',
      'call_invite',
      'call',
      'voice_call',
      'video_call',
    };

    if ((action != null && possibleActions.contains(action)) ||
        (category != null && category.contains('call')) ||
        hasCallIdentifiers) {
      return true;
    }
  } catch (_) {}
  return false;
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
        
        // CRITICAL FIX: Clean up call listener service on sign out
        try {
          CallListenerService.forceCleanup();
          print('✅ CallListenerService cleaned up on sign out');
        } catch (e) {
          print('⚠️ Error cleaning up CallListenerService on sign out: $e');
        }
      }

      // CRITICAL FIX: Handle OAuth redirects immediately
      if (authState.event == AuthChangeEvent.signedIn) {
        print('✅ DEBUG: User signed in via OAuth, refreshing state immediately');
        
        // 🔔 CRITICAL FIX: Register FCM token after successful authentication
        try {
          NotificationService.registerFCMToken().then((_) {
            print('✅ DEBUG: FCM token registration attempted after OAuth sign-in');
          }).catchError((e) {
            print('❌ DEBUG: FCM token registration failed after OAuth sign-in: $e');
          });
        } catch (e) {
          print('❌ DEBUG: FCM token registration failed after OAuth sign-in: $e');
        }
        
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
            // Debug: Log each field to see what's missing
            print('🔍 DEBUG: Profile completeness check:');
            print('🔍 DEBUG: name: ${profile['name']} (null: ${profile['name'] == null}, empty: ${profile['name']?.toString().trim().isEmpty})');
            print('🔍 DEBUG: age: ${profile['age']} (null: ${profile['age'] == null}, zero: ${profile['age'] == 0})');
            print('🔍 DEBUG: description: ${profile['description']} (null: ${profile['description'] == null}, empty: ${profile['description']?.toString().trim().isEmpty})');
            print('🔍 DEBUG: hobbies: ${profile['hobbies']} (null: ${profile['hobbies'] == null}, empty: ${(profile['hobbies'] as List?)?.isEmpty})');
            print('🔍 DEBUG: image_urls: ${profile['image_urls']} (null: ${profile['image_urls'] == null}, empty: ${(profile['image_urls'] as List?)?.isEmpty})');
            
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
            // Check if this is a new user (recently created profile) OR has incomplete profile
            final profileCreatedAt = DateTime.parse(profile['created_at']);
            final now = DateTime.now();
            final timeDifference = now.difference(profileCreatedAt).inMinutes;
            
            // Check if profile is incomplete (missing required fields)
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
            
            if (timeDifference < 5 || hasIncompleteProfile) {
              // New user OR incomplete profile - go to profile creation
              print('🆕 DEBUG: New user or incomplete profile detected, navigating to profile creation');
              print('🆕 DEBUG: Time difference: ${timeDifference}min, Incomplete: $hasIncompleteProfile');
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
          
          // Detect and update location for authenticated user (non-blocking)
          LocationService.updateUserLocation().catchError((e) {
            print('❌ Location update failed: $e');
          });
          
          // AppStateService already initialized at app startup
          
          // CRITICAL FIX: Initialize Android background service
          if (Platform.isAndroid) {
            await AndroidBackgroundService.initialize();
            await AndroidBackgroundService.requestBatteryOptimizationExemption();
          }
          
          // CRITICAL FIX: Handle push notification actions
          FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
            print('📱 Push notification opened app: ${message.data}');
            final data = message.data;
            if (_isIncomingCallPayload(data)) {
              _handleCallNotificationAction(data);
            }
          });

          // Handle foreground push to show in-app call prompt immediately
          FirebaseMessaging.onMessage.listen((RemoteMessage message) {
            print('📱 Push received in foreground: ${message.data}');
            final data = message.data;
            if (_isIncomingCallPayload(data)) {
              _showIncomingCallPrompt(data);
            }
          });

          // Handle push notification when app is launched from TERMINATED state
          FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
            if (message != null) {
              final data = message.data;
              if (_isIncomingCallPayload(data)) {
                print('📱 App launched from terminated state with call notification');
                _handleCallNotificationAction(data);
              }
            }
          });
          
          // Initialize call listener service for incoming calls
          print('📞 DEBUG: About to initialize CallListenerService...');
          // Ensure push notifications are set up so receiver gets invites
          await NotificationService.initialize();
          
          try {
            await CallListenerService.initialize();
            print('📞 DEBUG: CallListenerService initialization completed');
            
            // CRITICAL FIX: For iOS, also set up additional call invitation handling
            if (Platform.isIOS) {
              print('📞 DEBUG: Setting up iOS-specific call invitation handling...');
              // The CallKitListenerService is already initialized below
              // This ensures both real-time and CallKit are working together
            }
          } catch (e) {
            print('❌ DEBUG: CallListenerService initialization failed: $e');
            // CRITICAL FIX: If CallListenerService fails on iOS, try aggressive polling
            if (Platform.isIOS) {
              print('📞 DEBUG: iOS CallListenerService failed, attempting recovery...');
              try {
                // Force reinitialize with aggressive polling
                await CallListenerService.initialize();
                print('📞 DEBUG: iOS CallListenerService recovery successful');
              } catch (recoveryError) {
                print('❌ DEBUG: iOS CallListenerService recovery failed: $recoveryError');
              }
            }
          }
          
          // Retry FCM token registration after a delay to ensure APNS is ready
          Future.delayed(Duration(seconds: 5), () async {
            try {
              await NotificationService.retryFCMTokenRegistration();
            } catch (e) {
              print('❌ DEBUG: FCM token retry failed: $e');
            }
          });
          
          // Run debug validations after a delay to ensure everything is initialized
          // TEMPORARILY DISABLED TO FIX CRASH
          // Future.delayed(Duration(seconds: 10), () async {
          //   try {
          //     print('🔧 DEBUG: Running call system validations...');
          //     await CallDebugHelper.runAllValidations();
          //   } catch (e) {
          //     print('❌ DEBUG: Validation failed: $e');
          //   }
          // });
          
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

  // Show an in-app prompt for incoming calls in foreground
  void _showIncomingCallPrompt(Map<String, dynamic> data) {
    final callerName = data['caller_name'] as String? ?? 'Unknown';
    final callType = data['call_type'] as String? ?? 'audio';

    // Avoid stacking multiple dialogs
    if (Get.isDialogOpen == true) return;

    Get.dialog(
      AlertDialog(
        title: Text('Incoming ${callType == 'video' ? 'Video' : 'Audio'} Call'),
        content: Text('from $callerName'),
        actions: [
          TextButton(
            onPressed: () async {
              // Decline: mark session declined on server and close dialog
              try {
                final callId = data['call_id'] as String?;
                if (callId != null) {
                  await SupabaseService.client
                      .from('call_sessions')
                      .update({'state': 'declined'})
                      .eq('id', callId);
                }
              } catch (e) {
                print('❌ Failed to mark call declined: $e');
              }
              Get.back();
            },
            child: const Text('Decline'),
          ),
          TextButton(
            onPressed: () async {
              Get.back();
              // Accept: use the same handler we use when tapping the push
              _handleCallNotificationAction(data);
            },
            child: const Text('Accept'),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  void _showAccountDeactivatedDialog(String userId) {
    Get.dialog(
      AlertDialog(
        title: Text('account_deactivated'.tr),
        content: Text('account_deactivated_message'.tr),
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
            child: Text('cancel'.tr),
          ),
          TextButton(
            onPressed: () async {
              Get.back();
              await _reactivateAccount(userId);
            },
            child: Text('reactivate_account'.tr),
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
      
      // Refresh location when app resumes to keep filtering accurate (non-blocking)
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
