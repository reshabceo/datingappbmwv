-- Fix Flame Chat Database Trigger
-- This updates the old trigger to work with the new flame_started_at/flame_expires_at system

-- Step 1: Drop the old trigger
DROP TRIGGER IF EXISTS trg_enforce_flame_window ON public.messages;

-- Step 2: Update the function to use flame_expires_at instead of created_at
CREATE OR REPLACE FUNCTION public.enforce_flame_window()
RETURNS TRIGGER AS $$
DECLARE
  v_flame_expires_at timestamptz;
  ok boolean := false;
BEGIN
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
    -- NEW: Check flame_expires_at instead of created_at
    -- This ensures we use the flame window that starts when chat is opened
    IF now() <= v_flame_expires_at THEN
      ok := true;
    END IF;
  END IF;
  
  -- Allow if chat was extended (premium feature)
  IF EXISTS(SELECT 1 FROM public.chat_extensions WHERE match_id = new.match_id) THEN
    ok := true;
  END IF;
  
  IF NOT ok THEN
    RAISE EXCEPTION 'FlameChat expired - time window has ended. Upgrade to continue chatting.';
  END IF;
  
  RETURN new;
END;
$$ LANGUAGE plpgsql;

-- Step 3: Recreate the trigger
CREATE TRIGGER trg_enforce_flame_window
BEFORE INSERT ON public.messages
FOR EACH ROW 
EXECUTE FUNCTION public.enforce_flame_window();

-- Verification: Check if trigger exists
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_trigger 
    WHERE tgname = 'trg_enforce_flame_window'
  ) THEN
    RAISE NOTICE '✅ Trigger trg_enforce_flame_window created successfully';
  ELSE
    RAISE EXCEPTION '❌ Trigger creation failed';
  END IF;
END $$;

