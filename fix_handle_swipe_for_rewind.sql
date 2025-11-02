-- Fix handle_swipe function to set can_rewind=true for premium users
-- This ensures that swipes are marked as rewindable when created

-- First, let's see the current function signature
-- We need to update it to set can_rewind=true for premium users

DO $$
BEGIN
  -- Check if handle_swipe function exists and update it
  IF EXISTS (
    SELECT 1 FROM pg_proc 
    WHERE proname = 'handle_swipe' 
    AND pronamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public')
  ) THEN
    RAISE NOTICE 'Updating handle_swipe function to support rewind...';
  ELSE
    RAISE NOTICE 'handle_swipe function does not exist. Creating it...';
  END IF;
END $$;

-- Create or replace handle_swipe with can_rewind support
-- Note: This is a simplified version. If your handle_swipe function has more logic,
-- you'll need to merge this carefully or update it manually.

-- For now, let's create a trigger that automatically sets can_rewind=true for premium users
CREATE OR REPLACE FUNCTION public.set_can_rewind_on_swipe()
RETURNS TRIGGER
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
DECLARE
  v_is_premium BOOLEAN;
BEGIN
  -- Check if the swiper is premium
  SELECT is_premium INTO v_is_premium
  FROM profiles
  WHERE id = NEW.swiper_id;
  
  -- Set can_rewind=true for premium users
  IF v_is_premium = true THEN
    NEW.can_rewind := true;
  ELSE
    NEW.can_rewind := false;
  END IF;
  
  RETURN NEW;
END;
$$;

-- Drop trigger if it exists and recreate it
DROP TRIGGER IF EXISTS trg_set_can_rewind_on_swipe ON public.swipes;

CREATE TRIGGER trg_set_can_rewind_on_swipe
BEFORE INSERT ON public.swipes
FOR EACH ROW
EXECUTE FUNCTION public.set_can_rewind_on_swipe();

-- Also update existing swipes for premium users (optional - for existing data)
DO $$
DECLARE
  v_updated_count INTEGER;
BEGIN
  -- Set can_rewind=true for all swipes by premium users that haven't been rewound
  UPDATE public.swipes s
  SET can_rewind = true
  FROM public.profiles p
  WHERE s.swiper_id = p.id
    AND p.is_premium = true
    AND (s.can_rewind IS NULL OR s.can_rewind = false)
    AND s.rewinded_at IS NULL;
  
  GET DIAGNOSTICS v_updated_count = ROW_COUNT;
  RAISE NOTICE 'Updated % swipes to be rewindable for premium users', v_updated_count;
END $$;

-- Verify the trigger is created
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_trigger 
    WHERE tgname = 'trg_set_can_rewind_on_swipe'
    AND tgrelid = 'public.swipes'::regclass
  ) THEN
    RAISE NOTICE '✅ Trigger trg_set_can_rewind_on_swipe created successfully';
  ELSE
    RAISE NOTICE '❌ Trigger trg_set_can_rewind_on_swipe was not created';
  END IF;
END $$;

