-- Add Ghost Mode feature to profiles table
-- This allows users to become invisible for 24 hours

-- Add ghost mode columns to profiles table
ALTER TABLE public.profiles 
ADD COLUMN IF NOT EXISTS is_ghost_mode BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS ghost_mode_activated_at TIMESTAMP WITH TIME ZONE,
ADD COLUMN IF NOT EXISTS ghost_mode_expires_at TIMESTAMP WITH TIME ZONE;

-- Create index for efficient queries
CREATE INDEX IF NOT EXISTS idx_profiles_ghost_mode 
ON public.profiles(is_ghost_mode, ghost_mode_expires_at) 
WHERE is_ghost_mode = TRUE;

-- Create a function to automatically deactivate ghost mode after 24 hours
CREATE OR REPLACE FUNCTION public.check_and_deactivate_ghost_mode()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Deactivate ghost mode for users whose expiry time has passed
  UPDATE public.profiles
  SET 
    is_ghost_mode = FALSE,
    ghost_mode_activated_at = NULL,
    ghost_mode_expires_at = NULL,
    updated_at = NOW()
  WHERE 
    is_ghost_mode = TRUE 
    AND ghost_mode_expires_at IS NOT NULL
    AND ghost_mode_expires_at < NOW();
END;
$$;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION public.check_and_deactivate_ghost_mode() TO authenticated, anon;

-- Create a function to activate ghost mode
CREATE OR REPLACE FUNCTION public.activate_ghost_mode(p_user_id UUID)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_expires_at TIMESTAMP WITH TIME ZONE;
BEGIN
  -- Calculate expiry time (24 hours from now)
  v_expires_at := NOW() + INTERVAL '24 hours';
  
  -- Update profile with ghost mode activated
  UPDATE public.profiles
  SET 
    is_ghost_mode = TRUE,
    ghost_mode_activated_at = NOW(),
    ghost_mode_expires_at = v_expires_at,
    updated_at = NOW()
  WHERE id = p_user_id;
  
  -- Return status
  RETURN jsonb_build_object(
    'success', TRUE,
    'is_ghost_mode', TRUE,
    'activated_at', NOW(),
    'expires_at', v_expires_at
  );
END;
$$;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION public.activate_ghost_mode(UUID) TO authenticated, anon;

-- Create a function to deactivate ghost mode
CREATE OR REPLACE FUNCTION public.deactivate_ghost_mode(p_user_id UUID)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Deactivate ghost mode
  UPDATE public.profiles
  SET 
    is_ghost_mode = FALSE,
    ghost_mode_activated_at = NULL,
    ghost_mode_expires_at = NULL,
    updated_at = NOW()
  WHERE id = p_user_id;
  
  -- Return status
  RETURN jsonb_build_object(
    'success', TRUE,
    'is_ghost_mode', FALSE,
    'message', 'Ghost mode deactivated'
  );
END;
$$;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION public.deactivate_ghost_mode(UUID) TO authenticated, anon;

-- Create a function to get ghost mode status
CREATE OR REPLACE FUNCTION public.get_ghost_mode_status(p_user_id UUID)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_result jsonb;
BEGIN
  SELECT jsonb_build_object(
    'is_ghost_mode', COALESCE(is_ghost_mode, FALSE),
    'activated_at', ghost_mode_activated_at,
    'expires_at', ghost_mode_expires_at,
    'is_expired', CASE 
      WHEN ghost_mode_expires_at IS NOT NULL AND ghost_mode_expires_at < NOW() 
      THEN TRUE 
      ELSE FALSE 
    END,
    'remaining_hours', CASE
      WHEN ghost_mode_expires_at IS NOT NULL AND ghost_mode_expires_at > NOW()
      THEN EXTRACT(EPOCH FROM (ghost_mode_expires_at - NOW())) / 3600
      ELSE 0
    END
  )
  INTO v_result
  FROM public.profiles
  WHERE id = p_user_id;
  
  RETURN COALESCE(v_result, jsonb_build_object(
    'is_ghost_mode', FALSE,
    'activated_at', NULL,
    'expires_at', NULL,
    'is_expired', FALSE,
    'remaining_hours', 0
  ));
END;
$$;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION public.get_ghost_mode_status(UUID) TO authenticated, anon;

