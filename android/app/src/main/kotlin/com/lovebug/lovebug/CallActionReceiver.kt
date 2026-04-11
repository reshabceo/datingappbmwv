package com.lovebug.lovebug

import android.app.NotificationManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log
import io.flutter.plugin.common.MethodChannel

class CallActionReceiver : BroadcastReceiver() {
    
    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action
        Log.d(TAG, "Received action: $action")

        if (action == null) return

        val callId = intent.getStringExtra("call_id")
        val callerId = intent.getStringExtra("caller_id")
        val matchId = intent.getStringExtra("match_id")
        val callType = intent.getStringExtra("call_type")

        if (callId == null) {
            Log.e(TAG, "No call_id in intent")
            return
        }

        if (action == "ACCEPT_CALL") {
            Log.d(TAG, "Accepting call: $callId")
            
            // Send action to Flutter
            val args = HashMap<String, Any?>()
            args["action"] = "accept"
            args["call_id"] = callId
            args["caller_id"] = callerId
            args["match_id"] = matchId
            args["call_type"] = callType
            
            methodChannel?.invokeMethod("handleCallAction", args)
            
            // Launch app
            val launchIntent = Intent(context, MainActivity::class.java)
            launchIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
            launchIntent.putExtra("action", "accept_call")
            launchIntent.putExtra("call_id", callId)
            context.startActivity(launchIntent)
            
        } else if (action == "DECLINE_CALL") {
            Log.d(TAG, "Declining call: $callId")
            
            val args = HashMap<String, Any?>()
            args["action"] = "decline"
            args["call_id"] = callId
            
            methodChannel?.invokeMethod("handleCallAction", args)
        }
        
        // Dismiss notification
        val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        notificationManager.cancel(12345)
    }

    companion object {
        private const val TAG = "CallActionReceiver"
        private var methodChannel: MethodChannel? = null

        fun setMethodChannel(channel: MethodChannel) {
            methodChannel = channel
        }
    }
}
