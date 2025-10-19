-- Enable BFF mode for testing
-- This script enables BFF mode for some profiles so you can test the BFF functionality

-- 1. Enable BFF mode for all existing profiles (for testing purposes)
UPDATE profiles 
SET 
    bff_enabled = true,
    bff_last_active = NOW(),
    bff_swipes_count = 0
WHERE bff_enabled IS NULL OR bff_enabled = false;

-- 2. Check how many profiles now have BFF enabled
SELECT 
    COUNT(*) as total_profiles,
    COUNT(CASE WHEN bff_enabled = true THEN 1 END) as bff_enabled_count,
    COUNT(CASE WHEN bff_enabled = false THEN 1 END) as bff_disabled_count
FROM profiles;

-- 3. Show some sample profiles with BFF enabled
SELECT 
    id,
    name,
    age,
    bff_enabled,
    bff_last_active,
    bff_swipes_count
FROM profiles 
WHERE bff_enabled = true
ORDER BY created_at DESC
LIMIT 5;

-- 4. Create some dummy BFF interactions for testing (optional)
-- Uncomment the lines below if you want to create some test interactions
/*
INSERT INTO bff_interactions (user_id, target_user_id, interaction_type)
SELECT 
    p1.id,
    p2.id,
    'like'
FROM profiles p1
CROSS JOIN profiles p2
WHERE p1.id != p2.id
    AND p1.bff_enabled = true
    AND p2.bff_enabled = true
    AND NOT EXISTS (
        SELECT 1 FROM bff_interactions bi 
        WHERE bi.user_id = p1.id AND bi.target_user_id = p2.id
    )
LIMIT 10;
*/

-- 5. Show current BFF system status
DO $$
DECLARE
    total_profiles INTEGER;
    bff_enabled_count INTEGER;
    bff_interactions_count INTEGER;
    bff_matches_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO total_profiles FROM profiles;
    SELECT COUNT(*) INTO bff_enabled_count FROM profiles WHERE bff_enabled = true;
    SELECT COUNT(*) INTO bff_interactions_count FROM bff_interactions;
    SELECT COUNT(*) INTO bff_matches_count FROM bff_matches;
    
    RAISE NOTICE '=== BFF Testing Setup Complete ===';
    RAISE NOTICE 'Total profiles: %', total_profiles;
    RAISE NOTICE 'Profiles with BFF enabled: %', bff_enabled_count;
    RAISE NOTICE 'BFF interactions: %', bff_interactions_count;
    RAISE NOTICE 'BFF matches: %', bff_matches_count;
    RAISE NOTICE 'Ready for BFF testing!';
END $$;
