-- Create BFF Mutual Likes for Testing
-- This will make some profiles "like you back" so you can test the matching feature

-- Your user ID: 7ffe44fe-9c0f-4783-aec2-a6172a6e008b

-- 1. First, let's see what BFF profiles are available
SELECT 
    'Available BFF Profiles' as status,
    COUNT(*) as count
FROM profiles 
WHERE bff_enabled = true
    AND id != '7ffe44fe-9c0f-4783-aec2-a6172a6e008b';

-- 2. Show the available BFF profiles
SELECT 
    id,
    name,
    age,
    bff_enabled
FROM profiles 
WHERE bff_enabled = true
    AND id != '7ffe44fe-9c0f-4783-aec2-a6172a6e008b'
ORDER BY name;

-- 3. Create mutual likes - make some profiles "like you back"
INSERT INTO bff_interactions (user_id, target_user_id, interaction_type, created_at)
SELECT 
    p.id as user_id,
    '7ffe44fe-9c0f-4783-aec2-a6172a6e008b' as target_user_id,
    'like' as interaction_type,
    NOW() - INTERVAL '1 hour' as created_at
FROM profiles p
WHERE p.bff_enabled = true
    AND p.id != '7ffe44fe-9c0f-4783-aec2-a6172a6e008b'
    AND p.id IN (
        'f13c7e7c-27fd-4c3b-a298-4c1848999696', -- PK
        'c1ffb3e0-0e25-4176-9736-0db8522fd357', -- SS
        'ec79c6b0-9fe6-4a58-be3a-4bf64c0d3565'  -- Viz
    )
ON CONFLICT (user_id, target_user_id) DO NOTHING;

-- 4. Check the mutual likes created
SELECT 
    'Profiles that liked you back' as status,
    COUNT(*) as count
FROM bff_interactions 
WHERE target_user_id = '7ffe44fe-9c0f-4783-aec2-a6172a6e008b'
    AND interaction_type = 'like';

-- 5. Show which profiles have liked you back
SELECT 
    p.name,
    p.age,
    bi.interaction_type,
    bi.created_at as liked_at
FROM bff_interactions bi
JOIN profiles p ON p.id = bi.user_id
WHERE bi.target_user_id = '7ffe44fe-9c0f-4783-aec2-a6172a6e008b'
    AND bi.interaction_type = 'like'
ORDER BY bi.created_at DESC;

-- 6. Check your current BFF interactions (what you've swiped)
SELECT 
    'Your BFF Interactions' as status,
    COUNT(*) as count
FROM bff_interactions 
WHERE user_id = '7ffe44fe-9c0f-4783-aec2-a6172a6e008b';

-- 7. Show your interactions
SELECT 
    p.name as target_name,
    p.age,
    bi.interaction_type,
    bi.created_at as swiped_at
FROM bff_interactions bi
JOIN profiles p ON p.id = bi.target_user_id
WHERE bi.user_id = '7ffe44fe-9c0f-4783-aec2-a6172a6e008b'
ORDER BY bi.created_at DESC;

-- 8. Check for potential matches (mutual likes)
SELECT 
    'Potential BFF matches (mutual likes)' as status,
    COUNT(*) as count
FROM bff_interactions bi1
JOIN bff_interactions bi2 ON bi1.user_id = bi2.target_user_id 
    AND bi1.target_user_id = bi2.user_id
WHERE bi1.user_id = '7ffe44fe-9c0f-4783-aec2-a6172a6e008b'
    AND bi1.interaction_type = 'like'
    AND bi2.interaction_type = 'like';

-- 9. Show mutual likes details
SELECT 
    p.name,
    p.age,
    bi1.created_at as you_liked_them_at,
    bi2.created_at as they_liked_you_at
FROM bff_interactions bi1
JOIN bff_interactions bi2 ON bi1.user_id = bi2.target_user_id 
    AND bi1.target_user_id = bi2.user_id
JOIN profiles p ON p.id = bi1.target_user_id
WHERE bi1.user_id = '7ffe44fe-9c0f-4783-aec2-a6172a6e008b'
    AND bi1.interaction_type = 'like'
    AND bi2.interaction_type = 'like'
ORDER BY bi2.created_at DESC;

-- 10. Final status and instructions
DO $$
DECLARE
    liked_you_count INTEGER;
    your_swipes_count INTEGER;
    mutual_likes_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO liked_you_count FROM bff_interactions 
    WHERE target_user_id = '7ffe44fe-9c0f-4783-aec2-a6172a6e008b'
        AND interaction_type = 'like';
    
    SELECT COUNT(*) INTO your_swipes_count FROM bff_interactions 
    WHERE user_id = '7ffe44fe-9c0f-4783-aec2-a6172a6e008b';
    
    SELECT COUNT(*) INTO mutual_likes_count FROM bff_interactions bi1
    JOIN bff_interactions bi2 ON bi1.user_id = bi2.target_user_id 
        AND bi1.target_user_id = bi2.user_id
    WHERE bi1.user_id = '7ffe44fe-9c0f-4783-aec2-a6172a6e008b'
        AND bi1.interaction_type = 'like'
        AND bi2.interaction_type = 'like';
    
    RAISE NOTICE '=== BFF MUTUAL LIKES SETUP COMPLETE ===';
    RAISE NOTICE 'Profiles that liked you back: %', liked_you_count;
    RAISE NOTICE 'Your BFF swipes: %', your_swipes_count;
    RAISE NOTICE 'Mutual likes: %', mutual_likes_count;
    
    IF mutual_likes_count > 0 THEN
        RAISE NOTICE '✅ Perfect! You have mutual likes.';
        RAISE NOTICE '📱 Now go to your app:';
        RAISE NOTICE '   1. Switch to BFF mode';
        RAISE NOTICE '   2. Swipe RIGHT on PK, SS, or Viz';
        RAISE NOTICE '   3. You should get a match! 🎉';
    ELSE
        RAISE NOTICE '⚠️  No mutual likes yet.';
        RAISE NOTICE 'You need to swipe right on PK, SS, or Viz first.';
        RAISE NOTICE 'Then they will have liked you back!';
    END IF;
END $$;
