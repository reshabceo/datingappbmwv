-- Fix Flame Chat Trigger to Allow Premium Users
-- Premium users should be able to send messages even after flame chat expires

-- Step 1: Drop the existing trigger
DROP TRIGGER IF EXISTS trg_enforce_flame_window ON public.messages;

-- Step 2: Update the function to check premium status
CREATE OR REPLACE FUNCTION public.enforce_flame_window()
RETURNS TRIGGER AS $$
DECLARE
  v_flame_expires_at timestamptz;
  v_sender_id UUID;
  v_is_premium BOOLEAN;
  ok boolean := false;
BEGIN
  -- Get the sender's user ID from the message
  v_sender_id := new.sender_id;
  
  -- If no sender_id, deny (shouldn't happen in normal flow)
  IF v_sender_id IS NULL THEN
    RAISE EXCEPTION 'Sender ID is required';
  END IF;
  
  -- Check if sender is premium - premium users bypass flame chat restriction
  SELECT is_premium INTO v_is_premium
  FROM public.profiles
  WHERE id = v_sender_id;
  
  -- Handle case where profile might not exist
  IF v_is_premium IS NULL THEN
    v_is_premium := false;
  END IF;
  
  -- Premium users can always send messages
  IF v_is_premium = true THEN
    ok := true;
  ELSE
    -- For free users, enforce flame chat window
    -- Check dating matches for flame_expires_at
    SELECT flame_expires_at INTO v_flame_expires_at
    FROM public.matches 
    WHERE id = new.match_id
    LIMIT 1;
    
    -- If not found in dating matches, check BFF matches
    IF v_flame_expires_at IS NULL THEN
      SELECT flame_expires_at INTO v_flame_expires_at
      FROM public.bff_matches 
      WHERE id = new.match_id
      LIMIT 1;
    END IF;
    
    -- If still null, match doesn't exist (or columns not set yet)
    IF v_flame_expires_at IS NULL THEN
      -- Allow message if match exists (first message might trigger flame)
      IF EXISTS (SELECT 1 FROM public.matches WHERE id = new.match_id)
         OR EXISTS (SELECT 1 FROM public.bff_matches WHERE id = new.match_id) THEN
        ok := true;
      ELSE
        RAISE EXCEPTION 'Match not found';
      END IF;
    ELSE
      -- Check if flame chat window is still active
      IF now() <= v_flame_expires_at THEN
        ok := true;
      END IF;
    END IF;
    
    -- Allow if chat was extended (premium feature)
    IF EXISTS(SELECT 1 FROM public.chat_extensions WHERE match_id = new.match_id) THEN
      ok := true;
    END IF;
  END IF;
  
  IF NOT ok THEN
    RAISE EXCEPTION 'FlameChat expired - time window has ended. Upgrade to continue chatting.';
  END IF;
  
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Step 3: Recreate the trigger
CREATE TRIGGER trg_enforce_flame_window
BEFORE INSERT ON public.messages
FOR EACH ROW 
EXECUTE FUNCTION public.enforce_flame_window();

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION public.enforce_flame_window() TO authenticated;

-- Verification: Check if trigger exists
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_trigger 
    WHERE tgname = 'trg_enforce_flame_window'
  ) THEN
    RAISE NOTICE '✅ Trigger trg_enforce_flame_window updated successfully';
    RAISE NOTICE '   Premium users can now send messages after flame chat expires';
  ELSE
    RAISE EXCEPTION '❌ Trigger creation failed';
  END IF;
END $$;

