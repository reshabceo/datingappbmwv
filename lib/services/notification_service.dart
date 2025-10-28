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
    if (_initialized) {
      print('🔔 FCM: NotificationService already initialized, skipping');
      return;
    }
    try {
      // Skip on web for now (push not needed for in-tab calls)
      if (kIsWeb) {
        print('🔔 FCM: Skipping FCM initialization on web platform');
        _initialized = true;
        return;
      }

      print('🔔 FCM: Starting NotificationService initialization...');
      
      // Ensure Firebase is initialized
      try {
        await Firebase.initializeApp();
        print('🔔 FCM: Firebase initialized successfully');
      } catch (e) {
        print('🔔 FCM: Firebase already initialized or error: $e');
      }

      _messaging = FirebaseMessaging.instance;
      print('🔔 FCM: FirebaseMessaging instance created');

      // Request permissions (iOS)
      if (Platform.isIOS) {
        print('🍎 DEBUG: Requesting iOS push notification permissions...');
        final permission = await _messaging!.requestPermission(
          alert: true,
          badge: true,
          sound: true,
          provisional: false,
        );
        print('🍎 DEBUG: iOS permission result: $permission');
        
        // CRITICAL: Get APNs token immediately after permission
        print('🍎 DEBUG: Attempting to get APNs token...');
        String? apnsToken = await _messaging!.getAPNSToken();
        if (apnsToken != null) {
          print('🍎 DEBUG: APNs token obtained during init: ${apnsToken.substring(0, 20)}...');
        } else {
          print('🍎 DEBUG: APNs token not available during init - will retry later');
        }
      }

      // Android-specific configuration
      if (Platform.isAndroid) {
        print('🤖 ANDROID: Configuring Android push notifications...');
        
        // Set foreground notification presentation options
        await _messaging!.setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );
        
        // Create notification channel for Android 8+
        await _createAndroidNotificationChannel();
        
        print('✅ ANDROID: Android push notification configuration completed');
      }

      // Set up message handlers
      _setupMessageHandlers();

      _initialized = true;
      print('✅ NotificationService initialized (FCM token will be registered after login)');
    } catch (e) {
      print('❌ NotificationService init failed: $e');
    }
  }

  /// Create Android notification channel for call notifications
  static Future<void> _createAndroidNotificationChannel() async {
    if (!Platform.isAndroid) return;
    
    try {
      print('🤖 ANDROID: Creating notification channel for call notifications...');
      
      // This will be handled by the native Android code
      // The channel should be created in MainActivity.java
      print('🤖 ANDROID: Notification channel creation delegated to native Android code');
    } catch (e) {
      print('❌ ANDROID: Error creating notification channel: $e');
    }
  }

  /// Register FCM token for the current user (call this after login)
  static Future<void> registerFCMToken() async {
    if (!_initialized || _messaging == null) {
      print('❌ FCM: NotificationService not initialized');
      return;
    }

    print('🔔 FCM: Starting FCM token registration...');
    print('🔔 FCM: Platform: ${Platform.isAndroid ? "Android" : Platform.isIOS ? "iOS" : "Other"}');

    try {
      // iOS-specific: Ensure APNS token is available first
      if (Platform.isIOS) {
        print('🍎 DEBUG: iOS detected - checking APNS token...');

        // Wait for APNS token to be available with exponential backoff
        String? apnsToken;
        int attempts = 0;
        int delayMs = 500; // Start with 500ms delay
        
        while (apnsToken == null && attempts < 20) { // Increased attempts
          apnsToken = await _messaging!.getAPNSToken();
          if (apnsToken == null) {
            print('🍎 DEBUG: APNS token not ready, waiting... (attempt ${attempts + 1}/20)');
            await Future.delayed(Duration(milliseconds: delayMs));
            attempts++;
            // Exponential backoff: 500ms, 1s, 2s, 4s, 8s, then 8s max
            delayMs = delayMs < 8000 ? delayMs * 2 : 8000;
          } else {
            print('🍎 DEBUG: APNS token obtained: ${apnsToken.substring(0, 20)}...');
          }
        }

        if (apnsToken == null) {
          print('❌ DEBUG: APNS token not available after 20 attempts - trying FCM anyway');
          // Don't return, try FCM token anyway
        }
      }

      // Get FCM token
      print('🔔 FCM: Requesting FCM token...');
      final token = await _messaging!.getToken() ?? '';
      print('🔔 FCM: FCM Token obtained: ${token.isNotEmpty ? "YES" : "NO"}');
      if (token.isNotEmpty) {
        print('🔔 FCM: FCM Token: ${token.substring(0, 20)}...');
        print('🔔 FCM: Storing FCM token in database...');
        await SupabaseService.updateFCMToken(token);
        print('✅ FCM: FCM Token stored in database successfully');

        // Listen for token refresh
        _messaging!.onTokenRefresh.listen((newToken) async {
          print('🔔 FCM: FCM token refresh detected');
          await SupabaseService.updateFCMToken(newToken);
          print('✅ FCM: FCM token refreshed and stored: ${newToken.substring(0, 20)}...');
        });
      } else {
        print('❌ FCM: FCM Token is empty!');
        
        // Platform-specific fallback: Try again after a longer delay
        if (Platform.isIOS) {
          print('🍎 IOS: iOS FCM fallback - retrying in 10 seconds...');
          Future.delayed(Duration(seconds: 10), () async {
            try {
              final retryToken = await _messaging!.getToken() ?? '';
              if (retryToken.isNotEmpty) {
                print('🍎 IOS: FCM Token obtained on retry: ${retryToken.substring(0, 20)}...');
                await SupabaseService.updateFCMToken(retryToken);
                print('✅ IOS: FCM Token stored in database on retry');
              } else {
                print('❌ IOS: FCM Token still empty on retry');
                // Final fallback: Try one more time after another delay
                Future.delayed(Duration(seconds: 15), () async {
                  try {
                    final finalToken = await _messaging!.getToken() ?? '';
                    if (finalToken.isNotEmpty) {
                      print('🍎 IOS: FCM Token obtained on final retry: ${finalToken.substring(0, 20)}...');
                      await SupabaseService.updateFCMToken(finalToken);
                      print('✅ IOS: FCM Token stored in database on final retry');
                    } else {
                      print('❌ IOS: FCM Token still empty on final retry - giving up');
                    }
                  } catch (e) {
                    print('❌ IOS: FCM final retry failed: $e');
                  }
                });
              }
            } catch (e) {
              print('❌ IOS: FCM retry failed: $e');
            }
          });
        } else if (Platform.isAndroid) {
          print('🤖 ANDROID: Android FCM fallback - retrying in 5 seconds...');
          Future.delayed(Duration(seconds: 5), () async {
            try {
              final retryToken = await _messaging!.getToken() ?? '';
              if (retryToken.isNotEmpty) {
                print('🤖 ANDROID: FCM Token obtained on retry: ${retryToken.substring(0, 20)}...');
                await SupabaseService.updateFCMToken(retryToken);
                print('✅ ANDROID: FCM Token stored in database on retry');
              } else {
                print('❌ ANDROID: FCM Token still empty on retry');
                // Android-specific: Try one more time with longer delay
                Future.delayed(Duration(seconds: 10), () async {
                  try {
                    final finalToken = await _messaging!.getToken() ?? '';
                    if (finalToken.isNotEmpty) {
                      print('🤖 ANDROID: FCM Token obtained on final retry: ${finalToken.substring(0, 20)}...');
                      await SupabaseService.updateFCMToken(finalToken);
                      print('✅ ANDROID: FCM Token stored in database on final retry');
                    } else {
                      print('❌ ANDROID: FCM Token still empty on final retry - giving up');
                    }
                  } catch (e) {
                    print('❌ ANDROID: FCM final retry failed: $e');
                  }
                });
              }
            } catch (e) {
              print('❌ ANDROID: FCM retry failed: $e');
            }
          });
        }
      }
    } catch (e) {
      print('❌ Failed to register FCM token: $e');
    }
  }

  static void _setupMessageHandlers() {
    print('🔔 FCM: Setting up message handlers...');
    
    // Handle messages when app is in foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('📱 PUSH: Received foreground message: ${message.messageId}');
      print('📱 PUSH: Message data: ${message.data}');
      print('📱 PUSH: Message notification: ${message.notification?.title} - ${message.notification?.body}');
      _handleForegroundMessage(message);
    });

    // Handle messages when app is opened from background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('📱 PUSH: App opened from notification: ${message.messageId}');
      print('📱 PUSH: Message data: ${message.data}');
      print('📱 PUSH: Message notification: ${message.notification?.title} - ${message.notification?.body}');
      _handleNotificationTap(message);
    });

    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    print('✅ FCM: Message handlers set up successfully');
  }

  static void _handleForegroundMessage(RemoteMessage message) {
    print('📱 FOREGROUND: Handling foreground message');
    print('📱 FOREGROUND: Message data: ${message.data}');
    
    final data = message.data;
    final type = data['type'];
    
    // CRITICAL FIX: Handle incoming call in foreground - don't show push notification
    if (type == 'incoming_call') {
      print('📱 FOREGROUND: Incoming call detected - CallListenerService should handle this via real-time');
      // Don't show push notification UI - let CallListenerService handle it via real-time listener
      // This prevents duplicate notifications when app is open
      return;
    }
    
    // For non-call notifications, show in-app notification
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
    print('📞 CALL: Handling incoming call notification');
    print('📞 CALL: Data received: $data');
    
    final callId = data['call_id'];
    final callerName = data['caller_name'];
    final callType = data['call_type'] ?? 'audio';
    
    print('📞 CALL: Call ID: $callId');
    print('📞 CALL: Caller Name: $callerName');
    print('📞 CALL: Call Type: $callType');
    
    if (callId != null) {
      print('📞 CALL: Navigating to call screen with call data');
      // Navigate to call screen with call data
      Get.toNamed('/call', arguments: {
        'callId': callId,
        'callerName': callerName,
        'callType': callType,
        'isIncoming': true,
      });
    } else {
      print('⚠️ CALL: Missing call ID, falling back to matches screen');
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

  // Method to manually retry FCM token registration
  static Future<void> retryFCMTokenRegistration() async {
    print('🔄 DEBUG: Manually retrying FCM token registration...');
    await registerFCMToken();
  }
}


