# Deployment Guide: Android Push Notification Fix

## Overview
This guide walks you through deploying the fix for Android push notifications (Priority 1).

## Prerequisites
- Supabase CLI installed
- Android development environment set up
- Access to Supabase project dashboard

---

## Step 1: Verify Database Schema

### 1.1 Check if FCM token column exists
Run this in Supabase SQL Editor:

```sql
SELECT column_name 
FROM information_schema.columns
WHERE table_name = 'profiles' 
  AND column_name = 'fcm_token';
```

### 1.2 If column doesn't exist, run the migration
```bash
# In Supabase SQL Editor, run the contents of:
cat fix_fcm_token_column.sql
```

Or manually execute:
```sql
ALTER TABLE public.profiles 
ADD COLUMN IF NOT EXISTS fcm_token TEXT;

CREATE INDEX IF NOT EXISTS idx_profiles_fcm_token 
ON public.profiles(fcm_token);
```

---

## Step 2: Deploy Edge Function

### 2.1 Login to Supabase (if not already logged in)
```bash
cd /Users/reshab/Desktop/datingappbmwv
supabase login
```

### 2.2 Link to your project (if not already linked)
```bash
supabase link --project-ref YOUR_PROJECT_REF
```

### 2.3 Deploy the updated Edge Function
```bash
supabase functions deploy send-push-notification
```

Expected output:
```
✓ Deployed send-push-notification
✓ Function deployed successfully
```

### 2.4 Verify deployment in Supabase Dashboard
1. Go to: https://supabase.com/dashboard/project/YOUR_PROJECT_ID/functions
2. Check that `send-push-notification` shows recent deployment time
3. Click on it and verify the logs are working

---

## Step 3: Rebuild and Deploy Android App

### 3.1 Clean the project
```bash
cd /Users/reshab/Desktop/datingappbmwv
flutter clean
flutter pub get
```

### 3.2 Build the app
For testing on device:
```bash
flutter run
```

For release build:
```bash
flutter build apk --release
# or
flutter build appbundle --release
```

### 3.3 Install on test device
- Connect Android device via USB
- Enable USB debugging
- Run: `flutter install` or `flutter run`

---

## Step 4: Test FCM Token Registration

### 4.1 Monitor app logs during launch
```bash
flutter logs | grep -E "FCM|PUSH|ANDROID"
```

Look for these success indicators:
```
✅ 🔔 FCM: Firebase initialized successfully
✅ 🔔 FCM: FirebaseMessaging instance created
✅ 🤖 ANDROID: Android push notification configuration completed
✅ 🔔 FCM: FCM Token obtained: YES
✅ 🔔 FCM: FCM Token stored in database successfully
```

### 4.2 Verify token in database
Run in Supabase SQL Editor:
```sql
SELECT 
  id, 
  email, 
  LEFT(fcm_token, 30) as token_preview,
  LENGTH(fcm_token) as token_length
FROM profiles 
WHERE email = 'YOUR_TEST_EMAIL'
  AND fcm_token IS NOT NULL;
```

Expected: Token length should be ~150-200 characters

---

## Step 5: Test Push Notifications

### 5.1 Send test notification via SQL
Replace placeholders and run in Supabase SQL Editor:

```sql
SELECT extensions.http((
  'POST',
  'YOUR_SUPABASE_URL/functions/v1/send-push-notification',
  ARRAY[
    extensions.http_header('Authorization', 'Bearer YOUR_ANON_KEY'),
    extensions.http_header('Content-Type', 'application/json')
  ],
  'application/json',
  json_build_object(
    'userId', 'USER_ID_FROM_STEP_4',
    'type', 'incoming_call',
    'title', '📞 Test Call',
    'body', 'Testing Android push notification',
    'data', json_build_object(
      'call_id', 'test-call-123',
      'caller_name', 'Test User',
      'call_type', 'video',
      'caller_id', 'test-caller-id',
      'match_id', 'test-match-id',
      'action', 'incoming_call'
    )
  )::text
)::text);
```

### 5.2 Check Edge Function logs
1. Go to: Supabase Dashboard > Edge Functions > send-push-notification > Logs
2. Look for recent execution
3. Verify no errors (especially no "invalid JSON" errors)
4. Check that payload structure looks correct

### 5.3 Verify notification on Android device
- Notification should appear as heads-up (high priority)
- Should show call icon and caller name
- Should use "Call Notifications" channel
- Tapping should open the app

---

## Step 6: Test Real Call Flow

### 6.1 Set up two test accounts
- Account A: Android device (receiver)
- Account B: Any device (caller)

### 6.2 Initiate call from Account B to Account A
Watch Android logs on Account A:
```bash
flutter logs | grep -E "PUSH|CALL|FCM"
```

Expected log sequence:
```
📱 PUSH: Received foreground message
📱 PUSH: Message data: {type: incoming_call, call_id: ...}
📞 CALL: Handling incoming call notification
📞 CALL: Call Type: video
✅ Notification displayed
```

### 6.3 Verify notification behavior
- [ ] Notification appears within 2-3 seconds
- [ ] Shows as heads-up notification (slides down from top)
- [ ] Displays caller name and call type
- [ ] Uses correct notification channel
- [ ] Tapping opens call screen
- [ ] Call can be answered successfully

---

## Step 7: Background/Killed App Testing

### 7.1 Test with app in background
1. Open app and log in
2. Press Home button (app in background)
3. Have someone call you
4. Verify notification appears
5. Tap notification
6. Verify app opens to call screen

### 7.2 Test with app killed
1. Open app and log in
2. Swipe away app from recent apps (kill it)
3. Have someone call you
4. Verify notification appears
5. Tap notification
6. Verify app launches and shows call screen

---

## Troubleshooting

### Issue: FCM token not saving
**Symptoms:** No token in database after login

**Solutions:**
1. Check Firebase initialization:
   ```bash
   flutter logs | grep "Firebase initialized"
   ```
2. Verify user is authenticated:
   ```bash
   flutter logs | grep "User signed in"
   ```
3. Check RLS policies:
   ```sql
   SELECT policyname, cmd 
   FROM pg_policies 
   WHERE tablename = 'profiles';
   ```
4. Manually retry registration:
   - Log out and log back in
   - Or force app restart

### Issue: "invalid JSON" errors in Edge Function logs
**Symptoms:** Edge Function logs show JSON parsing errors

**Solutions:**
1. Verify you deployed the updated Edge Function (Step 2.3)
2. Check deployment timestamp in Supabase Dashboard
3. Redeploy if needed:
   ```bash
   supabase functions deploy send-push-notification --no-verify-jwt
   ```

### Issue: Notifications not appearing on Android
**Symptoms:** No notification appears despite successful Edge Function call

**Solutions:**
1. Check notification channels are created:
   ```bash
   # Look for this in logs:
   flutter logs | grep "notification channel"
   ```
2. Verify battery optimization is disabled
3. Check notification permissions:
   - Settings > Apps > LoveBug > Notifications
   - Ensure "Call Notifications" channel is enabled
4. Test with device connected to computer to see logs

### Issue: Notification appears but wrong priority
**Symptoms:** Notification shows in notification tray but not as heads-up

**Solutions:**
1. Verify channel importance:
   - Android Settings > Apps > LoveBug > Notifications
   - "Call Notifications" should be set to "High" or "Urgent"
2. Check Edge Function is setting correct priority:
   ```typescript
   priority: 'HIGH'
   notification_priority: 'PRIORITY_MAX'
   ```
3. Rebuild app after confirming MainActivity changes

### Issue: Data not reaching Flutter app
**Symptoms:** Notification appears but data is null in app

**Solutions:**
1. Verify all data values are strings in Edge Function
2. Check logs for data structure:
   ```bash
   flutter logs | grep "Message data:"
   ```
3. Verify payload in Edge Function logs matches expected structure

---

## Verification Checklist

Use this checklist to confirm everything is working:

### Database
- [ ] `fcm_token` column exists in `profiles` table
- [ ] Test user has FCM token saved (query shows non-null value)
- [ ] Token length is ~150-200 characters
- [ ] RLS policies allow updates

### Edge Function
- [ ] Successfully deployed with recent timestamp
- [ ] Logs show no "invalid JSON" errors
- [ ] Payload structure matches FCM V1 API spec
- [ ] All data values are strings

### Android App
- [ ] App builds without errors
- [ ] Notification channels created on launch
- [ ] FCM token registered on login
- [ ] Token refresh listener active

### Notifications
- [ ] Test notification received
- [ ] Appears as heads-up (high priority)
- [ ] Shows correct title and body
- [ ] Uses correct channel
- [ ] Tapping opens app

### Real Call Flow
- [ ] Call notification received within 3 seconds
- [ ] Shows caller name and call type
- [ ] Can accept call from notification
- [ ] Works with app in background
- [ ] Works with app killed

---

## Success Metrics

After deploying the fix, you should see:

1. **Zero "invalid JSON" errors** in Edge Function logs
2. **100% FCM token registration rate** for Android users
3. **< 3 second notification delivery time** for calls
4. **High priority notifications** displayed as heads-up
5. **Correct channel usage** (call_notifications for calls)

---

## Rollback Plan

If the fix causes issues:

### 1. Rollback Edge Function
```bash
# Get previous version
supabase functions list --version

# Deploy previous version
supabase functions deploy send-push-notification --version PREVIOUS_VERSION
```

### 2. Rollback Android App
- Revert MainActivity.java changes
- Rebuild and redeploy app

### 3. Emergency Fix
If you need to quickly fix Edge Function:
1. Go to Supabase Dashboard > Edge Functions
2. Click on send-push-notification
3. Edit code directly in browser
4. Click "Deploy"

---

## Next Steps

After confirming this fix works:

1. **Monitor production logs** for 24-48 hours
2. **Collect metrics** on notification delivery rates
3. **Test on multiple Android versions** (8.0+)
4. **Proceed to Priority 2**: Fix call type mismatch (audio vs video)

---

## Support

If you encounter issues:
1. Check Edge Function logs in Supabase Dashboard
2. Check Android app logs: `flutter logs`
3. Run test queries: `test_android_push.sql`
4. Verify deployment: `ANDROID_PUSH_NOTIFICATION_FIX.md`

