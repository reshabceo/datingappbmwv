package com.lovebug.lovebug

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.media.RingtoneManager
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val NOTIFICATION_CHANNEL = "com.lovebug.lovebug/notification"
    private val CALL_CHANNEL_ID = "call_notifications"
    private val DEFAULT_CHANNEL_ID = "default_notifications"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        createNotificationChannels(notificationManager)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, NOTIFICATION_CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "clearCallNotification") {
                clearCallNotification()
                result.success(null)
            } else {
                result.notImplemented()
            }
        }

        // Channel for call notification actions (Accept/Decline)
        val callActionChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.lovebug.lovebug/call_actions"
        )
        CallActionReceiver.setMethodChannel(callActionChannel)
    }

    private fun clearCallNotification() {
        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        // Clear specific call notification ID (12345) to avoid removing chat notifications
        notificationManager.cancel(12345)
    }

    private fun createNotificationChannels(notificationManager: NotificationManager) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            // Call channel - CRITICAL: High priority and specific sound
            val callChannel = NotificationChannel(
                CALL_CHANNEL_ID,
                "Incoming Calls",
                NotificationManager.IMPORTANCE_HIGH
            )
            callChannel.description = "Incoming audio and video call notifications"
            callChannel.enableVibration(true)
            callChannel.vibrationPattern = longArrayOf(0, 1000, 500, 1000)
            callChannel.setSound(RingtoneManager.getDefaultUri(RingtoneManager.TYPE_RINGTONE), null)
            callChannel.lockscreenVisibility = Notification.VISIBILITY_PUBLIC
            callChannel.setBypassDnd(true) // Important for calls

            // Default channel
            val defaultChannel = NotificationChannel(
                DEFAULT_CHANNEL_ID,
                "App Notifications",
                NotificationManager.IMPORTANCE_DEFAULT
            )
            defaultChannel.description = "General notifications from LoveBug"

            notificationManager.createNotificationChannel(callChannel)
            notificationManager.createNotificationChannel(defaultChannel)
        }
    }
}
