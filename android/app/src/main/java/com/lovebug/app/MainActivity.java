package com.lovebug.app;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;
import java.util.Map;
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
    private MethodChannel callActionChannel;
    
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
        callActionChannel = new MethodChannel(
            flutterEngine.getDartExecutor().getBinaryMessenger(),
            "com.lovebug.app/call_actions"
        );
        CallActionReceiver.setMethodChannel(callActionChannel);

        // If activity was launched from a notification action, forward it now
        handleLaunchIntent(getIntent());
    }

    @Override
    protected void onNewIntent(Intent intent) {
        super.onNewIntent(intent);
        setIntent(intent);
        handleLaunchIntent(intent);
    }

    private void handleLaunchIntent(Intent intent) {
        if (intent == null || intent.getExtras() == null) return;
        Bundle extras = intent.getExtras();
        String action = extras.getString("action", "");
        if ("accept_call".equals(action)) {
            Log.d(TAG, "Handling accept_call launch intent");
            String callId = extras.getString("call_id", "");
            String callerId = extras.getString("caller_id", "");
            String matchId = extras.getString("match_id", "");
            String callType = extras.getString("call_type", "video");
            if (callActionChannel != null) {
                Map<String, Object> args = new java.util.HashMap<>();
                args.put("action", "accept");
                args.put("call_id", callId);
                args.put("caller_id", callerId);
                args.put("match_id", matchId);
                args.put("call_type", callType);
                callActionChannel.invokeMethod("handleCallAction", args);
            }
        }
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
