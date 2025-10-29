-- Debug FCM Token Registration
-- Check which user has FCM token and help diagnose registration issues

-- 1. Check which user has the FCM token
SELECT 
    id,
    name,
    email,
    LEFT(fcm_token, 20) || '...' as token_preview,
    LENGTH(fcm_token) as token_length,
    created_at,
    updated_at,
    CASE 
        WHEN updated_at > created_at THEN 'Token Updated'
        ELSE 'Token Never Updated'
    END as token_status
FROM profiles 
WHERE fcm_token IS NOT NULL AND fcm_token != ''
ORDER BY updated_at DESC;

-- 2. Check recent profile updates (last 7 days)
SELECT 
    id,
    name,
    email,
    CASE 
        WHEN fcm_token IS NOT NULL AND fcm_token != '' THEN 'Has Token'
        ELSE 'No Token'
    END as fcm_status,
    updated_at,
    EXTRACT(EPOCH FROM (NOW() - updated_at))/3600 as hours_ago
FROM profiles 
WHERE updated_at > NOW() - INTERVAL '7 days'
ORDER BY updated_at DESC;

-- 3. Check if there are any recent FCM token updates
SELECT 
    'Recent FCM Updates' as info,
    COUNT(*) as count
FROM profiles 
WHERE fcm_token IS NOT NULL 
    AND fcm_token != '' 
    AND updated_at > NOW() - INTERVAL '24 hours';

-- 4. Check notification preferences for users with tokens
SELECT 
    id,
    name,
    notification_matches,
    notification_messages,
    notification_likes,
    notification_stories,
    notification_admin,
    CASE 
        WHEN fcm_token IS NOT NULL AND fcm_token != '' THEN 'Has Token'
        ELSE 'No Token'
    END as fcm_status
FROM profiles 
ORDER BY 
    CASE 
        WHEN fcm_token IS NOT NULL AND fcm_token != '' THEN 0
        ELSE 1
    END,
    updated_at DESC;
