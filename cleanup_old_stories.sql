-- Clean up old expired stories
-- Run this in Supabase SQL Editor

-- Delete stories that have expired (expires_at < now())
DELETE FROM stories 
WHERE expires_at < NOW();

-- Show remaining stories
SELECT 
    id,
    user_id,
    created_at,
    expires_at,
    CASE 
        WHEN expires_at > NOW() THEN 'Active'
        ELSE 'Expired'
    END as status
FROM stories 
ORDER BY created_at DESC;

-- Show count by user
SELECT 
    user_id,
    COUNT(*) as story_count
FROM stories 
WHERE expires_at > NOW()
GROUP BY user_id
ORDER BY story_count DESC;
