-- Check if dummy profiles and interactions exist

-- 1. Check dummy profiles
SELECT 'Dummy Profiles' as check_type, COUNT(*) as count 
FROM profiles 
WHERE id IN ('11111111-1111-1111-1111-111111111111', '22222222-2222-2222-2222-222222222222', '33333333-3333-3333-3333-333333333333');

-- 2. Check BFF interactions
SELECT 'BFF Interactions' as check_type, COUNT(*) as count 
FROM bff_interactions 
WHERE target_user_id = 'c1ffb3e0-0e25-4176-9736-0db8522fd357';

-- 3. List the dummy profiles if they exist
SELECT id, name, age, location, mode_preferences 
FROM profiles 
WHERE id IN ('11111111-1111-1111-1111-111111111111', '22222222-2222-2222-2222-222222222222', '33333333-3333-3333-3333-333333333333');

-- 4. List BFF interactions if they exist
SELECT p.name as liked_by, bi.interaction_type, bi.created_at
FROM bff_interactions bi
JOIN profiles p ON bi.user_id = p.id
WHERE bi.target_user_id = 'c1ffb3e0-0e25-4176-9736-0db8522fd357'
ORDER BY bi.created_at DESC;
