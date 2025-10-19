-- Debug the actual BFF state to see what's really happening

-- 1. Check if the test interactions were created
SELECT 
    'Test Interactions Created' as status,
    COUNT(*) as count
FROM bff_interactions 
WHERE target_user_id = '7ffe44fe-9c0f-4783-aec2-a6172a6e008b'
    AND interaction_type = 'like';

-- 2. Show which profiles have liked you back
SELECT 
    p.name,
    p.age,
    bi.interaction_type,
    bi.created_at
FROM bff_interactions bi
JOIN profiles p ON p.id = bi.user_id
WHERE bi.target_user_id = '7ffe44fe-9c0f-4783-aec2-a6172a6e008b'
    AND bi.interaction_type = 'like'
ORDER BY bi.created_at DESC;

-- 3. Check your BFF interactions (what you've swiped)
SELECT 
    'Your BFF Interactions' as status,
    COUNT(*) as count
FROM bff_interactions 
WHERE user_id = '7ffe44fe-9c0f-4783-aec2-a6172a6e008b';

-- 4. Show your interactions
SELECT 
    p.name as target_name,
    p.age,
    bi.interaction_type,
    bi.created_at
FROM bff_interactions bi
JOIN profiles p ON p.id = bi.target_user_id
WHERE bi.user_id = '7ffe44fe-9c0f-4783-aec2-a6172a6e008b'
ORDER BY bi.created_at DESC;

-- 5. Check BFF matches
SELECT 
    'BFF Matches' as status,
    COUNT(*) as count
FROM bff_matches 
WHERE (user_id_1 = '7ffe44fe-9c0f-4783-aec2-a6172a6e008b' OR user_id_2 = '7ffe44fe-9c0f-4783-aec2-a6172a6e008b');

-- 6. Show matches
SELECT 
    bm.user_id_1,
    bm.user_id_2,
    p1.name as user_1_name,
    p2.name as user_2_name,
    bm.status,
    bm.created_at
FROM bff_matches bm
LEFT JOIN profiles p1 ON p1.id = bm.user_id_1
LEFT JOIN profiles p2 ON p2.id = bm.user_id_2
WHERE (bm.user_id_1 = '7ffe44fe-9c0f-4783-aec2-a6172a6e008b' OR bm.user_id_2 = '7ffe44fe-9c0f-4783-aec2-a6172a6e008b')
ORDER BY bm.created_at DESC;

-- 7. Check available profiles for swiping
SELECT 
    'Available BFF Profiles' as status,
    COUNT(*) as count
FROM get_bff_profiles('7ffe44fe-9c0f-4783-aec2-a6172a6e008b');

-- 8. Show available profiles
SELECT 
    id,
    name,
    age,
    bff_enabled,
    created_at
FROM get_bff_profiles('7ffe44fe-9c0f-4783-aec2-a6172a6e008b')
ORDER BY created_at DESC
LIMIT 5;
