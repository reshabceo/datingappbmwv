-- Quick FCM Token Check
-- Simple queries to quickly check FCM token status

-- 1. Quick count of FCM token status
SELECT 
    COUNT(*) as total_profiles,
    COUNT(CASE WHEN fcm_token IS NOT NULL AND fcm_token != '' THEN 1 END) as with_tokens,
    COUNT(CASE WHEN fcm_token IS NULL OR fcm_token = '' THEN 1 END) as without_tokens
FROM profiles;

-- 2. Check if fcm_token column exists
SELECT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'profiles' AND column_name = 'fcm_token'
) as fcm_column_exists;

-- 3. Sample of profiles with FCM tokens
SELECT 
    id,
    name,
    LEFT(fcm_token, 20) || '...' as token_preview,
    LENGTH(fcm_token) as token_length,
    updated_at
FROM profiles 
WHERE fcm_token IS NOT NULL AND fcm_token != ''
ORDER BY updated_at DESC
LIMIT 5;

-- 4. Sample of profiles without FCM tokens
SELECT 
    id,
    name,
    email,
    created_at
FROM profiles 
WHERE fcm_token IS NULL OR fcm_token = ''
ORDER BY created_at DESC
LIMIT 5;
