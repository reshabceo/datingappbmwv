-- Test Activity Feed Function
-- Run this AFTER running activity_feed_setup.sql

-- Step 1: Get your user ID
SELECT id, email, 'Your User ID:' as label 
FROM auth.users 
WHERE email = 'reshab.retheesh@gmail.com';

-- Step 2: Test the activity feed function
-- Replace the UUID below with your actual user ID from Step 1
SELECT 
  activity_type,
  other_user_name,
  message_preview,
  created_at,
  is_unread,
  '---' as separator
FROM get_user_activities(
  (SELECT id FROM auth.users WHERE email = 'reshab.retheesh@gmail.com'),
  50
);

-- Step 3: Verify data sources individually

-- Check likes you received
SELECT 
  'LIKES' as type,
  p.name as from_user,
  s.action,
  s.created_at
FROM swipes s
JOIN profiles p ON p.id = s.swiper_id
WHERE s.swiped_id = (SELECT id FROM auth.users WHERE email = 'reshab.retheesh@gmail.com')
  AND s.action IN ('like', 'super_like')
  AND s.created_at > NOW() - INTERVAL '7 days'
ORDER BY s.created_at DESC;

-- Check your matches
SELECT 
  'MATCHES' as type,
  CASE 
    WHEN m.user_id_1 = (SELECT id FROM auth.users WHERE email = 'reshab.retheesh@gmail.com')
    THEN p2.name 
    ELSE p1.name 
  END as matched_with,
  m.created_at
FROM matches m
LEFT JOIN profiles p1 ON p1.id = m.user_id_1
LEFT JOIN profiles p2 ON p2.id = m.user_id_2
WHERE (m.user_id_1 = (SELECT id FROM auth.users WHERE email = 'reshab.retheesh@gmail.com')
   OR m.user_id_2 = (SELECT id FROM auth.users WHERE email = 'reshab.retheesh@gmail.com'))
  AND m.status = 'matched'
  AND m.created_at > NOW() - INTERVAL '7 days'
ORDER BY m.created_at DESC;

-- Check messages sent to you
SELECT 
  'MESSAGES' as type,
  p.name as from_user,
  SUBSTRING(msg.content, 1, 50) as preview,
  msg.is_read,
  msg.created_at
FROM messages msg
JOIN matches m ON m.id = msg.match_id
JOIN profiles p ON p.id = msg.sender_id
WHERE (m.user_id_1 = (SELECT id FROM auth.users WHERE email = 'reshab.retheesh@gmail.com')
   OR m.user_id_2 = (SELECT id FROM auth.users WHERE email = 'reshab.retheesh@gmail.com'))
  AND msg.sender_id != (SELECT id FROM auth.users WHERE email = 'reshab.retheesh@gmail.com')
  AND msg.created_at > NOW() - INTERVAL '3 days'
ORDER BY msg.created_at DESC;

