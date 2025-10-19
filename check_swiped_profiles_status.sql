-- Check the current status of swiped profiles
DO $$
DECLARE
    test_user_id UUID := '7ffe44fe-9c0f-4783-aec2-a6172a6e008b';
BEGIN
    RAISE NOTICE '--- Profile Swiping Status Check ---';
    
    -- 1. Check profiles in bff_swipes table
    RAISE NOTICE '--- 1. Profiles you have swiped on (bff_swipes table) ---';
    PERFORM 'BFF SWIPES' as table_name, p.name, bs.action, bs.created_at
    FROM bff_swipes bs
    JOIN profiles p ON p.id = bs.swiped_id
    WHERE bs.swiper_id = test_user_id
    ORDER BY bs.created_at DESC;
    
    -- 2. Check profiles in bff_interactions table
    RAISE NOTICE '--- 2. Profiles you have interacted with (bff_interactions table) ---';
    PERFORM 'BFF INTERACTIONS' as table_name, p.name, bi.interaction_type, bi.created_at
    FROM bff_interactions bi
    JOIN profiles p ON p.id = bi.target_user_id
    WHERE bi.user_id = test_user_id
    ORDER BY bi.created_at DESC;
    
    -- 3. Check total BFF enabled profiles
    RAISE NOTICE '--- 3. Total BFF enabled profiles ---';
    PERFORM 'TOTAL BFF PROFILES' as status, COUNT(*) as count
    FROM profiles p
    WHERE p.mode_preferences->>'bff' = 'true'
        AND p.id != test_user_id;
    
    -- 4. Check profiles you can still see (not swiped)
    RAISE NOTICE '--- 4. Profiles you can still see (not swiped) ---';
    PERFORM 'AVAILABLE PROFILES' as status, p.name, p.age
    FROM profiles p
    WHERE p.id != test_user_id
        AND p.mode_preferences->>'bff' = 'true'
        AND p.id NOT IN (
            SELECT swiped_id FROM bff_swipes WHERE swiper_id = test_user_id
        )
        AND p.id NOT IN (
            SELECT target_user_id FROM bff_interactions WHERE user_id = test_user_id
        )
    ORDER BY p.name;
    
END $$;

-- Add some new test profiles for BFF mode
INSERT INTO profiles (id, name, age, location, description, hobbies, mode_preferences, is_active, created_at)
VALUES 
    (gen_random_uuid(), 'Test Friend 1', 22, 'New York', 'Looking for new friends!', '["Music", "Movies", "Coffee"]', '{"dating": false, "bff": true}', true, NOW()),
    (gen_random_uuid(), 'Test Friend 2', 25, 'Los Angeles', 'Love hiking and adventures', '["Hiking", "Photography", "Travel"]', '{"dating": false, "bff": true}', true, NOW()),
    (gen_random_uuid(), 'Test Friend 3', 23, 'Chicago', 'Foodie and book lover', '["Cooking", "Reading", "Art"]', '{"dating": false, "bff": true}', true, NOW())
ON CONFLICT (id) DO NOTHING;

-- Check how many profiles are now available
SELECT 
    'After adding test profiles' as status,
    COUNT(*) as available_count
FROM get_bff_profiles('7ffe44fe-9c0f-4783-aec2-a6172a6e008b');
