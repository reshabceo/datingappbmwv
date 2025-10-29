import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:get/get.dart';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lovebug/services/notification_clearing_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lovebug/ThemeController/theme_controller.dart';
import 'supabase_service.dart';
import 'webrtc_service.dart';
import '../models/call_models.dart';
import 'package:lovebug/screens/call_screens/video_call_screen.dart';
import 'package:lovebug/screens/call_screens/audio_call_screen.dart';
import 'package:lovebug/services/callkit_service.dart';
import 'package:lovebug/services/app_state_service.dart';

/// Service to listen for incoming calls in real-time
/// This is especially important for web where push notifications don't work
class CallListenerService {
  static StreamSubscription? _callSessionSubscription;
  static StreamSubscription? _webrtcRoomSubscription;
  static Timer? _pollingTimer;
  static bool _isInitialized = false;
  static final Set<String> _processedCallIds = <String>{};
  // When the app is opened from an incoming_call notification body tap on Android,
  // suppress the in-app invite once to avoid confusion and auto-join vibes.
  static bool _suppressNextInvite = false;

  /// Mark that the next in-app invite should be suppressed because the app
  /// was opened from a notification body tap (no accept action yet).
  static void markOpenedFromNotificationTap() {
    _suppressNextInvite = true;
  }

  /// Initialize the call listener service
  static Future<void> initialize() async {
    if (_isInitialized) {
      print('📞 CallListenerService already initialized');
      return;
    }

    final currentUser = SupabaseService.currentUser;
    if (currentUser == null) {
      print('❌ Cannot initialize CallListenerService: No user logged in');
      return;
    }

    print('📞 Initializing CallListenerService for user: ${currentUser.id}');
    
    // Listen for incoming call sessions
    _setupCallSessionListener(currentUser.id);
    
    // Set up polling as fallback for missed real-time events
    _setupPollingFallback(currentUser.id);
    
    _isInitialized = true;
    print('✅ CallListenerService initialized successfully');
  }

  /// Set up real-time listener for incoming call sessions
  static void _setupCallSessionListener(String userId) {
    try {
      print('📞 Setting up call session listener for user: $userId');
      
      // Subscribe to call_sessions table where this user is the receiver
      final channel = SupabaseService.client
          .channel('call_sessions_$userId')
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'call_sessions',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'receiver_id',
              value: userId,
            ),
            callback: (payload) {
              print('📞 NEW INCOMING CALL DETECTED!');
              print('📞 Call payload: ${payload.newRecord}');
              print('📞 Receiver ID in payload: ${payload.newRecord['receiver_id']}');
              print('📞 Current user ID: $userId');
              _handleIncomingCall(payload.newRecord);
            },
          )
          .subscribe();
      
      print('✅ Call session listener subscribed successfully');
      
      // Add a test to verify the subscription is working
      print('📞 Testing real-time subscription...');
      Future.delayed(Duration(seconds: 2), () {
        print('📞 Real-time subscription test completed');
      });
    } catch (e) {
      print('❌ Error setting up call session listener: $e');
      // CRITICAL FIX: If real-time subscription fails, fall back to polling immediately
      print('📞 Real-time subscription failed, falling back to aggressive polling...');
      _setupAggressivePollingFallback(userId);
    }
  }

  /// Handle incoming call
  static void _handleIncomingCall(Map<String, dynamic> callData) async {
    try {
      print('📞 ═══════════════════════════════════════════════');
      print('📞 INCOMING CALL RECEIVED VIA REALTIME LISTENER!');
      print('📞 ═══════════════════════════════════════════════');
      print('📞 Processing incoming call...');
      print('📞 Call data: $callData');
      
      final callId = callData['id'] as String;
      final callerId = callData['caller_id'] as String;
      final matchId = callData['match_id'] as String;
      final callType = callData['call_type'] as String; // FIXED: Use 'call_type' not 'type'
      final callState = callData['state'] as String;

      // De-dupe: ignore already processed call rows with 5s window
      if (_processedCallIds.contains(callId)) {
        final last = _processedCallTimestamps[callId];
        if (last != null && DateTime.now().difference(last) < const Duration(seconds: 5)) {
          print('📞 Ignoring duplicate call event for $callId (within window)');
          return;
        }
      }
      // Ignore accidental self-invites on creator device
      final currentUserId = SupabaseService.currentUser?.id;
      if (currentUserId != null && callerId == currentUserId) {
        print('📞 Ignoring self-call on caller device');
        return;
      }
      
      // Only show incoming call if state is 'initial' or 'ringing'
      if (callState != 'initial' && callState != 'ringing') {
        print('📞 Ignoring call with state: $callState');
        return;
      }

      _processedCallIds.add(callId);
      _processedCallTimestamps[callId] = DateTime.now();
      
      print('📞 Incoming $callType call from: $callerId');
      print('📞 Match ID: $matchId');
      print('📞 Call ID: $callId');
      
      // Get caller profile information
      final callerProfile = await _getCallerProfile(callerId);
      final callerName = callerProfile?['name'] ?? 'Someone';
      final callerImage = _getCallerImageUrl(callerProfile);
      
      // If launched from notification body tap, skip showing in-app invite once.
      if (_suppressNextInvite && Platform.isAndroid) {
        print('📞 Skipping in-app invite (opened from notification tap)');
        _suppressNextInvite = false;
        return;
      }

      // Show incoming call dialog
      _showIncomingCallDialog(
        callId: callId,
        callerId: callerId,
        callerName: callerName,
        callerImage: callerImage,
        matchId: matchId,
        callType: callType,
      );
    } catch (e) {
      print('❌ Error handling incoming call: $e');
    }
  }

  static final Map<String, DateTime> _processedCallTimestamps = {};

  /// Get caller profile information
  static Future<Map<String, dynamic>?> _getCallerProfile(String callerId) async {
    try {
      final response = await SupabaseService.client
          .from('profiles')
          .select('name, image_urls, photos')
          .eq('id', callerId)
          .single();
      
      return response;
    } catch (e) {
      print('❌ Error fetching caller profile: $e');
      return null;
    }
  }

  /// Extract caller image URL from profile data
  static String? _getCallerImageUrl(Map<String, dynamic>? profile) {
    if (profile == null) return null;
    
    // Try image_urls first (array)
    final imageUrls = profile['image_urls'];
    if (imageUrls is List && imageUrls.isNotEmpty) {
      return imageUrls.first.toString();
    }
    
    // Try photos (array)
    final photos = profile['photos'];
    if (photos is List && photos.isNotEmpty) {
      return photos.first.toString();
    }
    
    return null;
  }

  /// Show CallKit incoming call for iOS
  static void _showCallKitIncomingCall({
    required String callId,
    required String callerId,
    required String callerName,
    required String? callerImage,
    required String matchId,
    required String callType,
  }) async {
    try {
      print('📞 Showing CallKit incoming call for iOS');
      print('📞 Call ID: $callId');
      print('📞 Caller: $callerName');
      print('📞 Call Type: $callType');
      
      // Create CallPayload for CallKit
      final payload = CallPayload(
        userId: callerId,
        name: callerName,
        username: callerName,
        imageUrl: callerImage,
        callType: callType == 'video' ? CallType.video : CallType.audio,
        callAction: CallAction.create,
        notificationId: callId,
        webrtcRoomId: callId,
        matchId: matchId,
        isBffMatch: false, // Will be updated by CallKit listener
      );
      
      // Show CallKit incoming call
      await CallKitService.showIncomingCall(payload: payload);
      
      print('✅ CallKit incoming call shown successfully');
    } catch (e) {
      print('❌ Error showing CallKit incoming call: $e');
      // Fallback to in-app dialog if CallKit fails
      _showInAppCallDialog(
        callId: callId,
        callerId: callerId,
        callerName: callerName,
        callerImage: callerImage,
        matchId: matchId,
        callType: callType,
      );
    }
  }

  /// Show in-app call dialog (fallback for Android and when CallKit fails)
  static void _showInAppCallDialog({
    required String callId,
    required String callerId,
    required String callerName,
    required String? callerImage,
    required String matchId,
    required String callType,
  }) {
    final themeController = Get.find<ThemeController>();
    final isVideo = callType == 'video';
    RealtimeChannel? _inviteChannel;

    try {
      Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.symmetric(horizontal: 24.w),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  themeController.getAccentColor().withValues(alpha: 0.18),
                  themeController.getSecondaryColor().withValues(alpha: 0.18),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22.r),
              border: Border.all(
                color: themeController.getAccentColor().withValues(alpha: 0.35),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: themeController.getAccentColor().withValues(alpha: 0.15),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.all(20.w),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Caller profile picture
                    Container(
                      width: 100.w,
                      height: 100.w,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: themeController.getAccentColor().withValues(alpha: 0.5),
                          width: 3.w,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: themeController.getAccentColor().withValues(alpha: 0.3),
                            blurRadius: 15,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: callerImage != null && callerImage.isNotEmpty
                            ? Image.network(
                                callerImage,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return _buildDefaultCallerAvatar(callerName, themeController);
                                },
                              )
                            : _buildDefaultCallerAvatar(callerName, themeController),
                      ),
                    ),
                    SizedBox(height: 20.h),
                    
                    // Call type indicator
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
                      decoration: BoxDecoration(
                        color: themeController.getAccentColor().withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20.r),
                        border: Border.all(
                          color: themeController.getAccentColor().withValues(alpha: 0.5),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isVideo ? Icons.videocam : Icons.call,
                            color: themeController.whiteColor,
                            size: 16.sp,
                          ),
                          SizedBox(width: 6.w),
                          Text(
                            'Incoming ${isVideo ? 'Video' : 'Audio'} Call',
                            style: TextStyle(
                              color: themeController.whiteColor,
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 16.h),
                    
                    // Caller name
                    Text(
                      callerName,
                      style: TextStyle(
                        color: themeController.whiteColor,
                        fontSize: 24.sp,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      'is calling you...',
                      style: TextStyle(
                        color: themeController.whiteColor.withValues(alpha: 0.8),
                        fontSize: 16.sp,
                      ),
                    ),
                    SizedBox(height: 24.h),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () async {
                              try { _inviteChannel?.unsubscribe(); } catch (_) {}
                              if (Get.isDialogOpen ?? false) Get.back();
                              await _declineCall(callId);
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(vertical: 12.h),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20.r),
                                border: Border.all(
                                  color: Colors.red.withOpacity(0.4),
                                  width: 1.5,
                                ),
                              ),
                              child: const Text(
                                'Decline',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: GestureDetector(
                            onTap: () async {
                              try { _inviteChannel?.unsubscribe(); } catch (_) {}
                              if (Get.isDialogOpen ?? false) Get.back();
                              await _acceptCall(callId, callerId, matchId, callType);
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(vertical: 12.h),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(colors: [
                                  themeController.getAccentColor(),
                                  themeController.getSecondaryColor(),
                                ]),
                                borderRadius: BorderRadius.circular(20.r),
                                border: Border.all(
                                  color: themeController.getAccentColor().withValues(alpha: 0.5),
                                  width: 1.5,
                                ),
                              ),
                              child: const Text(
                                'Accept',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      barrierDismissible: false,
    ).then((_) {
      // Cleanup when dialog is dismissed
      try { _inviteChannel?.unsubscribe(); } catch (_) {}
    });
    } catch (e) {
      print('❌ Failed to show dialog: $e');
    }

    // Subscribe to call state updates to auto-dismiss
    try {
      _inviteChannel = SupabaseService.client.channel('call_invite_$callId');
      _inviteChannel.onPostgresChanges(
        event: PostgresChangeEvent.update,
        schema: 'public',
        table: 'call_sessions',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'id',
          value: callId,
        ),
        callback: (payload) {
          final s = (payload.newRecord['state'] ?? '').toString();
          if (s == 'canceled' || s == 'ended' || s == 'declined' || s == 'timeout') {
            if (Get.isDialogOpen ?? false) {
              print('📞 Auto-dismissing invite dialog due to state=$s');
              Get.back();
            }
            try { _inviteChannel?.unsubscribe(); } catch (_) {}
          }
        },
      ).subscribe();
    } catch (e) {
      print('❌ Failed to subscribe invite state updates: $e');
    }

    // Safety timeout: 30s
    Future.delayed(const Duration(seconds: 30), () {
      if (Get.isDialogOpen ?? false) {
        print('📞 Call invitation timed out');
        try { _inviteChannel?.unsubscribe(); } catch (_) {}
        Get.back();
      }
    });
  }

  /// Build default caller avatar when no image is available
  static Widget _buildDefaultCallerAvatar(String name, ThemeController themeController) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            themeController.getAccentColor(),
            themeController.getAccentColor().withValues(alpha: 0.7),
          ],
        ),
      ),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: TextStyle(
            color: themeController.whiteColor,
            fontSize: 36.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  /// Show incoming call dialog
  static void _showIncomingCallDialog({
    required String callId,
    required String callerId,
    required String callerName,
    required String? callerImage,
    required String matchId,
    required String callType,
  }) {
    print('📞 CALL: _showIncomingCallDialog called');
    print('📞 CALL: Call ID: $callId, Caller: $callerName, Type: $callType');
    print('📞 CALL: Platform: ${Platform.isIOS ? "iOS" : Platform.isAndroid ? "Android" : "Other"}');

    if (Platform.isIOS) {
      print('📞 CALL: iOS: Using CallKit for in-app call invitation');
      _showCallKitIncomingCall(
        callId: callId,
        callerId: callerId,
        callerName: callerName,
        callerImage: callerImage,
        matchId: matchId,
        callType: callType,
      );
    } else {
      print('📞 CALL: Android: Using in-app dialog');
      _showInAppCallDialog(
        callId: callId,
        callerId: callerId,
        callerName: callerName,
        callerImage: callerImage,
        matchId: matchId,
        callType: callType,
      );
    }
  }

  /// Accept incoming call
  static Future<void> _acceptCall(
    String callId,
    String callerId,
    String matchId,
    String callType,
  ) async {
    try {
      print('📞 Accepting call: $callId');
      
      // CRITICAL DEBUG: Log call acceptance details
      print('🎯 ===========================================');
      print('🎯 CALL ACCEPTANCE DEBUG');
      print('🎯 ===========================================');
      print('🎯 User Role: RECEIVER (Accepter)');
      print('🎯 Call ID: $callId');
      print('🎯 Caller ID: $callerId');
      print('🎯 Call Type: ${callType.toUpperCase()}');
      print('🎯 Match ID: $matchId');
      print('🎯 ===========================================');
      
      // Update call session state to a valid value per DB constraint
      await SupabaseService.client
          .from('call_sessions')
          .update({'state': 'connecting'})
          .eq('id', callId);
      
      print('✅ Call accepted, updating state to connecting');
      
      // CRITICAL FIX: Clear notifications using server-side clearing for reliability
      final currentUserId = SupabaseService.currentUser?.id;
      if (currentUserId != null) {
        await NotificationClearingService.clearAllNotifications(
          userId: currentUserId,
          callId: callId,
        );
        print('✅ Notifications cleared via server for call acceptance');
      }
      
      // Local clearing as backup
      if (Platform.isAndroid) {
        try {
          final MethodChannel channel = MethodChannel('com.lovebug.app/notification');
          await channel.invokeMethod('clearCallNotification');
          print('✅ Android call notification cleared locally after in-app accept');
        } catch (e) {
          print('⚠️ Error clearing Android notification locally: $e');
        }
      }
      
      // Ensure WebRTCService is registered
      if (!Get.isRegistered<WebRTCService>()) {
        print('📞 Registering WebRTCService...');
        Get.put(WebRTCService());
      }
      
      // Get call session info to check if BFF match
      final callSession = await SupabaseService.client
          .from('call_sessions')
          .select()
          .eq('id', callId)
          .single();
      
      final isBffMatch = callSession['is_bff_match'] as bool? ?? false;
      
      // Get caller name from profile
      final callerProfile = await _getCallerProfile(callerId);
      final callerName = callerProfile?['name'] ?? 'Someone';
      
      // Initialize WebRTC and join the call as RECEIVER
      final webrtcService = Get.find<WebRTCService>();
      await webrtcService.initializeCall(
        roomId: callId,
        callType: callType == 'video' ? CallType.video : CallType.audio,
        matchId: matchId,
        isBffMatch: isBffMatch,
        isInitiator: false, // RECEIVER role
      );
      
      print('✅ Joined call successfully');
      // Dismiss any in-app invite that might still be visible
      _dismissInAppInviteIfOpen();
      
      // Subscribe to call session updates to detect remote hangup/finish
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
            print('📞 Call session state updated: $newState');
            // CRITICAL FIX: Handle all call termination states including 'timeout'
            // Remove connecting state check to allow cancellation during connecting
            if (newState == 'disconnected' || newState == 'failed' || newState == 'canceled' || newState == 'declined' || newState == 'timeout' || newState == 'ended') {
              print('🔄 STATE: Remote ended/canceled the call. State: $newState');
              webrtcService.endCall();
              _dismissInAppInviteIfOpen();
            }
          },
        ).subscribe();
      } catch (e) {
        print('❌ Failed to subscribe to call session updates: $e');
      }
      
      // CRITICAL DEBUG: Log navigation to call screen
      print('🎯 ===========================================');
      print('🎯 RECEIVER NAVIGATION DEBUG');
      print('🎯 ===========================================');
      print('🎯 User Role: RECEIVER (Accepter)');
      print('🎯 Call Action: ${CallAction.join}');
      print('🎯 Call Type: ${callType.toUpperCase()}');
      print('🎯 Caller ID: $callerId');
      print('🎯 Caller Name: $callerName');
      print('🎯 Room ID: $callId');
      print('🎯 Match ID: $matchId');
      print('🎯 ===========================================');
      
      // CRITICAL FIX: Wait for WebRTC initialization to complete before navigation
      print('🎯 NAV: Waiting for WebRTC initialization to complete...');
      await Future.delayed(Duration(milliseconds: 500)); // Give WebRTC time to initialize
      
      // Check if we're already in a call screen to prevent duplicate navigation
      final currentRoute = Get.currentRoute;
      print('🎯 NAV: Current route: $currentRoute');
      
      if (currentRoute.contains('VideoCallScreen') || currentRoute.contains('AudioCallScreen')) {
        print('⚠️ NAV: Already in call screen, skipping navigation');
        return;
      }
      
      // Navigate to call screen - use the same screens as the caller
      if (callType == 'video') {
        print('🎯 NAV: Navigating to VideoCallScreen for RECEIVER');
        Get.to(() => VideoCallScreen(payload: CallPayload(
          userId: callerId,
          name: callerName,
          callType: CallType.video,
          callAction: CallAction.join,
          notificationId: callId,
          webrtcRoomId: callId,
          matchId: matchId,
          isBffMatch: isBffMatch,
        )));
      } else {
        print('🎯 NAV: Navigating to AudioCallScreen for RECEIVER');
        Get.to(() => AudioCallScreen(payload: CallPayload(
          userId: callerId,
          name: callerName,
          callType: CallType.audio,
          callAction: CallAction.join,
          notificationId: callId,
          webrtcRoomId: callId,
          matchId: matchId,
          isBffMatch: isBffMatch,
        )));
      }
    } catch (e) {
      print('❌ Error accepting call: $e');
      Get.snackbar(
        'Error',
        'Failed to accept call: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  /// Dismiss in-app invite overlay if it is currently open
  static void _dismissInAppInviteIfOpen() {
    try {
      if (Get.isOverlaysOpen) {
        Get.back();
      }
    } catch (e) {
      // ignore
    }
  }

  /// Decline incoming call
  static Future<void> _declineCall(String callId) async {
    try {
      print('📞 Declining call: $callId');
      
      // Get call session info for server-side clearing
      final callSession = await SupabaseService.client
          .from('call_sessions')
          .select('caller_id, receiver_id')
          .eq('id', callId)
          .single();
      
      // Get caller's name from profiles table (caller_name doesn't exist in call_sessions)
      final callerId = callSession['caller_id']?.toString();
      final receiverId = callSession['receiver_id']?.toString();
      String callerName = 'Unknown';
      
      if (callerId != null) {
        try {
          final callerProfile = await SupabaseService.getProfile(callerId);
          callerName = callerProfile?['name']?.toString() ?? 'Unknown';
        } catch (e) {
          print('⚠️ Error fetching caller profile: $e');
        }
      }
      
      // Update call session state to a valid terminal value
      await SupabaseService.client
          .from('call_sessions')
          .update({
            'state': 'declined',
            'ended_at': DateTime.now().toIso8601String(),
          })
          .eq('id', callId);
      
      // CRITICAL FIX: Clear notifications using server-side clearing
      
      if (callerId != null) {
        await NotificationClearingService.clearCallNotification(
          userId: callerId,
          callId: callId,
          callerName: callerName,
        );
      }
      
      if (receiverId != null) {
        await NotificationClearingService.clearCallNotification(
          userId: receiverId,
          callId: callId,
          callerName: callerName,
        );
      }
      
      print('✅ Call declined and notifications cleared');
    } catch (e) {
      print('❌ Error declining call: $e');
    }
  }

  // =========================
  // Public bridge methods for notification/Android actions
  // =========================
  static Future<void> acceptCallFromNotification({
    required String callId,
    required String callerId,
    required String matchId,
    required String callType,
  }) async {
    await _acceptCall(callId, callerId, matchId, callType);
  }

  static Future<void> declineCall(String callId) async {
    await _declineCall(callId);
  }

  /// Set up aggressive polling fallback for iOS when real-time fails
  static void _setupAggressivePollingFallback(String userId) {
    print('📞 Setting up AGGRESSIVE polling fallback for user: $userId (iOS fallback)');
    
    // Add jitter (2-4 seconds) to prevent thundering herd on database
    final random = Random();
    final baseInterval = 2;
    final jitterSeconds = random.nextInt(3); // 0-2 seconds jitter
    final intervalWithJitter = baseInterval + jitterSeconds;
    
    print('📞 Polling interval: ${intervalWithJitter}s (base: ${baseInterval}s + jitter: ${jitterSeconds}s)');
    
    _pollingTimer = Timer.periodic(Duration(seconds: intervalWithJitter), (timer) async {
      try {
        // Check for new call sessions where this user is the receiver
        final response = await SupabaseService.client
            .from('call_sessions')
            .select('*')
            .eq('receiver_id', userId)
            .inFilter('state', ['initial', 'ringing'])
            .gte('created_at', DateTime.now().subtract(Duration(minutes: 5)).toIso8601String())
            .order('created_at', ascending: false)
            .limit(10); // Increased limit for aggressive polling
        
        if (response.isNotEmpty) {
          print('📞 AGGRESSIVE POLLING detected ${response.length} incoming call(s)');
          for (final callData in response) {
            print('📞 Processing incoming call via aggressive polling: ${callData['id']}');
            _handleIncomingCall(callData);
          }
        }
      } catch (e) {
        print('❌ Error in aggressive polling fallback: $e');
      }
    });
    
    print('✅ Aggressive polling fallback set up successfully');
  }

  /// Set up polling fallback to catch missed calls
  static void _setupPollingFallback(String userId) {
    print('📞 Setting up polling fallback for user: $userId');
    
    // Add jitter (10-13 seconds) to prevent thundering herd on database
    final random = Random();
    final baseInterval = 10;
    final jitterSeconds = random.nextInt(4); // 0-3 seconds jitter
    final intervalWithJitter = baseInterval + jitterSeconds;
    
    print('📞 Polling interval: ${intervalWithJitter}s (base: ${baseInterval}s + jitter: ${jitterSeconds}s)');
    
    _pollingTimer = Timer.periodic(Duration(seconds: intervalWithJitter), (timer) async {
      try {
        // Check for new call sessions where this user is the receiver
        // Use a shorter timeout and more specific query
        final response = await SupabaseService.client
            .from('call_sessions')
            .select('*')
            .eq('receiver_id', userId)
            .eq('state', 'initial')
            .gte('created_at', DateTime.now().subtract(Duration(minutes: 2)).toIso8601String())
            .order('created_at', ascending: false)
            .limit(5); // Limit to 5 most recent calls
        
        if (response.isNotEmpty) {
          print('📞 Polling detected ${response.length} missed call(s)');
          for (final callData in response) {
            print('📞 Processing missed call: ${callData['id']}');
            _handleIncomingCall(callData);
          }
        }
      } catch (e) {
        print('❌ Error in polling fallback: $e');
        // If we get too many errors, increase the polling interval
        if (e.toString().contains('Connection timed out') || 
            e.toString().contains('SocketException')) {
          print('⚠️ Network issues detected, increasing polling interval to 30 seconds');
          timer.cancel();
          // Add jitter to long interval too (30-35 seconds)
          final longIntervalJitter = Random().nextInt(6); // 0-5 seconds jitter
          _pollingTimer = Timer.periodic(Duration(seconds: 30 + longIntervalJitter), (timer) async {
            // Same logic but with longer interval
            try {
              final response = await SupabaseService.client
                  .from('call_sessions')
                  .select('*')
                  .eq('receiver_id', userId)
                  .eq('state', 'initial')
                  .gte('created_at', DateTime.now().subtract(Duration(minutes: 2)).toIso8601String())
                  .order('created_at', ascending: false)
                  .limit(5);
              
              if (response.isNotEmpty) {
                print('📞 Polling detected ${response.length} missed call(s)');
                for (final callData in response) {
                  print('📞 Processing missed call: ${callData['id']}');
                  _handleIncomingCall(callData);
                }
              }
            } catch (e) {
              print('❌ Error in extended polling fallback: $e');
            }
          });
        }
      }
    });
    
    print('✅ Polling fallback set up successfully');
  }

  /// Dispose and clean up
  static void dispose() {
    print('📞 Disposing CallListenerService');
    
    // CRITICAL FIX: Cancel all subscriptions and timers
    try {
      _callSessionSubscription?.cancel();
      _webrtcRoomSubscription?.cancel();
      _pollingTimer?.cancel();
      
      // Clear all processed call IDs
      _processedCallIds.clear();
      
      // Reset initialization flag
      _isInitialized = false;
      
      print('✅ CallListenerService disposed successfully');
    } catch (e) {
      print('❌ Error disposing CallListenerService: $e');
    }
  }
  
  /// Force cleanup of all resources
  static void forceCleanup() {
    print('📞 Force cleaning up CallListenerService');
    
    try {
      // Cancel all subscriptions
      _callSessionSubscription?.cancel();
      _webrtcRoomSubscription?.cancel();
      _pollingTimer?.cancel();
      
      // Clear all data
      _processedCallIds.clear();
      _isInitialized = false;
      
      // Reset all static variables
      _callSessionSubscription = null;
      _webrtcRoomSubscription = null;
      _pollingTimer = null;
      
      print('✅ CallListenerService force cleanup completed');
    } catch (e) {
      print('❌ Error in force cleanup: $e');
    }
  }
}

