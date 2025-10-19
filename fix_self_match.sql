-- Fix the self-match issue
-- Your user ID: 7ffe44fe-9c0f-4783-aec2-a6172a6e008b

-- 1. Check for self-matches (should show the problematic one)
SELECT * FROM matches WHERE user_id_1 = user_id_2;

-- 2. Delete the self-match
DELETE FROM matches WHERE user_id_1 = user_id_2;

-- 3. Verify it's gone
SELECT * FROM matches WHERE user_id_1 = user_id_2;

-- 4. Check your remaining matches
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
WHERE m.user_id_1 = '7ffe44fe-9c0f-4783-aec2-a6172a6e008b' 
   OR m.user_id_2 = '7ffe44fe-9c0f-4783-aec2-a6172a6e008b'
ORDER BY m.created_at DESC;

-- 5. Test the activity feed function
SELECT * FROM get_user_activities('7ffe44fe-9c0f-4783-aec2-a6172a6e008b', 50);
