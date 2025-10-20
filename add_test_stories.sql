-- Add test stories for superliker (Alex) and SS (Sarah)
-- Based on existing user IDs from add_dummy_bff_profile_corrected.sql

-- 1. Add story for Alex (superliker) - ID: 22222222-2222-2222-2222-222222222222
INSERT INTO stories (
    user_id,
    content,
    media_url,
    media_type,
    expires_at,
    created_at
) VALUES (
    '22222222-2222-2222-2222-222222222222',
    'Just finished an amazing workout! 💪 Who wants to join me for the next one?',
    'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=400',
    'image',
    NOW() + INTERVAL '24 hours',
    NOW() - INTERVAL '2 hours'
);

-- 2. Add another story for Alex (superliker)
INSERT INTO stories (
    user_id,
    content,
    media_url,
    media_type,
    expires_at,
    created_at
) VALUES (
    '22222222-2222-2222-2222-222222222222',
    'Exploring downtown LA today! The city has so much to offer 🌆',
    'https://images.unsplash.com/photo-1449824913935-59a10b8d2000?w=400',
    'image',
    NOW() + INTERVAL '24 hours',
    NOW() - INTERVAL '1 hour'
);

-- 3. Add story for Sarah (SS) - ID: 11111111-1111-1111-1111-111111111111
INSERT INTO stories (
    user_id,
    content,
    media_url,
    media_type,
    expires_at,
    created_at
) VALUES (
    '11111111-1111-1111-1111-111111111111',
    'Coffee date anyone? ☕ Found this amazing new cafe in SF!',
    'https://images.unsplash.com/photo-1501339847302-ac426a4a7cbb?w=400',
    'image',
    NOW() + INTERVAL '24 hours',
    NOW() - INTERVAL '3 hours'
);

-- 4. Add another story for Sarah (SS)
INSERT INTO stories (
    user_id,
    content,
    media_url,
    media_type,
    expires_at,
    created_at
) VALUES (
    '11111111-1111-1111-1111-111111111111',
    'Hiking trail was incredible today! 🥾 Nature never fails to amaze me',
    'https://images.unsplash.com/photo-1551632811-561732d1e306?w=400',
    'image',
    NOW() + INTERVAL '24 hours',
    NOW() - INTERVAL '30 minutes'
);

-- 5. Add story for Emma (third user) for more variety
INSERT INTO stories (
    user_id,
    content,
    media_url,
    media_type,
    expires_at,
    created_at
) VALUES (
    '33333333-3333-3333-3333-333333333333',
    'Book club meeting was so inspiring! 📚 What are you reading?',
    'https://images.unsplash.com/photo-1481627834876-b7833e8f5570?w=400',
    'image',
    NOW() + INTERVAL '24 hours',
    NOW() - INTERVAL '1 hour'
);

-- 6. Add a story for the current user (yourself) to test own stories
INSERT INTO stories (
    user_id,
    content,
    media_url,
    media_type,
    expires_at,
    created_at
) VALUES (
    'c1ffb3e0-0e25-4176-9736-0db8522fd357',
    'Amazing day exploring the city! 🌆',
    'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=400',
    'image',
    NOW() + INTERVAL '24 hours',
    NOW() - INTERVAL '15 minutes'
);

-- 7. Verify the stories were inserted correctly
SELECT 
    s.id,
    s.user_id,
    p.name as user_name,
    s.content,
    s.media_url,
    s.media_type,
    s.created_at,
    s.expires_at
FROM stories s
JOIN profiles p ON s.user_id = p.id
WHERE s.user_id IN (
    '22222222-2222-2222-2222-222222222222',  -- Alex (superliker)
    '11111111-1111-1111-1111-111111111111',  -- Sarah (SS)
    '33333333-3333-3333-3333-333333333333',  -- Emma
    'c1ffb3e0-0e25-4176-9736-0db8522fd357'   -- Current user
)
ORDER BY s.created_at DESC;

-- 8. Check active stories (not expired)
SELECT 
    s.id,
    s.user_id,
    p.name as user_name,
    s.content,
    s.media_url,
    s.media_type,
    s.created_at,
    s.expires_at
FROM stories s
JOIN profiles p ON s.user_id = p.id
WHERE s.expires_at > NOW()
ORDER BY s.created_at DESC;
