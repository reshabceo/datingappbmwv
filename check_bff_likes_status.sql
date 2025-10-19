-- Check BFF Likes Status
-- This will show you who has liked you back in BFF mode

-- Replace this with your actual user ID
-- Your user ID: 7ffe44fe-9c0f-4783-aec2-a6172a6e008b

-- 1. Check who has liked you back in BFF mode
SELECT 
    'Profiles that liked you back in BFF' as status,
    COUNT(*) as count
FROM bff_interactions 
WHERE target_user_id = '7ffe44fe-9c0f-4783-aec2-a6172a6e008b'
    AND interaction_type = 'like';

-- 2. Show which specific profiles have liked you back
SELECT 
    p.name,
    p.age,
    bi.interaction_type,
    bi.created_at as liked_at
FROM bff_interactions bi
JOIN profiles p ON p.id = bi.user_id
WHERE bi.target_user_id = '7ffe44fe-9c0f-4783-aec2-a6172a6e008b'
    AND bi.interaction_type = 'like'
ORDER BY bi.created_at DESC;

-- 3. Check your BFF interactions (who you've swiped on)
SELECT 
    'Your BFF swipes' as status,
    COUNT(*) as count
FROM bff_interactions 
WHERE user_id = '7ffe44fe-9c0f-4783-aec2-a6172a6e008b';

-- 4. Show who you've swiped on
SELECT 
    p.name as target_name,
    p.age,
    bi.interaction_type,
    bi.created_at as swiped_at
FROM bff_interactions bi
JOIN profiles p ON p.id = bi.target_user_id
WHERE bi.user_id = '7ffe44fe-9c0f-4783-aec2-a6172a6e008b'
ORDER BY bi.created_at DESC;

-- 5. Check for mutual likes (potential matches)
SELECT 
    'Potential BFF matches (mutual likes)' as status,
    COUNT(*) as count
FROM bff_interactions bi1
JOIN bff_interactions bi2 ON bi1.user_id = bi2.target_user_id 
    AND bi1.target_user_id = bi2.user_id
WHERE bi1.user_id = '7ffe44fe-9c0f-4783-aec2-a6172a6e008b'
    AND bi1.interaction_type = 'like'
    AND bi2.interaction_type = 'like';

-- 6. Show mutual likes details
SELECT 
    p.name,
    p.age,
    bi1.created_at as you_liked_them_at,
    bi2.created_at as they_liked_you_at
FROM bff_interactions bi1
JOIN bff_interactions bi2 ON bi1.user_id = bi2.target_user_id 
    AND bi1.target_user_id = bi2.user_id
JOIN profiles p ON p.id = bi1.target_user_id
WHERE bi1.user_id = '7ffe44fe-9c0f-4783-aec2-a6172a6e008b'
    AND bi1.interaction_type = 'like'
    AND bi2.interaction_type = 'like'
ORDER BY bi2.created_at DESC;

-- 7. Check existing BFF matches
SELECT 
    'Existing BFF matches' as status,
    COUNT(*) as count
FROM bff_matches 
WHERE (user_id_1 = '7ffe44fe-9c0f-4783-aec2-a6172a6e008b' 
    OR user_id_2 = '7ffe44fe-9c0f-4783-aec2-a6172a6e008b')
    AND status IN ('matched', 'active');

-- 8. Show existing BFF matches
SELECT 
    bm.id as match_id,
    bm.status,
    bm.created_at as matched_at,
    CASE 
        WHEN bm.user_id_1 = '7ffe44fe-9c0f-4783-aec2-a6172a6e008b' 
        THEN p2.name
        ELSE p1.name
    END as match_name,
    CASE 
        WHEN bm.user_id_1 = '7ffe44fe-9c0f-4783-aec2-a6172a6e008b' 
        THEN p2.age
        ELSE p1.age
    END as match_age
FROM bff_matches bm
LEFT JOIN profiles p1 ON p1.id = bm.user_id_1
LEFT JOIN profiles p2 ON p2.id = bm.user_id_2
WHERE (bm.user_id_1 = '7ffe44fe-9c0f-4783-aec2-a6172a6e008b' 
    OR bm.user_id_2 = '7ffe44fe-9c0f-4783-aec2-a6172a6e008b')
    AND bm.status IN ('matched', 'active')
ORDER BY bm.created_at DESC;

-- 9. Summary status
DO $$
DECLARE
    liked_you_count INTEGER;
    your_swipes_count INTEGER;
    mutual_likes_count INTEGER;
    existing_matches_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO liked_you_count FROM bff_interactions 
    WHERE target_user_id = '7ffe44fe-9c0f-4783-aec2-a6172a6e008b'
        AND interaction_type = 'like';
    
    SELECT COUNT(*) INTO your_swipes_count FROM bff_interactions 
    WHERE user_id = '7ffe44fe-9c0f-4783-aec2-a6172a6e008b';
    
    SELECT COUNT(*) INTO mutual_likes_count FROM bff_interactions bi1
    JOIN bff_interactions bi2 ON bi1.user_id = bi2.target_user_id 
        AND bi1.target_user_id = bi2.user_id
    WHERE bi1.user_id = '7ffe44fe-9c0f-4783-aec2-a6172a6e008b'
        AND bi1.interaction_type = 'like'
        AND bi2.interaction_type = 'like';
    
    SELECT COUNT(*) INTO existing_matches_count FROM bff_matches 
    WHERE (user_id_1 = '7ffe44fe-9c0f-4783-aec2-a6172a6e008b' 
        OR user_id_2 = '7ffe44fe-9c0f-4783-aec2-a6172a6e008b')
        AND status IN ('matched', 'active');
    
    RAISE NOTICE '=== BFF LIKES STATUS SUMMARY ===';
    RAISE NOTICE 'Profiles that liked you back: %', liked_you_count;
    RAISE NOTICE 'Your BFF swipes: %', your_swipes_count;
    RAISE NOTICE 'Mutual likes (potential matches): %', mutual_likes_count;
    RAISE NOTICE 'Existing BFF matches: %', existing_matches_count;
    
    IF mutual_likes_count > 0 AND existing_matches_count = 0 THEN
        RAISE NOTICE '⚠️  You have mutual likes but no matches created yet!';
        RAISE NOTICE 'Try swiping right on those profiles to trigger match creation.';
    ELSIF mutual_likes_count > 0 AND existing_matches_count > 0 THEN
        RAISE NOTICE '✅ BFF matching is working! You have matches.';
    ELSE
        RAISE NOTICE 'ℹ️  No mutual likes yet. Keep swiping!';
    END IF;
END $$;
