import 'package:flutter_callkit_incoming/entities/entities.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:lovebug/models/call_models.dart';

class CallKitService {
  static Future<void> showIncomingCall({
    required CallPayload payload,
  }) async {
    final params = CallKitParams(
      id: payload.notificationId,
      nameCaller: payload.username ?? payload.name,
      appName: 'LoveBug',
      avatar: payload.imageUrl ?? 'https://i.pravatar.cc',
      handle: payload.callType == CallType.video
          ? 'Incoming video call'
          : 'Incoming audio call',
      // 0 = audio, 1 = video in flutter_callkit_incoming
      type: payload.callType == CallType.video ? 1 : 0,
      duration: 30000,
      textAccept: 'Accept',
      textDecline: 'Decline',
      missedCallNotification: NotificationParams(
        showNotification: true,
        isShowCallback: true,
        subtitle: 'Missed call',
        callbackText: 'Call back',
      ),
      extra: {
        'callId': payload.webrtcRoomId ?? payload.notificationId,
        'matchId': payload.matchId,
        'callType': payload.callType?.name ?? 'audio',
        'isBffMatch': payload.isBffMatch ?? false,
        'callerId': payload.userId,
        'callerName': payload.name ?? payload.username ?? 'Unknown',
        ...payload.toJson(),
      },
      headers: <String, dynamic>{'apiKey': 'LoveBug@123!', 'platform': 'flutter'},
      android: AndroidParams(
        isCustomNotification: true,
        isShowLogo: false,
        ringtonePath: 'system_ringtone_default',
        backgroundColor: '#fa828f',
        actionColor: '#4CAF50',
        textColor: '#ffffff',
        incomingCallNotificationChannelName: "Incoming Call",
        missedCallNotificationChannelName: "Missed Call",
        isShowCallID: false,
      ),
      ios: IOSParams(
        iconName: 'CallKitLogo',
        // Use a valid handle type to ensure CallKit renders correctly
        // Valid values include 'generic', 'number', 'email'
        handleType: 'generic',
        supportsVideo: true,
        maximumCallGroups: 2,
        maximumCallsPerCallGroup: 1,
        audioSessionMode: 'default',
        audioSessionActive: true,
        audioSessionPreferredSampleRate: 44100.0,
        audioSessionPreferredIOBufferDuration: 0.005,
        supportsDTMF: true,
        supportsHolding: true,
        supportsGrouping: false,
        supportsUngrouping: false,
        ringtonePath: 'system_ringtone_default',
      ),
    );
    await FlutterCallkitIncoming.showCallkitIncoming(params);
  }

  static Future<void> endAllCalls() async {
    await FlutterCallkitIncoming.endAllCalls();
  }
}
