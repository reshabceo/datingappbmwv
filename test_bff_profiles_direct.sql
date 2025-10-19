-- Test BFF profiles query directly without using the function
-- This will help us see what data we have

-- 1. Check if BFF interactions table exists and has data
SELECT 'BFF Interactions Count' as check_type, COUNT(*) as count FROM bff_interactions;

-- 2. Check if dummy profiles were created
SELECT 'Dummy Profiles Count' as check_type, COUNT(*) as count 
FROM profiles 
WHERE id IN ('11111111-1111-1111-1111-111111111111', '22222222-2222-2222-2222-222222222222', '33333333-3333-3333-3333-333333333333');

-- 3. Check your profile's BFF mode status
SELECT 'Your Profile BFF Status' as check_type, name, mode_preferences, bff_enabled_at
FROM profiles 
WHERE id = 'c1ffb3e0-0e25-4176-9736-0db8522fd357';

-- 4. Check BFF interactions for your user
SELECT 'BFF Interactions for You' as check_type, 
       p.name as liked_by,
       bi.interaction_type,
       bi.created_at
FROM bff_interactions bi
JOIN profiles p ON bi.user_id = p.id
WHERE bi.target_user_id = 'c1ffb3e0-0e25-4176-9736-0db8522fd357'
ORDER BY bi.created_at DESC;

-- 5. Direct query to get BFF profiles (without function)
SELECT
    p.id,
    p.name,
    p.age,
    p.photos,
    p.location,
    p.description,
    p.hobbies,
    EXISTS(
        SELECT 1 FROM bff_interactions bi
        WHERE bi.user_id = 'c1ffb3e0-0e25-4176-9736-0db8522fd357'
        AND bi.target_user_id = p.id
        AND bi.interaction_type = 'super_like'
    ) as is_super_liked,
    p.bff_swipes_count,
    p.bff_last_active
FROM profiles p
WHERE p.id != 'c1ffb3e0-0e25-4176-9736-0db8522fd357'
AND p.mode_preferences->>'bff' = 'true'
AND p.bff_swipes_count > 0
AND p.id NOT IN (
    SELECT target_user_id
    FROM bff_interactions
    WHERE user_id = 'c1ffb3e0-0e25-4176-9736-0db8522fd357'
)
ORDER BY p.bff_last_active DESC NULLS LAST;
