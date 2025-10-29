# Android Push Notifications - Complete Setup

## ✅ What Was Implemented

### 1. Custom Firebase Messaging Service
**File:** `android/app/src/main/java/com/lovebug/app/MyFirebaseMessagingService.java`

Features:
- ✅ Custom handling of FCM messages in foreground and background
- ✅ Automatic notification display with custom channels
- ✅ Special handling for call notifications (full-screen intent, high priority)
- ✅ Logging for debugging FCM token and message reception
- ✅ Support for both notification and data payloads

### 2. Updated MainActivity
**File:** `android/app/src/main/java/com/lovebug/app/MainActivity.java`

Changes:
- ✅ Added `onCreate()` method to initialize notification channels on app start
- ✅ Added logging for intent extras (useful for debugging notification taps)
- ✅ Added ringtone sound to call notification channel
- ✅ Channels created: `call_notifications` (HIGH) and `default_notifications` (DEFAULT)

### 3. Updated AndroidManifest.xml
**File:** `android/app/src/main/AndroidManifest.xml`

Changes:
- ✅ Replaced default `FlutterFirebaseMessagingService` with custom `MyFirebaseMessagingService`
- ✅ Added Firebase Cloud Messaging metadata:
  - Default notification icon: `@drawable/ic_notification`
  - Default notification color: `@color/notification_color` (#FF6B6B)
  - Default notification channel: `default_notifications`

### 4. Notification Resources
**Files Created:**
- `android/app/src/main/res/drawable/ic_notification.xml` - Bell icon for notifications
- `android/app/src/main/res/values/colors.xml` - Notification color (#FF6B6B)

## 🔧 Firebase Configuration

### Current Setup
- **Sender ID:** 864463518345
- **Android API Key:** AIzaSyDRhi5nwAdtk4_BxhDMK4yqDxB55aMVQYM
- **iOS APNs:** Development auth key uploaded (9AU8Z3JX48)
- **Package Name:** com.lovebug.app

### Build Configuration
**File:** `android/app/build.gradle.kts`

```kotlin
dependencies {
    implementation(platform("com.google.firebase:firebase-bom:34.4.0"))
    implementation("com.google.firebase:firebase-analytics")
    implementation("com.google.firebase:firebase-messaging")
}
```

✅ Firebase dependencies are properly configured.

## 📱 Notification Channels

### 1. Call Notifications (`call_notifications`)
- **Importance:** HIGH
- **Features:**
  - Full-screen intent for incoming calls
  - Custom ringtone sound
  - Vibration enabled
  - Non-dismissible (ongoing) for active calls
  - Badge enabled

### 2. Default Notifications (`default_notifications`)
- **Importance:** DEFAULT
- **Features:**
  - Standard notification sound
  - Vibration enabled
  - Auto-dismissible
  - Badge enabled

## 🧪 Testing Push Notifications

### Method 1: Firebase Console
1. Go to Firebase Console → Cloud Messaging
2. Click "Send test message"
3. Enter your FCM token (get from Flutter app logs)
4. Send notification

### Method 2: Using Flutter Code
See `lib/services/push_notification_test_service.dart` for a complete test implementation.

### Method 3: Test with Supabase Edge Function
```dart
// Example: Test from your app
final response = await Supabase.instance.client.functions.invoke(
  'send-push-notification',
  body: {
    'userId': 'your-user-id',
    'type': 'new_message',
    'title': 'Test Notification',
    'body': 'This is a test message',
    'data': {'test': 'true'},
  },
);
print('Response: ${response.data}');
```

## 🐛 Debugging

### Check Logs
```bash
# Android Studio Logcat - Filter by:
adb logcat | grep -E "(FCM_SERVICE|MainActivity)"
```

### Key Log Messages
- `FCM_SERVICE: New FCM token: [token]` - Token generated successfully
- `FCM_SERVICE: Message received from: [sender]` - Message received
- `FCM_SERVICE: Notification shown with ID: [id]` - Notification displayed
- `MainActivity: Intent extras:` - Notification tapped

### Common Issues

#### 1. Notifications Not Appearing
**Checklist:**
- ✅ `google-services.json` exists in `android/app/`
- ✅ FCM token is being generated (check logs)
- ✅ App has notification permissions (Android 13+)
- ✅ App is not in battery optimization mode
- ✅ Notification channels are created

**Fix:**
```bash
# Rebuild the app
flutter clean
flutter pub get
flutter run
```

#### 2. No FCM Token Generated
**Check:**
```dart
String? token = await FirebaseMessaging.instance.getToken();
print('FCM Token: $token');
```

**Possible causes:**
- Missing `google-services.json`
- Internet connection issue
- Google Play Services not available

#### 3. Notifications Only Work in Foreground
**Check AndroidManifest.xml:**
- ✅ Custom service is declared
- ✅ `android:exported="false"` is set
- ✅ Intent filter for `com.google.firebase.MESSAGING_EVENT`

#### 4. Silent Notifications (No Sound/Vibration)
**Check:**
- Notification channels are created on app start
- Device is not in Do Not Disturb mode
- Volume is not muted
- For call notifications, ensure channel has ringtone sound

## 📋 Notification Payload Format

### For Regular Notifications
```json
{
  "to": "FCM_TOKEN",
  "notification": {
    "title": "New Message",
    "body": "You have a new message"
  },
  "data": {
    "type": "new_message",
    "senderId": "user123",
    "chatId": "chat456"
  },
  "android": {
    "priority": "high"
  }
}
```

### For Call Notifications
```json
{
  "to": "FCM_TOKEN",
  "notification": {
    "title": "Incoming Call",
    "body": "John is calling..."
  },
  "data": {
    "type": "incoming_call",
    "callerId": "user123",
    "callId": "call789"
  },
  "android": {
    "priority": "high"
  }
}
```

### Notification Types Handled
- `incoming_call` - Shows full-screen call UI
- `missed_call` - Standard notification
- `call_ended` - Standard notification
- `call_rejected` - Standard notification
- Any other type - Uses default channel

## 🚀 Next Steps

### 1. Request Notification Permission (Android 13+)
```dart
// In your Flutter app
await FirebaseMessaging.instance.requestPermission(
  alert: true,
  badge: true,
  sound: true,
);
```

### 2. Save FCM Token to Supabase
```dart
String? token = await FirebaseMessaging.instance.getToken();
if (token != null) {
  await Supabase.instance.client
    .from('users')
    .update({'fcm_token': token})
    .eq('id', userId);
}
```

### 3. Handle Token Refresh
```dart
FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
  // Update token in Supabase
  updateTokenInDatabase(newToken);
});
```

### 4. Test All Scenarios
- [ ] App in foreground
- [ ] App in background
- [ ] App terminated
- [ ] Device locked
- [ ] Low battery mode
- [ ] After device restart

## 🔐 Security Notes

- ✅ FCM tokens are device-specific and can be revoked
- ✅ Never commit `google-services.json` with production keys to public repos
- ✅ Server Key should be kept secret (used in Supabase Edge Functions)
- ✅ Consider implementing token rotation for enhanced security

## 📚 Resources

- [Firebase Cloud Messaging Documentation](https://firebase.google.com/docs/cloud-messaging)
- [Android Notification Channels](https://developer.android.com/develop/ui/views/notifications/channels)
- [FlutterFire Messaging Plugin](https://firebase.flutter.dev/docs/messaging/overview/)

## ✅ Configuration Checklist

- [x] Custom Firebase Messaging Service created
- [x] MainActivity updated with onCreate initialization
- [x] AndroidManifest.xml updated with custom service
- [x] Firebase metadata added to manifest
- [x] Notification icon and colors created
- [x] Notification channels configured (call + default)
- [x] Firebase dependencies verified
- [ ] Test on real device (physical Android phone)
- [ ] Test all notification scenarios
- [ ] Verify FCM token generation
- [ ] Test notification taps and deep links
- [ ] Check battery optimization exemption

---

**Status:** ✅ Setup Complete - Ready for Testing

**Last Updated:** October 29, 2025

