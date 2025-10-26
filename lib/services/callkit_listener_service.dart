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
      
      // Extract call info from extra data
      final extra = body['extra'] as Map<String, dynamic>?;
      if (extra == null) {
        print('❌ No extra data in call');
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

      // Initialize WebRTC and join the call as RECEIVER
      final webrtcService = Get.find<WebRTCService>();
      await webrtcService.initializeCall(
        roomId: callId,
        callType: callType == 'video' ? CallType.video : CallType.audio,
        matchId: matchId,
        isBffMatch: isBffMatch,
        isInitiator: false, // RECEIVER role (accepting call via CallKit)
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

      // Navigate to call screen - use the same screens as the caller
      if (callType == 'video') {
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
      
      print('✅ Navigated to CallScreen');
    } catch (e) {
      print('❌ Error handling accepted call: $e');
    }
  }

  /// Handle call declined
  static Future<void> _onCallDeclined(Map<String, dynamic>? body) async {
    try {
      if (body == null) return;

      final extra = body['extra'] as Map<String, dynamic>?;
      if (extra == null) return;

      final callId = extra['callId'] as String?;
      if (callId == null) return;

      print('📞 Declining call: $callId');

      // Update call session state
      await SupabaseService.client
          .from('call_sessions')
          .update({
            'state': 'failed',
            'ended_at': DateTime.now().toIso8601String(),
          })
          .eq('id', callId);
      
      print('✅ Call declined successfully');
    } catch (e) {
      print('❌ Error handling declined call: $e');
    }
  }

  /// Handle call ended
  static Future<void> _onCallEnded(Map<String, dynamic>? body) async {
    try {
      if (body == null) return;

      final extra = body['extra'] as Map<String, dynamic>?;
      if (extra == null) return;

      final callId = extra['callId'] as String?;
      if (callId == null) return;

      print('📞 Ending call: $callId');

      // Update call session state
      await SupabaseService.client
          .from('call_sessions')
          .update({
            'state': 'disconnected',
            'ended_at': DateTime.now().toIso8601String(),
          })
          .eq('id', callId);

      // End WebRTC call
      if (Get.isRegistered<WebRTCService>()) {
        final webrtcService = Get.find<WebRTCService>();
        await webrtcService.endCall();
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

      final extra = body['extra'] as Map<String, dynamic>?;
      if (extra == null) return;

      final callId = extra['callId'] as String?;
      if (callId == null) return;

      print('📞 Call timeout: $callId');

      // Update call session state
      await SupabaseService.client
          .from('call_sessions')
          .update({
            'state': 'failed',
            'ended_at': DateTime.now().toIso8601String(),
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


