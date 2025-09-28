-- Astrological Compatibility & Ice Breakers Migration
-- This script adds all necessary tables and columns for the new features

-- Step 1: Add astrological fields to profiles table
ALTER TABLE public.profiles 
ADD COLUMN IF NOT EXISTS birth_date DATE,
ADD COLUMN IF NOT EXISTS zodiac_sign TEXT,
ADD COLUMN IF NOT EXISTS gender TEXT,
ADD COLUMN IF NOT EXISTS last_seen TIMESTAMP WITH TIME ZONE DEFAULT NOW();

-- Step 2: Create match_enhancements table for storing AI-generated content
CREATE TABLE IF NOT EXISTS public.match_enhancements (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  match_id UUID NOT NULL REFERENCES public.matches(id) ON DELETE CASCADE,
  astro_compatibility JSONB NOT NULL DEFAULT '{}',
  ice_breakers JSONB NOT NULL DEFAULT '[]',
  generated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  expires_at TIMESTAMP WITH TIME ZONE DEFAULT (NOW() + INTERVAL '30 days'),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(match_id)
);

-- Step 3: Create ice_breaker_usage table for tracking used ice breakers
CREATE TABLE IF NOT EXISTS public.ice_breaker_usage (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  match_id UUID NOT NULL REFERENCES public.matches(id) ON DELETE CASCADE,
  ice_breaker_text TEXT NOT NULL,
  used_by_user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  used_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Step 4: Enable RLS on new tables
ALTER TABLE public.match_enhancements ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ice_breaker_usage ENABLE ROW LEVEL SECURITY;

-- Step 5: Create RLS policies for match_enhancements
CREATE POLICY "Match participants can view enhancements"
ON public.match_enhancements FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM public.matches 
    WHERE matches.id = match_enhancements.match_id 
    AND (matches.user_id_1 = auth.uid() OR matches.user_id_2 = auth.uid())
  )
);

CREATE POLICY "Match participants can insert enhancements"
ON public.match_enhancements FOR INSERT
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.matches 
    WHERE matches.id = match_enhancements.match_id 
    AND (matches.user_id_1 = auth.uid() OR matches.user_id_2 = auth.uid())
  )
);

CREATE POLICY "Match participants can update enhancements"
ON public.match_enhancements FOR UPDATE
USING (
  EXISTS (
    SELECT 1 FROM public.matches 
    WHERE matches.id = match_enhancements.match_id 
    AND (matches.user_id_1 = auth.uid() OR matches.user_id_2 = auth.uid())
  )
);

-- Step 6: Create RLS policies for ice_breaker_usage
CREATE POLICY "Users can track their ice breaker usage"
ON public.ice_breaker_usage FOR ALL
USING (used_by_user_id = auth.uid());

-- Step 7: Create function to calculate zodiac sign from birth date
CREATE OR REPLACE FUNCTION public.calculate_zodiac_sign(birth_date DATE)
RETURNS TEXT AS $$
BEGIN
  CASE 
    WHEN (EXTRACT(MONTH FROM birth_date) = 3 AND EXTRACT(DAY FROM birth_date) >= 21) OR
         (EXTRACT(MONTH FROM birth_date) = 4 AND EXTRACT(DAY FROM birth_date) <= 19) THEN
      RETURN 'aries';
    WHEN (EXTRACT(MONTH FROM birth_date) = 4 AND EXTRACT(DAY FROM birth_date) >= 20) OR
         (EXTRACT(MONTH FROM birth_date) = 5 AND EXTRACT(DAY FROM birth_date) <= 20) THEN
      RETURN 'taurus';
    WHEN (EXTRACT(MONTH FROM birth_date) = 5 AND EXTRACT(DAY FROM birth_date) >= 21) OR
         (EXTRACT(MONTH FROM birth_date) = 6 AND EXTRACT(DAY FROM birth_date) <= 20) THEN
      RETURN 'gemini';
    WHEN (EXTRACT(MONTH FROM birth_date) = 6 AND EXTRACT(DAY FROM birth_date) >= 21) OR
         (EXTRACT(MONTH FROM birth_date) = 7 AND EXTRACT(DAY FROM birth_date) <= 22) THEN
      RETURN 'cancer';
    WHEN (EXTRACT(MONTH FROM birth_date) = 7 AND EXTRACT(DAY FROM birth_date) >= 23) OR
         (EXTRACT(MONTH FROM birth_date) = 8 AND EXTRACT(DAY FROM birth_date) <= 22) THEN
      RETURN 'leo';
    WHEN (EXTRACT(MONTH FROM birth_date) = 8 AND EXTRACT(DAY FROM birth_date) >= 23) OR
         (EXTRACT(MONTH FROM birth_date) = 9 AND EXTRACT(DAY FROM birth_date) <= 22) THEN
      RETURN 'virgo';
    WHEN (EXTRACT(MONTH FROM birth_date) = 9 AND EXTRACT(DAY FROM birth_date) >= 23) OR
         (EXTRACT(MONTH FROM birth_date) = 10 AND EXTRACT(DAY FROM birth_date) <= 22) THEN
      RETURN 'libra';
    WHEN (EXTRACT(MONTH FROM birth_date) = 10 AND EXTRACT(DAY FROM birth_date) >= 23) OR
         (EXTRACT(MONTH FROM birth_date) = 11 AND EXTRACT(DAY FROM birth_date) <= 21) THEN
      RETURN 'scorpio';
    WHEN (EXTRACT(MONTH FROM birth_date) = 11 AND EXTRACT(DAY FROM birth_date) >= 22) OR
         (EXTRACT(MONTH FROM birth_date) = 12 AND EXTRACT(DAY FROM birth_date) <= 21) THEN
      RETURN 'sagittarius';
    WHEN (EXTRACT(MONTH FROM birth_date) = 12 AND EXTRACT(DAY FROM birth_date) >= 22) OR
         (EXTRACT(MONTH FROM birth_date) = 1 AND EXTRACT(DAY FROM birth_date) <= 19) THEN
      RETURN 'capricorn';
    WHEN (EXTRACT(MONTH FROM birth_date) = 1 AND EXTRACT(DAY FROM birth_date) >= 20) OR
         (EXTRACT(MONTH FROM birth_date) = 2 AND EXTRACT(DAY FROM birth_date) <= 18) THEN
      RETURN 'aquarius';
    WHEN (EXTRACT(MONTH FROM birth_date) = 2 AND EXTRACT(DAY FROM birth_date) >= 19) OR
         (EXTRACT(MONTH FROM birth_date) = 3 AND EXTRACT(DAY FROM birth_date) <= 20) THEN
      RETURN 'pisces';
    ELSE
      RETURN 'unknown';
  END CASE;
END;
$$ LANGUAGE plpgsql;

-- Step 8: Create trigger to auto-calculate zodiac sign when birth_date is updated
CREATE OR REPLACE FUNCTION public.update_zodiac_sign()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.birth_date IS NOT NULL AND (OLD.birth_date IS NULL OR NEW.birth_date != OLD.birth_date) THEN
    NEW.zodiac_sign = public.calculate_zodiac_sign(NEW.birth_date);
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_update_zodiac_sign ON public.profiles;
CREATE TRIGGER trg_update_zodiac_sign
  BEFORE INSERT OR UPDATE ON public.profiles
  FOR EACH ROW
  EXECUTE FUNCTION public.update_zodiac_sign();

-- Step 9: Create function to generate match insights (will be called from edge function)
CREATE OR REPLACE FUNCTION public.generate_match_insights(p_match_id UUID)
RETURNS JSONB AS $$
DECLARE
  match_data RECORD;
  user1_data RECORD;
  user2_data RECORD;
  result JSONB;
BEGIN
  -- Get match data
  SELECT * INTO match_data FROM public.matches WHERE id = p_match_id;
  
  IF match_data IS NULL THEN
    RETURN jsonb_build_object('error', 'Match not found');
  END IF;
  
  -- Get user profiles
  SELECT * INTO user1_data FROM public.profiles WHERE id = match_data.user_id_1;
  SELECT * INTO user2_data FROM public.profiles WHERE id = match_data.user_id_2;
  
  IF user1_data IS NULL OR user2_data IS NULL THEN
    RETURN jsonb_build_object('error', 'User profiles not found');
  END IF;
  
  -- Return user data for edge function processing
  result := jsonb_build_object(
    'match_id', p_match_id,
    'user1', jsonb_build_object(
      'id', user1_data.id,
      'name', user1_data.name,
      'age', user1_data.age,
      'zodiac_sign', user1_data.zodiac_sign,
      'hobbies', user1_data.hobbies,
      'location', user1_data.location,
      'gender', user1_data.gender
    ),
    'user2', jsonb_build_object(
      'id', user2_data.id,
      'name', user2_data.name,
      'age', user2_data.age,
      'zodiac_sign', user2_data.zodiac_sign,
      'hobbies', user2_data.hobbies,
      'location', user2_data.location,
      'gender', user2_data.gender
    )
  );
  
  RETURN result;
END;
$$ LANGUAGE plpgsql;

-- Step 10: Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_match_enhancements_match_id ON public.match_enhancements(match_id);
CREATE INDEX IF NOT EXISTS idx_ice_breaker_usage_match_id ON public.ice_breaker_usage(match_id);
CREATE INDEX IF NOT EXISTS idx_ice_breaker_usage_user_id ON public.ice_breaker_usage(used_by_user_id);
CREATE INDEX IF NOT EXISTS idx_profiles_zodiac_sign ON public.profiles(zodiac_sign);
CREATE INDEX IF NOT EXISTS idx_profiles_gender ON public.profiles(gender);

-- Step 11: Update existing profiles with sample data (for testing)
-- This will be run after the migration to populate some test data
UPDATE public.profiles 
SET 
  gender = CASE 
    WHEN name = 'Ashley' THEN 'female'
    WHEN name IN ('RESHAB', 'Daniel') THEN 'male'
    ELSE 'other'
  END,
  birth_date = CASE 
    WHEN name = 'Ashley' THEN '1995-03-15'::date
    WHEN name = 'RESHAB' THEN '1992-07-22'::date
    WHEN name = 'Daniel' THEN '1990-11-08'::date
    WHEN name = 'Sophia' THEN '1998-04-12'::date
    WHEN name = 'Ava' THEN '1996-09-30'::date
    ELSE '1995-01-01'::date
  END
WHERE name IN ('Ashley', 'RESHAB', 'Daniel', 'Sophia', 'Ava');

-- Step 12: Verify the migration
SELECT 
  'Migration Complete' as status,
  COUNT(*) as total_profiles,
  COUNT(CASE WHEN zodiac_sign IS NOT NULL THEN 1 END) as profiles_with_zodiac,
  COUNT(CASE WHEN gender IS NOT NULL THEN 1 END) as profiles_with_gender
FROM public.profiles;
