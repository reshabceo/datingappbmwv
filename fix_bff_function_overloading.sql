-- Fix BFF Function Overloading Issue
-- This script fixes the function overloading problem that's preventing BFF interactions from being recorded

-- 1. Drop all existing record_bff_interaction functions to avoid conflicts
DROP FUNCTION IF EXISTS public.record_bff_interaction(UUID, UUID, TEXT);
DROP FUNCTION IF EXISTS public.record_bff_interaction(UUID, UUID, VARCHAR);
DROP FUNCTION IF EXISTS public.record_bff_interaction(UUID, UUID, CHARACTER VARYING);

-- 2. Create a single, clean record_bff_interaction function
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
  -- Validate interaction type (BFF mode only supports 'like' and 'pass')
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
  
  -- Update user's BFF activity counters and timestamps
  UPDATE public.profiles
  SET 
    bff_last_active = NOW(),
    bff_swipes_count = COALESCE(bff_swipes_count, 0) + 1
  WHERE id = p_user_id;
  
  -- Log the interaction for debugging
  RAISE NOTICE 'BFF interaction recorded: user_id=%, target_user_id=%, type=%', 
    p_user_id, p_target_user_id, p_interaction_type;
    
END;
$$;

-- 3. Grant permissions
GRANT EXECUTE ON FUNCTION public.record_bff_interaction(UUID, UUID, TEXT) TO anon, authenticated;

-- 4. Test the function
DO $$
BEGIN
  RAISE NOTICE 'BFF function overloading issue fixed!';
  RAISE NOTICE 'Single record_bff_interaction function created with TEXT parameter type.';
END $$;
