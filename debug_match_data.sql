-- Debug Match Data and Relations
-- This file contains queries to investigate the match table and understand the "matched with myself" issue

-- 1. Check all matches in the database
SELECT 
  m.id,
  m.user_id_1,
  m.user_id_2,
  m.created_at,
  p1.name as user1_name,
  p2.name as user2_name
FROM matches m
LEFT JOIN profiles p1 ON p1.id = m.user_id_1
LEFT JOIN profiles p2 ON p2.id = m.user_id_2
ORDER BY m.created_at DESC;

-- 2. Check matches for a specific user (replace 'your_user_id' with actual ID)
-- First, let's find your user ID
SELECT id, name, email FROM profiles WHERE email = 'your_email@example.com';

-- 3. Check matches for your user ID (replace with actual ID from step 2)
SELECT 
  m.id,
  m.user_id_1,
  m.user_id_2,
  m.created_at,
  CASE 
    WHEN m.user_id_1 = 'your_user_id' THEN m.user_id_2 
    ELSE m.user_id_1 
  END as other_user_id,
  p1.name as user1_name,
  p2.name as user2_name,
  CASE 
    WHEN m.user_id_1 = 'your_user_id' THEN p2.name 
    ELSE p1.name 
  END as other_user_name
FROM matches m
LEFT JOIN profiles p1 ON p1.id = m.user_id_1
LEFT JOIN profiles p2 ON p2.id = m.user_id_2
WHERE m.user_id_1 = 'your_user_id' OR m.user_id_2 = 'your_user_id'
ORDER BY m.created_at DESC;

-- 4. Check the activity feed function directly
SELECT * FROM get_user_activities('your_user_id', 50);

-- 5. Check if there are any matches where user_id_1 = user_id_2 (self-matches)
SELECT * FROM matches WHERE user_id_1 = user_id_2;

-- 6. Check the profiles table for any issues
SELECT id, name, email, created_at FROM profiles ORDER BY created_at DESC;

-- 7. Check if there are any duplicate matches
SELECT user_id_1, user_id_2, COUNT(*) as count
FROM matches 
GROUP BY user_id_1, user_id_2 
HAVING COUNT(*) > 1;

-- 8. Check the most recent matches
SELECT 
  m.*,
  p1.name as user1_name,
  p2.name as user2_name
FROM matches m
LEFT JOIN profiles p1 ON p1.id = m.user_id_1
LEFT JOIN profiles p2 ON p2.id = m.user_id_2
ORDER BY m.created_at DESC
LIMIT 10;
