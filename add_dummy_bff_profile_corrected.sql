-- Add dummy BFF profiles with correct schema
-- Based on actual profiles table schema

-- 1. Add a dummy BFF profile (Sarah)
INSERT INTO profiles (
    id,
    name,
    age,
    location,
    image_urls,
    description,
    mode_preferences,
    bff_enabled_at,
    bff_swipes_count,
    bff_last_active,
    created_at,
    updated_at
) VALUES (
    '11111111-1111-1111-1111-111111111111',
    'Sarah',
    26,
    'San Francisco, CA',
    '["https://images.unsplash.com/photo-1494790108755-2616b612b786?w=400"]',
    'Looking for new friends to explore the city with! Love hiking, coffee, and good conversations.',
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
    '11111111-1111-1111-1111-111111111111',
    'c1ffb3e0-0e25-4176-9736-0db8522fd357',  -- Your user ID
    'like',
    NOW() - INTERVAL '1 hour'
);

-- 3. Add another BFF profile that has super liked you (Alex)
INSERT INTO profiles (
    id,
    name,
    age,
    location,
    image_urls,
    description,
    mode_preferences,
    bff_enabled_at,
    bff_swipes_count,
    bff_last_active,
    created_at,
    updated_at
) VALUES (
    '22222222-2222-2222-2222-222222222222',
    'Alex',
    28,
    'Los Angeles, CA',
    '["https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400"]',
    'New to the city and looking for workout buddies and adventure friends!',
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
    '22222222-2222-2222-2222-222222222222',
    'c1ffb3e0-0e25-4176-9736-0db8522fd357',  -- Your user ID
    'super_like',
    NOW() - INTERVAL '15 minutes'
);

-- 5. Add a third BFF profile for variety (Emma)
INSERT INTO profiles (
    id,
    name,
    age,
    location,
    image_urls,
    description,
    mode_preferences,
    bff_enabled_at,
    bff_swipes_count,
    bff_last_active,
    created_at,
    updated_at
) VALUES (
    '33333333-3333-3333-3333-333333333333',
    'Emma',
    24,
    'Seattle, WA',
    '["https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=400"]',
    'Coffee enthusiast, book lover, and always up for a new adventure!',
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
    '33333333-3333-3333-3333-333333333333',
    'c1ffb3e0-0e25-4176-9736-0db8522fd357',  -- Your user ID
    'like',
    NOW() - INTERVAL '20 minutes'
);

-- 7. Update your profile to enable BFF mode
UPDATE profiles 
SET mode_preferences = '{"dating": true, "bff": true}',
    bff_enabled_at = NOW()
WHERE id = 'c1ffb3e0-0e25-4176-9736-0db8522fd357';  -- Your user ID

-- 8. Verify the data was inserted correctly
SELECT 
    p.name,
    p.age,
    p.location,
    p.description,
    p.mode_preferences,
    p.bff_swipes_count,
    p.bff_last_active,
    bi.interaction_type,
    bi.created_at as interaction_time
FROM profiles p
JOIN bff_interactions bi ON p.id = bi.user_id
WHERE bi.target_user_id = 'c1ffb3e0-0e25-4176-9736-0db8522fd357'  -- Your user ID
ORDER BY bi.created_at DESC;

-- 9. Test the BFF profiles query
SELECT * FROM get_bff_profiles('c1ffb3e0-0e25-4176-9736-0db8522fd357');  -- Your user ID

-- 10. Check if BFF interactions table exists and has data
SELECT COUNT(*) as bff_interactions_count FROM bff_interactions;

-- 11. Check if the BFF RPC function exists
SELECT routine_name FROM information_schema.routines 
WHERE routine_name = 'get_bff_profiles' AND routine_schema = 'public';
