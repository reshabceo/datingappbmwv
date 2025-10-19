-- CHECK MISSING MATCHES AND DATA INTEGRITY
-- Run this in Supabase SQL Editor to check for missing matches

-- Check all matches
SELECT 'All Matches' as check_type, COUNT(*) as count FROM matches;

-- Check BFF matches
SELECT 'BFF Matches' as check_type, COUNT(*) as count FROM bff_matches;

-- Check messages
SELECT 'Messages' as check_type, COUNT(*) as count FROM messages;

-- Check if BFF matches exist in regular matches table
SELECT 'BFF in Regular Matches' as check_type, COUNT(*) as count 
FROM matches WHERE id IN (SELECT id FROM bff_matches);

-- Check for orphaned messages (messages without valid match_id)
SELECT 'Orphaned Messages' as check_type, COUNT(*) as count 
FROM messages m 
WHERE m.match_id NOT IN (SELECT id FROM matches);

-- Check specific user matches (replace with your user ID)
-- First, get your user ID:
SELECT 'User IDs' as info, id, name FROM profiles LIMIT 5;

-- Check matches for a specific user (replace 'YOUR_USER_ID' with actual ID)
-- SELECT 'User Matches' as check_type, COUNT(*) as count 
-- FROM matches WHERE user_id_1 = 'YOUR_USER_ID' OR user_id_2 = 'YOUR_USER_ID';

-- Check BFF matches for a specific user (replace 'YOUR_USER_ID' with actual ID)
-- SELECT 'User BFF Matches' as check_type, COUNT(*) as count 
-- FROM bff_matches WHERE user_id_1 = 'YOUR_USER_ID' OR user_id_2 = 'YOUR_USER_ID';

-- Check if there are any matches with specific names (SuperLiker, Emma, SS)
SELECT 'Matches with SuperLiker' as check_type, COUNT(*) as count 
FROM matches m
JOIN profiles p1 ON m.user_id_1 = p1.id
JOIN profiles p2 ON m.user_id_2 = p2.id
WHERE p1.name ILIKE '%superliker%' OR p2.name ILIKE '%superliker%';

SELECT 'Matches with Emma' as check_type, COUNT(*) as count 
FROM matches m
JOIN profiles p1 ON m.user_id_1 = p1.id
JOIN profiles p2 ON m.user_id_2 = p2.id
WHERE p1.name ILIKE '%emma%' OR p2.name ILIKE '%emma%';

SELECT 'Matches with SS' as check_type, COUNT(*) as count 
FROM matches m
JOIN profiles p1 ON m.user_id_1 = p1.id
JOIN profiles p2 ON m.user_id_2 = p2.id
WHERE p1.name ILIKE '%ss%' OR p2.name ILIKE '%ss%';

-- Check BFF matches with specific names
SELECT 'BFF Matches with SS' as check_type, COUNT(*) as count 
FROM bff_matches bm
JOIN profiles p1 ON bm.user_id_1 = p1.id
JOIN profiles p2 ON bm.user_id_2 = p2.id
WHERE p1.name ILIKE '%ss%' OR p2.name ILIKE '%ss%';

-- Check if messages exist for these matches
SELECT 'Messages for SuperLiker matches' as check_type, COUNT(*) as count 
FROM messages m
JOIN matches mt ON m.match_id = mt.id
JOIN profiles p1 ON mt.user_id_1 = p1.id
JOIN profiles p2 ON mt.user_id_2 = p2.id
WHERE p1.name ILIKE '%superliker%' OR p2.name ILIKE '%superliker%';

SELECT 'Messages for Emma matches' as check_type, COUNT(*) as count 
FROM messages m
JOIN matches mt ON m.match_id = mt.id
JOIN profiles p1 ON mt.user_id_1 = p1.id
JOIN profiles p2 ON mt.user_id_2 = p2.id
WHERE p1.name ILIKE '%emma%' OR p2.name ILIKE '%emma%';

SELECT 'Messages for SS matches' as check_type, COUNT(*) as count 
FROM messages m
JOIN matches mt ON m.match_id = mt.id
JOIN profiles p1 ON mt.user_id_1 = p1.id
JOIN profiles p2 ON mt.user_id_2 = p2.id
WHERE p1.name ILIKE '%ss%' OR p2.name ILIKE '%ss%';
