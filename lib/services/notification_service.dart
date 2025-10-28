import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lovebug/services/supabase_service.dart';

// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('Handling a background message: ${message.messageId}');
  print('Background message data: ${message.data}');
}

class NotificationService {
  static bool _initialized = false;
  static FirebaseMessaging? _messaging;

  static Future<void> initialize() async {
    if (_initialized) return;
    try {
      // Skip on web for now (push not needed for in-tab calls)
      if (kIsWeb) {
        _initialized = true;
        return;
      }

      // Ensure Firebase is initialized
      try {
        await Firebase.initializeApp();
      } catch (_) {}

      _messaging = FirebaseMessaging.instance;

      // Request permissions (iOS)
      if (Platform.isIOS) {
        await _messaging!.requestPermission(
          alert: true,
          badge: true,
          sound: true,
          provisional: false,
        );
        // Get APNs token (optional, for diagnostics)
        await _messaging!.getAPNSToken();
      }

      // Get FCM token
      final token = await _messaging!.getToken() ?? '';
      if (token.isNotEmpty) {
        await SupabaseService.updateFCMToken(token);
        print('FCM Token: $token');
      }

      // Listen for token refresh
      _messaging!.onTokenRefresh.listen((newToken) async {
        await SupabaseService.updateFCMToken(newToken);
        print('FCM token refreshed: $newToken');
      });

      // Set up message handlers
      _setupMessageHandlers();

      _initialized = true;
      print('✅ NotificationService initialized');
    } catch (e) {
      print('❌ NotificationService init failed: $e');
    }
  }

  static void _setupMessageHandlers() {
    // Handle messages when app is in foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Received foreground message: ${message.messageId}');
      _handleForegroundMessage(message);
    });

    // Handle messages when app is opened from background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('App opened from notification: ${message.messageId}');
      _handleNotificationTap(message);
    });

    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  static void _handleForegroundMessage(RemoteMessage message) {
    // Show in-app notification or update UI
    final notification = message.notification;
    if (notification != null) {
      _showInAppNotification(notification.title ?? 'New Message', 
                           notification.body ?? '');
    }
  }

  static void _handleNotificationTap(RemoteMessage message) {
    // Navigate to specific screen based on notification data
    final data = message.data;
    final type = data['type'];
    
    switch (type) {
      case 'new_match':
        // Navigate to matches screen
        Get.toNamed('/matches');
        break;
      case 'new_message':
        final chatId = data['chat_id'];
        if (chatId != null) {
          Get.toNamed('/chat', arguments: {'chatId': chatId});
        }
        break;
      case 'new_like':
        // Navigate to discover screen
        Get.toNamed('/discover');
        break;
      case 'account_suspended':
        // Show account suspended dialog
        _showAccountSuspendedDialog(data['message'] ?? 'Your account has been suspended');
        break;
      case 'story_reply':
        // Navigate to stories screen
        Get.toNamed('/stories');
        break;
      case 'incoming_call':
        // Handle incoming call notification
        _handleIncomingCallNotification(data);
        break;
      case 'missed_call':
        // Navigate to calls or matches screen
        Get.toNamed('/matches');
        break;
      case 'call_ended':
        // Navigate to matches screen
        Get.toNamed('/matches');
        break;
      case 'call_rejected':
        // Navigate to matches screen
        Get.toNamed('/matches');
        break;
      default:
        // Navigate to home
        Get.toNamed('/home');
    }
  }

  static void _showInAppNotification(String title, String body) {
    Get.snackbar(
      title,
      body,
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.black87,
      colorText: Colors.white,
      duration: Duration(seconds: 3),
      margin: EdgeInsets.all(16),
      borderRadius: 8,
    );
  }

  static void _showAccountSuspendedDialog(String message) {
    Get.dialog(
      AlertDialog(
        title: Text('Account Suspended'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('OK'),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  // =============================================================================
  // CALL NOTIFICATION HANDLING
  // =============================================================================

  static void _handleIncomingCallNotification(Map<String, dynamic> data) {
    final callId = data['call_id'];
    final callerName = data['caller_name'];
    final callType = data['call_type'] ?? 'audio';
    
    if (callId != null) {
      // Navigate to call screen with call data
      Get.toNamed('/call', arguments: {
        'callId': callId,
        'callerName': callerName,
        'callType': callType,
        'isIncoming': true,
      });
    } else {
      // Fallback to matches screen
      Get.toNamed('/matches');
    }
  }

  static void _showIncomingCallDialog(Map<String, dynamic> data) {
    final callId = data['call_id'];
    final callerName = data['caller_name'];
    final callType = data['call_type'] ?? 'audio';
    final callIcon = callType == 'video' ? '📹' : '📞';
    
    Get.dialog(
      AlertDialog(
        title: Row(
          children: [
            Text(callIcon, style: TextStyle(fontSize: 24)),
            SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Incoming ${callType == 'video' ? 'Video' : 'Audio'} Call'),
                  Text(
                    callerName,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.normal,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: Text('$callerName is calling you'),
        actions: [
          TextButton(
            onPressed: () {
              Get.back();
              // Handle call decline
              _handleCallAction('decline', callId, callerName, callType);
            },
            child: Text('Decline', style: TextStyle(color: Colors.red)),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              // Handle call answer
              _handleCallAction('answer', callId, callerName, callType);
            },
            child: Text('Answer'),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  static void _handleCallAction(String action, String? callId, String callerName, String callType) {
    if (callId == null) return;
    
    switch (action) {
      case 'answer':
        // Navigate to call screen
        Get.toNamed('/call', arguments: {
          'callId': callId,
          'callerName': callerName,
          'callType': callType,
          'isIncoming': true,
        });
        break;
      case 'decline':
        // Handle call decline logic
        print('Call declined: $callId');
        // You can add call decline logic here
        break;
    }
  }

  // Method to subscribe to topics
  static Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging!.subscribeToTopic(topic);
      print('Subscribed to topic: $topic');
    } catch (e) {
      print('Error subscribing to topic: $e');
    }
  }

  // Method to unsubscribe from topics
  static Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging!.unsubscribeFromTopic(topic);
      print('Unsubscribed from topic: $topic');
    } catch (e) {
      print('Error unsubscribing from topic: $e');
    }
  }
}


