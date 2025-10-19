-- Debug BFF Interactions Issue
-- This script will help us understand why BFF interactions aren't being recorded

-- 1. Check if the record_bff_interaction function exists and works
SELECT 
    routine_name,
    routine_type,
    data_type as return_type
FROM information_schema.routines 
WHERE routine_schema = 'public' 
    AND routine_name = 'record_bff_interaction';

-- 2. Check BFF interactions table structure
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_schema = 'public' 
    AND table_name = 'bff_interactions'
ORDER BY ordinal_position;

-- 3. Check current BFF interactions count
SELECT COUNT(*) as total_bff_interactions FROM bff_interactions;

-- 4. Check if there are any BFF interactions at all
SELECT * FROM bff_interactions LIMIT 5;

-- 5. Test the record_bff_interaction function manually
-- Replace with actual user IDs from your app
DO $$
DECLARE
    test_user_id UUID := '7ffe44fe-9c0f-4783-aec2-a6172a6e008b'; -- Your user ID
    test_target_id UUID := 'bcb1c077-1b71-4d78-b30b-717393f65fb7'; -- SuperLiker ID
BEGIN
    -- Try to record a test interaction
    BEGIN
        PERFORM record_bff_interaction(test_user_id, test_target_id, 'like');
        RAISE NOTICE 'SUCCESS: BFF interaction recorded successfully';
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE 'ERROR: Failed to record BFF interaction: %', SQLERRM;
    END;
END $$;

-- 6. Check if the function was called
SELECT COUNT(*) as interactions_after_test FROM bff_interactions;

-- 7. Check RLS policies on bff_interactions table
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd
FROM pg_policies 
WHERE schemaname = 'public'
    AND tablename = 'bff_interactions'
ORDER BY policyname;

-- 8. Check if the table has RLS enabled
SELECT 
    schemaname,
    tablename,
    rowsecurity
FROM pg_tables 
WHERE schemaname = 'public'
    AND tablename = 'bff_interactions';
