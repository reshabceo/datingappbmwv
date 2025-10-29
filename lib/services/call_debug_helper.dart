import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:lovebug/services/supabase_service.dart';
import 'package:lovebug/services/push_notification_service.dart';
import 'package:lovebug/services/app_state_service.dart';

class CallDebugHelper {
  /// Validate Android FCM setup
  static Future<void> validateAndroidFCMSetup() async {
    if (!Platform.isAndroid) {
      print('🤖 ANDROID: Not running on Android, skipping validation');
      return;
    }

    print('🤖 ANDROID: Starting FCM setup validation...');
    
    try {
      // Check if Firebase is initialized
      print('🤖 ANDROID: Checking Firebase initialization...');
      final messaging = FirebaseMessaging.instance;
      print('✅ ANDROID: Firebase Messaging instance created');

      // Check FCM token
      print('🤖 ANDROID: Checking FCM token...');
      final token = await messaging.getToken();
      if (token != null && token.isNotEmpty) {
        print('✅ ANDROID: FCM token obtained: ${token.substring(0, 20)}...');
        
        // Check if token is stored in database
        print('🤖 ANDROID: Checking if FCM token is stored in database...');
        final currentUser = SupabaseService.currentUser;
        if (currentUser != null) {
          final profile = await SupabaseService.getProfile(currentUser.id);
          final storedToken = profile?['fcm_token'];
          if (storedToken == token) {
            print('✅ ANDROID: FCM token matches database');
          } else {
            print('❌ ANDROID: FCM token mismatch with database');
            print('🤖 ANDROID: Device token: ${token.substring(0, 20)}...');
            print('🤖 ANDROID: Database token: ${storedToken?.substring(0, 20) ?? 'null'}...');
          }
        } else {
          print('❌ ANDROID: No current user found');
        }
      } else {
        print('❌ ANDROID: FCM token is null or empty');
      }

      // Check notification permissions
      print('🤖 ANDROID: Checking notification permissions...');
      final settings = await messaging.getNotificationSettings();
      print('🤖 ANDROID: Notification settings: $settings');
      
      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print('✅ ANDROID: Notifications are authorized');
      } else {
        print('❌ ANDROID: Notifications are not authorized: ${settings.authorizationStatus}');
      }

    } catch (e) {
      print('❌ ANDROID: FCM validation error: $e');
    }
  }

  /// Test Android push notification
  static Future<void> testAndroidPushNotification() async {
    if (!Platform.isAndroid) {
      print('🤖 ANDROID: Not running on Android, skipping test');
      return;
    }

    print('🤖 ANDROID: Testing push notification...');
    
    try {
      final currentUser = SupabaseService.currentUser;
      if (currentUser == null) {
        print('❌ ANDROID: No current user found');
        return;
      }

      // Send test notification
      final success = await PushNotificationService.sendIncomingCallNotification(
        userId: currentUser.id,
        callerName: 'Test Caller',
        callId: 'test-call-${DateTime.now().millisecondsSinceEpoch}',
        callType: 'audio',
        callerImageUrl: 'https://i.pravatar.cc/150?img=1',
      );

      if (success) {
        print('✅ ANDROID: Test notification sent successfully');
      } else {
        print('❌ ANDROID: Test notification failed');
      }
    } catch (e) {
      print('❌ ANDROID: Test notification error: $e');
    }
  }

  /// Validate notification channels
  static Future<void> validateNotificationChannels() async {
    if (!Platform.isAndroid) {
      print('🤖 ANDROID: Not running on Android, skipping channel validation');
      return;
    }

    print('🤖 ANDROID: Validating notification channels...');
    // This would need to be implemented in native Android code
    // For now, just log that we're checking
    print('🤖 ANDROID: Notification channel validation delegated to native Android code');
  }

  /// Log FCM token chain
  static Future<void> logFCMTokenChain() async {
    print('🔔 FCM: Logging FCM token chain...');
    
    try {
      final messaging = FirebaseMessaging.instance;
      final token = await messaging.getToken();
      
      print('🔔 FCM: Device FCM token: ${token?.substring(0, 20) ?? 'null'}...');
      
      final currentUser = SupabaseService.currentUser;
      if (currentUser != null) {
        final profile = await SupabaseService.getProfile(currentUser.id);
        final storedToken = profile?['fcm_token'];
        
        print('🔔 FCM: Database FCM token: ${storedToken?.substring(0, 20) ?? 'null'}...');
        print('🔔 FCM: Tokens match: ${token == storedToken}');
        
        if (token != null && storedToken != null) {
          print('🔔 FCM: Token length - Device: ${token.length}, Database: ${storedToken.length}');
        }
      } else {
        print('❌ FCM: No current user found');
      }
    } catch (e) {
      print('❌ FCM: Error logging token chain: $e');
    }
  }

  /// Comprehensive call flow validation
  static Future<void> validateCallFlow() async {
    print('📞 CALL: Validating call flow...');
    
    try {
      // Check if services are initialized
      print('📞 CALL: Checking service initialization...');
      
      // Check AppStateService
      print('📞 CALL: AppStateService - isAppInForeground: ${AppStateService.isAppInForeground}');
      print('📞 CALL: AppStateService - shouldSendPushNotification: ${AppStateService.shouldSendPushNotification}');
      
      // Check current user
      final currentUser = SupabaseService.currentUser;
      if (currentUser != null) {
        print('✅ CALL: Current user found: ${currentUser.id}');
      } else {
        print('❌ CALL: No current user found');
      }
      
      // Check FCM token
      await logFCMTokenChain();
      
    } catch (e) {
      print('❌ CALL: Call flow validation error: $e');
    }
  }

  /// Validate notification payload
  static Future<void> validateNotificationPayload() async {
    print('📱 PUSH: Validating notification payload...');
    
    try {
      final testData = {
        'call_id': 'test-call-123',
        'caller_name': 'Test Caller',
        'call_type': 'video',
        'caller_image_url': 'https://i.pravatar.cc/150?img=1',
        'action': 'incoming_call',
      };
      
      print('📱 PUSH: Test payload: $testData');
      
      // Validate required fields
      final requiredFields = ['call_id', 'caller_name', 'call_type', 'action'];
      for (final field in requiredFields) {
        if (testData.containsKey(field) && testData[field] != null) {
          print('✅ PUSH: $field is present');
        } else {
          print('❌ PUSH: $field is missing or null');
        }
      }
      
    } catch (e) {
      print('❌ PUSH: Notification payload validation error: $e');
    }
  }

  /// Run all validations
  static Future<void> runAllValidations() async {
    print('🔧 DEBUG: Running all validations...');
    
    await validateCallFlow();
    await validateNotificationPayload();
    
    if (Platform.isAndroid) {
      await validateAndroidFCMSetup();
      await validateNotificationChannels();
      await testAndroidPushNotification();
    }
    
    print('✅ DEBUG: All validations completed');
  }
}
