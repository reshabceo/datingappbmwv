-- Test Super Like Glow Effect
-- This script creates a dummy profile that has super liked you

-- Step 1: Create a dummy profile that will super like you
INSERT INTO profiles (
    id,
    name,
    age,
    photos,
    location,
    distance,
    description,
    hobbies,
    created_at,
    updated_at
) VALUES (
    gen_random_uuid(),
    'SuperLiker',
    25,
    '["https://images.unsplash.com/photo-1494790108755-2616b612b786?w=400"]'::jsonb,
    'New York',
    '5 miles',
    'I love to super like amazing people! 💙',
    '["Photography", "Travel", "Music"]'::jsonb,
    NOW(),
    NOW()
) ON CONFLICT DO NOTHING;

-- Step 2: Get your user ID (replace with your actual email)
-- You can find your user ID by running: SELECT id FROM auth.users WHERE email = 'your-email@example.com';
-- For now, let's assume your user ID is the one from the current session

-- Step 3: Create a super like from the dummy profile to you
-- First, let's get the dummy profile ID and your user ID
WITH dummy_profile AS (
    SELECT id FROM profiles WHERE name = 'SuperLiker' LIMIT 1
),
your_user AS (
    SELECT id FROM auth.users WHERE email = 'reshab.retheesh@gmail.com' LIMIT 1
)
INSERT INTO swipes (
    id,
    swiper_id,
    swiped_id,
    action,
    created_at
)
SELECT 
    gen_random_uuid(),
    dp.id,
    yu.id,
    'super_like',
    NOW()
FROM dummy_profile dp, your_user yu
WHERE dp.id IS NOT NULL AND yu.id IS NOT NULL
ON CONFLICT DO NOTHING;

-- Step 4: Verify the super like was created
SELECT 
    s.id,
    s.swiper_id,
    s.swiped_id,
    s.action,
    p.name as swiper_name,
    s.created_at
FROM swipes s
JOIN profiles p ON p.id = s.swiper_id
WHERE s.action = 'super_like'
ORDER BY s.created_at DESC
LIMIT 5;

-- Step 5: Test the function
-- This should show the SuperLiker profile with is_super_liked = true
-- First get your user ID
WITH your_user AS (
    SELECT id FROM auth.users WHERE email = 'reshab.retheesh@gmail.com' LIMIT 1
)
SELECT 
    result.name,
    result.age,
    result.photos,
    result.is_super_liked
FROM your_user yu,
     get_profiles_with_super_likes(yu.id) as result
WHERE result.name = 'SuperLiker';
