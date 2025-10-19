-- Reset BFF Interactions for Testing
-- This script clears BFF interactions so you can test the matching feature

-- 1. Check current BFF interactions
SELECT 
    'Current BFF Interactions' as status,
    COUNT(*) as count
FROM bff_interactions;

-- 2. Show current interactions
SELECT 
    user_id,
    target_user_id,
    interaction_type,
    created_at
FROM bff_interactions
ORDER BY created_at DESC;

-- 3. Clear all BFF interactions (for testing purposes)
DELETE FROM bff_interactions;

-- 4. Reset BFF swipe counts in profiles
UPDATE profiles 
SET 
    bff_swipes_count = 0,
    bff_last_active = NULL
WHERE bff_enabled = true;

-- 5. Verify the reset
SELECT 
    'After Reset' as status,
    COUNT(*) as bff_interactions_count
FROM bff_interactions;

-- 6. Check profiles with BFF enabled
SELECT 
    id,
    name,
    age,
    bff_enabled,
    bff_swipes_count,
    bff_last_active
FROM profiles 
WHERE bff_enabled = true
ORDER BY created_at DESC
LIMIT 10;

-- 7. Test the get_bff_profiles function
-- This should now return profiles since interactions are cleared
SELECT 
    'BFF Profiles Available' as status,
    COUNT(*) as available_profiles
FROM (
    SELECT * FROM get_bff_profiles('7ffe44fe-9c0f-4783-aec2-a6172a6e008b')
) as bff_profiles;

-- 8. Show available BFF profiles
SELECT 
    id,
    name,
    age,
    bff_enabled
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
    )
ORDER BY created_at DESC;

-- 9. Final status
DO $$
DECLARE
    bff_profiles_count INTEGER;
    bff_interactions_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO bff_interactions_count FROM bff_interactions;
    SELECT COUNT(*) INTO bff_profiles_count FROM profiles WHERE bff_enabled = true;
    
    RAISE NOTICE '=== BFF Testing Reset Complete ===';
    RAISE NOTICE 'BFF interactions cleared: %', bff_interactions_count;
    RAISE NOTICE 'BFF profiles available: %', bff_profiles_count;
    RAISE NOTICE 'You can now test BFF matching!';
END $$;
