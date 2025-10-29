-- Test script for Android Push Notification Fix
-- Run this in Supabase SQL Editor to verify the fix

-- ==========================================
-- STEP 1: Verify FCM Token Column Exists
-- ==========================================
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'profiles' 
  AND column_name = 'fcm_token';

-- Expected: Should return one row showing fcm_token column exists
-- If empty, run fix_fcm_token_column.sql first


-- ==========================================
-- STEP 2: Check FCM Tokens Are Being Saved
-- ==========================================
SELECT 
  id,
  email,
  fcm_token,
  LEFT(fcm_token, 30) as token_preview,
  LENGTH(fcm_token) as token_length,
  created_at,
  updated_at
FROM profiles 
WHERE fcm_token IS NOT NULL 
ORDER BY updated_at DESC 
LIMIT 10;

-- Expected: Should show users with FCM tokens
-- Token length should be ~150-200 characters
-- If empty, no tokens have been registered yet


-- ==========================================
-- STEP 3: Check Notification Preferences
-- ==========================================
SELECT 
  id,
  email,
  notification_matches,
  notification_messages,
  notification_stories,
  notification_likes,
  notification_admin,
  notification_calls
FROM profiles 
WHERE fcm_token IS NOT NULL 
LIMIT 5;

-- Expected: All notification preferences should be TRUE by default
-- If columns don't exist, run fix_fcm_token_column.sql


-- ==========================================
-- STEP 4: Send Test Push Notification
-- ==========================================
-- Replace USER_ID_HERE with actual user ID from Step 2
-- Replace YOUR_SUPABASE_URL with your Supabase project URL
-- Replace YOUR_ANON_KEY with your anon key

/*
SELECT extensions.http((
  'POST',
  'YOUR_SUPABASE_URL/functions/v1/send-push-notification',
  ARRAY[
    extensions.http_header('Authorization', 'Bearer YOUR_ANON_KEY'),
    extensions.http_header('Content-Type', 'application/json')
  ],
  'application/json',
  json_build_object(
    'userId', 'USER_ID_HERE',
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
*/

-- Expected: Should return success response
-- Check Android device for notification
-- Check Edge Function logs in Supabase Dashboard


-- ==========================================
-- STEP 5: Check Edge Function Logs
-- ==========================================
-- Go to Supabase Dashboard > Edge Functions > send-push-notification > Logs
-- Look for:
--   ✅ "FCM message structure" log with proper payload
--   ✅ "Notification sent successfully" message
--   ❌ No "invalid JSON" errors


-- ==========================================
-- STEP 6: Verify Android Device
-- ==========================================
-- On Android device:
-- 1. Open app and check logs for:
--    - "🔔 FCM: FCM Token obtained: YES"
--    - "✅ FCM: FCM Token stored in database successfully"
-- 2. Have another user call you
-- 3. Verify notification appears as high priority (heads-up)
-- 4. Check notification uses correct channel


-- ==========================================
-- TROUBLESHOOTING QUERIES
-- ==========================================

-- Find users without FCM tokens (need to log in again)
SELECT 
  id,
  email,
  created_at,
  fcm_token IS NULL as missing_token
FROM profiles 
WHERE fcm_token IS NULL
ORDER BY created_at DESC
LIMIT 10;

-- Check specific user's FCM token
-- SELECT id, email, fcm_token 
-- FROM profiles 
-- WHERE email = 'USER_EMAIL_HERE';

-- Clear FCM token for testing (forces re-registration)
-- UPDATE profiles 
-- SET fcm_token = NULL 
-- WHERE email = 'USER_EMAIL_HERE';

-- Check RLS policies on profiles table
SELECT 
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual,
  with_check
FROM pg_policies
WHERE tablename = 'profiles'
  AND (
    policyname LIKE '%update%' 
    OR policyname LIKE '%fcm%'
  );

-- Expected: Should have policy allowing users to update their own profile

