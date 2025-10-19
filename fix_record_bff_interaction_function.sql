-- Fix the record_bff_interaction function
-- The function is failing silently, so let's create a working version

-- 1. Drop the existing function
DROP FUNCTION IF EXISTS public.record_bff_interaction(UUID, UUID, TEXT);

-- 2. Create a working version with proper error handling
CREATE OR REPLACE FUNCTION public.record_bff_interaction(
  p_user_id UUID,
  p_target_user_id UUID,
  p_interaction_type TEXT
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Validate input parameters
  IF p_user_id IS NULL THEN
    RAISE EXCEPTION 'User ID cannot be null';
  END IF;
  
  IF p_target_user_id IS NULL THEN
    RAISE EXCEPTION 'Target user ID cannot be null';
  END IF;
  
  IF p_interaction_type IS NULL THEN
    RAISE EXCEPTION 'Interaction type cannot be null';
  END IF;
  
  -- Validate interaction type
  IF p_interaction_type NOT IN ('like', 'pass') THEN
    RAISE EXCEPTION 'Invalid BFF interaction type: %', p_interaction_type;
  END IF;
  
  -- Record the BFF interaction
  INSERT INTO public.bff_interactions (
    user_id,
    target_user_id,
    interaction_type,
    created_at
  ) VALUES (
    p_user_id,
    p_target_user_id,
    p_interaction_type,
    NOW()
  )
  ON CONFLICT (user_id, target_user_id) 
  DO UPDATE SET 
    interaction_type = EXCLUDED.interaction_type,
    created_at = NOW();
  
  -- Update user's BFF activity counters
  UPDATE public.profiles
  SET 
    bff_last_active = NOW(),
    bff_swipes_count = COALESCE(bff_swipes_count, 0) + 1
  WHERE id = p_user_id;
  
  -- Log success
  RAISE NOTICE 'BFF interaction recorded: user_id=%, target_user_id=%, type=%', 
    p_user_id, p_target_user_id, p_interaction_type;
    
END;
$$;

-- 3. Grant permissions
GRANT EXECUTE ON FUNCTION public.record_bff_interaction(UUID, UUID, TEXT) TO anon, authenticated;

-- 4. Test the function
DO $$
DECLARE
    test_user_id UUID := '7ffe44fe-9c0f-4783-aec2-a6172a6e008b';
    test_target_id UUID := 'f13c7e7c-27fd-4c3b-a298-4c1848999696'; -- PK
BEGIN
    -- Try to record a test interaction
    BEGIN
        PERFORM record_bff_interaction(test_user_id, test_target_id, 'like');
        RAISE NOTICE 'SUCCESS: BFF interaction function works correctly';
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE 'ERROR: BFF interaction function failed: %', SQLERRM;
    END;
END $$;

-- 5. Check if the interaction was recorded
SELECT 
    'Interactions after function test' as status,
    COUNT(*) as count
FROM bff_interactions 
WHERE user_id = '7ffe44fe-9c0f-4783-aec2-a6172a6e008b';

-- 6. Show the interaction
SELECT 
    p.name as target_name,
    bi.interaction_type,
    bi.created_at
FROM bff_interactions bi
JOIN profiles p ON p.id = bi.target_user_id
WHERE bi.user_id = '7ffe44fe-9c0f-4783-aec2-a6172a6e008b'
ORDER BY bi.created_at DESC;

-- 7. Final status
DO $$
BEGIN
  RAISE NOTICE '=== BFF Interaction Function Fixed ===';
  RAISE NOTICE 'Function should now work correctly';
  RAISE NOTICE 'BFF interactions should be recorded properly';
  RAISE NOTICE 'Test the app now - interactions should be recorded!';
END $$;
