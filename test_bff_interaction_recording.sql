-- Test BFF interaction recording directly
-- This will help us understand why interactions aren't being recorded

-- 1. Test the record_bff_interaction function directly
DO $$
DECLARE
    test_user_id UUID := '7ffe44fe-9c0f-4783-aec2-a6172a6e008b';
    test_target_id UUID := '33333333-3333-3333-3333-333333333333'; -- Emma
BEGIN
    -- Try to record a test interaction
    BEGIN
        PERFORM record_bff_interaction(test_user_id, test_target_id, 'like');
        RAISE NOTICE 'SUCCESS: BFF interaction recorded successfully';
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE 'ERROR: Failed to record BFF interaction: %', SQLERRM;
    END;
END $$;

-- 2. Check if the interaction was recorded
SELECT 
    'Interactions after test' as status,
    COUNT(*) as count
FROM bff_interactions 
WHERE user_id = '7ffe44fe-9c0f-4783-aec2-a6172a6e008b';

-- 3. Show the interaction
SELECT 
    p.name as target_name,
    bi.interaction_type,
    bi.created_at
FROM bff_interactions bi
JOIN profiles p ON p.id = bi.target_user_id
WHERE bi.user_id = '7ffe44fe-9c0f-4783-aec2-a6172a6e008b'
ORDER BY bi.created_at DESC;

-- 4. Check if the function exists and works
SELECT 
    routine_name,
    routine_type,
    data_type as return_type
FROM information_schema.routines 
WHERE routine_schema = 'public' 
    AND routine_name = 'record_bff_interaction';

-- 5. Test with a different approach
INSERT INTO bff_interactions (user_id, target_user_id, interaction_type, created_at)
VALUES (
    '7ffe44fe-9c0f-4783-aec2-a6172a6e008b',
    '33333333-3333-3333-3333-333333333333',
    'like',
    NOW()
)
ON CONFLICT (user_id, target_user_id) DO NOTHING;

-- 6. Check if the direct insert worked
SELECT 
    'Direct insert test' as status,
    COUNT(*) as count
FROM bff_interactions 
WHERE user_id = '7ffe44fe-9c0f-4783-aec2-a6172a6e008b';

-- 7. Final status
DO $$
BEGIN
  RAISE NOTICE '=== BFF Interaction Recording Test Complete ===';
  RAISE NOTICE 'Check the results above to see if interactions are being recorded';
  RAISE NOTICE 'If the function test fails, there is a database issue';
  RAISE NOTICE 'If the direct insert works, the function has a problem';
END $$;
