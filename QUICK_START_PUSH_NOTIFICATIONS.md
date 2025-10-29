# Quick Start: Testing Android Push Notifications

## 🚀 Step 1: Add the Test Service to Your App

In your main app initialization (e.g., `main.dart` or a splash screen):

```dart
import 'package:lovebug/services/push_notification_test_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Supabase
  await Supabase.initialize(
    url: 'YOUR_SUPABASE_URL',
    anonKey: 'YOUR_SUPABASE_ANON_KEY',
  );
  
  // Initialize Firebase (if not already done)
  await Firebase.initializeApp();
  
  // Initialize push notifications
  final pushService = PushNotificationTestService();
  await pushService.initialize();
  
  runApp(MyApp());
}
```

## 🧪 Step 2: Test Notifications

### Option A: Using Firebase Console

1. **Get your FCM token:**
   - Run your app
   - Check the debug console
   - Look for: `✅ FCM Token: [YOUR_TOKEN]`
   - Copy this token

2. **Send test notification:**
   - Go to [Firebase Console](https://console.firebase.google.com/)
   - Select your project
   - Navigate to **Cloud Messaging**
   - Click **Send test message**
   - Paste your FCM token
   - Fill in title and body
   - Click **Test**

### Option B: Using Flutter App

Add a test button in your app (for debugging):

```dart
import 'package:lovebug/services/push_notification_test_service.dart';

class TestScreen extends StatelessWidget {
  final pushService = PushNotificationTestService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Push Notification Test')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Test regular notification
            ElevatedButton(
              onPressed: () async {
                await pushService.testNotification(
                  type: 'new_message',
                  title: 'New Message',
                  body: 'You have a new message!',
                );
              },
              child: Text('Test Message Notification'),
            ),
            
            SizedBox(height: 20),
            
            // Test call notification
            ElevatedButton(
              onPressed: () async {
                await pushService.testNotification(
                  type: 'incoming_call',
                  title: 'Incoming Call',
                  body: 'Sarah is calling...',
                );
              },
              child: Text('Test Call Notification'),
            ),
            
            SizedBox(height: 20),
            
            // Check settings
            ElevatedButton(
              onPressed: () async {
                await pushService.checkNotificationSettings();
              },
              child: Text('Check Notification Settings'),
            ),
            
            SizedBox(height: 20),
            
            // Get current token
            ElevatedButton(
              onPressed: () async {
                final token = await pushService.getCurrentToken();
                print('Current FCM Token: $token');
                // You can show this in a dialog or copy to clipboard
              },
              child: Text('Get FCM Token'),
            ),
          ],
        ),
      ),
    );
  }
}
```

### Option C: Using ADB (Command Line)

```bash
# Send a test notification via ADB
adb shell am start -a android.intent.action.VIEW \
  -d "lovebug://notification?type=test&title=Test&body=TestBody" \
  com.lovebug.app
```

## 📱 Step 3: Test Different Scenarios

### Scenario 1: App in Foreground
1. Open your app
2. Keep it visible on screen
3. Send a notification
4. ✅ Should see log in debug console
5. ✅ Android will show notification in system tray

### Scenario 2: App in Background
1. Open your app
2. Press home button (app goes to background)
3. Send a notification
4. ✅ Should see notification in system tray
5. ✅ Tap notification to open app

### Scenario 3: App Terminated
1. Force close your app (swipe away from recent apps)
2. Send a notification
3. ✅ Should see notification in system tray
4. ✅ Tap notification to launch app

### Scenario 4: Device Locked
1. Lock your device
2. Send a notification
3. ✅ Should see notification on lock screen
4. ✅ Should hear sound/vibration

### Scenario 5: Call Notification (Full Screen)
1. Lock your device
2. Send a notification with `type: "incoming_call"`
3. ✅ Should show full-screen notification
4. ✅ Should hear ringtone

## 🐛 Troubleshooting

### Problem: No FCM token generated

**Solution:**
```bash
# 1. Check google-services.json exists
ls android/app/google-services.json

# 2. Clean and rebuild
flutter clean
flutter pub get
cd android && ./gradlew clean && cd ..
flutter run
```

### Problem: Notifications not showing

**Check these:**
```dart
// 1. Check notification permission
final pushService = PushNotificationTestService();
await pushService.checkNotificationSettings();

// 2. Check if FCM token exists
final token = await pushService.getCurrentToken();
print('Token: $token');

// 3. Check Android system settings
// Settings → Apps → LoveBug → Notifications → Ensure "Allow notifications" is ON
```

### Problem: No sound/vibration

**Fix:**
1. Go to Android Settings → Apps → LoveBug → Notifications
2. Select the notification channel (Call Notifications or General Notifications)
3. Ensure:
   - Sound is enabled
   - Vibration is enabled
   - Importance is set to High (for calls) or Default

### Problem: Notification not tapping properly

**Check:**
```dart
// Make sure you're listening to notification taps in main.dart
FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
  print('Notification tapped: ${message.data}');
  // Navigate based on message.data
});
```

## 📊 View Logs

### Android Studio / Logcat
```bash
# Filter by package name
adb logcat | grep "com.lovebug.app"

# Filter by FCM tags
adb logcat | grep -E "(FCM_SERVICE|MainActivity|FirebaseMessaging)"

# Clear and watch logs
adb logcat -c && adb logcat | grep -E "(FCM|lovebug)"
```

### Flutter Debug Console
All push notification events will appear in your Flutter debug console with these prefixes:
- `✅` Success messages
- `❌` Error messages
- `📨` Foreground messages
- `🔔` Notification taps
- `📞` Call notifications
- `💬` Message notifications
- `🧪` Test messages

## ✅ Verification Checklist

Before deploying to production:

- [ ] FCM token is generated successfully
- [ ] FCM token is saved to Supabase users table
- [ ] Foreground notifications work (app open)
- [ ] Background notifications work (app minimized)
- [ ] Terminated notifications work (app closed)
- [ ] Notification taps open the app
- [ ] Deep links work from notifications
- [ ] Call notifications show full-screen
- [ ] Sound and vibration work
- [ ] Notification icons display correctly
- [ ] Battery optimization exemption requested
- [ ] Tested on Android 8, 10, 12, 13+

## 🔒 Production Checklist

- [ ] Remove test notification buttons from production builds
- [ ] Add proper error handling and user feedback
- [ ] Implement notification permission request UI
- [ ] Add analytics for notification delivery rates
- [ ] Set up notification preferences in user settings
- [ ] Test with production Firebase project
- [ ] Upload production `google-services.json`
- [ ] Verify FCM server key in Supabase secrets
- [ ] Test with release build (signed APK)

## 📚 Next Steps

1. **Customize notification handlers** in `push_notification_test_service.dart`
2. **Add navigation logic** when notifications are tapped
3. **Style notifications** with images, actions, and custom layouts
4. **Implement notification preferences** (allow users to mute certain types)
5. **Add notification history** in your app
6. **Set up notification analytics** to track delivery and open rates

## 🆘 Need Help?

**Check documentation:**
- `ANDROID_PUSH_NOTIFICATIONS_SETUP.md` - Detailed technical documentation
- `lib/services/push_notification_test_service.dart` - Service with inline comments

**Common Firebase Errors:**
- [Firebase Cloud Messaging Troubleshooting](https://firebase.google.com/docs/cloud-messaging/android/first-message#troubleshooting)
- [Android Notification Channels](https://developer.android.com/training/notify-user/channels)

---

**Current Status:** ✅ Ready to Test

**Your Firebase Setup:**
- Sender ID: 864463518345
- Package: com.lovebug.app
- FCM API: Enabled (V1)
- Android Key: AIzaSyDRhi5nwAdtk4_BxhDMK4yqDxB55aMVQYM

