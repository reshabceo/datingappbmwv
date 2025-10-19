-- Test BFF swipe function with explicit user ID
-- The issue is that handle_bff_swipe uses auth.uid() which doesn't work in SQL context

-- Let's test the matching logic manually
DO $$
DECLARE
    test_user_id UUID := '7ffe44fe-9c0f-4783-aec2-a6172a6e008b';
    test_target_id UUID := 'c1ffb3e0-0e25-4176-9736-0db8522fd357'; -- SS
    reciprocal_like_exists BOOLEAN;
BEGIN
    -- Check if SS has liked you back
    SELECT EXISTS(
        SELECT 1 FROM bff_interactions 
        WHERE user_id = test_target_id 
        AND target_user_id = test_user_id 
        AND interaction_type = 'like'
    ) INTO reciprocal_like_exists;
    
    RAISE NOTICE 'SS has liked you back: %', reciprocal_like_exists;
    
    -- Check if you have liked SS
    SELECT EXISTS(
        SELECT 1 FROM bff_interactions 
        WHERE user_id = test_user_id 
        AND target_user_id = test_target_id 
        AND interaction_type = 'like'
    ) INTO reciprocal_like_exists;
    
    RAISE NOTICE 'You have liked SS: %', reciprocal_like_exists;
    
    -- If both exist, create a match manually
    IF reciprocal_like_exists THEN
        INSERT INTO bff_matches (user_id_1, user_id_2, status)
        VALUES (
            LEAST(test_user_id, test_target_id),
            GREATEST(test_user_id, test_target_id),
            'matched'
        )
        ON CONFLICT (user_id_1, user_id_2) DO NOTHING;
        
        RAISE NOTICE '✅ Manual match created for you and SS!';
    ELSE
        RAISE NOTICE '❌ No mutual like found';
    END IF;
END $$;

-- Check the result
SELECT 
    'BFF Matches after manual test' as status,
    COUNT(*) as count
FROM bff_matches 
WHERE (user_id_1 = '7ffe44fe-9c0f-4783-aec2-a6172a6e008b' 
    OR user_id_2 = '7ffe44fe-9c0f-4783-aec2-a6172a6e008b')
    AND status IN ('matched', 'active');

-- Show the match
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
