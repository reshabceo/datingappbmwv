-- Create the missing record_bff_interaction RPC function
-- This function records BFF interactions and updates user activity

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
