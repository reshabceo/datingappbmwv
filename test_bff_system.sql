-- Test BFF System Functionality
-- This script tests the BFF system to ensure it's working correctly

-- 1. Check if BFF functions exist
SELECT 
    routine_name,
    routine_type,
    data_type as return_type
FROM information_schema.routines 
WHERE routine_schema = 'public' 
    AND routine_name IN ('get_bff_profiles', 'get_filtered_profiles', 'record_bff_interaction')
ORDER BY routine_name;

-- 2. Check BFF table structures
SELECT 
    table_name,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_schema = 'public' 
    AND table_name IN ('bff_interactions', 'bff_matches')
ORDER BY table_name, ordinal_position;

-- 3. Check if profiles have BFF columns
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_schema = 'public' 
    AND table_name = 'profiles'
    AND column_name LIKE '%bff%'
ORDER BY ordinal_position;

-- 4. Test get_bff_profiles function (replace with actual user ID)
-- SELECT * FROM get_bff_profiles('your-user-id-here');

-- 5. Check BFF interactions count
SELECT 
    'BFF Interactions' as table_name,
    COUNT(*) as row_count
FROM bff_interactions
UNION ALL
SELECT 
    'BFF Matches' as table_name,
    COUNT(*) as row_count
FROM bff_matches
UNION ALL
SELECT 
    'Profiles with BFF enabled' as table_name,
    COUNT(*) as row_count
FROM profiles 
WHERE bff_enabled = true;

-- 6. Check RLS policies
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd
FROM pg_policies 
WHERE schemaname = 'public'
    AND tablename IN ('bff_interactions', 'bff_matches')
ORDER BY tablename, policyname;

-- 7. Check indexes
SELECT 
    schemaname,
    tablename,
    indexname,
    indexdef
FROM pg_indexes 
WHERE schemaname = 'public'
    AND (indexname LIKE '%bff%' OR tablename IN ('bff_interactions', 'bff_matches'))
ORDER BY tablename, indexname;

-- 8. Test record_bff_interaction function (replace with actual user IDs)
-- SELECT record_bff_interaction('user-id-1', 'user-id-2', 'like');

-- 9. Check if triggers exist
SELECT 
    trigger_name,
    event_manipulation,
    event_object_table,
    action_timing
FROM information_schema.triggers 
WHERE trigger_schema = 'public'
    AND trigger_name LIKE '%bff%'
ORDER BY event_object_table, trigger_name;

-- 10. Summary report
DO $$
DECLARE
    bff_profiles_count INTEGER;
    bff_interactions_count INTEGER;
    bff_matches_count INTEGER;
    profiles_with_bff INTEGER;
BEGIN
    -- Get counts
    SELECT COUNT(*) INTO bff_profiles_count FROM profiles WHERE bff_enabled = true;
    SELECT COUNT(*) INTO bff_interactions_count FROM bff_interactions;
    SELECT COUNT(*) INTO bff_matches_count FROM bff_matches;
    SELECT COUNT(*) INTO profiles_with_bff FROM profiles WHERE bff_enabled = true;
    
    RAISE NOTICE '=== BFF System Status Report ===';
    RAISE NOTICE 'Profiles with BFF enabled: %', profiles_with_bff;
    RAISE NOTICE 'BFF interactions recorded: %', bff_interactions_count;
    RAISE NOTICE 'BFF matches created: %', bff_matches_count;
    
    IF profiles_with_bff = 0 THEN
        RAISE NOTICE 'WARNING: No profiles have BFF enabled! Users need to enable BFF mode.';
    END IF;
    
    IF bff_interactions_count = 0 THEN
        RAISE NOTICE 'INFO: No BFF interactions recorded yet.';
    END IF;
    
    IF bff_matches_count = 0 THEN
        RAISE NOTICE 'INFO: No BFF matches created yet.';
    END IF;
    
    RAISE NOTICE '=== End Report ===';
END $$;
