-- Debug the matching issue between reshab and friend
-- Run these queries in Supabase SQL Editor

-- 1. Check if there are ANY swipes between you and your friend
SELECT 
    s.id,
    s.swiper_id,
    s.swiped_id,
    s.action,
    s.created_at,
    p1.name as swiper_name,
    p1.email as swiper_email,
    p2.name as swiped_name,
    p2.email as swiped_email
FROM swipes s
JOIN profiles p1 ON s.swiper_id = p1.id
JOIN profiles p2 ON s.swiped_id = p2.id
WHERE 
    (s.swiper_id = '7ffe44fe-9c0f-4783-aec2-a6172a6e008b' AND s.swiped_id = 'ea063754-8298-4a2b-a74a-58ee274e2dcb')
    OR
    (s.swiper_id = 'ea063754-8298-4a2b-a74a-58ee274e2dcb' AND s.swiped_id = '7ffe44fe-9c0f-4783-aec2-a6172a6e008b')
ORDER BY s.created_at DESC;

-- 2. Check if there are ANY matches between you and your friend
SELECT 
    m.id,
    m.user_id_1,
    m.user_id_2,
    m.status,
    m.created_at,
    p1.name as user1_name,
    p1.email as user1_email,
    p2.name as user2_name,
    p2.email as user2_email
FROM matches m
JOIN profiles p1 ON m.user_id_1 = p1.id
JOIN profiles p2 ON m.user_id_2 = p2.id
WHERE 
    (m.user_id_1 = '7ffe44fe-9c0f-4783-aec2-a6172a6e008b' AND m.user_id_2 = 'ea063754-8298-4a2b-a74a-58ee274e2dcb')
    OR
    (m.user_id_1 = 'ea063754-8298-4a2b-a74a-58ee274e2dcb' AND m.user_id_2 = '7ffe44fe-9c0f-4783-aec2-a6172a6e008b')
ORDER BY m.created_at DESC;

-- 3. Check ALL swipes made by reshab (you on iPhone)
SELECT 
    s.id,
    s.swiped_id,
    s.action,
    s.created_at,
    p.name as swiped_name,
    p.email as swiped_email
FROM swipes s
LEFT JOIN profiles p ON s.swiped_id = p.id
WHERE s.swiper_id = '7ffe44fe-9c0f-4783-aec2-a6172a6e008b'
ORDER BY s.created_at DESC;

-- 4. Check ALL swipes made by friend (kavinanup on Android)
SELECT 
    s.id,
    s.swiped_id,
    s.action,
    s.created_at,
    p.name as swiped_name,
    p.email as swiped_email
FROM swipes s
LEFT JOIN profiles p ON s.swiped_id = p.id
WHERE s.swiper_id = 'ea063754-8298-4a2b-a74a-58ee274e2dcb'
ORDER BY s.created_at DESC;

-- 5. Check the profiles are active and not blocked
SELECT 
    id,
    name,
    email,
    is_active,
    created_at
FROM profiles
WHERE id IN ('7ffe44fe-9c0f-4783-aec2-a6172a6e008b', 'ea063754-8298-4a2b-a74a-58ee274e2dcb');

-- 6. Check for any BFF interactions (in case mode confusion)
SELECT 
    bi.id,
    bi.user_id,
    bi.target_user_id,
    bi.action,
    bi.created_at,
    p1.name as user_name,
    p1.email as user_email,
    p2.name as target_name,
    p2.email as target_email
FROM bff_interactions bi
JOIN profiles p1 ON bi.user_id = p1.id
JOIN profiles p2 ON bi.target_user_id = p2.id
WHERE 
    (bi.user_id = '7ffe44fe-9c0f-4783-aec2-a6172a6e008b' AND bi.target_user_id = 'ea063754-8298-4a2b-a74a-58ee274e2dcb')
    OR
    (bi.user_id = 'ea063754-8298-4a2b-a74a-58ee274e2dcb' AND bi.target_user_id = '7ffe44fe-9c0f-4783-aec2-a6172a6e008b')
ORDER BY bi.created_at DESC;

-- 7. Check for any BFF matches
SELECT 
    bm.id,
    bm.user_id_1,
    bm.user_id_2,
    bm.status,
    bm.created_at,
    p1.name as user1_name,
    p1.email as user1_email,
    p2.name as user2_name,
    p2.email as user2_email
FROM bff_matches bm
JOIN profiles p1 ON bm.user_id_1 = p1.id
JOIN profiles p2 ON bm.user_id_2 = p2.id
WHERE 
    (bm.user_id_1 = '7ffe44fe-9c0f-4783-aec2-a6172a6e008b' AND bm.user_id_2 = 'ea063754-8298-4a2b-a74a-58ee274e2dcb')
    OR
    (bm.user_id_1 = 'ea063754-8298-4a2b-a74a-58ee274e2dcb' AND bm.user_id_2 = '7ffe44fe-9c0f-4783-aec2-a6172a6e008b')
ORDER BY bm.created_at DESC;

