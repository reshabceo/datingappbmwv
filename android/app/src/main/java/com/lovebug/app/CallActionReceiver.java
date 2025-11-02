package com.lovebug.app;

import android.app.NotificationManager;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.util.Log;

import java.util.HashMap;
import java.util.Map;

import io.flutter.plugin.common.MethodChannel;

public class CallActionReceiver extends BroadcastReceiver {
    private static final String TAG = "CallActionReceiver";
    private static MethodChannel channel;

    public static void setMethodChannel(MethodChannel ch) {
        channel = ch;
    }

    @Override
    public void onReceive(Context context, Intent intent) {
        String action = intent.getAction();
        String callId = intent.getStringExtra("call_id");
        String callerId = intent.getStringExtra("caller_id");
        String matchId = intent.getStringExtra("match_id");
        String callType = intent.getStringExtra("call_type");

        Log.d(TAG, "Action received: " + action + " for call: " + callId);

        if ("ACCEPT_CALL".equals(action)) {
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
            launchIntent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_CLEAR_TOP | Intent.FLAG_ACTIVITY_SINGLE_TOP);
            launchIntent.putExtra("action", "accept_call");
            launchIntent.putExtra("call_id", callId);
            launchIntent.putExtra("caller_id", callerId);
            launchIntent.putExtra("match_id", matchId);
            launchIntent.putExtra("call_type", callType);
            context.startActivity(launchIntent);

        } else if ("DECLINE_CALL".equals(action)) {
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


