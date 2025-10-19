-- Fresh Test Flow Setup - Create dummy user who has already liked you
-- This creates a new test profile and match for testing the complete flow

-- Step 1: Get your user ID
SELECT 'Your user ID:' as info;
SELECT id, email FROM auth.users WHERE email = 'reshab.retheesh@gmail.com';

-- Step 2: Create a dummy user profile (Emma)
INSERT INTO profiles (id, name, age, zodiac_sign, created_at, updated_at)
VALUES 
  ('11111111-2222-3333-4444-555555555555', 'Emma', 24, 'Gemini', NOW(), NOW())
ON CONFLICT (id) DO NOTHING;

-- Step 3: Create a swipe record - Emma has already swiped RIGHT on you
-- Replace 'YOUR_ACTUAL_USER_ID' with your real user ID from Step 1
INSERT INTO swipes (id, swiper_id, swiped_id, action, created_at)
VALUES 
  ('22222222-3333-4444-5555-666666666666', '11111111-2222-3333-4444-555555555555', '7ffe44fe-9c0f-4783-aec2-a6172a6e008b', 'like', NOW())
ON CONFLICT (id) DO NOTHING;

-- Step 4: Verify what we created
SELECT 'Dummy profile created:' as info;
SELECT id, name, zodiac_sign FROM profiles WHERE id = '11111111-2222-3333-4444-555555555555';

SELECT 'Swipe record created:' as info;
SELECT id, swiper_id, swiped_id, action FROM swipes WHERE id = '22222222-3333-4444-5555-666666666666';

-- Step 5: Check if any matches exist
SELECT 'Existing matches:' as info;
SELECT id, user_id_1, user_id_2, status, created_at FROM matches LIMIT 5;

-- Step 6: Check if any match enhancements exist
SELECT 'Existing match enhancements:' as info;
SELECT match_id, astro_compatibility IS NOT NULL as has_astro, ice_breakers IS NOT NULL as has_ice_breakers, expires_at, created_at
FROM match_enhancements 
LIMIT 5;

-- Step 7: Check if any ice breaker usage exists
SELECT 'Existing ice breaker usage:' as info;
SELECT match_id, ice_breaker_text, used_by_user_id
FROM ice_breaker_usage 
LIMIT 5;
