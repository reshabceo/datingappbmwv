import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_callkit_incoming/entities/entities.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:get/get.dart';
import 'package:lovebug/services/webrtc_service.dart';
import 'package:lovebug/services/supabase_service.dart';
import 'package:lovebug/screens/call_screens/video_call_screen.dart';
import 'package:lovebug/screens/call_screens/audio_call_screen.dart';
import 'package:lovebug/models/call_models.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service to handle CallKit events on iOS
/// Listens for when user accepts/declines calls through native CallKit UI
class CallKitListenerService {
  static StreamSubscription<CallEvent?>? _callEventSubscription;
  static bool _isInitialized = false;

  /// Initialize CallKit event listener (iOS only)
  static Future<void> initialize() async {
    if (!Platform.isIOS || kIsWeb) {
      print('📞 CallKitListenerService: Skipping initialization (not iOS)');
      return;
    }

    if (_isInitialized) {
      print('📞 CallKitListenerService already initialized');
      return;
    }

    print('📞 Initializing CallKitListenerService for iOS...');
    
    // Listen for CallKit events
    _callEventSubscription = FlutterCallkitIncoming.onEvent.listen((CallEvent? event) {
      if (event == null) return;
      
      print('📞 CallKit event received: ${event.event}');
      print('📞 CallKit event data: ${event.body}');
      
      _handleCallKitEvent(event);
    });
    
    _isInitialized = true;
    print('✅ CallKitListenerService initialized successfully');
  }

  /// Handle CallKit event
  static void _handleCallKitEvent(CallEvent event) {
    switch (event.event) {
      case Event.actionCallAccept:
        print('📞 User ACCEPTED call via CallKit');
        _onCallAccepted(event.body);
        break;
        
      case Event.actionCallDecline:
        print('📞 User DECLINED call via CallKit');
        _onCallDeclined(event.body);
        break;
        
      case Event.actionCallEnded:
        print('📞 User ENDED call via CallKit');
        _onCallEnded(event.body);
        break;
        
      case Event.actionCallTimeout:
        print('📞 Call TIMEOUT via CallKit');
        _onCallTimeout(event.body);
        break;
        
      default:
        print('📞 Unhandled CallKit event: ${event.event}');
    }
  }

  /// Handle call accepted
  static Future<void> _onCallAccepted(Map<String, dynamic>? body) async {
    try {
      if (body == null) {
        print('❌ No call data in accept event');
        return;
      }

      print('📞 Processing accepted call...');
      print('📞 Call body: $body');
      
      // Extract call info from extra data - FIX: Safe type casting
      final extraRaw = body['extra'];
      Map<String, dynamic>? extra;
      if (extraRaw is Map) {
        extra = Map<String, dynamic>.from(extraRaw);
      } else {
        print('❌ No extra data in call or wrong type: ${extraRaw.runtimeType}');
        return;
      }

      final callId = extra['callId'] as String?;
      final matchId = extra['matchId'] as String?;
      final callType = extra['callType'] as String?; // 'audio' or 'video'
      final isBffMatch = extra['isBffMatch'] as bool? ?? false;
      final callerId = extra['callerId'] as String?;
      final callerName = extra['callerName'] as String? ?? 'Someone';

      if (callId == null || matchId == null || callType == null) {
        print('❌ Missing required call data: callId=$callId, matchId=$matchId, callType=$callType');
        return;
      }

      print('📞 Call ID: $callId');
      print('📞 Match ID: $matchId');
      print('📞 Call Type: $callType');
      print('📞 Is BFF Match: $isBffMatch');

      // Update call session state to connecting
      await SupabaseService.client
          .from('call_sessions')
          .update({'state': 'connecting'})
          .eq('id', callId);
      
      print('✅ Call state updated to connecting');

      // Initialize WebRTC service if not already registered
      if (!Get.isRegistered<WebRTCService>()) {
        print('📞 Registering WebRTCService...');
        Get.put(WebRTCService());
      }

      // CRITICAL FIX: DO NOT dismiss CallKit immediately
      // Keep CallKit active until WebRTC connection is established
      
      // Navigate to call screen FIRST
      print('🍎 Navigating to VideoCallScreen as RECEIVER...');
      Get.offAll(() => VideoCallScreen(payload: CallPayload(
        userId: callerId,
        name: callerName,
        callType: callType == 'video' ? CallType.video : CallType.audio,
        callAction: CallAction.join,
        notificationId: callId,
        webrtcRoomId: callId,
        matchId: matchId,
        isBffMatch: isBffMatch,
      )));
      
      // Small delay for navigation to complete
      await Future.delayed(Duration(milliseconds: 500));
      
      // NOW trigger receiver join with polling
      print('🍎 Starting receiver join with offer polling...');
      final webrtcService = Get.find<WebRTCService>();
      
      // CRITICAL FIX: Set up CallKit lifecycle management
      webrtcService.onCallStateChanged = (state) {
        if (state == CallState.connected) {
          // Connection successful - now dismiss CallKit
          FlutterCallkitIncoming.endCall(callId);
          print('✅ CallKit dismissed after successful connection');
        } else if (state == CallState.failed || state == CallState.disconnected) {
          // Connection failed - dismiss CallKit and show error
          FlutterCallkitIncoming.endCall(callId);
          print('❌ CallKit dismissed due to connection failure');
        }
      };
      
      // CRITICAL FIX: Set timeout to dismiss CallKit if connection takes too long
      Timer(Duration(seconds: 15), () {
        if (webrtcService.callState != CallState.connected) {
          FlutterCallkitIncoming.endCall(callId);
          print('⚠️ CallKit dismissed due to connection timeout');
        }
      });
      
      await webrtcService.receiverJoinWithPolling(
        callId: callId,
        callType: callType,
        matchId: matchId,
      );
      
      print('✅ Joined call successfully via CallKit');

      // Subscribe to call session updates to detect remote hangup
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
            print('📞 [CallKit] Call session state updated: $newState');
            if ((newState == 'disconnected' || newState == 'failed') &&
                webrtcService.callState != CallState.connecting) {
              print('📞 [CallKit] Remote ended the call. Cleaning up...');
              webrtcService.endCall();
              if (Get.isOverlaysOpen) Get.back();
            }
          },
        ).subscribe();
      } catch (e) {
        print('❌ [CallKit] Failed to subscribe to call session updates: $e');
      }

      // Hint CallKit/OS we're active (best-effort; keeps plugin state in sync)
      try {
        await FlutterCallkitIncoming.activeCalls();
      } catch (_) {}
    } catch (e) {
      print('❌ Error handling accepted call: $e');
    }
  }

  /// Handle call declined
  static Future<void> _onCallDeclined(Map<String, dynamic>? body) async {
    try {
      if (body == null) return;

      // FIX: Safe type casting
      final extraRaw = body['extra'];
      Map<String, dynamic>? extra;
      if (extraRaw is Map) {
        extra = Map<String, dynamic>.from(extraRaw);
      } else {
        print('❌ No extra data in decline event or wrong type: ${extraRaw.runtimeType}');
        return;
      }

      final callId = extra['callId'] as String?;
      if (callId == null) return;

      print('📞 Declining call: $callId');

      // CRITICAL FIX: End CallKit UI first to prevent stuck UI
      await FlutterCallkitIncoming.endCall(callId);

      // Update call session state to 'declined' (user explicitly rejected)
      // This is important for analytics - tracks intentional rejections vs timeouts
      await SupabaseService.client
          .from('call_sessions')
          .update({
            'state': 'declined',
                'ended_at': DateTime.now().toIso8601String() + '+00:00',
          })
          .eq('id', callId);

      // CRITICAL FIX: Force reset WebRTC state to prevent stuck UI
      if (Get.isRegistered<WebRTCService>()) {
        final webrtcService = Get.find<WebRTCService>();
        await webrtcService.forceResetCallState();
      }
      
      print('✅ Call declined successfully');
    } catch (e) {
      print('❌ Error handling declined call: $e');
    }
  }

  /// Handle call ended
  static Future<void> _onCallEnded(Map<String, dynamic>? body) async {
    try {
      if (body == null) return;

      // FIX: Safe type casting
      final extraRaw = body['extra'];
      Map<String, dynamic>? extra;
      if (extraRaw is Map) {
        extra = Map<String, dynamic>.from(extraRaw);
      } else {
        print('❌ No extra data in ended event or wrong type: ${extraRaw.runtimeType}');
        return;
      }

      final callId = extra['callId'] as String?;
      if (callId == null) return;

      print('📞 Ending call: $callId');

      // CRITICAL FIX: End CallKit UI first to prevent stuck UI
      await FlutterCallkitIncoming.endCall(callId);
      
      // Update call session state to 'ended' (normal call termination)
      await SupabaseService.client
          .from('call_sessions')
          .update({
            'state': 'ended',
                'ended_at': DateTime.now().toIso8601String() + '+00:00',
          })
          .eq('id', callId);

      // End WebRTC call
      if (Get.isRegistered<WebRTCService>()) {
        final webrtcService = Get.find<WebRTCService>();
        await webrtcService.endCall();
        // CRITICAL FIX: Force reset call state to prevent stuck UI
        await webrtcService.forceResetCallState();
      }

      // Navigate back
      if (Get.isOverlaysOpen) {
        Get.back();
      }
      
      print('✅ Call ended successfully');
    } catch (e) {
      print('❌ Error handling ended call: $e');
    }
  }

  /// Handle call timeout
  static Future<void> _onCallTimeout(Map<String, dynamic>? body) async {
    try {
      if (body == null) return;

      // FIX: Safe type casting
      final extraRaw = body['extra'];
      Map<String, dynamic>? extra;
      if (extraRaw is Map) {
        extra = Map<String, dynamic>.from(extraRaw);
      } else {
        print('❌ No extra data in timeout event or wrong type: ${extraRaw.runtimeType}');
        return;
      }

      final callId = extra['callId'] as String?;
      if (callId == null) return;

      print('📞 Call timeout: $callId');

      // Update call session state to 'timeout' (no answer within timeout period)
      // Distinguishes from declined (active rejection) for analytics
      await SupabaseService.client
          .from('call_sessions')
          .update({
            'state': 'timeout',
                'ended_at': DateTime.now().toIso8601String() + '+00:00',
          })
          .eq('id', callId);
      
      print('✅ Call timeout handled');
    } catch (e) {
      print('❌ Error handling call timeout: $e');
    }
  }

  /// Dispose and clean up
  static void dispose() {
    print('📞 Disposing CallKitListenerService');
    _callEventSubscription?.cancel();
    _isInitialized = false;
  }
}


