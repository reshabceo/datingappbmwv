-- Create REAL mutual likes for BFF testing
-- This will make some profiles actually "like you back" so you can get matches

-- 1. First, let's see what profiles are available
SELECT 
    'Available BFF Profiles' as status,
    COUNT(*) as count
FROM profiles 
WHERE bff_enabled = true
    AND id != '7ffe44fe-9c0f-4783-aec2-a6172a6e008b';

-- 2. Create REAL mutual likes - some profiles will "like you back"
INSERT INTO bff_interactions (user_id, target_user_id, interaction_type, created_at)
SELECT 
    p.id as user_id,
    '7ffe44fe-9c0f-4783-aec2-a6172a6e008b' as target_user_id,
    'like' as interaction_type,
    NOW() - INTERVAL '2 hours' as created_at
FROM profiles p
WHERE p.bff_enabled = true
    AND p.id != '7ffe44fe-9c0f-4783-aec2-a6172a6e008b'
    AND p.id IN (
        '33333333-3333-3333-3333-333333333333', -- Emma
        '11111111-2222-3333-4444-555555555555', -- Emma (duplicate)
        'c1ffb3e0-0e25-4176-9736-0db8522fd357', -- SS
        'f13c7e7c-27fd-4c3b-a298-4c1848999696'  -- PK
    )
ON CONFLICT (user_id, target_user_id) DO NOTHING;

-- 3. Check the mutual likes created
SELECT 
    'Profiles that liked you back' as status,
    COUNT(*) as count
FROM bff_interactions 
WHERE target_user_id = '7ffe44fe-9c0f-4783-aec2-a6172a6e008b'
    AND interaction_type = 'like';

-- 4. Show which profiles have liked you back
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

-- 5. Check your current interactions
SELECT 
    'Your BFF Interactions' as status,
    COUNT(*) as count
FROM bff_interactions 
WHERE user_id = '7ffe44fe-9c0f-4783-aec2-a6172a6e008b';

-- 6. Show your interactions
SELECT 
    p.name as target_name,
    p.age,
    bi.interaction_type,
    bi.created_at
FROM bff_interactions bi
JOIN profiles p ON p.id = bi.target_user_id
WHERE bi.user_id = '7ffe44fe-9c0f-4783-aec2-a6172a6e008b'
ORDER BY bi.created_at DESC;

-- 7. Final status
DO $$
DECLARE
    mutual_likes INTEGER;
    your_interactions INTEGER;
BEGIN
    SELECT COUNT(*) INTO mutual_likes FROM bff_interactions 
    WHERE target_user_id = '7ffe44fe-9c0f-4783-aec2-a6172a6e008b'
        AND interaction_type = 'like';
    
    SELECT COUNT(*) INTO your_interactions FROM bff_interactions 
    WHERE user_id = '7ffe44fe-9c0f-4783-aec2-a6172a6e008b';
    
    RAISE NOTICE '=== BFF Mutual Likes Setup Complete ===';
    RAISE NOTICE 'Profiles that liked you back: %', mutual_likes;
    RAISE NOTICE 'Your BFF interactions: %', your_interactions;
    RAISE NOTICE 'Now when you swipe right on these profiles, you should get matches!';
    RAISE NOTICE 'Profiles to test: Emma, SS, PK';
END $$;
