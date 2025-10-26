-- Query to find the other ashley user (4fd6beaf-a15a-4a12-8d03-b301cbaae0e2)
-- This will show all details about that user profile

SELECT 
  id,
  name,
  age,
  gender,
  email,
  image_urls,
  photos,
  description,
  hobbies,
  location,
  is_active,
  created_at,
  updated_at,
  last_seen,
  is_premium,
  premium_until,
  birth_date,
  zodiac_sign,
  mode_preference,
  friendship_interests,
  activity_level,
  availability,
  mode_preferences,
  bff_swipes_count,
  bff_last_active,
  bff_enabled_at,
  bff_enabled,
  verification_status,
  verification_photo_url,
  verification_challenge,
  verification_submitted_at
FROM profiles 
WHERE id = '4fd6beaf-a15a-4a12-8d03-b301cbaae0e2';

-- Also check if this user has any matches with your user
SELECT 
  m.id as match_id,
  m.user_id_1,
  m.user_id_2,
  m.status,
  m.created_at as match_created_at,
  p1.name as user1_name,
  p2.name as user2_name
FROM matches m
LEFT JOIN profiles p1 ON p1.id = m.user_id_1
LEFT JOIN profiles p2 ON p2.id = m.user_id_2
WHERE (m.user_id_1 = '4fd6beaf-a15a-4a12-8d03-b301cbaae0e2' 
       AND m.user_id_2 = '195cb857-3a05-4425-a6ba-3dd836ca8627')
   OR (m.user_id_1 = '195cb857-3a05-4425-a6ba-3dd836ca8627' 
       AND m.user_id_2 = '4fd6beaf-a15a-4a12-8d03-b301cbaae0e2');

-- Check all users named ashley
SELECT 
  id,
  name,
  age,
  email,
  created_at,
  is_active
FROM profiles 
WHERE LOWER(name) = 'ashley'
ORDER BY created_at;
