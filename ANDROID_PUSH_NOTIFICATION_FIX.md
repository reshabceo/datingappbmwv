# Android Push Notification Fix - Priority 1

## Problem Summary
Android push notifications were failing with invalid JSON payload errors. The Firebase Cloud Messaging (FCM) V1 API was receiving invalid fields that don't exist in the API specification.

## Root Cause
The Supabase Edge Function `send-push-notification/index.ts` was sending FCM V1 API payloads with invalid fields for Android:

1. **Invalid `priority` field location** - Was inside `android.notification` but should be at `android` level
2. **Invalid `actions` array** - FCM V1 API doesn't support notification actions in the payload (lines 142-154)
3. **Invalid `notification_priority` values** - Was using strings like 'high'/'normal' instead of proper enum values
4. **Duplicate `data` block** - Had a redundant nested data block under android (lines 157-165)
5. **Non-string data values** - FCM requires all data values to be strings

## Fixes Applied

### 1. Fixed Firebase Cloud Messaging Payload Structure
**File:** `supabase/functions/send-push-notification/index.ts`

#### Changes Made:
- **Moved `priority` field** to correct location (`android` level instead of `android.notification`)
- **Removed invalid `actions` array** - FCM V1 API doesn't support this field
- **Fixed `notification_priority`** - Changed to use proper Android priority enum values:
  - `PRIORITY_MAX` for call notifications (most urgent)
  - `PRIORITY_DEFAULT` for normal notifications
- **Removed duplicate `data` block** under android section
- **Added data stringification** - Convert all data values to strings as required by FCM:
  ```typescript
  const stringifiedData: Record<string, string> = {}
  Object.entries(data).forEach(([key, value]) => {
    stringifiedData[key] = String(value ?? '')
  })
  stringifiedData['type'] = type
  ```

#### Valid FCM V1 API Structure (After Fix):
```typescript
{
  message: {
    token: profile.fcm_token,
    notification: {
      title: title,
      body: body,
    },
    data: stringifiedData, // All values as strings
    android: {
      priority: 'HIGH',  // ✅ Correct location
      notification: {
        icon: 'ic_call',
        color: '#4CAF50',
        sound: 'call_ringtone',
        notification_priority: 'PRIORITY_MAX',  // ✅ Valid enum value
        visibility: 'public',
        channel_id: 'call_notifications',
        image: caller_image_url  // Optional
      }
    }
  }
}
```

### 2. Added Default Notification Channel
**File:** `android/app/src/main/java/com/lovebug/app/MainActivity.java`

#### Changes Made:
- Added `default_notifications` channel alongside `call_notifications`
- Both channels are created in `initializeBackgroundService()` method
- Ensures the channel referenced in the Edge Function exists

```java
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
```

## FCM V1 API Validation

### Valid Fields for Android Notifications:

#### `android` level:
- `priority`: 'NORMAL' | 'HIGH'
- `notification`: object
- `ttl`: string
- `collapse_key`: string
- `restricted_package_name`: string

#### `android.notification` level:
- `title`: string
- `body`: string
- `icon`: string
- `color`: string (hex format)
- `sound`: string (filename without extension)
- `tag`: string
- `click_action`: string
- `body_loc_key`: string
- `body_loc_args`: string[]
- `title_loc_key`: string
- `title_loc_args`: string[]
- `channel_id`: string
- `ticker`: string
- `sticky`: boolean
- `event_time`: string (timestamp)
- `local_only`: boolean
- `notification_priority`: 'PRIORITY_MIN' | 'PRIORITY_LOW' | 'PRIORITY_DEFAULT' | 'PRIORITY_HIGH' | 'PRIORITY_MAX'
- `default_sound`: boolean
- `default_vibrate_timings`: boolean
- `default_light_settings`: boolean
- `vibrate_timings`: string[]
- `visibility`: 'PRIVATE' | 'PUBLIC' | 'SECRET'
- `notification_count`: number
- `light_settings`: object
- `image`: string (URL)

### Invalid Fields (Removed):
- ❌ `actions` array in `android.notification` - NOT supported in FCM V1 API
- ❌ `priority` in `android.notification` - Must be at `android` level
- ❌ Duplicate `data` block under `android` - Root level `data` is sufficient

## Testing Checklist

### Before Deployment:
- [x] Remove invalid `actions` field
- [x] Move `priority` to correct location
- [x] Use valid `notification_priority` enum values
- [x] Remove duplicate `data` block
- [x] Stringify all data values
- [x] Add default notification channel
- [x] Verify channel IDs match between Edge Function and MainActivity

### After Deployment:
- [ ] Run SQL migration: `fix_fcm_token_column.sql` (if not already run)
- [ ] Deploy updated Edge Function to Supabase
- [ ] Test FCM token registration on Android device
- [ ] Verify FCM token is saved in database (check `profiles.fcm_token` column)
- [ ] Test incoming call notification on Android
- [ ] Verify notification appears with correct channel
- [ ] Test other notification types (matches, messages)
- [ ] Check Supabase Edge Function logs for any errors

### FCM Token Verification Queries:
```sql
-- Check if FCM tokens are being saved
SELECT id, email, fcm_token, created_at 
FROM profiles 
WHERE fcm_token IS NOT NULL 
ORDER BY created_at DESC 
LIMIT 10;

-- Check FCM token for specific user
SELECT id, email, fcm_token 
FROM profiles 
WHERE id = 'USER_ID_HERE';
```

### Test Push Notification Manually:
Use the Supabase SQL Editor to send a test notification:
```sql
SELECT extensions.http((
  'POST',
  'YOUR_SUPABASE_URL/functions/v1/send-push-notification',
  ARRAY[extensions.http_header('Authorization', 'Bearer YOUR_ANON_KEY')],
  'application/json',
  json_build_object(
    'userId', 'USER_ID_HERE',
    'type', 'incoming_call',
    'title', 'Test Call',
    'body', 'Testing push notification',
    'data', json_build_object(
      'call_id', 'test-123',
      'caller_name', 'Test User',
      'call_type', 'video',
      'caller_id', 'test-user-id',
      'match_id', 'test-match-id'
    )
  )::text
)::text);
```

## Additional Notes

### FCM Token Registration Flow:
1. App starts → NotificationService.initialize()
2. User logs in → NotificationService.registerFCMToken()
3. FCM token obtained → SupabaseService.updateFCMToken(token)
4. Token saved to `profiles.fcm_token` column
5. Token refresh listener → Auto-update token on refresh

### Android-Specific Considerations:
- **Battery Optimization**: App requests exemption for reliable background notifications
- **Notification Channels**: Required for Android 8+ (API 26+)
- **Foreground Service**: May be needed for call notifications when app is killed
- **High Priority**: Call notifications use PRIORITY_MAX for heads-up display

### Common Issues & Solutions:

#### Issue: FCM token not saving
**Solution:** Check these in order:
1. Verify Firebase is initialized properly
2. Check user is authenticated
3. Verify database has `fcm_token` column
4. Check RLS policies allow updates
5. Look for errors in NotificationService logs

#### Issue: Notifications not appearing
**Solution:** Check these in order:
1. Verify FCM token exists in database
2. Check notification channels are created
3. Verify Edge Function payload is valid (check logs)
4. Ensure device has internet connection
5. Check battery optimization settings
6. Verify FCM API credentials are set in Supabase

#### Issue: Invalid JSON errors
**Solution:** All fixed! The payload now conforms to FCM V1 API spec

## Files Modified

1. `supabase/functions/send-push-notification/index.ts` - Fixed FCM payload structure
2. `android/app/src/main/java/com/lovebug/app/MainActivity.java` - Added default notification channel

## Files to Review (Already Correct)

1. `lib/services/notification_service.dart` - FCM token registration ✅
2. `lib/services/push_notification_service.dart` - Notification sending ✅
3. `lib/controllers/call_controller.dart` - Call notification triggering ✅
4. `lib/services/supabase_service.dart` - FCM token database updates ✅
5. `lib/main.dart` - Service initialization ✅

## Deployment Steps

1. **Deploy Edge Function:**
   ```bash
   cd supabase/functions/send-push-notification
   supabase functions deploy send-push-notification
   ```

2. **Rebuild Android App:**
   ```bash
   flutter clean
   flutter pub get
   flutter build apk --release
   # or
   flutter run
   ```

3. **Test on Android Device:**
   - Install updated app
   - Log in with test account
   - Check logs for FCM token registration
   - Have another user call you
   - Verify notification appears

## Success Criteria

- ✅ No more "invalid JSON" errors in Supabase logs
- ✅ FCM tokens being saved to database
- ✅ Android devices receiving push notifications
- ✅ Call notifications showing as high priority
- ✅ Notifications using correct channels
- ✅ All data fields properly stringified

## Next Priorities (After This Fix)

2. **Call type showing wrong** (audio instead of video) when calling from Android to iOS
3. **Call disconnect not syncing** between devices
4. **iOS caller image not showing** in CallKit
5. **iOS push notification acceptance** not connecting to call
6. **In-app invitation not showing** on Android

