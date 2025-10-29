# 📞 Call System Technical Documentation
## Cross-Platform Video/Audio Call Implementation with Push Notifications

---

## 📋 Table of Contents
1. [Test Scenarios](#test-scenarios)
2. [Bugs Identified](#bugs-identified)
3. [Complete Code Implementation](#complete-code-implementation)
4. [Technical Fixes Applied](#technical-fixes-applied)
5. [Expected Results](#expected-results)

---

## 🔍 Test Scenarios

### **Primary Test Scenarios**
1. **iOS App Closed** → Push notification → Should show Accept/Decline → Connect to video
2. **iOS App Open** → Push notification → Should show Accept/Decline → Connect to video  
3. **Android App Closed** → Push notification → Should show Accept/Decline → Connect to video
4. **Android App Open** → Push notification → Should show Accept/Decline → Connect to video
5. **Cross-platform calls** → Both sides should sync properly
6. **Call termination** → Notifications should clear, UI should reset

### **Secondary Test Scenarios**
- **Call decline flow** → Proper state cleanup
- **Call timeout** → Auto-cleanup after 30 seconds
- **Network interruption** → Graceful handling
- **App backgrounding** → Proper state preservation

---

## 🐛 Bugs Identified

### **Critical Database Issues**
- ❌ **Database Schema Error**: `column call_sessions.offer does not exist`
- ❌ **Wrong Table Query**: Code was querying `call_sessions.offer` instead of `webrtc_rooms.offer`

### **iOS Issues**
- ❌ **No Accept/Decline buttons when app closed**: Push notifications showed but no action buttons
- ❌ **App crashes when accepting from CallKit**: Multiple null pointer exceptions
- ❌ **Direct connection without connecting screen**: Bypassed proper flow
- ❌ **iOS gets stuck in connecting state**: Can't decline or reset
- ❌ **CallKit UI not dismissed**: Stuck "Call Failed" screen

### **Android Issues**
- ❌ **No Accept/Decline buttons when app closed**: Only basic notifications
- ❌ **Auto-connects on tap**: Should show Accept/Decline first
- ❌ **Notifications don't clear**: When call ends from other side

### **WebRTC Issues**
- ❌ **SDP Bundle Error**: `max-bundle configured but session description has no BUNDLE group`
- ❌ **State Conflicts**: `Called in wrong state: have-local-offer`
- ❌ **Peer connection not reset**: When switching from caller to receiver mode

---

## 💻 Complete Code Implementation

### **1. WebRTC Service (lib/services/webrtc_service.dart)**

#### **Fixed Database Query Method**
```dart
Future<Map<String, dynamic>?> _pollForOffer(
  String callId, {
  int maxAttempts = 3,
  int interval = 2000,
}) async {
  print('🔍 Polling for offer - max attempts: $maxAttempts, interval: ${interval}ms');
  
  for (int i = 0; i < maxAttempts; i++) {
    print('🔍 Poll attempt ${i + 1}/$maxAttempts...');
    
    try {
      // FIX: Query webrtc_rooms table for offer, not call_sessions
      final response = await SupabaseService.client
          .from('webrtc_rooms')
          .select('offer')
          .eq('room_id', callId)
          .maybeSingle();
      
      if (response != null && response['offer'] != null && response['offer'].toString().isNotEmpty) {
        print('✅ Offer found on attempt ${i + 1}');
        return response;
      }
      
      // Check if call was cancelled/declined by querying call_sessions
      final callStateResponse = await SupabaseService.client
          .from('call_sessions')
          .select('state')
          .eq('id', callId)
          .maybeSingle();
      
      if (callStateResponse != null) {
        final state = callStateResponse['state'] ?? '';
        if (state == 'declined' || state == 'canceled' || state == 'ended') {
          print('⚠️ Call state is $state - stopping poll');
          return null;
        }
      }
      
      print('⏳ No offer yet, waiting ${interval}ms...');
      
      if (i < maxAttempts - 1) {
        await Future.delayed(Duration(milliseconds: interval));
      }
      
    } catch (e) {
      print('❌ Error polling for offer: $e');
      if (i < maxAttempts - 1) {
        await Future.delayed(Duration(milliseconds: interval));
      }
    }
  }
  
  print('⚠️ No offer found after $maxAttempts attempts');
  return null;
}
```

#### **Fixed WebRTC Configuration**
```dart
final Map<String, dynamic> _webrtcConfiguration = {
  'iceServers': [
    {'urls': 'stun:stun.l.google.com:19302'},
    {'urls': 'stun:stun1.l.google.com:19302'},
    {'urls': 'stun:stun.cloudflare.com:3478'},
    {
      'urls': 'turn:openrelay.metered.ca:80',
      'username': 'openrelayproject',
      'credential': 'openrelayproject',
    },
    {
      'urls': 'turn:openrelay.metered.ca:443',
      'username': 'openrelayproject',
      'credential': 'openrelayproject',
    },
    {
      'urls': 'turn:openrelay.metered.ca:443?transport=tcp',
      'username': 'openrelayproject',
      'credential': 'openrelayproject',
    },
  ],
  'sdpSemantics': 'unified-plan',
  'iceTransportPolicy': 'all',
  'iceCandidatePoolSize': 10,
  'bundlePolicy': 'balanced', // FIXED: Changed from max-bundle to balanced
  'rtcpMuxPolicy': 'require',
};
```

#### **Fixed Peer Connection Recreation**
```dart
if (retryRoomData == null || retryRoomData['offer'] == null) {
  print('⚠️ Still no offer after retries. Switching to CALLER mode...');
  _isInitiator = true;
  // CRITICAL FIX: Always recreate peer connection when switching modes
  print('📞 Recreating peer connection for caller mode...');
  await _peerConnection?.close();
  _peerConnection = await createPeerConnection(_webrtcConfiguration);
  _registerPeerConnectionListeners();
  _localStream?.getTracks().forEach((track) {
    _peerConnection?.addTrack(track, _localStream!);
  });
  await _createRoom(roomId);
  return;
}
```

#### **Added Force Reset Method**
```dart
/// CRITICAL FIX: Force reset call state (public method for external calls)
Future<void> forceResetCallState() async {
  print('📞 FORCE RESET: Resetting call state...');
  await _resetServiceState();
  _updateCallState(CallState.initial);
  print('✅ FORCE RESET: Call state reset completed');
}

/// CRITICAL FIX: Reset service state for new call
Future<void> _resetServiceState() async {
  try {
    print('📞 Resetting WebRTCService state...');
    
    // Cancel all timers
    _iceConnectionTimeout?.cancel();
    _noAnswerTimeout?.cancel();
    _relayWarnTimer?.cancel();
    _iceQuickFallbackTimer?.cancel();
    _queuedIceFlushTimer?.cancel();
    
    // Cancel all subscriptions
    _answerSubscription?.cancel();
    _iceCandidatesSubscription?.cancel();
    _callStateSubscription?.cancel();
    _callSessionStateSubscription?.cancel();
    
    // Reset all state variables
    _localStream = null;
    _remoteStream = null;
    _peerConnection = null;
    _currentCallId = null;
    _currentMatchId = null;
    _isInitialized = false;
    _isEnding = false;
    _queuedIceCandidates = null;
    _readyToAddRemoteCandidates = false;
    _answerApplied = false;
    _hasRelayCandidate = false;
    _lastDbState = null;
    
    // CRITICAL FIX: Force update call state to initial to clear UI
    _updateCallState(CallState.initial);
    
    print('✅ WebRTCService state reset completed');
  } catch (e) {
    print('❌ Error resetting WebRTCService state: $e');
  }
}
```

#### **Added Android Notification Cleanup**
```dart
// CRITICAL FIX: Clear Android notifications when call ends
if (Platform.isAndroid) {
  try {
    // Clear the call notification
    final MethodChannel channel = MethodChannel('com.lovebug.app/notification');
    await channel.invokeMethod('clearCallNotification');
    print('✅ Android call notification cleared');
  } catch (e) {
    print('⚠️ Error clearing Android notification: $e');
  }
}
```

### **2. iOS Background Handler (lib/services/notification_service.dart)**

#### **Fixed Background Message Handler**
```dart
// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('📱 BACKGROUND: Handling background message: ${message.messageId}');
  print('📱 BACKGROUND: Message data: ${message.data}');
  
  final data = message.data;
  final type = data['type'];
  
  // CRITICAL FIX: Handle incoming calls in background by triggering CallKit
  if (type == 'incoming_call') {
    print('📱 BACKGROUND: Incoming call detected - triggering CallKit...');
    
    try {
      // Import required services
      final callId = data['call_id'];
      final callerId = data['caller_id'];
      final callerName = data['caller_name'] ?? 'Unknown';
      final callType = data['call_type'] ?? 'video';
      final matchId = data['match_id'];
      final callerImageUrl = data['caller_image_url'];
      
      if (callId != null && callerId != null && matchId != null) {
        print('📱 BACKGROUND: CallKit data - ID: $callId, Caller: $callerName, Type: $callType');
        
        // Trigger CallKit directly for iOS
        if (Platform.isIOS) {
          // Use CallKit service to show incoming call
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
          print('✅ BACKGROUND: CallKit incoming call triggered successfully');
        }
      } else {
        print('❌ BACKGROUND: Missing required call data for CallKit');
      }
    } catch (e) {
      print('❌ BACKGROUND: Error triggering CallKit: $e');
    }
  }
}
```

### **3. Android Notification Service (android/app/src/main/java/com/lovebug/app/MyFirebaseMessagingService.java)**

#### **Complete Android Notification Implementation**
```java
package com.lovebug.app;

import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.content.Context;
import android.content.Intent;
import android.media.RingtoneManager;
import android.net.Uri;
import android.os.Build;
import android.util.Log;

import androidx.core.app.NotificationCompat;

import com.google.firebase.messaging.FirebaseMessagingService;
import com.google.firebase.messaging.RemoteMessage;

import java.util.Map;

public class MyFirebaseMessagingService extends FirebaseMessagingService {

    private static final String TAG = "FCM_SERVICE";
    private static final String CALL_CHANNEL_ID = "call_notifications";
    private static final String DEFAULT_CHANNEL_ID = "default_notifications";

    @Override
    public void onNewToken(String token) {
        super.onNewToken(token);
        Log.d(TAG, "New FCM token: " + token);
        // Token is automatically handled by FlutterFirebaseMessaging
    }

    @Override
    public void onMessageReceived(RemoteMessage remoteMessage) {
        super.onMessageReceived(remoteMessage);
        
        Log.d(TAG, "Message received from: " + remoteMessage.getFrom());
        Log.d(TAG, "Message data: " + remoteMessage.getData().toString());
        
        // Check if message contains a notification payload
        if (remoteMessage.getNotification() != null) {
            Log.d(TAG, "Notification Title: " + remoteMessage.getNotification().getTitle());
            Log.d(TAG, "Notification Body: " + remoteMessage.getNotification().getBody());
        }

        // Handle both data and notification payloads
        Map<String, String> data = remoteMessage.getData();
        String notificationType = data.getOrDefault("type", "");
        
        // Check if it's a call notification
        boolean isCallNotification = notificationType.equals("incoming_call") || 
                                     notificationType.equals("missed_call") || 
                                     notificationType.equals("call_ended") || 
                                     notificationType.equals("call_rejected");

        Log.d(TAG, "Notification type: " + notificationType + ", isCall: " + isCallNotification);

        // Get title and body from notification or data
        String title = remoteMessage.getNotification() != null ? 
                      remoteMessage.getNotification().getTitle() : 
                      data.getOrDefault("title", "LoveBug");
        String body = remoteMessage.getNotification() != null ? 
                     remoteMessage.getNotification().getBody() : 
                     data.getOrDefault("body", "");

        // Prefer caller_name for incoming call body if provided
        String callerName = data.get("caller_name");
        if (notificationType.equals("incoming_call")) {
            if (callerName != null && (body == null || body.trim().isEmpty() || body.toLowerCase().contains("unknown"))) {
                body = callerName + " is calling you";
            }
        }

        // Show notification
        sendNotification(title, body, data, isCallNotification);
    }

    private void sendNotification(String title, String body, Map<String, String> data, boolean isCallNotification) {
        Log.d(TAG, "Creating notification - Title: " + title + ", Body: " + body + ", IsCall: " + isCallNotification);

        Intent intent = new Intent(this, MainActivity.class);
        intent.addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP);
        
        // Add all data as extras
        for (Map.Entry<String, String> entry : data.entrySet()) {
            intent.putExtra(entry.getKey(), entry.getValue());
        }

        int pendingIntentFlags = PendingIntent.FLAG_ONE_SHOT;
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            pendingIntentFlags |= PendingIntent.FLAG_IMMUTABLE;
        }

        PendingIntent pendingIntent = PendingIntent.getActivity(
            this, 
            0, 
            intent, 
            pendingIntentFlags
        );

        String type = data.get("type");
        boolean isIncoming = "incoming_call".equals(type);
        String channelId = isIncoming ? CALL_CHANNEL_ID : DEFAULT_CHANNEL_ID;
        Uri defaultSoundUri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION);

        NotificationCompat.Builder notificationBuilder = new NotificationCompat.Builder(this, channelId)
            .setSmallIcon(R.drawable.ic_notification)
            .setContentTitle(title)
            .setContentText(body)
            .setAutoCancel(true)
            .setContentIntent(pendingIntent)
            .setPriority(isCallNotification ? 
                NotificationCompat.PRIORITY_MAX : 
                NotificationCompat.PRIORITY_DEFAULT);

        // Add sound for non-call notifications (call notifications use channel sound)
        if (!isCallNotification) {
            notificationBuilder.setSound(defaultSoundUri);
        }

        // For incoming call notifications, add full-screen intent, actions and make it non-dismissible
        if (isIncoming) {
            Log.d(TAG, "Creating incoming call notification with actions");
            
            // Accept action (Broadcast to receiver)
            Intent acceptIntent = new Intent(this, CallActionReceiver.class);
            acceptIntent.setAction("ACCEPT_CALL");
            acceptIntent.putExtra("call_id", data.get("call_id"));
            acceptIntent.putExtra("caller_id", data.get("caller_id"));
            acceptIntent.putExtra("match_id", data.get("match_id"));
            acceptIntent.putExtra("call_type", data.get("call_type"));

            PendingIntent acceptPendingIntent = PendingIntent.getBroadcast(
                this,
                1,
                acceptIntent,
                (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M
                    ? PendingIntent.FLAG_UPDATE_CURRENT | PendingIntent.FLAG_IMMUTABLE
                    : PendingIntent.FLAG_UPDATE_CURRENT)
            );

            // Decline action (Broadcast to receiver)
            Intent declineIntent = new Intent(this, CallActionReceiver.class);
            declineIntent.setAction("DECLINE_CALL");
            declineIntent.putExtra("call_id", data.get("call_id"));

            PendingIntent declinePendingIntent = PendingIntent.getBroadcast(
                this,
                2,
                declineIntent,
                (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M
                    ? PendingIntent.FLAG_UPDATE_CURRENT | PendingIntent.FLAG_IMMUTABLE
                    : PendingIntent.FLAG_UPDATE_CURRENT)
            );

            // Full-screen intent for locked screen
            Intent fullScreenIntent = new Intent(this, MainActivity.class);
            fullScreenIntent.setAction("INCOMING_CALL");
            fullScreenIntent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_CLEAR_TOP);
            fullScreenIntent.putExtra("call_id", data.get("call_id"));
            fullScreenIntent.putExtra("caller_id", data.get("caller_id"));
            fullScreenIntent.putExtra("match_id", data.get("match_id"));
            fullScreenIntent.putExtra("call_type", data.get("call_type"));
            fullScreenIntent.putExtra("caller_name", data.get("caller_name"));
            
            PendingIntent fullScreenPendingIntent = PendingIntent.getActivity(
                this,
                0,
                fullScreenIntent,
                (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M
                    ? PendingIntent.FLAG_UPDATE_CURRENT | PendingIntent.FLAG_IMMUTABLE
                    : PendingIntent.FLAG_UPDATE_CURRENT)
            );

            notificationBuilder
                .addAction(R.drawable.ic_call, "Accept", acceptPendingIntent)
                .addAction(R.drawable.ic_call_end, "Decline", declinePendingIntent)
                .setCategory(NotificationCompat.CATEGORY_CALL)
                .setFullScreenIntent(fullScreenPendingIntent, true)
                .setOngoing(true) // Make it non-dismissible for incoming calls
                .setPriority(NotificationCompat.PRIORITY_MAX)
                .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
                .setAutoCancel(false); // Don't auto-cancel for incoming calls
                
            Log.d(TAG, "Incoming call notification configured with actions and full-screen intent");
        } else if (isCallNotification) {
            // Non-incoming call events: normal priority, no actions, no full-screen, no ongoing
            notificationBuilder
                .setCategory(NotificationCompat.CATEGORY_EVENT)
                .setOngoing(false)
                .setPriority(NotificationCompat.PRIORITY_DEFAULT);
        }

        NotificationManager notificationManager = 
            (NotificationManager) getSystemService(Context.NOTIFICATION_SERVICE);

        // Create notification channels for Android O and above
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            createNotificationChannels(notificationManager);
        }

        // Use a fixed ID for call notifications so they replace each other
        // Use timestamp for other notifications
        int notificationId = isIncoming ? 12345 : (int) System.currentTimeMillis();

        notificationManager.notify(notificationId, notificationBuilder.build());
        Log.d(TAG, "Notification shown with ID: " + notificationId);
    }

    private void createNotificationChannels(NotificationManager notificationManager) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            // Call notifications channel
            NotificationChannel callChannel = new NotificationChannel(
                CALL_CHANNEL_ID,
                "Call Notifications",
                NotificationManager.IMPORTANCE_HIGH
            );
            callChannel.setDescription("Notifications for incoming calls");
            callChannel.enableVibration(true);
            callChannel.setSound(
                RingtoneManager.getDefaultUri(RingtoneManager.TYPE_RINGTONE),
                null
            );
            callChannel.setLockscreenVisibility(Notification.VISIBILITY_PUBLIC);
            callChannel.enableLights(true);
            callChannel.setShowBadge(true);

            // Default notifications channel
            NotificationChannel defaultChannel = new NotificationChannel(
                DEFAULT_CHANNEL_ID,
                "General Notifications",
                NotificationManager.IMPORTANCE_DEFAULT
            );
            defaultChannel.setDescription("General app notifications");
            defaultChannel.enableVibration(true);

            notificationManager.createNotificationChannel(callChannel);
            notificationManager.createNotificationChannel(defaultChannel);
            
            Log.d(TAG, "Notification channels created");
        }
    }
}
```

### **4. Android Call Action Receiver (android/app/src/main/java/com/lovebug/app/CallActionReceiver.java)**

```java
package com.lovebug.app;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.app.NotificationManager;
import android.util.Log;

import io.flutter.plugin.common.MethodChannel;

public class CallActionReceiver extends BroadcastReceiver {
    private static final String TAG = "CallActionReceiver";
    private static MethodChannel channel;

    public static void setMethodChannel(MethodChannel methodChannel) {
        channel = methodChannel;
    }

    @Override
    public void onReceive(Context context, Intent intent) {
        String action = intent.getAction();
        Log.d(TAG, "Received action: " + action);

        if (action == null) return;

        String callId = intent.getStringExtra("call_id");
        String callerId = intent.getStringExtra("caller_id");
        String matchId = intent.getStringExtra("match_id");
        String callType = intent.getStringExtra("call_type");

        if (callId == null) {
            Log.e(TAG, "No call_id in intent");
            return;
        }

        if ("ACCEPT_CALL".equals(action)) {
            Log.d(TAG, "Accepting call: " + callId);
            
            if (channel != null) {
                Map<String, Object> args = new HashMap<>();
                args.put("action", "accept");
                args.put("call_id", callId);
                args.put("caller_id", callerId);
                args.put("match_id", matchId);
                args.put("call_type", callType);
                channel.invokeMethod("handleCallAction", args);
            }
            
            // Launch app to handle the call
            Intent launchIntent = new Intent(context, MainActivity.class);
            launchIntent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_CLEAR_TOP);
            launchIntent.putExtra("action", "accept_call");
            launchIntent.putExtra("call_id", callId);
            context.startActivity(launchIntent);
            
        } else if ("DECLINE_CALL".equals(action)) {
            Log.d(TAG, "Declining call: " + callId);
            
            if (channel != null) {
                Map<String, Object> args = new HashMap<>();
                args.put("action", "decline");
                args.put("call_id", callId);
                channel.invokeMethod("handleCallAction", args);
            }
        }
        
        // Dismiss the ongoing call notification id used for calls
        NotificationManager notificationManager = (NotificationManager) context.getSystemService(Context.NOTIFICATION_SERVICE);
        if (notificationManager != null) {
            notificationManager.cancel(12345);
        }
    }
}
```

### **5. Android MainActivity (android/app/src/main/java/com/lovebug/app/MainActivity.java)**

```java
package com.lovebug.app;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;
import android.content.Intent;
import android.os.Build;
import android.os.Bundle;
import android.os.PowerManager;
import android.provider.Settings;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.media.RingtoneManager;
import android.os.Build.VERSION_CODES;
import android.util.Log;

public class MainActivity extends FlutterActivity {
    private static final String TAG = "MainActivity";
    private static final String CHANNEL = "android_background_service";
    
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        Log.d(TAG, "MainActivity onCreate");
        
        // Create notification channels immediately on app start
        initializeBackgroundService();
        
        // Log intent data for debugging
        if (getIntent() != null && getIntent().getExtras() != null) {
            Bundle extras = getIntent().getExtras();
            Log.d(TAG, "Intent extras:");
            for (String key : extras.keySet()) {
                Log.d(TAG, "  " + key + ": " + extras.get(key));
            }
        }
    }
    
    @Override
    public void configureFlutterEngine(FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);
        
        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL)
            .setMethodCallHandler((call, result) -> {
                switch (call.method) {
                    case "initializeBackgroundService":
                        initializeBackgroundService();
                        result.success("Background service initialized");
                        break;
                    case "requestBatteryOptimizationExemption":
                        requestBatteryOptimizationExemption();
                        result.success("Battery optimization exemption requested");
                        break;
                    default:
                        result.notImplemented();
                        break;
                }
            });

        // Channel for notification management
        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), "com.lovebug.app/notification")
            .setMethodCallHandler((call, result) -> {
                switch (call.method) {
                    case "clearCallNotification":
                        clearCallNotification();
                        result.success("Call notification cleared");
                        break;
                    default:
                        result.notImplemented();
                        break;
                }
            });

        // Channel for call notification actions (Accept/Decline)
        MethodChannel callActionChannel = new MethodChannel(
            flutterEngine.getDartExecutor().getBinaryMessenger(),
            "com.lovebug.app/call_actions"
        );
        CallActionReceiver.setMethodChannel(callActionChannel);
    }
    
    private void initializeBackgroundService() {
        // Create notification channels for Android 8+
        if (Build.VERSION.SDK_INT >= VERSION_CODES.O) {
            NotificationManager notificationManager = getSystemService(NotificationManager.class);
            
            // Channel for call notifications with ringtone
            NotificationChannel callChannel = new NotificationChannel(
                "call_notifications",
                "Call Notifications",
                NotificationManager.IMPORTANCE_HIGH
            );
            callChannel.setDescription("Incoming call notifications");
            callChannel.enableLights(true);
            callChannel.enableVibration(true);
            callChannel.setShowBadge(true);
            callChannel.setSound(
                RingtoneManager.getDefaultUri(RingtoneManager.TYPE_RINGTONE),
                null
            );
            notificationManager.createNotificationChannel(callChannel);
            
            // Channel for default notifications (matches, messages, etc.)
            NotificationChannel defaultChannel = new NotificationChannel(
                "default_notifications",
                "General Notifications",
                NotificationManager.IMPORTANCE_DEFAULT
            );
            defaultChannel.setDescription("General app notifications");
            defaultChannel.enableLights(true);
            defaultChannel.enableVibration(true);
            defaultChannel.setShowBadge(true);
            notificationManager.createNotificationChannel(defaultChannel);
            
            Log.d(TAG, "Notification channels created in MainActivity");
        }
    }
    
    private void requestBatteryOptimizationExemption() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            PowerManager powerManager = (PowerManager) getSystemService(POWER_SERVICE);
            if (!powerManager.isIgnoringBatteryOptimizations(getPackageName())) {
                Intent intent = new Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS);
                intent.setData(android.net.Uri.parse("package:" + getPackageName()));
                startActivity(intent);
            }
        }
    }
    
    private void clearCallNotification() {
        try {
            NotificationManager notificationManager = getSystemService(NotificationManager.class);
            // Clear the call notification (ID 12345)
            notificationManager.cancel(12345);
            Log.d(TAG, "Call notification cleared");
        } catch (Exception e) {
            Log.e(TAG, "Error clearing call notification: " + e.getMessage());
        }
    }
}
```

### **6. iOS CallKit Listener Service (lib/services/callkit_listener_service.dart)**

#### **Fixed Call Accepted Handler**
```dart
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

    // CRITICAL: End the CallKit call UI immediately
    await FlutterCallkitIncoming.endCall(callId);
    
    // Small delay to let CallKit UI dismiss
    await Future.delayed(Duration(milliseconds: 300));
    
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
          
          if (newState == 'ended' || newState == 'declined' || newState == 'canceled') {
            print('📞 [CallKit] Remote ended/canceled the call. State: $newState');
            // End the call on this side too
            if (Get.isRegistered<WebRTCService>()) {
              final webrtcService = Get.find<WebRTCService>();
              webrtcService.endCall();
            }
            // Navigate back
            if (Get.isOverlaysOpen) {
              Get.back();
            }
          }
        },
      );
      updateChannel.subscribe();
    } catch (e) {
      print('⚠️ Error setting up call session listener: $e');
    }

  } catch (e) {
    print('❌ Error handling accepted call: $e');
  }
}
```

#### **Fixed Call Ended Handler**
```dart
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
          'ended_at': DateTime.now().toIso8601String(),
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
```

#### **Fixed Call Declined Handler**
```dart
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
          'ended_at': DateTime.now().toIso8601String(),
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
```

---

## 🔧 Technical Fixes Applied

### **1. Database Schema Fix**
**Problem**: Code was querying `call_sessions.offer` but offer is stored in `webrtc_rooms.offer`
**Solution**: Updated `_pollForOffer` method to query correct table
```dart
// BEFORE (BROKEN)
final response = await SupabaseService.client
    .from('call_sessions')
    .select('offer')
    .eq('id', callId)
    .single();

// AFTER (FIXED)
final response = await SupabaseService.client
    .from('webrtc_rooms')
    .select('offer')
    .eq('room_id', callId)
    .maybeSingle();
```

### **2. iOS Background Push Notifications Fix**
**Problem**: iOS push notifications didn't trigger CallKit when app was closed
**Solution**: Enhanced background message handler to trigger CallKit directly
```dart
// Added CallKit trigger in background handler
if (type == 'incoming_call' && Platform.isIOS) {
  final payload = CallPayload(/* ... */);
  await CallKitService.showIncomingCall(payload: payload);
}
```

### **3. WebRTC State Management Fix**
**Problem**: Peer connection state conflicts when switching from caller to receiver
**Solution**: Always recreate peer connection when switching modes
```dart
// BEFORE (BROKEN)
if (_peerConnection == null) {
  _peerConnection = await createPeerConnection(_webrtcConfiguration);
}

// AFTER (FIXED)
await _peerConnection?.close();
_peerConnection = await createPeerConnection(_webrtcConfiguration);
```

### **4. CallKit State Synchronization Fix**
**Problem**: CallKit UI not properly dismissed, causing stuck states
**Solution**: Added proper CallKit UI dismissal and force reset
```dart
// Added in call ended/declined handlers
await FlutterCallkitIncoming.endCall(callId);
await webrtcService.forceResetCallState();
```

### **5. Android Notification Cleanup Fix**
**Problem**: Android notifications didn't clear when call ended
**Solution**: Added notification clearing method and called it from WebRTC service
```java
// Added clearCallNotification method in MainActivity
private void clearCallNotification() {
    NotificationManager notificationManager = getSystemService(NotificationManager.class);
    notificationManager.cancel(12345);
}
```

### **6. WebRTC Configuration Fix**
**Problem**: SDP bundle error with `max-bundle` policy
**Solution**: Changed to more compatible `balanced` policy
```dart
// BEFORE (BROKEN)
'bundlePolicy': 'max-bundle',

// AFTER (FIXED)
'bundlePolicy': 'balanced',
```

### **7. Force Reset Call State Fix**
**Problem**: iOS getting stuck in connecting state
**Solution**: Added public method to force reset all call state
```dart
Future<void> forceResetCallState() async {
  await _resetServiceState();
  _updateCallState(CallState.initial);
}
```

---

## 🎯 Expected Results

### **✅ iOS App Closed**
- Push notification → CallKit with Accept/Decline → Proper connection flow
- No more crashes when accepting calls
- Proper connecting screen before video

### **✅ iOS App Open**
- Real-time listener → CallKit with Accept/Decline → Proper connection flow
- No stuck states, proper UI cleanup

### **✅ Android App Closed**
- Push notification with Accept/Decline buttons → Proper connection flow
- Notifications clear when call ends

### **✅ Android App Open**
- Real-time listener → In-app dialog with Accept/Decline → Proper connection flow
- No auto-connection on tap

### **✅ Cross-platform Sync**
- Both sides show proper states
- Notifications clear properly
- No stuck UI states

### **✅ Call Termination**
- UI resets properly
- No stuck states
- Notifications clear
- Proper state cleanup

---

## 📊 Fix Summary

- **Database Issues**: 1 fixed
- **iOS Issues**: 5 fixed  
- **Android Issues**: 3 fixed
- **WebRTC Issues**: 3 fixed
- **Total Fixes**: 12 critical issues resolved

The app should now handle all call scenarios properly with Accept/Decline buttons showing consistently across both platforms and proper state management throughout the call lifecycle.

---

*Document created: October 29, 2025*
*Last updated: October 29, 2025*
