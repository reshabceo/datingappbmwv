-- Check BFF Interactions Status
-- This script will show us exactly what BFF interactions exist and why profiles are being filtered

-- 1. Check all BFF interactions for your user
SELECT 
    'Your BFF Interactions' as status,
    COUNT(*) as total_interactions
FROM bff_interactions 
WHERE user_id = '7ffe44fe-9c0f-4783-aec2-a6172a6e008b';

-- 2. Show all your BFF interactions with details
SELECT 
    bi.user_id,
    bi.target_user_id,
    p.name as target_name,
    bi.interaction_type,
    bi.created_at
FROM bff_interactions bi
JOIN profiles p ON p.id = bi.target_user_id
WHERE bi.user_id = '7ffe44fe-9c0f-4783-aec2-a6172a6e008b'
ORDER BY bi.created_at DESC;

-- 3. Check interactions where others have liked you back
SELECT 
    'Profiles that liked you back' as status,
    COUNT(*) as mutual_likes
FROM bff_interactions 
WHERE target_user_id = '7ffe44fe-9c0f-4783-aec2-a6172a6e008b'
    AND interaction_type = 'like';

-- 4. Show which profiles have liked you back
SELECT 
    p.name as profile_name,
    p.age,
    bi.interaction_type,
    bi.created_at
FROM bff_interactions bi
JOIN profiles p ON p.id = bi.user_id
WHERE bi.target_user_id = '7ffe44fe-9c0f-4783-aec2-a6172a6e008b'
    AND bi.interaction_type = 'like'
ORDER BY bi.created_at DESC;

-- 5. Check BFF matches table
SELECT 
    'BFF Matches' as status,
    COUNT(*) as total_matches
FROM bff_matches 
WHERE (user_id_1 = '7ffe44fe-9c0f-4783-aec2-a6172a6e008b' OR user_id_2 = '7ffe44fe-9c0f-4783-aec2-a6172a6e008b');

-- 6. Show your BFF matches
SELECT 
    bm.user_id_1,
    bm.user_id_2,
    p1.name as user_1_name,
    p2.name as user_2_name,
    bm.status,
    bm.created_at
FROM bff_matches bm
LEFT JOIN profiles p1 ON p1.id = bm.user_id_1
LEFT JOIN profiles p2 ON p2.id = bm.user_id_2
WHERE (bm.user_id_1 = '7ffe44fe-9c0f-4783-aec2-a6172a6e008b' OR bm.user_id_2 = '7ffe44fe-9c0f-4783-aec2-a6172a6e008b')
ORDER BY bm.created_at DESC;

-- 7. Check what profiles are available for BFF swiping
SELECT 
    'Available BFF Profiles' as status,
    COUNT(*) as available_count
FROM profiles 
WHERE bff_enabled = true
    AND id != '7ffe44fe-9c0f-4783-aec2-a6172a6e008b'
    AND id NOT IN (
        SELECT target_user_id 
        FROM bff_interactions 
        WHERE user_id = '7ffe44fe-9c0f-4783-aec2-a6172a6e008b'
    )
    AND id NOT IN (
        SELECT CASE 
            WHEN user_id_1 = '7ffe44fe-9c0f-4783-aec2-a6172a6e008b' THEN user_id_2 
            ELSE user_id_1 
        END
        FROM bff_matches 
        WHERE (user_id_1 = '7ffe44fe-9c0f-4783-aec2-a6172a6e008b' OR user_id_2 = '7ffe44fe-9c0f-4783-aec2-a6172a6e008b')
            AND status IN ('matched', 'active')
    );

-- 8. Show available profiles for swiping
SELECT 
    p.id,
    p.name,
    p.age,
    p.bff_enabled,
    p.bff_last_active
FROM profiles p
WHERE p.bff_enabled = true
    AND p.id != '7ffe44fe-9c0f-4783-aec2-a6172a6e008b'
    AND p.id NOT IN (
        SELECT target_user_id 
        FROM bff_interactions 
        WHERE user_id = '7ffe44fe-9c0f-4783-aec2-a6172a6e008b'
    )
    AND p.id NOT IN (
        SELECT CASE 
            WHEN user_id_1 = '7ffe44fe-9c0f-4783-aec2-a6172a6e008b' THEN user_id_2 
            ELSE user_id_1 
        END
        FROM bff_matches 
        WHERE (user_id_1 = '7ffe44fe-9c0f-4783-aec2-a6172a6e008b' OR user_id_2 = '7ffe44fe-9c0f-4783-aec2-a6172a6e008b')
            AND status IN ('matched', 'active')
    )
ORDER BY p.created_at DESC;

-- 9. Test the get_bff_profiles function directly
SELECT 
    'get_bff_profiles function result' as status,
    COUNT(*) as function_result_count
FROM (
    SELECT * FROM get_bff_profiles('7ffe44fe-9c0f-4783-aec2-a6172a6e008b')
) as bff_profiles;

-- 10. Show the actual profiles returned by the function
SELECT 
    id,
    name,
    age,
    bff_enabled
FROM get_bff_profiles('7ffe44fe-9c0f-4783-aec2-a6172a6e008b')
ORDER BY created_at DESC;

-- 11. Final summary
DO $$
DECLARE
    your_interactions INTEGER;
    mutual_likes INTEGER;
    available_profiles INTEGER;
    function_result INTEGER;
BEGIN
    SELECT COUNT(*) INTO your_interactions FROM bff_interactions 
    WHERE user_id = '7ffe44fe-9c0f-4783-aec2-a6172a6e008b';
    
    SELECT COUNT(*) INTO mutual_likes FROM bff_interactions 
    WHERE target_user_id = '7ffe44fe-9c0f-4783-aec2-a6172a6e008b'
        AND interaction_type = 'like';
    
    SELECT COUNT(*) INTO available_profiles FROM profiles 
    WHERE bff_enabled = true
        AND id != '7ffe44fe-9c0f-4783-aec2-a6172a6e008b'
        AND id NOT IN (
            SELECT target_user_id 
            FROM bff_interactions 
            WHERE user_id = '7ffe44fe-9c0f-4783-aec2-a6172a6e008b'
        );
    
    SELECT COUNT(*) INTO function_result FROM (
        SELECT * FROM get_bff_profiles('7ffe44fe-9c0f-4783-aec2-a6172a6e008b')
    ) as bff_profiles;
    
    RAISE NOTICE '=== BFF Interactions Status Summary ===';
    RAISE NOTICE 'Your BFF interactions: %', your_interactions;
    RAISE NOTICE 'Profiles that liked you back: %', mutual_likes;
    RAISE NOTICE 'Available profiles for swiping: %', available_profiles;
    RAISE NOTICE 'get_bff_profiles function result: %', function_result;
    
    IF your_interactions > 0 THEN
        RAISE NOTICE 'You have swiped on % profiles - this is why they are filtered out', your_interactions;
    END IF;
    
    IF function_result = 0 AND available_profiles > 0 THEN
        RAISE NOTICE 'WARNING: Function returns 0 but % profiles should be available', available_profiles;
    END IF;
END $$;
