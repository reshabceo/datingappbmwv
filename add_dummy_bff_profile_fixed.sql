-- Add dummy BFF profiles with correct column names
-- Replace 'your-user-id-here' with your actual user ID from the find_user_id_and_setup_bff.sql results

-- 1. Add a dummy BFF profile (Sarah)
INSERT INTO profiles (
    id,
    name,
    age,
    location,
    latitude,
    longitude,
    photos,
    mode_preferences,
    bff_enabled_at,
    bff_swipes_count,
    bff_last_active,
    created_at,
    updated_at
) VALUES (
    'bff-test-profile-001',
    'Sarah',
    26,
    'San Francisco, CA',
    37.7749,
    -122.4194,
    '["https://images.unsplash.com/photo-1494790108755-2616b612b786?w=400"]',
    '{"dating": false, "bff": true}',
    NOW(),
    5,
    NOW() - INTERVAL '2 hours',
    NOW(),
    NOW()
);

-- 2. Record that Sarah has liked you in BFF mode
INSERT INTO bff_interactions (
    user_id,
    target_user_id,
    interaction_type,
    created_at
) VALUES (
    'bff-test-profile-001',
    'c1ffb3e0-0e25-4176-9736-0db8522fd357',  -- Replace with your user ID
    'like',
    NOW() - INTERVAL '1 hour'
);

-- 3. Add another BFF profile that has super liked you (Alex)
INSERT INTO profiles (
    id,
    name,
    age,
    location,
    latitude,
    longitude,
    photos,
    mode_preferences,
    bff_enabled_at,
    bff_swipes_count,
    bff_last_active,
    created_at,
    updated_at
) VALUES (
    'bff-test-profile-002',
    'Alex',
    28,
    'Los Angeles, CA',
    34.0522,
    -118.2437,
    '["https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400"]',
    '{"dating": false, "bff": true}',
    NOW(),
    3,
    NOW() - INTERVAL '30 minutes',
    NOW(),
    NOW()
);

-- 4. Record that Alex has super liked you in BFF mode
INSERT INTO bff_interactions (
    user_id,
    target_user_id,
    interaction_type,
    created_at
) VALUES (
    'bff-test-profile-002',
    'c1ffb3e0-0e25-4176-9736-0db8522fd357',  -- Replace with your user ID
    'super_like',
    NOW() - INTERVAL '15 minutes'
);

-- 5. Add a third BFF profile for variety (Emma)
INSERT INTO profiles (
    id,
    name,
    age,
    location,
    latitude,
    longitude,
    photos,
    mode_preferences,
    bff_enabled_at,
    bff_swipes_count,
    bff_last_active,
    created_at,
    updated_at
) VALUES (
    'bff-test-profile-003',
    'Emma',
    24,
    'Seattle, WA',
    47.6062,
    -122.3321,
    '["https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=400"]',
    '{"dating": false, "bff": true}',
    NOW(),
    7,
    NOW() - INTERVAL '45 minutes',
    NOW(),
    NOW()
);

-- 6. Record that Emma has liked you in BFF mode
INSERT INTO bff_interactions (
    user_id,
    target_user_id,
    interaction_type,
    created_at
) VALUES (
    'bff-test-profile-003',
    'c1ffb3e0-0e25-4176-9736-0db8522fd357',  -- Replace with your user ID
    'like',
    NOW() - INTERVAL '20 minutes'
);

-- 7. Update your profile to enable BFF mode
UPDATE profiles 
SET mode_preferences = '{"dating": true, "bff": true}',
    bff_enabled_at = NOW()
WHERE id = 'c1ffb3e0-0e25-4176-9736-0db8522fd357';  -- Replace with your user ID

-- 8. Verify the data was inserted correctly
SELECT 
    p.name,
    p.age,
    p.location,
    p.mode_preferences,
    p.bff_swipes_count,
    p.bff_last_active,
    bi.interaction_type,
    bi.created_at as interaction_time
FROM profiles p
JOIN bff_interactions bi ON p.id = bi.user_id
WHERE bi.target_user_id = 'c1ffb3e0-0e25-4176-9736-0db8522fd357'  -- Replace with your user ID
ORDER BY bi.created_at DESC;

-- 9. Test the BFF profiles query
SELECT * FROM get_bff_profiles('c1ffb3e0-0e25-4176-9736-0db8522fd357');  -- Replace with your user ID
