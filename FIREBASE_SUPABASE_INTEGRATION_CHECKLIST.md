# 🔥 Firebase + Supabase Integration Checklist

## Based on Your Firebase Screenshots Analysis

### ✅ What's Already Configured (From Screenshots)

1. **✅ Firebase Cloud Messaging API (V1)** - ENABLED
   - Status: Enabled ✅
   - Sender ID: `864463518345` ✅
   - This is the modern API (Legacy API is correctly disabled)

2. **✅ Android API Key** - PRESENT
   - Key: `AIzaSyDRhi5nwAdtk4_BxhDMK4yqDxB55aMVQYM` ✅
   - This is used for Android app communication

3. **✅ Firebase Admin SDK** - CONFIGURED
   - Service Account: `firebase-adminsdk-fbsvc@lovebug-dating-app.iam.gserviceaccount.com` ✅
   - Project ID: `lovebug-dating-app` ✅
   - This is for server-side operations (Supabase Edge Functions)

---

## ⚠️ CRITICAL: What You MUST Configure in Supabase

Your Supabase Edge Function (`send-push-notification`) requires these environment variables to send notifications:

### Required Supabase Secrets

Your Edge Function needs these two secrets (lines 92-93 in `index.ts`):

```typescript
const firebasePrivateKey = Deno.env.get('FIREBASE_PRIVATE_KEY')
const firebaseClientEmail = Deno.env.get('FIREBASE_CLIENT_EMAIL')
```

---

## 📝 Step-by-Step: Configure Supabase Secrets

### Step 1: Download Firebase Service Account JSON

1. **Go to Firebase Console** → Project Settings → Service Accounts
2. **Click "Generate new private key"** (shown in your screenshot 2)
3. **Download the JSON file** (e.g., `lovebug-dating-app-firebase-adminsdk.json`)

The file will look like this:
```json
{
  "type": "service_account",
  "project_id": "lovebug-dating-app",
  "private_key_id": "...",
  "private_key": "-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n",
  "client_email": "firebase-adminsdk-fbsvc@lovebug-dating-app.iam.gserviceaccount.com",
  "client_id": "...",
  "auth_uri": "https://accounts.google.com/o/oauth2/auth",
  "token_uri": "https://oauth2.googleapis.com/token",
  "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
  "client_x509_cert_url": "..."
}
```

### Step 2: Set Supabase Environment Variables

**Option A: Using Supabase Dashboard**

1. Go to your Supabase project dashboard
2. Navigate to **Settings** → **Edge Functions** → **Secrets**
3. Add these two secrets:

   **Secret 1:**
   - Name: `FIREBASE_CLIENT_EMAIL`
   - Value: `firebase-adminsdk-fbsvc@lovebug-dating-app.iam.gserviceaccount.com`

   **Secret 2:**
   - Name: `FIREBASE_PRIVATE_KEY`
   - Value: Copy the entire `private_key` value from the JSON file (including the `-----BEGIN PRIVATE KEY-----` and `-----END PRIVATE KEY-----` lines)

**Option B: Using Supabase CLI**

```bash
# Navigate to your project
cd /Users/reshab/Desktop/datingappbmwv

# Set Firebase client email
supabase secrets set FIREBASE_CLIENT_EMAIL="firebase-adminsdk-fbsvc@lovebug-dating-app.iam.gserviceaccount.com"

# Set Firebase private key (replace with your actual private key)
supabase secrets set FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----
MIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQC...
-----END PRIVATE KEY-----"
```

### Step 3: Verify Secrets are Set

```bash
# List all secrets
supabase secrets list

# You should see:
# - FIREBASE_CLIENT_EMAIL
# - FIREBASE_PRIVATE_KEY
# - SUPABASE_URL (already set)
# - SUPABASE_SERVICE_ROLE_KEY (already set)
```

### Step 4: Redeploy Edge Function

After setting secrets, redeploy the edge function:

```bash
cd /Users/reshab/Desktop/datingappbmwv

# Deploy send-push-notification function
supabase functions deploy send-push-notification
```

---

## 🧪 Test Push Notification After Setup

### Test 1: Via Supabase SQL Editor

```sql
-- Call the edge function to send a test notification
SELECT
  http_post(
    url := 'https://YOUR_SUPABASE_URL/functions/v1/send-push-notification',
    headers := jsonb_build_object(
      'Authorization', 'Bearer YOUR_SUPABASE_ANON_KEY',
      'Content-Type', 'application/json'
    ),
    body := jsonb_build_object(
      'userId', 'YOUR_USER_ID',
      'type', 'new_message',
      'title', 'Test Notification',
      'body', 'Testing push notifications',
      'data', jsonb_build_object('test', 'true')
    )
  );
```

### Test 2: Via Flutter App

```dart
import 'package:lovebug/services/push_notification_test_service.dart';

// In your app
final testService = PushNotificationTestService();
await testService.initialize();

// Send test notification
await testService.testNotification(
  type: 'new_message',
  title: 'Test Notification',
  body: 'This is a test from Flutter',
);
```

---

## 🔍 Android-Specific Configuration Already Complete

Based on your setup and our implementation, these are already done:

### ✅ Android App Configuration (Complete)
- [x] `google-services.json` in `android/app/`
- [x] Firebase dependencies in `build.gradle.kts`
- [x] Custom `MyFirebaseMessagingService.java`
- [x] Updated `MainActivity.java` with notification channels
- [x] AndroidManifest.xml with FCM metadata
- [x] Notification icons and colors created
- [x] Notification channels:
  - `call_notifications` (HIGH priority)
  - `default_notifications` (DEFAULT priority)

### ✅ Flutter Integration (Complete)
- [x] `firebase_core: ^3.6.0`
- [x] `firebase_messaging: ^15.2.0`
- [x] Firebase initialized in `notification_service.dart`
- [x] FCM token registration implemented
- [x] Foreground/background message handlers
- [x] Notification tap handling

---

## 📊 Configuration Summary

### Android Client → Firebase

```
Android App (LoveBug)
  ├─ Package: com.lovebug.app ✅
  ├─ Sender ID: 864463518345 ✅
  ├─ API Key: AIzaSyDRhi5nwAdtk4_BxhDMK4yqDxB55aMVQYM ✅
  ├─ google-services.json ✅
  └─ FCM Token → Saved to Supabase users.fcm_token ✅
```

### Supabase Edge Function → Firebase

```
Supabase Edge Function (send-push-notification)
  ├─ Firebase Project: lovebug-dating-app ✅
  ├─ Service Account: firebase-adminsdk-fbsvc@... ✅
  ├─ FIREBASE_CLIENT_EMAIL: [NEEDS TO BE SET] ⚠️
  ├─ FIREBASE_PRIVATE_KEY: [NEEDS TO BE SET] ⚠️
  └─ Uses FCM V1 API ✅
```

---

## 🚨 Action Items

### Immediate Actions Required:

1. **⚠️ Download Firebase Service Account JSON**
   - Go to Firebase Console → Settings → Service Accounts
   - Click "Generate new private key"
   - Save the JSON file securely (DO NOT commit to git!)

2. **⚠️ Set Supabase Secrets**
   - Extract `client_email` from JSON → Set as `FIREBASE_CLIENT_EMAIL`
   - Extract `private_key` from JSON → Set as `FIREBASE_PRIVATE_KEY`
   - Use Supabase Dashboard or CLI

3. **⚠️ Redeploy Edge Function**
   ```bash
   supabase functions deploy send-push-notification
   ```

4. **✅ Test on Android Device**
   ```bash
   flutter run
   ```

---

## ✅ After Completing Above Steps

Once you've set the Supabase secrets, your complete push notification flow will be:

```
User Action (e.g., new message)
  ↓
Supabase Database Trigger/Manual Call
  ↓
Supabase Edge Function (send-push-notification)
  ↓
Firebase Cloud Messaging (FCM) V1 API
  ↓
Android Device (via FCM token)
  ↓
MyFirebaseMessagingService receives message
  ↓
Notification displayed with sound/vibration
  ↓
User taps notification
  ↓
App opens with notification data
```

---

## 🔒 Security Notes

### ⚠️ NEVER Commit These to Git:
- ❌ Firebase service account JSON file
- ❌ Private keys
- ❌ `google-services.json` (if it contains production keys)

### ✅ Safe to Commit:
- ✅ `android/app/src/main/java/**/*.java` (no secrets)
- ✅ `AndroidManifest.xml` (no secrets)
- ✅ Edge function code (`index.ts`) - uses environment variables
- ✅ Flutter Dart code (no hardcoded keys)

### 🔐 Add to .gitignore:
```gitignore
# Firebase
**/google-services.json
**/GoogleService-Info.plist
firebase-adminsdk-*.json
serviceAccountKey.json

# Supabase
.env
.env.local
```

---

## 📚 Reference URLs

- [Firebase Console](https://console.firebase.google.com/project/lovebug-dating-app)
- [Firebase Cloud Messaging V1 API Docs](https://firebase.google.com/docs/reference/fcm/rest/v1/projects.messages)
- [Supabase Edge Functions Docs](https://supabase.com/docs/guides/functions)
- [Supabase Secrets Management](https://supabase.com/docs/guides/functions/secrets)

---

## 🆘 Common Issues After Setup

### Issue: "Firebase configuration missing" error in Edge Function
**Solution:** Verify both secrets are set correctly in Supabase

### Issue: "Failed to send notification" with 401 error
**Solution:** The private key may be incorrectly formatted. Ensure it includes the `-----BEGIN/END-----` lines

### Issue: "Invalid token" error
**Solution:** The FCM token may have expired. Regenerate token in the Flutter app

### Issue: Notifications not received on Android
**Solution:** 
1. Check FCM token is saved to database
2. Verify device has Google Play Services
3. Check internet connection
4. Ensure notification permissions are granted

---

**Status After Completing Above:** ✅ Full push notification system ready for production

**Last Updated:** October 29, 2025

