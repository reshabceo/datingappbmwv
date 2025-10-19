-- PHASE 1: Verify Data State
-- Check PK's mutual like status and available BFF profiles

-- 1. Check who has liked you back in BFF mode
SELECT 
    'WHO LIKED YOU BACK' as check_type,
    p.name,
    p.age,
    bi.created_at as they_liked_you_at
FROM bff_interactions bi
JOIN profiles p ON p.id = bi.user_id
WHERE bi.target_user_id = '7ffe44fe-9c0f-4783-aec2-a6172a6e008b'
    AND bi.interaction_type = 'like'
ORDER BY bi.created_at DESC;

-- 2. Check your BFF interactions (who you have liked/passed)
SELECT 
    'WHO YOU LIKED' as check_type,
    p.name as target_name,
    p.age,
    bi.interaction_type,
    bi.created_at as you_interacted_at
FROM bff_interactions bi
JOIN profiles p ON p.id = bi.target_user_id
WHERE bi.user_id = '7ffe44fe-9c0f-4783-aec2-a6172a6e008b'
ORDER BY bi.created_at DESC;

-- 3. Check for potential BFF matches (mutual likes)
SELECT 
    'POTENTIAL BFF MATCHES' as check_type,
    p.name,
    p.age,
    your_like.created_at as you_liked_them_at,
    their_like.created_at as they_liked_you_at
FROM bff_interactions your_like
JOIN bff_interactions their_like
    ON your_like.user_id = their_like.target_user_id
    AND your_like.target_user_id = their_like.user_id
JOIN profiles p ON p.id = your_like.target_user_id
WHERE your_like.user_id = '7ffe44fe-9c0f-4783-aec2-a6172a6e008b'
    AND your_like.interaction_type = 'like'
    AND their_like.interaction_type = 'like';

-- 4. Check existing BFF matches
SELECT 
    'EXISTING BFF MATCHES' as check_type,
    p1.name as user_1_name,
    p2.name as user_2_name,
    bm.status,
    bm.created_at
FROM bff_matches bm
JOIN profiles p1 ON p1.id = bm.user_id_1
JOIN profiles p2 ON p2.id = bm.user_id_2
WHERE (bm.user_id_1 = '7ffe44fe-9c0f-4783-aec2-a6172a6e008b' OR bm.user_id_2 = '7ffe44fe-9c0f-4783-aec2-a6172a6e008b')
    AND bm.status IN ('matched', 'active');

-- 5. Test get_bff_profiles function to see what profiles are available
SELECT 
    'AVAILABLE BFF PROFILES' as check_type,
    id,
    name,
    age,
    location,
    bff_enabled
FROM get_bff_profiles('7ffe44fe-9c0f-4783-aec2-a6172a6e008b')
ORDER BY id DESC
LIMIT 10;

-- 6. Check all BFF-enabled profiles in the database
SELECT 
    'ALL BFF ENABLED PROFILES' as check_type,
    p.id,
    p.name,
    p.age,
    p.bff_enabled,
    p.is_active,
    CASE 
        WHEN EXISTS(SELECT 1 FROM bff_interactions bi WHERE bi.user_id = '7ffe44fe-9c0f-4783-aec2-a6172a6e008b' AND bi.target_user_id = p.id)
        THEN 'You interacted with them'
        ELSE 'No interaction'
    END as interaction_status
FROM profiles p
WHERE p.bff_enabled = true
    AND p.id != '7ffe44fe-9c0f-4783-aec2-a6172a6e008b'
ORDER BY p.created_at DESC;
