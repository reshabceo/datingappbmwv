-- Investigate the chat users and find the real other ashley
-- This will help us understand why the same profile picture appears

-- 1. Check what users are actually in your matches
SELECT 
  m.id as match_id,
  m.user_id_1,
  m.user_id_2,
  m.status,
  m.created_at,
  p1.name as user1_name,
  p1.id as user1_id,
  p2.name as user2_name,
  p2.id as user2_id
FROM matches m
LEFT JOIN profiles p1 ON p1.id = m.user_id_1
LEFT JOIN profiles p2 ON p2.id = m.user_id_2
WHERE m.user_id_1 = '195cb857-3a05-4425-a6ba-3dd836ca8627' 
   OR m.user_id_2 = '195cb857-3a05-4425-a6ba-3dd836ca8627'
ORDER BY m.created_at DESC;

-- 2. Check if the chat-referenced user ID actually exists
SELECT 
  id,
  name,
  age,
  email,
  created_at,
  is_active,
  'EXISTS' as status
FROM profiles 
WHERE id = '4fd6beaf-a15a-4a12-8d03-b301cbaae0e2'

UNION ALL

SELECT 
  NULL as id,
  'NOT FOUND' as name,
  NULL as age,
  NULL as email,
  NULL as created_at,
  NULL as is_active,
  'MISSING' as status
WHERE NOT EXISTS (
  SELECT 1 FROM profiles WHERE id = '4fd6beaf-a15a-4a12-8d03-b301cbaae0e2'
);

-- 3. Find all users named ashley (case insensitive)
SELECT 
  id,
  name,
  age,
  email,
  created_at,
  is_active,
  image_urls
FROM profiles 
WHERE LOWER(name) LIKE '%ashley%'
ORDER BY created_at;

-- 4. Check the actual chat data structure
-- This will show us what's really in the chat system
SELECT 
  'Chat data investigation' as info,
  'Check your app logs for actual chat loading' as note;
