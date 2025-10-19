-- Setup BFF Test Scenario
-- This script creates a test scenario where some profiles have already liked you back
-- so you can test the BFF matching feature

-- 1. First, let's see what profiles are available
SELECT 
    'Available BFF Profiles' as status,
    COUNT(*) as count
FROM profiles 
WHERE bff_enabled = true
    AND id != '7ffe44fe-9c0f-4783-aec2-a6172a6e008b';

-- 2. Get some test profile IDs
SELECT 
    id,
    name,
    age
FROM profiles 
WHERE bff_enabled = true
    AND id != '7ffe44fe-9c0f-4783-aec2-a6172a6e008b'
ORDER BY created_at DESC
LIMIT 5;

-- 3. Create some test BFF interactions where other users have liked you back
-- This simulates the scenario where you can get matches
INSERT INTO bff_interactions (user_id, target_user_id, interaction_type, created_at)
SELECT 
    p.id as user_id,
    '7ffe44fe-9c0f-4783-aec2-a6172a6e008b' as target_user_id,
    'like' as interaction_type,
    NOW() - INTERVAL '1 hour' as created_at
FROM profiles p
WHERE p.bff_enabled = true
    AND p.id != '7ffe44fe-9c0f-4783-aec2-a6172a6e008b'
    AND p.id IN (
        '22222222-2222-2222-2222-222222222222', -- Alex
        '33333333-3333-3333-3333-333333333333', -- Emma
        '11111111-1111-1111-1111-111111111111'  -- Sarah
    )
ON CONFLICT (user_id, target_user_id) DO NOTHING;

-- 4. Check the test interactions created
SELECT 
    'Test Interactions Created' as status,
    COUNT(*) as count
FROM bff_interactions 
WHERE target_user_id = '7ffe44fe-9c0f-4783-aec2-a6172a6e008b'
    AND interaction_type = 'like';

-- 5. Show which profiles have liked you back
SELECT 
    p.name,
    p.age,
    bi.interaction_type,
    bi.created_at
FROM bff_interactions bi
JOIN profiles p ON p.id = bi.user_id
WHERE bi.target_user_id = '7ffe44fe-9c0f-4783-aec2-a6172a6e008b'
    AND bi.interaction_type = 'like'
ORDER BY bi.created_at DESC;

-- 6. Test the BFF profiles function - should now show profiles
SELECT 
    'BFF Profiles Available for Swiping' as status,
    COUNT(*) as available_count
FROM (
    SELECT * FROM get_bff_profiles('7ffe44fe-9c0f-4783-aec2-a6172a6e008b')
) as bff_profiles;

-- 7. Show available profiles for swiping
SELECT 
    id,
    name,
    age,
    bff_enabled,
    created_at
FROM get_bff_profiles('7ffe44fe-9c0f-4783-aec2-a6172a6e008b')
ORDER BY created_at DESC
LIMIT 5;

-- 8. Final test scenario status
DO $$
DECLARE
    available_profiles INTEGER;
    mutual_likes INTEGER;
BEGIN
    SELECT COUNT(*) INTO available_profiles FROM (
        SELECT * FROM get_bff_profiles('7ffe44fe-9c0f-4783-aec2-a6172a6e008b')
    ) as bff_profiles;
    
    SELECT COUNT(*) INTO mutual_likes FROM bff_interactions 
    WHERE target_user_id = '7ffe44fe-9c0f-4783-aec2-a6172a6e008b'
        AND interaction_type = 'like';
    
    RAISE NOTICE '=== BFF Test Scenario Setup Complete ===';
    RAISE NOTICE 'Available profiles for swiping: %', available_profiles;
    RAISE NOTICE 'Profiles that have liked you back: %', mutual_likes;
    RAISE NOTICE 'You can now test BFF matching by swiping right on profiles!';
    RAISE NOTICE 'When you swipe right on a profile that has already liked you, you should get a match!';
END $$;