import 'package:get/get.dart';
import 'package:lovebug/models/call_models.dart';
import 'package:lovebug/services/supabase_service.dart';
import 'package:lovebug/services/webrtc_service.dart';
import 'package:lovebug/services/callkit_service.dart';
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

      // Generate unique IDs
      final callId = const Uuid().v4();
      final roomId = const Uuid().v4();
      final notificationId = const Uuid().v4();

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
      );

      // Store call session in database
      await SupabaseService.client.from('call_sessions').insert(callSession.toJson());

      // Create call payload
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

      // Send notification to receiver
      await _sendCallNotification(payload);

      // Start local call
      _startLocalCall(payload);

    } catch (e) {
      print('Error initiating call: $e');
      Get.snackbar('Error', 'Failed to start call');
    }
  }

  Future<void> _sendCallNotification(CallPayload payload) async {
    try {
      // Send push notification via Supabase Edge Function
      await SupabaseService.client.functions.invoke(
        'send-call-notification',
        body: payload.toJson(),
      );
    } catch (e) {
      print('Error sending call notification: $e');
    }
  }

  void _startLocalCall(CallPayload payload) {
    _isInCall.value = true;
    _currentCall.value = CallSession.fromJson({
      'id': payload.notificationId,
      'match_id': payload.matchId,
      'caller_id': payload.userId,
      'receiver_id': payload.userId, // This will be updated when receiver joins
      'type': payload.callType?.name,
      'state': CallState.initial.name,
      'created_at': DateTime.now().toIso8601String(),
      'is_bff_match': payload.isBffMatch,
    });

    // Navigate to appropriate call screen
    if (payload.callType == CallType.video) {
      Get.to(() => VideoCallScreen(payload: payload));
    } else {
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
        // Update call session
        await SupabaseService.client
            .from('call_sessions')
            .update({
              'state': CallState.disconnected.name,
              'ended_at': DateTime.now().toIso8601String(),
            })
            .eq('id', _currentCall.value!.id);
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

  Future<void> showIncomingCall(CallPayload payload) async {
    await CallKitService.showIncomingCall(payload: payload);
  }
}
