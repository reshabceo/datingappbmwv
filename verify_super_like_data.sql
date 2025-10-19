-- Verify Super Like Data
-- Check if the super like was actually created

-- Step 1: Check if SuperLiker profile exists
SELECT 
    id,
    name,
    age,
    created_at
FROM profiles 
WHERE name = 'SuperLiker';

-- Step 2: Check if super like exists
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
ORDER BY s.created_at DESC;

-- Step 3: Check your user ID
SELECT 
    id,
    email
FROM auth.users 
WHERE email = 'reshab.retheesh@gmail.com';

-- Step 4: Test the function directly
WITH your_user AS (
    SELECT id FROM auth.users WHERE email = 'reshab.retheesh@gmail.com' LIMIT 1
)
SELECT 
    result.name,
    result.age,
    result.is_super_liked,
    result.id as profile_id
FROM your_user yu,
     get_profiles_with_super_likes(yu.id) as result
WHERE result.name = 'SuperLiker';
