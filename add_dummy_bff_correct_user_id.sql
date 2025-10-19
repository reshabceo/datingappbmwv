-- Add dummy BFF profiles with the CORRECT user ID from the logs
-- Your actual user ID is: 7ffe44fe-9c0f-4783-aec2-a6172a6e008b

-- 1. Add Sarah profile
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
    'Looking for new friends to explore the city with!',
    '{"dating": false, "bff": true}',
    NOW(),
    5,
    NOW() - INTERVAL '2 hours',
    NOW(),
    NOW()
) ON CONFLICT (id) DO NOTHING;

-- 2. Add Alex profile
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
    'New to the city and looking for workout buddies!',
    '{"dating": false, "bff": true}',
    NOW(),
    3,
    NOW() - INTERVAL '30 minutes',
    NOW(),
    NOW()
) ON CONFLICT (id) DO NOTHING;

-- 3. Add Emma profile
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
    'Coffee enthusiast and book lover!',
    '{"dating": false, "bff": true}',
    NOW(),
    7,
    NOW() - INTERVAL '45 minutes',
    NOW(),
    NOW()
) ON CONFLICT (id) DO NOTHING;

-- 4. Record BFF interactions with CORRECT user ID
INSERT INTO bff_interactions (user_id, target_user_id, interaction_type, created_at)
VALUES 
    ('11111111-1111-1111-1111-111111111111', '7ffe44fe-9c0f-4783-aec2-a6172a6e008b', 'like', NOW() - INTERVAL '1 hour'),
    ('22222222-2222-2222-2222-222222222222', '7ffe44fe-9c0f-4783-aec2-a6172a6e008b', 'super_like', NOW() - INTERVAL '15 minutes'),
    ('33333333-3333-3333-3333-333333333333', '7ffe44fe-9c0f-4783-aec2-a6172a6e008b', 'like', NOW() - INTERVAL '20 minutes')
ON CONFLICT (user_id, target_user_id) DO NOTHING;

-- 5. Enable BFF mode for your profile with CORRECT user ID
UPDATE profiles 
SET mode_preferences = '{"dating": true, "bff": true}',
    bff_enabled_at = NOW()
WHERE id = '7ffe44fe-9c0f-4783-aec2-a6172a6e008b';

-- 6. Verify results
SELECT 'Profiles Created' as status, COUNT(*) as count FROM profiles WHERE id IN ('11111111-1111-1111-1111-111111111111', '22222222-2222-2222-2222-222222222222', '33333333-3333-3333-3333-333333333333');

SELECT 'BFF Interactions' as status, COUNT(*) as count FROM bff_interactions WHERE target_user_id = '7ffe44fe-9c0f-4783-aec2-a6172a6e008b';

SELECT 'Your Profile Updated' as status, name, mode_preferences FROM profiles WHERE id = '7ffe44fe-9c0f-4783-aec2-a6172a6e008b';
