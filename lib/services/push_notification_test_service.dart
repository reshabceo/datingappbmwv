import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service for testing and debugging push notifications
/// 
/// Usage:
/// ```dart
/// final testService = PushNotificationTestService();
/// await testService.initialize();
/// await testService.testNotification();
/// ```
class PushNotificationTestService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  /// Initialize push notifications and set up listeners
  Future<void> initialize() async {
    debugPrint('=== Initializing Push Notifications ===');

    // Request permission (required for Android 13+)
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    debugPrint('✅ User granted permission: ${settings.authorizationStatus}');

    // Get FCM token
    String? token = await _fcm.getToken();
    if (token != null) {
      debugPrint('✅ FCM Token: $token');
      debugPrint('   Copy this token for testing in Firebase Console');
      
      // TODO: Save token to Supabase
      // await _saveTokenToSupabase(token);
    } else {
      debugPrint('❌ Failed to get FCM token');
    }

    // Listen for token refresh
    _fcm.onTokenRefresh.listen((newToken) {
      debugPrint('🔄 FCM Token refreshed: $newToken');
      // TODO: Update token in Supabase
    });

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Background handler is registered centrally in main.dart

    // Handle notification taps (when app was in background)
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // Check if app was opened from a terminated state via notification
    RemoteMessage? initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      debugPrint('📱 App opened from terminated state via notification');
      _handleNotificationTap(initialMessage);
    }

    debugPrint('=== Push Notifications Initialized ===');
  }

  /// Handle messages when app is in foreground
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('📨 Got a message whilst in the foreground!');
    debugPrint('   From: ${message.from}');
    debugPrint('   Message ID: ${message.messageId}');
    debugPrint('   Data: ${message.data}');

    if (message.notification != null) {
      debugPrint('   Notification Title: ${message.notification!.title}');
      debugPrint('   Notification Body: ${message.notification!.body}');
    }

    // Handle the message based on type
    _handleNotificationData(message.data);
  }

  /// Handle notification tap
  void _handleNotificationTap(RemoteMessage message) {
    debugPrint('🔔 Notification tapped!');
    debugPrint('   Message data: ${message.data}');
    
    // Handle the notification tap based on type
    _handleNotificationData(message.data);
  }

  /// Route notification data to appropriate handlers
  void _handleNotificationData(Map<String, dynamic> data) {
    final type = data['type'] as String?;

    switch (type) {
      case 'incoming_call':
        _handleIncomingCall(data);
        break;
      case 'missed_call':
        _handleMissedCall(data);
        break;
      case 'new_message':
        _handleNewMessage(data);
        break;
      case 'new_match':
        _handleNewMatch(data);
        break;
      default:
        debugPrint('⚠️ Unknown notification type: $type');
    }
  }

  void _handleIncomingCall(Map<String, dynamic> data) {
    debugPrint('📞 Handling incoming call notification');
    debugPrint('   Caller ID: ${data['callerId']}');
    debugPrint('   Call ID: ${data['callId']}');
    // TODO: Navigate to call screen or show call UI
  }

  void _handleMissedCall(Map<String, dynamic> data) {
    debugPrint('📵 Handling missed call notification');
    // TODO: Update UI or navigate to call history
  }

  void _handleNewMessage(Map<String, dynamic> data) {
    debugPrint('💬 Handling new message notification');
    debugPrint('   Sender ID: ${data['senderId']}');
    debugPrint('   Chat ID: ${data['chatId']}');
    // TODO: Navigate to chat screen
  }

  void _handleNewMatch(Map<String, dynamic> data) {
    debugPrint('💝 Handling new match notification');
    // TODO: Show match screen or celebration
  }

  /// Save FCM token to Supabase
  Future<void> _saveTokenToSupabase(String token) async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        debugPrint('⚠️ No user logged in, cannot save FCM token');
        return;
      }

      await Supabase.instance.client
          .from('users')
          .update({'fcm_token': token})
          .eq('id', userId);

      debugPrint('✅ FCM token saved to Supabase');
    } catch (e) {
      debugPrint('❌ Error saving FCM token: $e');
    }
  }

  /// Test push notification by calling Supabase edge function
  Future<void> testNotification({
    String? targetUserId,
    String type = 'new_message',
    String title = 'Test Notification',
    String body = 'This is a test notification from Flutter',
  }) async {
    try {
      debugPrint('🧪 Sending test notification...');

      final userId = targetUserId ?? Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        debugPrint('❌ No user ID provided or logged in');
        return;
      }

      final response = await Supabase.instance.client.functions.invoke(
        'send-push-notification',
        body: {
          'userId': userId,
          'type': type,
          'title': title,
          'body': body,
          'data': {
            'test': 'true',
            'timestamp': DateTime.now().toIso8601String(),
          },
        },
      );

      if (response.status == 200) {
        debugPrint('✅ Test notification sent successfully');
        debugPrint('   Response: ${response.data}');
      } else {
        debugPrint('❌ Failed to send test notification');
        debugPrint('   Status: ${response.status}');
        debugPrint('   Error: ${response.data}');
      }
    } catch (e) {
      debugPrint('❌ Error sending test notification: $e');
    }
  }

  /// Get current FCM token
  Future<String?> getCurrentToken() async {
    try {
      return await _fcm.getToken();
    } catch (e) {
      debugPrint('❌ Error getting FCM token: $e');
      return null;
    }
  }

  /// Delete FCM token (logout)
  Future<void> deleteToken() async {
    try {
      await _fcm.deleteToken();
      debugPrint('✅ FCM token deleted');
    } catch (e) {
      debugPrint('❌ Error deleting FCM token: $e');
    }
  }

  /// Check notification settings
  Future<void> checkNotificationSettings() async {
    debugPrint('=== Notification Settings ===');

    final settings = await _fcm.getNotificationSettings();
    debugPrint('Authorization Status: ${settings.authorizationStatus}');
    debugPrint('Alert Setting: ${settings.alert}');
    debugPrint('Badge Setting: ${settings.badge}');
    debugPrint('Sound Setting: ${settings.sound}');
    debugPrint('Announcement Setting: ${settings.announcement}');
    debugPrint('Critical Alert Setting: ${settings.criticalAlert}');
    
    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      debugPrint('⚠️ Notifications are DENIED - ask user to enable in settings');
    } else if (settings.authorizationStatus == AuthorizationStatus.notDetermined) {
      debugPrint('⚠️ Notification permission not requested yet');
    } else {
      debugPrint('✅ Notifications are enabled');
    }

    debugPrint('==============================');
  }
}

// Background handler defined and registered in main.dart

