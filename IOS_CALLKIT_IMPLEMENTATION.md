# iOS CallKit Incoming Call Implementation (Detailed)

## 1) High‑level Flow

- FCM delivers a data push with `type = incoming_call` when the iOS app is closed/background.
- A top‑level background handler runs in a background isolate and shows native CallKit UI (Accept/Decline) via `flutter_callkit_incoming`.
- When the user taps Accept/Decline on the CallKit sheet/Dynamic Island, CallKit events are forwarded to Flutter.
- Accept: CallKit UI is dismissed, app foregrounds, we navigate to the Flutter call screen and join via WebRTC receiver flow with offer polling.
- Decline/End: Call state is updated in Supabase and WebRTC state is force‑reset to avoid “stuck connecting”.

## 2) Push Payload (Contract)

Required data fields in push payload:

- `type`: `incoming_call`
- `call_id`: string
- `caller_id`: string
- `caller_name`: string
- `call_type`: `video` | `audio`
- `match_id`: string
- `caller_image_url`: string (optional)

The server ensures correct routing (e.g., decline notifications go to the caller, not the decliner).

## 3) App Entry Point – Register Background Handler Before `runApp`

The FCM background handler must be registered at process start so iOS can invoke it when the app is closed:

```12:20:lib/main.dart
import 'services/notification_service.dart' show firebaseMessagingBackgroundHandler;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Critical: must be registered at app entry point
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  // ...
}
```

## 4) Background FCM Handler – Shows CallKit

Runs in a background isolate, initializes Firebase, reads data, and invokes CallKit with the correct call type and metadata.

```12:64:lib/services/notification_service.dart
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  final data = message.data;
  if (data['type'] == 'incoming_call' && Platform.isIOS) {
    final callId = data['call_id'];
    final callerId = data['caller_id'];
    final callerName = data['caller_name'] ?? 'Unknown';
    final callType = data['call_type'] ?? 'video';
    final matchId = data['match_id'];
    final callerImageUrl = data['caller_image_url'];
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
      await CallKitService.showIncomingCall(payload: payload);
    }
  }
}
```

Notes:
- We use `flutter_callkit_incoming` to present the native CallKit sheet/Dynamic Island. The Accept/Decline UI is from CallKit (not a banner notification).
- Works when the app is terminated/backgrounded because the handler is top‑level and registered before `runApp`.

## 5) CallKit Event Handling (Accept/Decline/End)

Accept handler dismisses CallKit, foregrounds app, navigates to call screen, then joins via WebRTC with offer polling to avoid race conditions:

```128:157:lib/services/callkit_listener_service.dart
await FlutterCallkitIncoming.endCall(callId);
await Future.delayed(Duration(milliseconds: 300));
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
await Future.delayed(Duration(milliseconds: 500));
final webrtcService = Get.find<WebRTCService>();
await webrtcService.receiverJoinWithPolling(callId: callId, callType: callType, matchId: matchId);
```

Decline/End handlers dismiss CallKit and force‑reset WebRTC state and DB state:

```194:230:lib/services/callkit_listener_service.dart
await FlutterCallkitIncoming.endCall(callId);
await SupabaseService.client.from('call_sessions').update({'state': 'ended','ended_at': DateTime.now().toIso8601String()}).eq('id', callId);
final webrtcService = Get.find<WebRTCService>();
await webrtcService.endCall();
await webrtcService.forceResetCallState();
```

```231:265:lib/services/callkit_listener_service.dart
await FlutterCallkitIncoming.endCall(callId);
await SupabaseService.client.from('call_sessions').update({'state': 'declined','ended_at': DateTime.now().toIso8601String()}).eq('id', callId);
final webrtcService = Get.find<WebRTCService>();
await webrtcService.forceResetCallState();
```

Rationale:
- Ending CallKit first avoids “stuck UI”.
- Navigating before joining ensures Flutter UI exists to bind streams.
- Polling for offer (2s × 3) avoids flakiness on iOS accept‑from‑lock‑screen.

## 6) WebRTC Join (Receiver) with Offer Polling

The receiver waits for the caller’s offer in `webrtc_rooms`, then joins; if no offer arrives, it flips to caller mode safely.

```1995:2013:lib/services/webrtc_service.dart
await initializeCall(roomId: callId, callType: callType == 'video' ? CallType.video : CallType.audio, matchId: matchId, isBffMatch: false, isInitiator: false);
await _joinRoom(callId);
```

```2022:2054:lib/services/webrtc_service.dart
final response = await SupabaseService.client.from('webrtc_rooms').select('offer').eq('room_id', callId).maybeSingle();
if (response != null && response['offer'] != null && response['offer'].toString().isNotEmpty) {
  return response;
}
// also checks call_sessions.state for declined/canceled/ended
```

Additional stability fixes in WebRTC:
- SDP `bundlePolicy` changed to `balanced` for compatibility.
- When flipping roles, explicitly close and recreate the peer connection (fixes `have-local-offer` errors).

## 7) Foreground Behavior

When the app is open, we avoid duplicate push UI and rely on in‑app invitation/real‑time listener. The foreground handler short‑circuits `incoming_call` banners:

```318:324:lib/services/notification_service.dart
if (type == 'incoming_call') {
  // handled by real-time listener/in-app UI; avoid duplicate push while foreground
  return;
}
```

## 8) iOS Project Requirements

Capabilities:
- Push Notifications
- Background Modes: Remote notifications, Audio (VoIP if using PushKit; not required here)
- Proper APNs + FCM setup

AppDelegate:
- Firebase/APNs initialization; CallKit UI is driven from Dart via the plugin.

## 9) UX Specifics

- CallKit banner shows:
  - Title: “LoveBug Audio/Video”
  - Subtitle/Name: `caller_name`
  - Red/Blue buttons: Decline/Accept
- Post‑accept, the app moves to the in‑app call UI; the CallKit sheet is the system entry point, not the media UI.

## 10) Failure Handling and Safeguards

- Offer polling to avoid race after accept from lock screen.
- Early abort if call state is terminal (`declined`/`canceled`/`ended`).
- Public `forceResetCallState` to clean up WebRTC/UI on decline/end.

## 11) End‑to‑End Test Checklist

- App closed → send `incoming_call` → CallKit shows → Accept → connects within ~2–6s.
- App locked → unlock → shows correct call type and name.
- Decline from CallKit → caller receives “declined”; receiver doesn’t ring again.
- Repeat accept/decline without stuck states.
- Cross‑platform: Android initiates → iOS accepts via CallKit → connection stable.

---

Document owner: Call/RTC subsystem
Last updated: 2025-10-30


