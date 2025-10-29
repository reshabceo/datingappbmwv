-- Check FCM Token Status in Profiles Table
-- This query helps diagnose push notification issues

-- 1. Check if fcm_token column exists
SELECT 
    column_name, 
    data_type, 
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'profiles' 
AND column_name = 'fcm_token';

-- 2. Count profiles with and without FCM tokens
SELECT 
    'Total Profiles' as category,
    COUNT(*) as count
FROM profiles
UNION ALL
SELECT 
    'Profiles with FCM Token' as category,
    COUNT(*) as count
FROM profiles 
WHERE fcm_token IS NOT NULL AND fcm_token != ''
UNION ALL
SELECT 
    'Profiles without FCM Token' as category,
    COUNT(*) as count
FROM profiles 
WHERE fcm_token IS NULL OR fcm_token = '';

-- 3. Detailed FCM token analysis
SELECT 
    id,
    name,
    email,
    CASE 
        WHEN fcm_token IS NULL THEN 'No Token'
        WHEN fcm_token = '' THEN 'Empty Token'
        WHEN LENGTH(fcm_token) < 50 THEN 'Invalid Token (too short)'
        WHEN fcm_token LIKE 'fcm_%' THEN 'Valid FCM Token'
        ELSE 'Unknown Format'
    END as token_status,
    LENGTH(fcm_token) as token_length,
    created_at,
    updated_at
FROM profiles 
ORDER BY 
    CASE 
        WHEN fcm_token IS NULL THEN 1
        WHEN fcm_token = '' THEN 2
        ELSE 3
    END,
    created_at DESC;

-- 4. Check notification preferences (only existing columns)
SELECT 
    'Notification Preferences' as info,
    COUNT(*) as total_profiles,
    COUNT(CASE WHEN notification_matches = true THEN 1 END) as matches_enabled,
    COUNT(CASE WHEN notification_messages = true THEN 1 END) as messages_enabled,
    COUNT(CASE WHEN notification_likes = true THEN 1 END) as likes_enabled,
    COUNT(CASE WHEN notification_stories = true THEN 1 END) as stories_enabled,
    COUNT(CASE WHEN notification_admin = true THEN 1 END) as admin_enabled
FROM profiles;

-- 5. Recent FCM token updates (last 24 hours)
SELECT 
    id,
    name,
    fcm_token,
    updated_at,
    CASE 
        WHEN fcm_token IS NOT NULL AND fcm_token != '' THEN 'Has Token'
        ELSE 'No Token'
    END as status
FROM profiles 
WHERE updated_at > NOW() - INTERVAL '24 hours'
ORDER BY updated_at DESC;

-- 6. Check for duplicate FCM tokens (security issue)
SELECT 
    fcm_token,
    COUNT(*) as usage_count,
    STRING_AGG(id::text, ', ') as user_ids
FROM profiles 
WHERE fcm_token IS NOT NULL AND fcm_token != ''
GROUP BY fcm_token 
HAVING COUNT(*) > 1
ORDER BY usage_count DESC;

-- 7. FCM token format validation
SELECT 
    'Token Format Analysis' as analysis,
    COUNT(CASE WHEN fcm_token LIKE 'fcm_%' THEN 1 END) as fcm_format,
    COUNT(CASE WHEN fcm_token LIKE 'APA%' THEN 1 END) as legacy_format,
    COUNT(CASE WHEN fcm_token ~ '^[A-Za-z0-9_-]+$' AND fcm_token NOT LIKE 'fcm_%' AND fcm_token NOT LIKE 'APA%' THEN 1 END) as other_format,
    COUNT(CASE WHEN fcm_token !~ '^[A-Za-z0-9_-]+$' AND fcm_token IS NOT NULL AND fcm_token != '' THEN 1 END) as invalid_format
FROM profiles 
WHERE fcm_token IS NOT NULL AND fcm_token != '';

-- 8. Summary for debugging push notifications
SELECT 
    'PUSH NOTIFICATION DIAGNOSTICS' as section,
    '' as details
UNION ALL
SELECT 
    'FCM Token Column Exists',
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_name = 'profiles' AND column_name = 'fcm_token'
        ) THEN 'YES' 
        ELSE 'NO - Run fix_fcm_token_column.sql'
    END
UNION ALL
SELECT 
    'Total Profiles',
    COUNT(*)::text
FROM profiles
UNION ALL
SELECT 
    'Profiles with FCM Tokens',
    COUNT(*)::text
FROM profiles 
WHERE fcm_token IS NOT NULL AND fcm_token != ''
UNION ALL
SELECT 
    'Profiles Ready for Push Notifications',
    COUNT(*)::text
FROM profiles 
WHERE fcm_token IS NOT NULL 
    AND fcm_token != '' 
    AND LENGTH(fcm_token) > 50
    AND (notification_matches = true OR notification_messages = true OR notification_likes = true);
