package com.lovebug.lovebug

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.media.RingtoneManager
import android.os.Build
import android.util.Log
import androidx.core.app.NotificationCompat
import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage

class MyFirebaseMessagingService : FirebaseMessagingService() {

    override fun onNewToken(token: String) {
        super.onNewToken(token)
        Log.d(TAG, "New FCM token: $token")
    }

    override fun onMessageReceived(remoteMessage: RemoteMessage) {
        super.onMessageReceived(remoteMessage)
        
        Log.d(TAG, "Message received from: ${remoteMessage.from}")
        val data: Map<String, String> = remoteMessage.data
        val notificationType: String = data["type"] ?: ""
        
        val isIncomingCall: Boolean = notificationType == "incoming_call"
        
        val titleString: String = remoteMessage.notification?.title ?: data["title"] ?: "LoveBug"
        var bodyString: String = remoteMessage.notification?.body ?: data["body"] ?: ""
        val callerName: String? = data["caller_name"]
        if (isIncomingCall) {
            if (callerName != null && (bodyString == "" || bodyString.lowercase().contains("unknown"))) {
                bodyString = "$callerName is calling you"
            }
        }

        sendNotification(titleString, bodyString, data, isIncomingCall)
    }

    private fun sendNotification(title: String, body: String, data: Map<String, String>, isIncoming: Boolean) {
        Log.d(TAG, "Creating notification - IsIncoming: $isIncoming")

        val intent = Intent(this as Context, MainActivity::class.java)
        intent.addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP)
        for (entry in data.entries) {
            intent.putExtra(entry.key, entry.value)
        }

        val pendingIntent = PendingIntent.getActivity(
            this as Context, 
            0, 
            intent, 
            PendingIntent.FLAG_ONE_SHOT or PendingIntent.FLAG_IMMUTABLE
        )

        val channelId = if (isIncoming) CALL_CHANNEL_ID else DEFAULT_CHANNEL_ID
        
        val notificationBuilder = NotificationCompat.Builder(this as Context, channelId)
            .setSmallIcon(com.lovebug.lovebug.R.mipmap.ic_launcher)
            .setContentTitle(title)
            .setContentText(body)
            .setAutoCancel(true)
            .setContentIntent(pendingIntent)
            .setPriority(if (isIncoming) NotificationCompat.PRIORITY_MAX else NotificationCompat.PRIORITY_DEFAULT)
            .setCategory(if (isIncoming) NotificationCompat.CATEGORY_CALL else NotificationCompat.CATEGORY_MESSAGE)

        if (isIncoming) {
            // Accept Action
            val acceptIntent = Intent(this as Context, CallActionReceiver::class.java)
            acceptIntent.setAction("ACCEPT_CALL")
            acceptIntent.putExtra("call_id", data["call_id"])
            acceptIntent.putExtra("caller_id", data["caller_id"])
            acceptIntent.putExtra("match_id", data["match_id"])
            acceptIntent.putExtra("call_type", data["call_type"])
            
            val acceptPendingIntent = PendingIntent.getBroadcast(
                this as Context, 1, acceptIntent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )

            // Decline Action
            val declineIntent = Intent(this as Context, CallActionReceiver::class.java)
            declineIntent.setAction("DECLINE_CALL")
            declineIntent.putExtra("call_id", data["call_id"])
            
            val declinePendingIntent = PendingIntent.getBroadcast(
                this as Context, 2, declineIntent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )

            notificationBuilder
                .addAction(android.R.drawable.ic_menu_call, "Accept", acceptPendingIntent)
                .addAction(android.R.drawable.ic_menu_close_clear_cancel, "Decline", declinePendingIntent)
                .setOngoing(true)
                .setFullScreenIntent(pendingIntent, true)
        }

        val notificationManager = this.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            createNotificationChannels(notificationManager)
        }

        val notificationId = if (isIncoming) 12345 else System.currentTimeMillis().toInt()
        notificationManager.notify(notificationId, notificationBuilder.build())
    }

    private fun createNotificationChannels(notificationManager: NotificationManager) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            // Call channel
            val callChannel = NotificationChannel(
                CALL_CHANNEL_ID,
                "Call Notifications",
                NotificationManager.IMPORTANCE_HIGH
            )
            callChannel.description = "Incoming call notifications"
            callChannel.enableVibration(true)
            callChannel.setSound(RingtoneManager.getDefaultUri(RingtoneManager.TYPE_RINGTONE), null)
            callChannel.lockscreenVisibility = Notification.VISIBILITY_PUBLIC

            // Default channel
            val defaultChannel = NotificationChannel(
                DEFAULT_CHANNEL_ID,
                "General Notifications",
                NotificationManager.IMPORTANCE_DEFAULT
            )
            defaultChannel.description = "General app notifications"

            notificationManager.createNotificationChannel(callChannel)
            notificationManager.createNotificationChannel(defaultChannel)
        }
    }

    companion object {
        private const val TAG = "FCM_SERVICE"
        private const val CALL_CHANNEL_ID = "call_notifications"
        private const val DEFAULT_CHANNEL_ID = "default_notifications"
    }
}
