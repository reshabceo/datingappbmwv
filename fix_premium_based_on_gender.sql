-- Fix premium status based on gender
-- Run this in Supabase SQL Editor

-- Create or replace function to set is_premium based on gender
CREATE OR REPLACE FUNCTION set_premium_based_on_gender()
RETURNS TRIGGER AS $$
BEGIN
  -- If gender is 'Female' (case-insensitive), set is_premium to true
  -- Otherwise, set is_premium to false (only if not a paid subscription)
  -- Note: We preserve paid subscriptions by checking premium_until
  IF LOWER(NEW.gender) = 'female' THEN
    NEW.is_premium = true;
  ELSIF NEW.premium_until IS NULL THEN
    -- Only set to false if they don't have a paid subscription
    NEW.is_premium = false;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to automatically update is_premium when gender changes
DROP TRIGGER IF EXISTS trigger_set_premium_on_gender_update ON public.profiles;
CREATE TRIGGER trigger_set_premium_on_gender_update
  BEFORE INSERT OR UPDATE OF gender ON public.profiles
  FOR EACH ROW
  EXECUTE FUNCTION set_premium_based_on_gender();

-- Update existing profiles to fix any incorrect premium status
-- Set is_premium = true for all Female users
UPDATE public.profiles
SET is_premium = true
WHERE LOWER(gender) = 'female' AND is_premium = false;

-- Set is_premium = false for non-Female users (only if no paid subscription)
UPDATE public.profiles
SET is_premium = false
WHERE LOWER(gender) != 'female' 
  AND is_premium = true 
  AND premium_until IS NULL;

