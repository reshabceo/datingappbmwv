-- IMMEDIATE FIX: Test the BFF swipe function directly
-- This will help us verify if the function works

-- Test the handle_bff_swipe function directly
DO $$
DECLARE
    result JSONB;
    test_user_id UUID := '7ffe44fe-9c0f-4783-aec2-a6172a6e008b';
    test_target_id UUID := 'c1ffb3e0-0e25-4176-9736-0db8522fd357'; -- SS
BEGIN
    -- Test BFF swipe directly
    result := handle_bff_swipe(test_target_id, 'like');
    
    RAISE NOTICE 'BFF swipe test result: %', result;
    
    IF result->>'matched' = 'true' THEN
        RAISE NOTICE '✅ SUCCESS: BFF match created!';
        RAISE NOTICE 'Match ID: %', result->>'match_id';
    ELSE
        RAISE NOTICE '❌ No match created. Result: %', result;
    END IF;
END $$;

-- Check if a match was created
SELECT 
    'BFF Matches after test' as status,
    COUNT(*) as count
FROM bff_matches 
WHERE (user_id_1 = '7ffe44fe-9c0f-4783-aec2-a6172a6e008b' 
    OR user_id_2 = '7ffe44fe-9c0f-4783-aec2-a6172a6e008b')
    AND status IN ('matched', 'active');

-- Show the match if it exists
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
