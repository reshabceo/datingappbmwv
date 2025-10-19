-- Test Flow Setup Script for reshab.retheesh@gmail.com
-- This creates a test profile that has already swiped on you

-- Step 1: Find your user ID first
SELECT 'Your user ID:' as info;
SELECT id, email FROM auth.users WHERE email = 'reshab.retheesh@gmail.com';

-- Step 2: Create a test profile (Ashley) with realistic data
INSERT INTO profiles (id, name, age, zodiac_sign, created_at, updated_at)
VALUES 
  ('a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'Ashley', 26, 'Pisces', NOW(), NOW())
ON CONFLICT (id) DO NOTHING;

-- Step 3: Create a swipe record - Ashley has already swiped RIGHT on you
INSERT INTO swipes (id, swiper_id, swiped_id, action, created_at)
VALUES 
  ('b2c3d4e5-f6a7-8901-bcde-f23456789012', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', '7ffe44fe-9c0f-4783-aec2-a6172a6e008b', 'like', NOW())
ON CONFLICT (id) DO NOTHING;

-- 4. Check what we created
SELECT 'Profiles created:' as info;
SELECT id, name, zodiac_sign FROM profiles WHERE id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890';

SELECT 'Swipes created:' as info;
SELECT id, swiper_id, swiped_id, action FROM swipes WHERE id = 'b2c3d4e5-f6a7-8901-bcde-f23456789012';
