-- Enable BFF mode for your profile
-- This will allow you to see and interact with BFF profiles

UPDATE profiles 
SET mode_preferences = '{"dating": true, "bff": true}',
    bff_enabled_at = NOW()
WHERE id = 'c1ffb3e0-0e25-4176-9736-0db8522fd357';

-- Verify the update
SELECT 
    name,
    mode_preferences,
    bff_enabled_at
FROM profiles 
WHERE id = 'c1ffb3e0-0e25-4176-9736-0db8522fd357';

-- Also check if the dummy profiles were created
SELECT 
    name,
    age,
    location,
    mode_preferences,
    bff_swipes_count
FROM profiles 
WHERE id IN ('11111111-1111-1111-1111-111111111111', '22222222-2222-2222-2222-222222222222', '33333333-3333-3333-3333-333333333333');

-- Check BFF interactions
SELECT 
    p.name as liked_by,
    bi.interaction_type,
    bi.created_at
FROM bff_interactions bi
JOIN profiles p ON bi.user_id = p.id
WHERE bi.target_user_id = 'c1ffb3e0-0e25-4176-9736-0db8522fd357'
ORDER BY bi.created_at DESC;
