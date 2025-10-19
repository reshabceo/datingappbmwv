-- Debug why dummy BFF profiles aren't showing up

-- 1. Check if dummy profiles exist
SELECT 'Dummy Profiles Check' as debug_type, 
       id, name, age, mode_preferences, bff_swipes_count, bff_enabled_at
FROM profiles 
WHERE id IN ('11111111-1111-1111-1111-111111111111', '22222222-2222-2222-2222-222222222222', '33333333-3333-3333-3333-333333333333');

-- 2. Check all profiles with BFF mode enabled
SELECT 'All BFF Enabled Profiles' as debug_type,
       id, name, age, mode_preferences, bff_swipes_count, bff_enabled_at
FROM profiles 
WHERE mode_preferences->>'bff' = 'true';

-- 3. Check BFF interactions
SELECT 'BFF Interactions' as debug_type,
       COUNT(*) as total_interactions
FROM bff_interactions;

-- 4. Test the get_bff_profiles function directly
SELECT 'BFF Function Test' as debug_type,
       *
FROM get_bff_profiles('c1ffb3e0-0e25-4176-9736-0db8522fd357');

-- 5. Check your current user ID (from the logs)
SELECT 'Your Profile' as debug_type,
       id, name, mode_preferences, bff_enabled_at
FROM profiles 
WHERE id = 'c1ffb3e0-0e25-4176-9736-0db8522fd357';
