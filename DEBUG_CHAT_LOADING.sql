-- DEBUG CHAT LOADING - Step by step check
-- Run this in Supabase SQL Editor to debug chat loading

-- Step 1: Check your user ID (replace with your actual user ID)
SELECT 'Your User ID' as info, '7ffe44fe-9c0f-4783-aec2-a6172a6e008b' as user_id;

-- Step 2: Check all matches for your user
SELECT 'All Matches for User' as check_type, 
       m.id as match_id,
       p1.name as user1_name,
       p2.name as user2_name,
       m.created_at
FROM matches m
JOIN profiles p1 ON m.user_id_1 = p1.id
JOIN profiles p2 ON m.user_id_2 = p2.id
WHERE m.user_id_1 = '7ffe44fe-9c0f-4783-aec2-a6172a6e008b' 
   OR m.user_id_2 = '7ffe44fe-9c0f-4783-aec2-a6172a6e008b';

-- Step 3: Check BFF matches for your user
SELECT 'BFF Matches for User' as check_type,
       bm.id as match_id,
       p1.name as user1_name,
       p2.name as user2_name,
       bm.created_at
FROM bff_matches bm
JOIN profiles p1 ON bm.user_id_1 = p1.id
JOIN profiles p2 ON bm.user_id_2 = p2.id
WHERE bm.user_id_1 = '7ffe44fe-9c0f-4783-aec2-a6172a6e008b' 
   OR bm.user_id_2 = '7ffe44fe-9c0f-4783-aec2-a6172a6e008b';

-- Step 4: Check messages for each match
SELECT 'Messages for Match' as check_type,
       m.id as match_id,
       msg.content,
       msg.created_at,
       p.name as sender_name
FROM matches m
LEFT JOIN messages msg ON m.id = msg.match_id
LEFT JOIN profiles p ON msg.sender_id = p.id
WHERE (m.user_id_1 = '7ffe44fe-9c0f-4783-aec2-a6172a6e008b' 
   OR m.user_id_2 = '7ffe44fe-9c0f-4783-aec2-a6172a6e008b')
ORDER BY m.id, msg.created_at DESC;

-- Step 5: Check if BFF matches exist in regular matches table
SELECT 'BFF in Regular Matches' as check_type,
       bm.id as bff_match_id,
       m.id as regular_match_id,
       p1.name as user1_name,
       p2.name as user2_name
FROM bff_matches bm
LEFT JOIN matches m ON bm.id = m.id
JOIN profiles p1 ON bm.user_id_1 = p1.id
JOIN profiles p2 ON bm.user_id_2 = p2.id
WHERE bm.user_id_1 = '7ffe44fe-9c0f-4783-aec2-a6172a6e008b' 
   OR bm.user_id_2 = '7ffe44fe-9c0f-4783-aec2-a6172a6e008b';

-- Step 6: Check dating matches (excluding BFF)
SELECT 'Dating Matches (Excluding BFF)' as check_type,
       m.id as match_id,
       p1.name as user1_name,
       p2.name as user2_name,
       CASE WHEN bm.id IS NOT NULL THEN 'BFF Match' ELSE 'Dating Match' END as match_type
FROM matches m
JOIN profiles p1 ON m.user_id_1 = p1.id
JOIN profiles p2 ON m.user_id_2 = p2.id
LEFT JOIN bff_matches bm ON m.id = bm.id
WHERE (m.user_id_1 = '7ffe44fe-9c0f-4783-aec2-a6172a6e008b' 
   OR m.user_id_2 = '7ffe44fe-9c0f-4783-aec2-a6172a6e008b')
   AND bm.id IS NULL;  -- Exclude BFF matches
