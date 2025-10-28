import 'package:get/get.dart';
import 'package:lovebug/models/call_models.dart';
import 'package:lovebug/services/supabase_service.dart';
import 'package:lovebug/services/webrtc_service.dart';
import 'package:lovebug/services/callkit_service.dart';
import 'package:lovebug/services/push_notification_service.dart';
import 'package:lovebug/screens/call_screens/video_call_screen.dart';
import 'package:lovebug/screens/call_screens/audio_call_screen.dart';
import 'package:uuid/uuid.dart';

class CallController extends GetxController {
  static CallController get instance => Get.find<CallController>();

  final RxList<CallSession> _callHistory = <CallSession>[].obs;
  final RxBool _isInCall = false.obs;
  final Rx<CallSession?> _currentCall = Rx<CallSession?>(null);

  // Getters
  List<CallSession> get callHistory => _callHistory;
  bool get isInCall => _isInCall.value;
  CallSession? get currentCall => _currentCall.value;

  @override
  void onInit() {
    super.onInit();
    _loadCallHistory();
  }

  Future<void> _loadCallHistory() async {
    try {
      final currentUserId = SupabaseService.currentUser?.id;
      if (currentUserId == null) return;

      final response = await SupabaseService.client
          .from('call_sessions')
          .select('*')
          .or('caller_id.eq.$currentUserId,receiver_id.eq.$currentUserId')
          .order('created_at', ascending: false);

      _callHistory.value = response
          .map<CallSession>((json) => CallSession.fromJson(json))
          .toList();
    } catch (e) {
      print('Error loading call history: $e');
    }
  }

  Future<void> initiateCall({
    required String matchId,
    required String receiverId,
    required String receiverName,
    required String receiverImage,
    required String receiverFcmToken,
    required CallType callType,
    required bool isBffMatch,
  }) async {
    try {
      final currentUserId = SupabaseService.currentUser?.id;
      if (currentUserId == null) return;

      // CRITICAL DEBUG: Log call initiation details
      print('🎯 ===========================================');
      print('🎯 CALL INITIATION DEBUG');
      print('🎯 ===========================================');
      print('🎯 User Role: CALLER (Initiator)');
      print('🎯 Caller ID: $currentUserId');
      print('🎯 Receiver ID: $receiverId');
      print('🎯 Receiver Name: $receiverName');
      print('🎯 Call Type: ${callType == CallType.video ? "VIDEO" : "AUDIO"}');
      print('🎯 Match ID: $matchId');
      print('🎯 BFF Match: $isBffMatch');
      print('🎯 ===========================================');

      // Generate unique IDs - use the SAME id for call, room and notification
      final callId = const Uuid().v4();
      final roomId = callId;
      final notificationId = callId;

      // Create call session
      final callSession = CallSession(
        id: callId,
        matchId: matchId,
        callerId: currentUserId,
        receiverId: receiverId,
        type: callType,
        state: CallState.initial,
        createdAt: DateTime.now(),
        isBffMatch: isBffMatch,
        startedAt: DateTime.now().toIso8601String(),
        callType: callType,
      );

      // Store call session in database
      await SupabaseService.client.from('call_sessions').insert(callSession.toJson());

      // Create call payload (roomId == callId, notificationId == callId)
      final payload = CallPayload(
        userId: currentUserId,
        name: SupabaseService.currentUser?.userMetadata?['name'] ?? 'Unknown',
        username: receiverName,
        imageUrl: receiverImage,
        fcmToken: receiverFcmToken,
        callType: callType,
        callAction: CallAction.create,
        notificationId: notificationId,
        webrtcRoomId: roomId,
        matchId: matchId,
        isBffMatch: isBffMatch,
      );

      // Start local call FIRST (don't wait for push notification)
      _startLocalCall(payload, receiverId);

      // Send notification to receiver (non-blocking, fire and forget)
      _sendCallNotification(payload).catchError((e) {
        print('⚠️ Push notification failed (continuing with call anyway): $e');
      });

    } catch (e) {
      print('Error initiating call: $e');
      Get.snackbar('Error', 'Failed to start call');
    }
  }

  Future<void> _sendCallNotification(CallPayload payload) async {
    try {
      // Get receiver ID from the match
      final receiverId = await _getReceiverId(payload.matchId ?? '');
      if (receiverId == null) {
        print('⚠️ Could not find receiver ID for match: ${payload.matchId}');
        return;
      }

      // Get receiver's name
      final receiverProfile = await SupabaseService.getProfile(receiverId);
      final receiverName = receiverProfile?['name'] ?? 'Unknown';

      // Send incoming call notification using our unified system
      await PushNotificationService.sendIncomingCallNotification(
        userId: receiverId,
        callerName: payload.name ?? 'Unknown',
        callId: payload.webrtcRoomId ?? '',
        callType: payload.callType?.name ?? 'audio', // 'audio' or 'video'
      );

      print('✅ Call notification sent to $receiverName');
    } catch (e) {
      print('Error sending call notification: $e');
    }
  }

  Future<String?> _getReceiverId(String matchId) async {
    try {
      final response = await SupabaseService.client
          .from('matches')
          .select('user_id_1, user_id_2')
          .eq('id', matchId)
          .single();

      final currentUserId = SupabaseService.currentUser?.id;
      if (currentUserId == null) return null;

      return response['user_id_1'] == currentUserId 
          ? response['user_id_2'] 
          : response['user_id_1'];
    } catch (e) {
      print('Error getting receiver ID: $e');
      return null;
    }
  }

  void _startLocalCall(CallPayload payload, String receiverId) {
    // CRITICAL DEBUG: Log local call start
    print('🎯 ===========================================');
    print('🎯 LOCAL CALL START DEBUG');
    print('🎯 ===========================================');
    print('🎯 User Role: CALLER (Initiator)');
    print('🎯 Call Action: ${payload.callAction}');
    print('🎯 Call Type: ${payload.callType}');
    print('🎯 Room ID: ${payload.webrtcRoomId}');
    print('🎯 Match ID: ${payload.matchId}');
    print('🎯 Receiver ID: $receiverId');
    print('🎯 ===========================================');
    
    _isInCall.value = true;
    _currentCall.value = CallSession.fromJson({
      'id': payload.notificationId,
      'match_id': payload.matchId,
      'caller_id': payload.userId,
      'receiver_id': receiverId, // FIXED: Use the actual receiver ID passed to initiateCall
      'type': payload.callType?.name,
      'state': CallState.initial.name,
      'created_at': DateTime.now().toIso8601String(),
      'is_bff_match': payload.isBffMatch,
    });

    // Navigate to appropriate call screen
    if (payload.callType == CallType.video) {
      print('🎯 Navigating to VideoCallScreen for CALLER');
      Get.to(() => VideoCallScreen(payload: payload));
    } else {
      print('🎯 Navigating to AudioCallScreen for CALLER');
      Get.to(() => AudioCallScreen(payload: payload));
    }
  }

  Future<void> answerCall(CallPayload payload) async {
    try {
      _isInCall.value = true;
      
      // Update call session
      await SupabaseService.client
          .from('call_sessions')
          .update({
            'state': CallState.connected.name,
            'receiver_id': SupabaseService.currentUser?.id,
          })
          .eq('id', payload.notificationId ?? '');

      // Navigate to call screen
      if (payload.callType == CallType.video) {
        Get.to(() => VideoCallScreen(payload: payload));
      } else {
        Get.to(() => AudioCallScreen(payload: payload));
      }
    } catch (e) {
      print('Error answering call: $e');
    }
  }

  Future<void> endCall() async {
    try {
      if (_currentCall.value != null) {
        final callSession = _currentCall.value!;
        
        // Update call session
        await SupabaseService.client
            .from('call_sessions')
            .update({
              'state': CallState.disconnected.name,
              'ended_at': DateTime.now().toIso8601String(),
            })
            .eq('id', callSession.id);

        // Send call ended notification to the other participant
        await _sendCallEndedNotification(callSession);
      }

      _isInCall.value = false;
      _currentCall.value = null;
      
      // End CallKit call
      await CallKitService.endAllCalls();
      
      // Navigate back
      Get.back();
      
    } catch (e) {
      print('Error ending call: $e');
    }
  }

  Future<void> _sendCallEndedNotification(CallSession callSession) async {
    try {
      // Get the other participant's ID
      final otherUserId = await _getReceiverId(callSession.matchId);
      if (otherUserId == null) return;

      // Get current user's name
      final currentProfile = await SupabaseService.getProfile(SupabaseService.currentUser?.id ?? '');
      final currentUserName = currentProfile?['name'] ?? 'Unknown';

      // Calculate call duration
      final startTime = DateTime.parse(callSession.startedAt);
      final endTime = DateTime.now();
      final duration = endTime.difference(startTime);
      final durationString = _formatDuration(duration);

      // Send call ended notification
      await PushNotificationService.sendCallEndedNotification(
        userId: otherUserId,
        callerName: currentUserName,
        callType: callSession.callType.name,
        duration: durationString,
      );

      print('✅ Call ended notification sent');
    } catch (e) {
      print('Error sending call ended notification: $e');
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes}m ${seconds}s';
  }

  Future<void> showIncomingCall(CallPayload payload) async {
    await CallKitService.showIncomingCall(payload: payload);
  }
}
