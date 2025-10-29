-- Test FCM Token Registration Fix
-- Run this after testing the app to verify FCM tokens are being registered

-- 1. Check current FCM token status
SELECT 
    'BEFORE FIX' as status,
    COUNT(*) as total_profiles,
    COUNT(CASE WHEN fcm_token IS NOT NULL AND fcm_token != '' THEN 1 END) as with_tokens,
    COUNT(CASE WHEN fcm_token IS NULL OR fcm_token = '' THEN 1 END) as without_tokens
FROM profiles;

-- 2. Check specific users (Ashley and Reshab)
SELECT 
    id,
    name,
    CASE 
        WHEN fcm_token IS NOT NULL AND fcm_token != '' THEN 'HAS TOKEN'
        ELSE 'NO TOKEN'
    END as token_status,
    LENGTH(fcm_token) as token_length,
    updated_at
FROM profiles 
WHERE name IN ('ashley', 'RESHAB', 'Reshab Retheesh')
ORDER BY name;

-- 3. Check recent FCM token updates (last hour)
SELECT 
    'Recent Updates' as info,
    COUNT(*) as count
FROM profiles 
WHERE fcm_token IS NOT NULL 
    AND fcm_token != '' 
    AND updated_at > NOW() - INTERVAL '1 hour';

-- 4. Show all users with FCM tokens
SELECT 
    name,
    LEFT(fcm_token, 20) || '...' as token_preview,
    LENGTH(fcm_token) as token_length,
    updated_at
FROM profiles 
WHERE fcm_token IS NOT NULL AND fcm_token != ''
ORDER BY updated_at DESC;
