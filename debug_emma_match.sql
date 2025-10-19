-- Debug script to check Emma match status
-- Replace 'YOUR_USER_ID' with your actual user ID

-- 1. Find your user ID (using your email)
SELECT id, email FROM auth.users WHERE email = 'reshab.retheesh@gmail.com';

-- 2. Find Emma's profile
SELECT id, name FROM profiles WHERE name ILIKE '%emma%';

-- 3. Check if there's a match record between you and Emma
SELECT 
  m.id as match_id,
  m.user_id_1,
  m.user_id_2,
  m.status,
  m.created_at,
  p1.name as user1_name,
  p2.name as user2_name
FROM matches m
LEFT JOIN profiles p1 ON p1.id = m.user_id_1
LEFT JOIN profiles p2 ON p2.id = m.user_id_2
WHERE 
  (m.user_id_1 IN (SELECT id FROM auth.users WHERE email = 'reshab.retheesh@gmail.com')
   OR m.user_id_2 IN (SELECT id FROM auth.users WHERE email = 'reshab.retheesh@gmail.com'))
  AND (p1.name ILIKE '%emma%' OR p2.name ILIKE '%emma%');

-- 4. Check all your matches to see their statuses
SELECT 
  m.id as match_id,
  m.status,
  CASE 
    WHEN m.user_id_1 = (SELECT id FROM auth.users WHERE email = 'reshab.retheesh@gmail.com') 
    THEN p2.name 
    ELSE p1.name 
  END as matched_with,
  m.created_at
FROM matches m
LEFT JOIN profiles p1 ON p1.id = m.user_id_1
LEFT JOIN profiles p2 ON p2.id = m.user_id_2
WHERE 
  m.user_id_1 IN (SELECT id FROM auth.users WHERE email = 'reshab.retheesh@gmail.com')
  OR m.user_id_2 IN (SELECT id FROM auth.users WHERE email = 'reshab.retheesh@gmail.com')
ORDER BY m.created_at DESC;

