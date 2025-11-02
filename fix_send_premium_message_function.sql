-- Fix send_premium_message function to ensure it works correctly
-- This script recreates the function with the correct parameter order

DROP FUNCTION IF EXISTS public.send_premium_message(UUID, TEXT);
DROP FUNCTION IF EXISTS public.send_premium_message(TEXT, UUID);

-- Recreate the function with explicit parameter names and order
CREATE OR REPLACE FUNCTION public.send_premium_message(
  p_recipient_id UUID,
  p_message_content TEXT
) RETURNS JSONB
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
DECLARE
  v_sender_id UUID;
  v_is_premium BOOLEAN;
  v_message_id UUID;
BEGIN
  -- Get current user
  v_sender_id := auth.uid();
  
  IF v_sender_id IS NULL THEN
    RETURN jsonb_build_object('error', 'User not authenticated');
  END IF;
  
  -- Check if sender is premium
  SELECT is_premium INTO v_is_premium
  FROM profiles
  WHERE id = v_sender_id;
  
  IF v_is_premium != true THEN
    RETURN jsonb_build_object(
      'error', 'Premium subscription required to send messages before matching',
      'requires_premium', true
    );
  END IF;
  
  -- Insert premium message
  INSERT INTO premium_messages (sender_id, recipient_id, message_content)
  VALUES (v_sender_id, p_recipient_id, p_message_content)
  RETURNING id INTO v_message_id;
  
  -- Create activity feed entry for recipient (if activity system exists)
  -- This is optional - comment out if user_events table doesn't exist
  BEGIN
    INSERT INTO user_events (
      event_type,
      event_data,
      user_id,
      timestamp
    ) VALUES (
      'premium_message_received',
      jsonb_build_object(
        'sender_id', v_sender_id,
        'message_preview', LEFT(p_message_content, 50),
        'is_blurred', true
      ),
      p_recipient_id,
      NOW()
    );
  EXCEPTION
    WHEN undefined_table THEN
      -- user_events table doesn't exist, skip this
      NULL;
    WHEN OTHERS THEN
      -- Ignore other errors in activity tracking
      NULL;
  END;
  
  RETURN jsonb_build_object(
    'success', true,
    'message_id', v_message_id
  );
END;
$$;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION public.send_premium_message(UUID, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.send_premium_message(UUID, TEXT) TO anon;

-- Verify the function exists
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_proc 
    WHERE proname = 'send_premium_message' 
    AND pronamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public')
  ) THEN
    RAISE NOTICE '✅ Function send_premium_message created successfully';
    RAISE NOTICE '   Parameters: p_recipient_id (UUID), p_message_content (TEXT)';
  ELSE
    RAISE NOTICE '❌ Function send_premium_message was not created';
  END IF;
END $$;

