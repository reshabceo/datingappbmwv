import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter/services.dart';
import 'package:lovebug/services/supabase_service.dart';
import 'package:lovebug/services/call_listener_service.dart';
import 'package:lovebug/services/callkit_service.dart';
import 'package:lovebug/models/call_models.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:flutter_callkit_incoming/entities/entities.dart';

// Background message handler (must be top-level function)
// Public so it can be registered in main.dart before runApp
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('📱 BACKGROUND: Handling background message: ${message.messageId}');
  print('📱 BACKGROUND: Message data: ${message.data}');
  
  final data = message.data;
  final type = data['type'];
  
  // CRITICAL FIX: Handle incoming calls in background by triggering CallKit IMMEDIATELY
  if (type == 'incoming_call' && Platform.isIOS) {
    print('📱 BACKGROUND: Incoming call detected - triggering CallKit IMMEDIATELY...');
    
    try {
      final callId = data['call_id'] as String?;
      final callerId = data['caller_id'] as String?;
      final callerName = data['caller_name'] as String? ?? 'Unknown';
      final callType = data['call_type'] as String? ?? 'video';
      final matchId = data['match_id'] as String?;
      final callerImageUrl = data['caller_image_url'] as String?;
      
      if (callId != null && callerId != null && matchId != null) {
        // Suppress repeat if recently declined
        if (NotificationService._isSuppressed(callId)) {
          print('🚫 BACKGROUND(iOS): Suppressed incoming call UI for $callId');
          return;
        }
        print('📱 BACKGROUND: CallKit data - ID: $callId, Caller: $callerName, Type: $callType');
        // De-dup: if CallKit already showing this call, skip
        try {
          final active = await FlutterCallkitIncoming.activeCalls();
          final isActive = (active ?? []).any((c) => (c['id']?.toString() ?? '') == callId);
          if (isActive) {
            print('⚠️ BACKGROUND: Call $callId already active in CallKit - skipping duplicate show');
            return;
          }
        } catch (_) {}
        
        // CRITICAL: Use showCallkitIncoming for CallKit triggering
        // This is the correct API for the current flutter_callkit_incoming version
        final params = CallKitParams(
          id: callId,
          nameCaller: callerName,
          appName: 'LoveBug',
          avatar: callerImageUrl ?? 'https://i.pravatar.cc',
          handle: callType == 'video' ? 'Incoming video call' : 'Incoming audio call',
          type: callType == 'video' ? 1 : 0,
          duration: 30000,
          textAccept: 'Accept',
          textDecline: 'Decline',
          extra: {
            'callId': callId,
            'matchId': matchId,
            'callType': callType,
            'isBffMatch': false,
            'callerId': callerId,
            'callerName': callerName,
          },
          headers: <String, dynamic>{'apiKey': 'LoveBug@123!', 'platform': 'flutter'},
          ios: IOSParams(
            iconName: 'CallKitLogo',
            handleType: 'generic',
            supportsVideo: callType == 'video',
            maximumCallGroups: 1,
            maximumCallsPerCallGroup: 1,
            audioSessionMode: 'default',
            audioSessionActive: true,
            audioSessionPreferredSampleRate: 44100.0,
            audioSessionPreferredIOBufferDuration: 0.005,
            supportsDTMF: true,
            supportsHolding: true,
            supportsGrouping: false,
            supportsUngrouping: false,
            ringtonePath: 'call_ringtone.wav',
          ),
        );
        
        // CRITICAL: Use showCallkitIncoming for CallKit triggering
        await FlutterCallkitIncoming.showCallkitIncoming(params);
        print('✅ BACKGROUND: CallKit incoming call reported successfully');

        // Verify CallKit is active; retry if needed to ensure sheet is visible
        try {
          await Future.delayed(const Duration(milliseconds: 700));
          final firstActive = await FlutterCallkitIncoming.activeCalls();
          final firstIsActive = (firstActive ?? []).any((c) => (c['id']?.toString() ?? '') == callId);
          if (!firstIsActive) {
            print('⚠️ BACKGROUND: CallKit not active after 700ms for $callId - retrying show');
            try {
              await FlutterCallkitIncoming.endAllCalls();
              print('🧹 BACKGROUND: Cleared any phantom CallKit calls before retry #1');
            } catch (_) {}
            await FlutterCallkitIncoming.showCallkitIncoming(params);
          } else {
            print('✅ BACKGROUND: CallKit active after 700ms for $callId');
          }

          await Future.delayed(const Duration(seconds: 2));
          final secondActive = await FlutterCallkitIncoming.activeCalls();
          final secondIsActive = (secondActive ?? []).any((c) => (c['id']?.toString() ?? '') == callId);
          if (!secondIsActive) {
            print('⚠️ BACKGROUND: CallKit not active after 2s for $callId - final retry show');
            try {
              await FlutterCallkitIncoming.endAllCalls();
              print('🧹 BACKGROUND: Cleared any phantom CallKit calls before retry #2');
            } catch (_) {}
            await FlutterCallkitIncoming.showCallkitIncoming(params);
          } else {
            print('✅ BACKGROUND: CallKit confirmed active after 2s for $callId');
          }
        } catch (e) {
          print('⚠️ BACKGROUND: Error verifying CallKit active state: $e');
        }
      } else {
        print('❌ BACKGROUND: Missing required call data for CallKit');
      }
    } catch (e) {
      print('❌ BACKGROUND: Error triggering CallKit: $e');
    }
  }
}

class NotificationService {
  static bool _initialized = false;
  static FirebaseMessaging? _messaging;
  static const MethodChannel _androidCallActionsChannel = MethodChannel('com.lovebug.app/call_actions');
  static const MethodChannel _androidNotificationChannel = MethodChannel('com.lovebug.app/notification');

  // Suppression cache to avoid repeated in-app invitations for same call shortly after decline
  static final Map<String, DateTime> _suppressedCallIds = <String, DateTime>{};
  static const Duration _suppressionDuration = Duration(seconds: 90);

  static bool _isSuppressed(String? callId) {
    if (callId == null || callId.isEmpty) return false;
    // Cleanup expired entries
    final now = DateTime.now();
    _suppressedCallIds.removeWhere((_, until) => until.isBefore(now));
    final until = _suppressedCallIds[callId];
    final suppressed = until != null && until.isAfter(now);
    if (suppressed) {
      print('🚫 SUPPRESS: Call $callId is suppressed until $until');
    }
    return suppressed;
  }

  static void _suppressCall(String? callId) {
    if (callId == null || callId.isEmpty) return;
    final until = DateTime.now().add(_suppressionDuration);
    _suppressedCallIds[callId] = until;
    print('✅ SUPPRESS: Call $callId suppressed until $until');
  }

  // Public helpers for other services (realtime/polling) to use suppression
  static bool isCallSuppressed(String? callId) => _isSuppressed(callId);
  static void suppressCallId(String? callId) => _suppressCall(callId);

  static Future<void> _clearAndroidCallNotification() async {
    try {
      if (Platform.isAndroid) {
        await _androidNotificationChannel.invokeMethod('clearCallNotification');
      }
    } catch (_) {}
  }

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
        // Ensure foreground banners/sounds can appear when using alert-style pushes
        await _messaging!.setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );
        print('🍎 DEBUG: iOS foreground presentation options set (alert/badge/sound)');
        
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

      // Listen for native call action intents from both Android and iOS
      _setupAndroidCallActionsBridge();

      _initialized = true;
      print('✅ NotificationService initialized (FCM token will be registered after login)');
    } catch (e) {
      print('❌ NotificationService init failed: $e');
    }
  }

  static void _setupAndroidCallActionsBridge() {
    try {
      _androidCallActionsChannel.setMethodCallHandler((MethodCall call) async {
        if (call.method == 'handleCallAction') {
          final Map<dynamic, dynamic>? args = call.arguments as Map<dynamic, dynamic>?;
          final String action = (args?['action'] as String?) ?? '';
          final String? callId = args?['call_id'] as String?;
          final String callerName = (args?['caller_name'] as String?) ?? 'Unknown';
          final String callType = (args?['call_type'] as String?) ?? 'video';

          print('📲 NATIVE: Received call action from channel → action=$action, callId=$callId');

          if (action == 'accept') {
            if (callId != null && callId.isNotEmpty) {
              // Use same accept flow as Android notification accept
              _suppressCall(callId); // prevent duplicate prompts
              await CallListenerService.acceptCallFromNotification(
                callId: callId,
                callerId: (args?['caller_id'] as String?) ?? '',
                matchId: (args?['match_id'] as String?) ?? '',
                callType: callType,
              );
            }
          } else if (action == 'decline') {
            print('📲 NATIVE: Decline action received for callId=$callId');
            _suppressCall(callId);
            await _clearAndroidCallNotification();
            if (callId != null && callId.isNotEmpty) {
              try {
                await CallListenerService.declineCall(callId);
              } catch (_) {}
            }
          } else if (action == 'open') {
            // iOS default tap: just open app; do NOT suppress or auto-accept.
            print('📲 NATIVE: Open action received (show in-app invite) for callId=$callId');
            if (callId != null && callId.isNotEmpty) {
              // Immediately fetch and show invite if ringing to avoid race with polling
              try {
                final row = await SupabaseService.client
                    .from('call_sessions')
                    .select('id, caller_id, match_id, call_type, state')
                    .eq('id', callId)
                    .maybeSingle();
                final state = row != null ? (row['state'] as String? ?? '') : '';
                if (row != null && (state == 'initial' || state == 'ringing')) {
                  final cid = row['caller_id']?.toString() ?? '';
                  final mid = row['match_id']?.toString() ?? '';
                  final ctype = row['call_type']?.toString() ?? callType;
                  // Present the same in-app invite logic
                  await CallListenerService.showIncomingInvite(
                    callId: callId,
                    callerId: cid,
                    callerName: callerName,
                    matchId: mid,
                    callType: ctype,
                  );
                }
              } catch (_) {}
            }
          }
        }
      });
      print('✅ NATIVE: Call actions MethodChannel bridge initialized');
    } catch (e) {
      print('❌ NATIVE: Failed to initialize call actions bridge: $e');
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
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      print('📱 PUSH: Received foreground message: ${message.messageId}');
      print('📱 PUSH: Message data: ${message.data}');
      print('📱 PUSH: Message notification: ${message.notification?.title} - ${message.notification?.body}');
      await _handleForegroundMessage(message);
    });

    // Handle messages when app is opened from background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('📱 PUSH: App opened from notification: ${message.messageId}');
      print('📱 PUSH: Message data: ${message.data}');
      print('📱 PUSH: Message notification: ${message.notification?.title} - ${message.notification?.body}');
      _handleNotificationTap(message);
    });

    // Background handler must be registered in main.dart before runApp
    print('✅ FCM: Message handlers set up successfully (background handler registered in main.dart)');
  }

  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    print('📱 FOREGROUND: Handling foreground message');
    print('📱 FOREGROUND: Message data: ${message.data}');
    
    final data = message.data;
    final type = data['type'];
    
    // Foreground incoming call handling
    if (type == 'incoming_call') {
      if (Platform.isIOS) {
        print('📱 FOREGROUND(iOS): Incoming call - triggering CallKit');
        try {
          final callId = data['call_id'] as String?;
          final callerName = (data['caller_name'] as String?) ?? 'Unknown';
          final callType = (data['call_type'] as String?) ?? 'video';
          final matchId = data['match_id'] as String?;
          final callerId = data['caller_id'] as String?;
          final callerImageUrl = data['caller_image_url'] as String?;
          if (callId != null && matchId != null && callerId != null) {
            if (_isSuppressed(callId)) {
              print('🚫 FOREGROUND(iOS): Suppressed incoming call UI for $callId');
              return;
            }
            // De-dup: if CallKit already showing this call, skip
            try {
              final active = await FlutterCallkitIncoming.activeCalls();
              final isActive = (active ?? []).any((c) => (c['id']?.toString() ?? '') == callId);
              if (isActive) {
                print('⚠️ FOREGROUND(iOS): Call $callId already active in CallKit - skipping duplicate show');
                return;
              }
            } catch (_) {}
            final params = CallKitParams(
              id: callId,
              nameCaller: callerName,
              appName: 'LoveBug',
              avatar: callerImageUrl ?? 'https://i.pravatar.cc',
              handle: callType == 'video' ? 'Incoming video call' : 'Incoming audio call',
              type: callType == 'video' ? 1 : 0,
              duration: 30000,
              textAccept: 'Accept',
              textDecline: 'Decline',
              extra: {
                'callId': callId,
                'matchId': matchId,
                'callType': callType,
                'isBffMatch': false,
                'callerId': callerId,
                'callerName': callerName,
              },
              headers: <String, dynamic>{'apiKey': 'LoveBug@123!', 'platform': 'flutter'},
              ios: IOSParams(
                iconName: 'CallKitLogo',
                handleType: 'generic',
                supportsVideo: callType == 'video',
                maximumCallGroups: 1,
                maximumCallsPerCallGroup: 1,
                audioSessionMode: 'default',
                audioSessionActive: true,
                audioSessionPreferredSampleRate: 44100.0,
                audioSessionPreferredIOBufferDuration: 0.005,
                supportsDTMF: true,
                supportsHolding: true,
                supportsGrouping: false,
                supportsUngrouping: false,
                ringtonePath: 'call_ringtone.wav',
              ),
            );
            FlutterCallkitIncoming.showCallkitIncoming(params);
          }
        } catch (e) {
          print('❌ FOREGROUND(iOS): Error triggering CallKit: $e');
        }
      } else {
        // Android: allow native service to show actionable notification
        final callId = data['call_id'] as String?;
        if (_isSuppressed(callId)) {
          print('🚫 FOREGROUND(Android): Suppressed incoming call UI for $callId');
          return;
        }
        print('📱 FOREGROUND(Android): letting native notification show actions');
        _showIncomingCallNotification(data);
      }
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
      case 'incoming_call':
        if (Platform.isIOS) {
          try {
            final callId = data['call_id'] as String?;
            final callerId = data['caller_id'] as String?;
            final callerName = (data['caller_name'] as String?) ?? 'Unknown';
            final callType = (data['call_type'] as String?) ?? 'video';
            final matchId = data['match_id'] as String?;
            final callerImageUrl = data['caller_image_url'] as String?;
            if (callId != null && callerId != null && matchId != null) {
              final payload = CallPayload(
                userId: callerId,
                name: callerName,
                username: callerName,
                imageUrl: callerImageUrl,
                callType: callType == 'video' ? CallType.video : CallType.audio,
                callAction: CallAction.create,
                notificationId: callId,
                webrtcRoomId: callId,
                matchId: matchId,
                isBffMatch: false,
              );
              CallKitService.showIncomingCall(payload: payload);
            }
          } catch (e) {
            print('❌ TAP(iOS): Error triggering CallKit: $e');
          }
        }
        return;
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
        // Do not auto-join on Android (use notification actions or in-app invite)
        if (Platform.isAndroid) {
          // Mark to suppress the in-app invite once; user hasn't accepted yet
          CallListenerService.markOpenedFromNotificationTap();
        }
        if (Platform.isIOS) {
          // iOS CallKit flow already manages UI; no navigation here
        }
        return; // foreground only
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

  static void _showIncomingCallNotification(Map<String, dynamic> data) {
    // Show incoming call notification with action buttons
    final callerName = data['caller_name'] ?? 'Unknown';
    final callType = data['call_type'] ?? 'audio';
    final callId = data['call_id'] ?? '';
    
    print('📱 FOREGROUND: Showing incoming call notification for $callerName');
    print('📱 FOREGROUND: Call ID: $callId, Type: $callType');
    
    // The native Android service will handle showing the notification with action buttons
    // This method just logs the action - the actual notification is handled by MyFirebaseMessagingService
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
    if (_isSuppressed(callId is String ? callId : callId?.toString())) {
      print('🚫 DIALOG: Suppressed incoming call dialog for $callId');
      return;
    }
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
        _suppressCall(callId);
        _clearAndroidCallNotification();
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


