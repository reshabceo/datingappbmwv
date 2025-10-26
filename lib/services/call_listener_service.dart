import 'dart:async';
import 'package:get/get.dart';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lovebug/ThemeController/theme_controller.dart';
import 'supabase_service.dart';
import 'webrtc_service.dart';
import '../models/call_models.dart';
import 'package:lovebug/screens/call_screens/video_call_screen.dart';
import 'package:lovebug/screens/call_screens/audio_call_screen.dart';

/// Service to listen for incoming calls in real-time
/// This is especially important for web where push notifications don't work
class CallListenerService {
  static StreamSubscription? _callSessionSubscription;
  static StreamSubscription? _webrtcRoomSubscription;
  static Timer? _pollingTimer;
  static bool _isInitialized = false;
  static final Set<String> _processedCallIds = <String>{};

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
      final callType = callData['type'] as String; // 'audio' or 'video'
      final callState = callData['state'] as String;

      // De-dupe: ignore already processed call rows
      if (_processedCallIds.contains(callId)) {
        print('📞 Ignoring duplicate call event for $callId');
        return;
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
      
      print('📞 Incoming $callType call from: $callerId');
      print('📞 Match ID: $matchId');
      print('📞 Call ID: $callId');
      
      // Get caller profile information
      final callerProfile = await _getCallerProfile(callerId);
      final callerName = callerProfile?['name'] ?? 'Someone';
      
      // Show incoming call dialog
      _showIncomingCallDialog(
        callId: callId,
        callerId: callerId,
        callerName: callerName,
        matchId: matchId,
        callType: callType,
      );
    } catch (e) {
      print('❌ Error handling incoming call: $e');
    }
  }

  /// Get caller profile information
  static Future<Map<String, dynamic>?> _getCallerProfile(String callerId) async {
    try {
      final response = await SupabaseService.client
          .from('profiles')
          .select('name, image_urls')
          .eq('id', callerId)
          .single();
      
      return response;
    } catch (e) {
      print('❌ Error fetching caller profile: $e');
      return null;
    }
  }

  /// Show incoming call dialog
  static void _showIncomingCallDialog({
    required String callId,
    required String callerId,
    required String callerName,
    required String matchId,
    required String callType,
  }) {
    final themeController = Get.find<ThemeController>();
    final isVideo = callType == 'video';

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
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isVideo ? Icons.videocam : Icons.call,
                          color: themeController.whiteColor,
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          'Incoming ${isVideo ? 'Video' : 'Audio'} Call',
                          style: TextStyle(
                            color: themeController.whiteColor,
                            fontSize: 20.sp,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      callerName,
                      style: TextStyle(
                        color: themeController.whiteColor,
                        fontSize: 22.sp,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      'is calling you...',
                      style: TextStyle(
                        color: themeController.whiteColor.withValues(alpha: 0.8),
                        fontSize: 15.sp,
                      ),
                    ),
                    SizedBox(height: 24.h),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () async {
                              Get.back();
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
                              Get.back();
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
    );
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
            // Only end call if we're not still connecting (avoid race on accept)
            if ((newState == 'disconnected' || newState == 'failed') &&
                webrtcService.callState != CallState.connecting) {
              print('📞 Remote ended the call. Cleaning up...');
              webrtcService.endCall();
              if (Get.isOverlaysOpen) Get.back();
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
      
      // Navigate to call screen - use the same screens as the caller
      if (callType == 'video') {
        print('🎯 Navigating to VideoCallScreen for RECEIVER');
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
        print('🎯 Navigating to AudioCallScreen for RECEIVER');
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

  /// Decline incoming call
  static Future<void> _declineCall(String callId) async {
    try {
      print('📞 Declining call: $callId');
      
      // Update call session state to a valid terminal value
      await SupabaseService.client
          .from('call_sessions')
          .update({
            'state': 'declined',
            'ended_at': DateTime.now().toIso8601String(),
          })
          .eq('id', callId);
      
      print('✅ Call declined');
    } catch (e) {
      print('❌ Error declining call: $e');
    }
  }

  /// Set up polling fallback to catch missed calls
  static void _setupPollingFallback(String userId) {
    print('📞 Setting up polling fallback for user: $userId');
    
    // Poll every 5 seconds for new incoming calls
    _pollingTimer = Timer.periodic(Duration(seconds: 5), (timer) async {
      try {
        // Check for new call sessions where this user is the receiver
        final response = await SupabaseService.client
            .from('call_sessions')
            .select('*')
            .eq('receiver_id', userId)
            .eq('state', 'initial')
            .gte('created_at', DateTime.now().subtract(Duration(minutes: 1)).toIso8601String());
        
        if (response.isNotEmpty) {
          print('📞 Polling detected ${response.length} missed call(s)');
          for (final callData in response) {
            print('📞 Processing missed call: ${callData['id']}');
            _handleIncomingCall(callData);
          }
        }
      } catch (e) {
        print('❌ Error in polling fallback: $e');
      }
    });
    
    print('✅ Polling fallback set up successfully');
  }

  /// Dispose and clean up
  static void dispose() {
    print('📞 Disposing CallListenerService');
    _callSessionSubscription?.cancel();
    _webrtcRoomSubscription?.cancel();
    _pollingTimer?.cancel();
    _isInitialized = false;
    _processedCallIds.clear();
  }
}

