# 📞 Call System Test Report & Complete Fix Plan

## Executive Summary

This document provides a comprehensive analysis of all 6 test scenarios, identifies root causes, and outlines a complete implementation plan to fix all bugs while preserving existing functionality.

---

## 📋 Test Scenarios Summary

### **Test 1: iOS → Android (Android App Closed)**
**Scenario:** Call initiated from iOS to Android when Android app is closed.

**Issues Found:**
- ❌ Push notification doesn't show Accept/Deny buttons
- ❌ Shows "unknown" instead of caller name (reshab)
- ❌ When iOS cancels, Android push notification goes away but still ringing
- ❌ Doesn't show "you missed a call from reshab" notification

**Working:**
- ✅ Push notification is received
- ✅ Caller can cancel from iOS

---

### **Test 2: iOS → Android (Android App Open)**
**Scenario:** Call initiated from iOS to Android when Android app is open.

**Issues Found:**
- ❌ Push notification arrives 2 seconds after in-app invitation
- ❌ Push notification doesn't detect that accept was done from in-app
- ❌ Both notification and in-app invite remain visible simultaneously

**Working:**
- ✅ In-app invitation appears
- ✅ Video call connects when accepted from in-app
- ✅ Video call connects when accepted from push notification

---

### **Test 3: Android → iOS (iOS App Closed)**
**Scenario:** Call initiated from Android to iOS when iOS app is closed.

**Issues Found:**
- ❌ Push notification doesn't show Accept/Deny buttons
- ❌ Tapping notification takes 4-5 seconds to connect (delay)

**Working:**
- ✅ Push notification is received
- ✅ Video call connects after delay

---

### **Test 4: Android → iOS (iOS App Open)**
**Scenario:** Call initiated from Android to iOS when iOS app is open.

**Issues Found:**
- ❌ Push notification with Accept/Deny appears
- ❌ After accepting, iPhone shows video screen but displays "Call Failed"
- ❌ Android app quits immediately
- ❌ Cannot disconnect call from iOS by pressing red button

**Working:**
- ✅ Push notification with Accept/Deny buttons appears
- ✅ Call state synchronization starts

---

### **Test 5: Android → iOS (iOS App Open)**
**Scenario:** Call initiated from Android to iOS, receiver denies from iOS.

**Working:**
- ✅ Call instantly disconnected from Android
- ✅ State synchronization works correctly

---

### **Test 6: Android → iOS (iOS App Open)**
**Scenario:** Call initiated from Android to iOS, receiver denies from Android.

**Issues Found:**
- ❌ iOS push notification doesn't detect that call was denied from Android
- ❌ Push notification remains visible

**Working:**
- ✅ Miss call notification from ashley appears (correct behavior)

---

## 🔍 Root Cause Analysis

### **1. iOS Push Notifications Missing Accept/Deny Buttons (Tests 1 & 3)**

**Root Cause:**
- iOS requires VoIP push notifications to be reported to CallKit **immediately** when received in background
- The background handler (`firebaseMessagingBackgroundHandler`) exists but may not be triggering CallKit reliably
- iOS doesn't show actionable buttons for regular push notifications - only CallKit provides Accept/Deny UI
- When app is closed, the background handler must use CallKit's `reportNewIncomingCall` API

**Code Locations:**
- `lib/services/notification_service.dart` - Background handler (lines 15-65)
- `lib/services/callkit_service.dart` - CallKit service
- `supabase/functions/send-push-notification/index.ts` - Push notification payload

**Technical Details:**
- iOS requires `aps` payload with `mutable-content: 1` and a notification extension to trigger CallKit
- Background handler must be registered before `runApp()` in `main.dart`
- CallKit must be invoked within the background handler before the app wakes up

---

### **2. Android Push Notifications Missing Accept/Deny Buttons (Test 1)**

**Root Cause:**
- Android push notifications ARE configured with Accept/Deny buttons in `MyFirebaseMessagingService.java`
- However, when app is **completely closed** (not just backgrounded), the notification may not show buttons if:
  - The notification channel doesn't have proper importance settings
  - The notification is being auto-dismissed before buttons render
  - The FCM payload structure doesn't match Android's requirements

**Code Locations:**
- `android/app/src/main/java/com/lovebug/app/MyFirebaseMessagingService.java` (lines 123-187)
- `supabase/functions/send-push-notification/index.ts` (Android payload structure)

**Technical Details:**
- Android requires `priority: 'HIGH'` in the FCM message structure
- Notification channel must have `IMPORTANCE_HIGH` for call notifications
- Notification actions require proper `PendingIntent` flags with `FLAG_IMMUTABLE` on Android 12+

---

### **3. Caller Name Shows "Unknown" on Android (Test 1)**

**Root Cause:**
- The FCM payload includes `caller_name` in the data payload
- However, Android notification builder may not be extracting it correctly
- The notification body is built from `remoteMessage.getNotification().getBody()` first, which may not contain caller name
- Fallback logic exists (lines 68-74) but may not be triggered correctly

**Code Locations:**
- `android/app/src/main/java/com/lovebug/app/MyFirebaseMessagingService.java` (lines 60-74)
- `supabase/functions/send-push-notification/index.ts` (notification body construction)

**Technical Details:**
- FCM allows both `notification` payload (for display) and `data` payload (for app logic)
- When app is closed, Android shows the `notification` payload, but `data` payload is accessed when app opens
- Caller name must be in BOTH `notification.body` AND `data.caller_name` for proper display

---

### **4. Android Still Ringing After iOS Cancels (Test 1)**

**Root Cause:**
- When iOS cancels the call, it updates `call_sessions.state` to `canceled`
- Android's ongoing notification (ID 12345) should be dismissed when call state changes
- However, there's no listener for call state changes when app is closed
- The notification remains visible because there's no mechanism to clear it from background

**Code Locations:**
- `lib/services/webrtc_service.dart` - Call state listening (lines 1409-1434)
- `android/app/src/main/java/com/lovebug/app/MyFirebaseMessagingService.java` - Notification creation
- Background state synchronization missing

**Technical Details:**
- Android needs a background service or FCM data-only message to clear notifications when app is closed
- When call is canceled, send a `call_canceled` notification type that clears the ongoing notification
- Alternatively, implement a background work manager to poll call state

---

### **5. Missing "Missed Call" Notification (Test 1)**

**Root Cause:**
- Missed call notification is only sent when `state == 'canceled'` (line 1423 in webrtc_service.dart)
- This only happens if the receiver is listening to call state changes
- When app is closed, the listener doesn't exist, so missed call notification is never sent
- Server-side trigger should send missed call notification when call is canceled

**Code Locations:**
- `lib/services/webrtc_service.dart` (line 1423)
- `lib/services/push_notification_service.dart` - Missed call notification method
- Missing server-side trigger in Supabase function

**Technical Details:**
- Database trigger or edge function should detect `call_sessions.state` change to `canceled` or `timeout`
- Send missed call notification to receiver when state changes to terminal state
- Include caller name in notification

---

### **6. Push Notification Delayed When App Open (Test 2)**

**Root Cause:**
- When app is open, FCM delivers notification immediately (`onMessage`)
- But CallListenerService also triggers via real-time listener (instant)
- Push notification arrives 2 seconds later because FCM has network delay
- Both systems trigger independently without coordination

**Code Locations:**
- `lib/services/notification_service.dart` - Foreground handler (lines 311-332)
- `lib/services/call_listener_service.dart` - Real-time listener (lines 62-100)

**Technical Details:**
- Foreground FCM messages should be suppressed for incoming calls
- Real-time listener should handle all incoming calls when app is open
- Push notification should only be used as fallback or when app is closed

---

### **7. Push Notification Doesn't Detect In-App Acceptance (Test 2)**

**Root Cause:**
- When user accepts from in-app dialog, call state changes to `connecting`
- Push notification should detect this state change and dismiss itself
- However, no mechanism exists to clear notification when call is accepted from in-app
- Notification remains visible because it's not listening to call state changes

**Code Locations:**
- `lib/services/call_listener_service.dart` - Accept call handler (lines 573-723)
- `android/app/src/main/java/com/lovebug/app/MyFirebaseMessagingService.java` - Notification dismissal

**Technical Details:**
- When accepting from in-app, immediately clear notification using `NotificationManager.cancel(12345)`
- Add method channel call to clear notification from Flutter side
- Call this immediately after updating call state to `connecting`

---

### **8. iOS Shows "Call Failed" After Accept (Test 4)**

**Root Cause:**
- After accepting from CallKit, navigation happens to VideoCallScreen
- CallKit UI is dismissed with `FlutterCallkitIncoming.endCall(callId)` (line 129)
- However, WebRTC connection may fail or take time to establish
- If connection fails, CallKit shows "Call Failed" state
- Cannot disconnect because CallKit UI was already dismissed incorrectly

**Code Locations:**
- `lib/services/callkit_listener_service.dart` - Accept handler (lines 77-195)
- `lib/services/webrtc_service.dart` - Connection establishment

**Technical Details:**
- CallKit should remain active until WebRTC connection is established
- Only dismiss CallKit when connection is confirmed successful
- Handle connection failures gracefully and show proper error state
- Ensure CallKit state matches WebRTC state throughout call lifecycle

---

### **9. Android App Quits After iOS Accepts (Test 4)**

**Root Cause:**
- When iOS accepts, call state changes to `connecting`
- Android's WebRTC service may detect this change and trigger endCall logic
- Or Android app crashes due to null pointer exception when handling state change
- Need to verify Android's call state listener logic

**Code Locations:**
- `lib/services/webrtc_service.dart` - Call state listener (lines 1409-1434)
- `lib/services/call_listener_service.dart` - State change handling

**Technical Details:**
- State change from `ringing` to `connecting` should not trigger endCall
- Only terminal states (`ended`, `declined`, `canceled`) should trigger endCall
- Add proper state transition validation

---

### **10. Cannot Disconnect from iOS Red Button (Test 4)**

**Root Cause:**
- CallKit UI was dismissed too early (line 129 in callkit_listener_service.dart)
- After dismissing, CallKit is no longer in control
- Red button in VideoCallScreen may not be properly wired to endCall
- Or CallKit listeners are not properly handling disconnect event

**Code Locations:**
- `lib/services/callkit_listener_service.dart` - Call ended handler (lines 242-291)
- VideoCallScreen - Disconnect button handler
- CallKit state management

**Technical Details:**
- CallKit should remain active throughout the call
- Disconnect button should update call state AND dismiss CallKit properly
- Ensure proper cleanup sequence: update DB → end WebRTC → dismiss CallKit → navigate back

---

### **11. iOS Push Notification Doesn't Detect Android Decline (Test 6)**

**Root Cause:**
- When Android declines, call state changes to `declined`
- iOS push notification should be cleared
- However, no mechanism exists to clear iOS notification when remote side declines
- FCM data-only message should be sent to clear notification

**Code Locations:**
- `lib/services/call_listener_service.dart` - Decline handler (lines 737-754)
- iOS notification clearing mechanism missing

**Technical Details:**
- When declining, send FCM message with `type: 'call_declined'` to receiver
- iOS background handler should clear CallKit when receiving this message
- Or use CallKit's `endCall` API when state changes to `declined`

---

## 🛠️ Implementation Plan

### **Phase 1: Fix iOS Background Push Notifications with Accept/Deny**

**Task 1.1: Enhance iOS Background Handler**
- Ensure CallKit is triggered immediately in background handler
- Add proper error handling and retry logic
- Verify APNS payload structure includes all required fields

**Files to Modify:**
- `lib/services/notification_service.dart` (background handler)
- `supabase/functions/send-push-notification/index.ts` (APNS payload)

**Changes:**
1. Add immediate CallKit trigger in background handler
2. Ensure CallKit payload includes all required fields (callId, callerId, matchId, callType, callerName)
3. Add error handling and logging
4. Verify APNS payload has `mutable-content: 1` and proper category

---

### **Phase 2: Fix Android Push Notifications with Accept/Deny**

**Task 2.1: Ensure Notification Buttons Always Show**
- Verify notification channel importance settings
- Ensure FCM payload has correct priority
- Test with app completely closed

**Files to Modify:**
- `android/app/src/main/java/com/lovebug/app/MyFirebaseMessagingService.java`
- `supabase/functions/send-push-notification/index.ts`

**Changes:**
1. Verify notification channel has `IMPORTANCE_HIGH`
2. Ensure FCM message has `priority: 'HIGH'` at Android level
3. Ensure notification actions are always added for incoming calls
4. Test with app completely closed (force stop)

---

### **Phase 3: Fix Caller Name Display**

**Task 3.1: Ensure Caller Name in Notification Body**
- Include caller name in notification payload body
- Ensure Android extracts caller name correctly
- Fallback to data payload if notification body missing

**Files to Modify:**
- `supabase/functions/send-push-notification/index.ts`
- `android/app/src/main/java/com/lovebug/app/MyFirebaseMessagingService.java`

**Changes:**
1. Include caller name in `notification.body` for both iOS and Android
2. Ensure Android notification builder uses caller name from data if notification body is generic
3. Add logging to verify caller name is present

---

### **Phase 4: Fix Notification Clearing and State Synchronization**

**Task 4.1: Clear Notifications on Call State Changes**
- Clear Android notification when call is accepted from in-app
- Clear Android notification when call is canceled from remote
- Clear iOS CallKit when call is declined from remote
- Send missed call notification when call is canceled

**Files to Modify:**
- `lib/services/call_listener_service.dart` (accept/decline handlers)
- `lib/services/callkit_listener_service.dart` (iOS handlers)
- `lib/services/webrtc_service.dart` (state change handler)
- Create server-side trigger for missed call notification

**Changes:**
1. Add `clearCallNotification()` call immediately after accepting from in-app
2. Add listener for call state changes that clears notification when state becomes terminal
3. Send FCM data-only message when call is canceled to clear remote notification
4. Create Supabase database trigger to send missed call notification when state changes to `canceled` or `timeout`

---

### **Phase 5: Fix iOS CallKit State Management**

**Task 5.1: Proper CallKit Lifecycle Management**
- Keep CallKit active until WebRTC connection is established
- Only dismiss CallKit when connection is confirmed or call fails
- Handle disconnect button properly

**Files to Modify:**
- `lib/services/callkit_listener_service.dart`
- `lib/services/webrtc_service.dart`
- VideoCallScreen disconnect handler

**Changes:**
1. Remove early CallKit dismissal in accept handler
2. Add CallKit state update when WebRTC connects successfully
3. Dismiss CallKit only after connection is established or call fails
4. Ensure disconnect button properly ends call and dismisses CallKit

---

### **Phase 6: Fix Android App Quit Issue**

**Task 6.1: Prevent Premature App Termination**
- Fix state change listener to not trigger endCall on non-terminal states
- Add proper state transition validation
- Ensure only terminal states trigger cleanup

**Files to Modify:**
- `lib/services/webrtc_service.dart` (state listener)
- `lib/services/call_listener_service.dart` (state change handler)

**Changes:**
1. Update state listener to only trigger endCall on terminal states (`ended`, `declined`, `canceled`, `timeout`)
2. Add state transition validation
3. Ignore `connecting` state changes

---

### **Phase 7: Fix Push Notification When App Open**

**Task 7.1: Suppress Push Notification When App Open**
- Suppress FCM notification when app is in foreground
- Let real-time listener handle all incoming calls when app is open
- Only show push notification when app is closed

**Files to Modify:**
- `lib/services/notification_service.dart` (foreground handler)

**Changes:**
1. Return early in foreground handler for incoming_call type
2. Let CallListenerService handle via real-time listener
3. Only show push notification as fallback

---

### **Phase 8: Add Server-Side Missed Call Notification**

**Task 8.1: Create Database Trigger for Missed Calls**
- Create Supabase trigger that fires when call_sessions.state changes to `canceled` or `timeout`
- Trigger should send missed call notification to receiver
- Include caller name in notification

**Files to Create:**
- `supabase/migrations/fix_missed_call_notification.sql` (or similar)

**Changes:**
1. Create database trigger that listens to call_sessions state changes
2. When state becomes `canceled` or `timeout`, call edge function to send missed call notification
3. Include caller name from call_sessions table

---

## 📝 Detailed Code Changes

### **Change 1: iOS Background Handler Enhancement**

```dart
// lib/services/notification_service.dart
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('📱 BACKGROUND: Handling background message: ${message.messageId}');
  print('📱 BACKGROUND: Message data: ${message.data}');
  
  final data = message.data;
  final type = data['type'];
  
  // CRITICAL FIX: Handle incoming calls in background by triggering CallKit IMMEDIATELY
  if (type == 'incoming_call' && Platform.isIOS) {
    print('📱 BACKGROUND: Incoming call detected - triggering CallKit immediately...');
    
    try {
      final callId = data['call_id'] as String?;
      final callerId = data['caller_id'] as String?;
      final callerName = data['caller_name'] as String? ?? 'Unknown';
      final callType = data['call_type'] as String? ?? 'video';
      final matchId = data['match_id'] as String?;
      final callerImageUrl = data['caller_image_url'] as String?;
      
      if (callId != null && callerId != null && matchId != null) {
        print('📱 BACKGROUND: CallKit data - ID: $callId, Caller: $callerName, Type: $callType');
        
        // CRITICAL: Trigger CallKit immediately - this is what shows Accept/Deny buttons
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
        
        // CRITICAL: This must complete before handler returns
        await CallKitService.showIncomingCall(payload: payload);
        print('✅ BACKGROUND: CallKit incoming call triggered successfully');
      } else {
        print('❌ BACKGROUND: Missing required call data for CallKit');
      }
    } catch (e) {
      print('❌ BACKGROUND: Error triggering CallKit: $e');
      // Don't rethrow - allow handler to complete
    }
  }
}
```

---

### **Change 2: Android Notification Clear on Accept**

```dart
// lib/services/call_listener_service.dart
static Future<void> _acceptCall(
  String callId,
  String callerId,
  String matchId,
  String callType,
) async {
  try {
    print('📞 Accepting call: $callId');
    
    // Update call session state to connecting
    await SupabaseService.client
        .from('call_sessions')
        .update({'state': 'connecting'})
        .eq('id', callId);
    
    print('✅ Call accepted, updating state to connecting');
    
    // CRITICAL FIX: Clear push notification immediately when accepting from in-app
    if (Platform.isAndroid) {
      try {
        final MethodChannel channel = MethodChannel('com.lovebug.app/notification');
        await channel.invokeMethod('clearCallNotification');
        print('✅ Android call notification cleared after in-app accept');
      } catch (e) {
        print('⚠️ Error clearing Android notification: $e');
      }
    }
    
    // Continue with WebRTC initialization...
    // ... rest of the code
  } catch (e) {
    print('❌ Error accepting call: $e');
  }
}
```

---

### **Change 3: Fix Caller Name in Notification Body**

```typescript
// supabase/functions/send-push-notification/index.ts
// In the message building section:

const message = {
  message: {
    token: profile.fcm_token,
    notification: {
      // CRITICAL FIX: Include caller name in notification body for both platforms
      title: title,
      body: isCallNotification && data.caller_name 
        ? `${data.caller_name} is calling you` // Use caller name in body
        : body,
    },
    data: stringifiedData,
    android: {
      priority: isCallNotification ? 'HIGH' : 'NORMAL',
      notification: {
        icon: isCallNotification ? 'ic_call' : 'ic_notification',
        color: isCallNotification ? '#4CAF50' : '#FF6B6B',
        sound: isCallNotification ? 'call_ringtone' : 'default',
        notification_priority: isCallNotification ? 'PRIORITY_MAX' : 'PRIORITY_DEFAULT',
        visibility: 'public',
        channel_id: isCallNotification ? 'call_notifications' : 'default_notifications',
        // CRITICAL FIX: Ensure title and body include caller name
        title: isCallNotification && data.caller_name 
          ? `${data.caller_name} is calling you`
          : title,
        body: isCallNotification && data.caller_name 
          ? `${data.caller_name} is calling you`
          : body,
        ...(isCallNotification && data.caller_image_url && {
          image: data.caller_image_url
        }),
      },
    },
    apns: {
      payload: {
        aps: {
          sound: isCallNotification ? 'call_ringtone.wav' : 'default',
          badge: 1,
          category: isCallNotification ? 'CALL_CATEGORY' : undefined,
          'mutable-content': isCallNotification ? 1 : 0,
          alert: {
            // CRITICAL FIX: Include caller name in iOS alert
            title: isCallNotification && data.caller_name 
              ? `${data.caller_name} is calling you`
              : title,
            body: isCallNotification && data.caller_name 
              ? `${data.caller_name} is calling you`
              : body,
            'launch-image': isCallNotification ? 'call_background.png' : undefined
          }
        },
        // ... rest of APNS payload
      }
    }
  }
}
```

---

### **Change 4: Fix iOS CallKit Lifecycle**

```dart
// lib/services/callkit_listener_service.dart
static Future<void> _onCallAccepted(Map<String, dynamic>? body) async {
  try {
    // ... extract call data ...
    
    // Update call session state to connecting
    await SupabaseService.client
        .from('call_sessions')
        .update({'state': 'connecting'})
        .eq('id', callId);
    
    print('✅ Call state updated to connecting');
    
    // CRITICAL FIX: DO NOT dismiss CallKit immediately
    // Keep CallKit active until WebRTC connection is established
    
    // Initialize WebRTC service
    if (!Get.isRegistered<WebRTCService>()) {
      print('📞 Registering WebRTCService...');
      Get.put(WebRTCService());
    }
    
    // Navigate to call screen
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
    
    // Start receiver join
    final webrtcService = Get.find<WebRTCService>();
    await webrtcService.receiverJoinWithPolling(
      callId: callId,
      callType: callType,
      matchId: matchId,
    );
    
    // CRITICAL FIX: Only dismiss CallKit after connection is established
    // Listen for connection success
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
    
  } catch (e) {
    print('❌ Error handling accepted call: $e');
    // Dismiss CallKit on error
    FlutterCallkitIncoming.endCall(callId);
  }
}
```

---

### **Change 5: Clear Notification on State Change**

```dart
// lib/services/webrtc_service.dart
void _listenForCallSessionState(String callId) {
  try {
    // Listen to call_sessions state changes
    _callSessionStateSubscription = SupabaseService.client
        .from('call_sessions')
        .stream(primaryKey: ['id'])
        .eq('id', callId)
        .listen((rows) {
      if (rows.isEmpty) return;
      final row = rows.first;
      final state = (row['state'] ?? '').toString();
      if (state.isEmpty) return;
      
      print('📞 call_sessions state change: $state');
      
      if (state == 'declined' || state == 'canceled' || state == 'timeout' || state == 'ended' || state == 'failed' || state == 'disconnected') {
        // CRITICAL FIX: Clear notifications when call is terminated
        if (Platform.isAndroid) {
          try {
            final MethodChannel channel = MethodChannel('com.lovebug.app/notification');
            channel.invokeMethod('clearCallNotification');
            print('✅ Android notification cleared due to state change: $state');
          } catch (e) {
            print('⚠️ Error clearing Android notification: $e');
          }
        }
        
        if (Platform.isIOS) {
          try {
            FlutterCallkitIncoming.endCall(callId);
            print('✅ iOS CallKit cleared due to state change: $state');
          } catch (e) {
            print('⚠️ Error clearing iOS CallKit: $e');
          }
        }
        
        // If remote signaled termination, end locally
        if (_callState.value != CallState.disconnected && _callState.value != CallState.failed) {
          print('📞 Terminating due to call_sessions state=$state');
          
          // Only send missed-call notification for canceled timeouts from caller side
          if (state == 'canceled') {
            _sendMissedCallNotification();
          }
          
          endCall();
        }
      }
    });
  } catch (e) {
    print('❌ Error listening to call_sessions: $e');
  }
}
```

---

### **Change 6: Suppress Foreground Push Notification**

```dart
// lib/services/notification_service.dart
static void _handleForegroundMessage(RemoteMessage message) {
  print('📱 FOREGROUND: Handling foreground message');
  print('📱 FOREGROUND: Message data: ${message.data}');
  
  final data = message.data;
  final type = data['type'];
  
  // CRITICAL FIX: Suppress push notification for incoming calls when app is open
  // Real-time listener will handle it via CallListenerService
  if (type == 'incoming_call') {
    print('📱 FOREGROUND: Incoming call detected - suppressing notification (real-time listener will handle)');
    // Do NOT show notification - let CallListenerService handle via real-time listener
    return;
  }
  
  // For non-call notifications, show in-app notification
  final notification = message.notification;
  if (notification != null) {
    _showInAppNotification(notification.title ?? 'New Message', 
                         notification.body ?? '');
  }
}
```

---

### **Change 7: Server-Side Missed Call Notification**

Create a new Supabase database trigger:

```sql
-- Create function to send missed call notification
CREATE OR REPLACE FUNCTION send_missed_call_notification()
RETURNS TRIGGER AS $$
DECLARE
  caller_name TEXT;
  caller_profile RECORD;
BEGIN
  -- Only trigger on state changes to terminal states
  IF NEW.state IN ('canceled', 'timeout') AND OLD.state NOT IN ('canceled', 'timeout', 'ended', 'declined') THEN
    -- Get caller name from profile
    SELECT name INTO caller_name
    FROM profiles
    WHERE id = NEW.caller_id;
    
    -- Call edge function to send missed call notification
    PERFORM net.http_post(
      url := current_setting('app.supabase_url') || '/functions/v1/send-push-notification',
      headers := jsonb_build_object(
        'Content-Type', 'application/json',
        'Authorization', 'Bearer ' || current_setting('app.supabase_service_role_key')
      ),
      body := jsonb_build_object(
        'userId', NEW.receiver_id,
        'type', 'missed_call',
        'title', '📞 Missed Call',
        'body', 'You missed a call from ' || COALESCE(caller_name, 'Someone'),
        'data', jsonb_build_object(
          'caller_name', COALESCE(caller_name, 'Someone'),
          'call_type', NEW.call_type,
          'action', 'missed_call'
        )
      )
    );
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger
CREATE TRIGGER on_call_session_state_change
AFTER UPDATE ON call_sessions
FOR EACH ROW
WHEN (OLD.state IS DISTINCT FROM NEW.state)
EXECUTE FUNCTION send_missed_call_notification();
```

---

## ✅ Testing Checklist

After implementing all fixes, test each scenario:

- [ ] **Test 1:** iOS → Android (Android closed) - Verify Accept/Deny buttons show, caller name displays, notification clears on cancel, missed call notification appears
- [ ] **Test 2:** iOS → Android (Android open) - Verify no duplicate notifications, push notification clears when accepted from in-app
- [ ] **Test 3:** Android → iOS (iOS closed) - Verify Accept/Deny buttons show, quick connection
- [ ] **Test 4:** Android → iOS (iOS open) - Verify no "Call Failed", can disconnect properly
- [ ] **Test 5:** Android → iOS (decline from iOS) - Verify instant disconnect (already working)
- [ ] **Test 6:** Android → iOS (decline from Android) - Verify iOS notification clears

---

## 🎯 Priority Order

1. **HIGH PRIORITY:** Fix iOS background push notifications (Tests 1 & 3)
2. **HIGH PRIORITY:** Fix Android notification buttons (Test 1)
3. **HIGH PRIORITY:** Fix caller name display (Test 1)
4. **MEDIUM PRIORITY:** Fix notification clearing and state sync (Tests 1, 2, 6)
5. **MEDIUM PRIORITY:** Fix iOS CallKit lifecycle (Test 4)
6. **LOW PRIORITY:** Fix Android app quit issue (Test 4)
7. **LOW PRIORITY:** Suppress foreground notifications (Test 2)

---

## 📚 References

- [iOS VoIP Push Notifications Best Practices](https://developer.apple.com/documentation/usernotifications/notifying_users_in_real_time_with_voip_notifications)
- [Android High-Priority Notifications](https://developer.android.com/develop/ui/views/notifications/build-notification#priority)
- [FCM Message Structure](https://firebase.google.com/docs/cloud-messaging/concept-options)

---

*Report Generated: Based on comprehensive code analysis and test scenarios*
*Last Updated: Implementation plan ready for execution*

