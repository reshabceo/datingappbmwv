-- Fix Super Like Test Data
-- This script ensures the super like relationship is correctly created

-- Step 1: Delete any existing SuperLiker data to start fresh
DELETE FROM swipes WHERE swiper_id IN (SELECT id FROM profiles WHERE name = 'SuperLiker');
DELETE FROM profiles WHERE name = 'SuperLiker';

-- Step 2: Create SuperLiker profile with a fixed ID
INSERT INTO profiles (
    id,
    name,
    age,
    photos,
    location,
    distance,
    description,
    hobbies,
    is_active,
    created_at,
    updated_at
) VALUES (
    'bcb1c077-1b71-4d78-b30b-717393f65fb7', -- Fixed ID to match what we see in logs
    'SuperLiker',
    25,
    '["https://images.unsplash.com/photo-1494790108755-2616b612b786?w=400"]'::jsonb,
    'New York',
    '5 miles',
    'I love to super like amazing people! 💙',
    '["Photography", "Travel", "Music"]'::jsonb,
    true,
    NOW(),
    NOW()
);

-- Step 3: Create super like from SuperLiker to you
-- Using your actual user ID from the logs: 7ffe44fe-9c0f-4783-aec2-a6172a6e008b
INSERT INTO swipes (
    id,
    swiper_id,
    swiped_id,
    action,
    created_at
) VALUES (
    gen_random_uuid(),
    'bcb1c077-1b71-4d78-b30b-717393f65fb7', -- SuperLiker's ID
    '7ffe44fe-9c0f-4783-aec2-a6172a6e008b', -- Your user ID
    'super_like',
    NOW()
);

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
  AND s.swiper_id = 'bcb1c077-1b71-4d78-b30b-717393f65fb7'
  AND s.swiped_id = '7ffe44fe-9c0f-4783-aec2-a6172a6e008b';

-- Step 5: Test the function again
SELECT 
    result.name,
    result.age,
    result.is_super_liked,
    result.id as profile_id
FROM get_profiles_with_super_likes('7ffe44fe-9c0f-4783-aec2-a6172a6e008b') as result
WHERE result.name = 'SuperLiker';
