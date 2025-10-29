package com.lovebug.app;

import android.app.ActivityManager;
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
        // You can also send it to your server here if needed
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

        // CRITICAL FIX: Check if app is in foreground for incoming calls
        if (isCallNotification && isAppInForeground()) {
            Log.d(TAG, "App is in foreground, letting Flutter handle call notification");
            return; // Let Flutter's foreground handler show in-app dialog
        }

        // Get title and body from notification or data
        String title = remoteMessage.getNotification() != null ? 
                      remoteMessage.getNotification().getTitle() : 
                      data.getOrDefault("title", "LoveBug");
        String body = remoteMessage.getNotification() != null ? 
                     remoteMessage.getNotification().getBody() : 
                     data.getOrDefault("body", "");

        // CRITICAL FIX: Use caller_name for both title and body for incoming calls
        String callerName = data.get("caller_name");
        if (notificationType.equals("incoming_call")) {
            if (callerName != null && !callerName.trim().isEmpty() && !callerName.toLowerCase().contains("unknown")) {
                title = callerName + " is calling you";
                body = callerName + " is calling you";
            } else {
                // Fallback to notification payload if caller_name is missing
                title = remoteMessage.getNotification() != null ? 
                       remoteMessage.getNotification().getTitle() : 
                       "Incoming Call";
                body = remoteMessage.getNotification() != null ? 
                      remoteMessage.getNotification().getBody() : 
                      "Someone is calling you";
            }
        }

        // Show notification
        sendNotification(title, body, data, isCallNotification);
    }

    // CRITICAL FIX: Check if app is in foreground
    private boolean isAppInForeground() {
        try {
            ActivityManager.RunningAppProcessInfo appProcessInfo = new ActivityManager.RunningAppProcessInfo();
            ActivityManager.getMyMemoryState(appProcessInfo);
            return (appProcessInfo.importance == ActivityManager.RunningAppProcessInfo.IMPORTANCE_FOREGROUND ||
                    appProcessInfo.importance == ActivityManager.RunningAppProcessInfo.IMPORTANCE_VISIBLE);
        } catch (Exception e) {
            Log.e(TAG, "Error checking app state: " + e.getMessage());
            return false; // Default to showing notification if we can't determine state
        }
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

