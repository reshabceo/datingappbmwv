-- Quick check for FCM tokens
SELECT 
    name,
    fcm_token IS NOT NULL as has_token,
    CASE 
        WHEN fcm_token IS NOT NULL THEN SUBSTRING(fcm_token, 1, 30) || '...'
        ELSE 'NO TOKEN'
    END as token_preview,
    LENGTH(fcm_token) as token_length,
    updated_at
FROM profiles 
WHERE name IN ('ashley', 'RESHAB')
ORDER BY name;

