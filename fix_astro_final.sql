-- Consolidated Astrology & Match Insights Fix
-- Run this in your Supabase SQL Editor

-- 1. Ensure profiles have necessary columns
ALTER TABLE public.profiles 
ADD COLUMN IF NOT EXISTS birth_date DATE,
ADD COLUMN IF NOT EXISTS zodiac_sign TEXT,
ADD COLUMN IF NOT EXISTS birth_time TIME,
ADD COLUMN IF NOT EXISTS birth_location TEXT,
ADD COLUMN IF NOT EXISTS gender TEXT,
ADD COLUMN IF NOT EXISTS hobbies TEXT[];

-- 2. Create match_enhancements table
CREATE TABLE IF NOT EXISTS public.match_enhancements (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  match_id UUID NOT NULL,
  astro_compatibility JSONB NOT NULL DEFAULT '{}',
  ice_breakers JSONB NOT NULL DEFAULT '[]',
  generated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  expires_at TIMESTAMP WITH TIME ZONE DEFAULT (NOW() + INTERVAL '30 days'),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(match_id)
);

-- 3. Create ice_breaker_usage table
CREATE TABLE IF NOT EXISTS public.ice_breaker_usage (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  match_id UUID NOT NULL,
  ice_breaker_text TEXT NOT NULL,
  used_by_user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  used_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 4. Enable RLS
ALTER TABLE public.match_enhancements ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ice_breaker_usage ENABLE ROW LEVEL SECURITY;

-- 5. RLS Policies
DROP POLICY IF EXISTS "Match participants can view enhancements" ON public.match_enhancements;
CREATE POLICY "Match participants can view enhancements"
ON public.match_enhancements FOR SELECT
USING (true); -- Simplified for now, can be restricted further if needed

DROP POLICY IF EXISTS "Match participants can insert enhancements" ON public.match_enhancements;
CREATE POLICY "Match participants can insert enhancements"
ON public.match_enhancements FOR INSERT
WITH CHECK (true);

DROP POLICY IF EXISTS "Match participants can update enhancements" ON public.match_enhancements;
CREATE POLICY "Match participants can update enhancements"
ON public.match_enhancements FOR UPDATE
USING (true);

DROP POLICY IF EXISTS "Users can track their ice breaker usage" ON public.ice_breaker_usage;
CREATE POLICY "Users can track their ice breaker usage"
ON public.ice_breaker_usage FOR ALL
USING (used_by_user_id = auth.uid());

-- 6. Zodiac Calculation Function
DROP FUNCTION IF EXISTS public.calculate_zodiac_sign(DATE);
CREATE OR REPLACE FUNCTION public.calculate_zodiac_sign(p_birth_date DATE)
RETURNS TEXT AS $$
BEGIN
  CASE 
    WHEN (EXTRACT(MONTH FROM p_birth_date) = 3 AND EXTRACT(DAY FROM p_birth_date) >= 21) OR
         (EXTRACT(MONTH FROM p_birth_date) = 4 AND EXTRACT(DAY FROM p_birth_date) <= 19) THEN
      RETURN 'aries';
    WHEN (EXTRACT(MONTH FROM p_birth_date) = 4 AND EXTRACT(DAY FROM p_birth_date) >= 20) OR
         (EXTRACT(MONTH FROM p_birth_date) = 5 AND EXTRACT(DAY FROM p_birth_date) <= 20) THEN
      RETURN 'taurus';
    WHEN (EXTRACT(MONTH FROM p_birth_date) = 5 AND EXTRACT(DAY FROM p_birth_date) >= 21) OR
         (EXTRACT(MONTH FROM p_birth_date) = 6 AND EXTRACT(DAY FROM p_birth_date) <= 20) THEN
      RETURN 'gemini';
    WHEN (EXTRACT(MONTH FROM p_birth_date) = 6 AND EXTRACT(DAY FROM p_birth_date) >= 21) OR
         (EXTRACT(MONTH FROM p_birth_date) = 7 AND EXTRACT(DAY FROM p_birth_date) <= 22) THEN
      RETURN 'cancer';
    WHEN (EXTRACT(MONTH FROM p_birth_date) = 7 AND EXTRACT(DAY FROM p_birth_date) >= 23) OR
         (EXTRACT(MONTH FROM p_birth_date) = 8 AND EXTRACT(DAY FROM p_birth_date) <= 22) THEN
      RETURN 'leo';
    WHEN (EXTRACT(MONTH FROM p_birth_date) = 8 AND EXTRACT(DAY FROM p_birth_date) >= 23) OR
         (EXTRACT(MONTH FROM p_birth_date) = 9 AND EXTRACT(DAY FROM p_birth_date) <= 22) THEN
      RETURN 'virgo';
    WHEN (EXTRACT(MONTH FROM p_birth_date) = 9 AND EXTRACT(DAY FROM p_birth_date) >= 23) OR
         (EXTRACT(MONTH FROM p_birth_date) = 10 AND EXTRACT(DAY FROM p_birth_date) <= 22) THEN
      RETURN 'libra';
    WHEN (EXTRACT(MONTH FROM p_birth_date) = 10 AND EXTRACT(DAY FROM p_birth_date) >= 23) OR
         (EXTRACT(MONTH FROM p_birth_date) = 11 AND EXTRACT(DAY FROM p_birth_date) <= 21) THEN
      RETURN 'scorpio';
    WHEN (EXTRACT(MONTH FROM p_birth_date) = 11 AND EXTRACT(DAY FROM p_birth_date) >= 22) OR
         (EXTRACT(MONTH FROM p_birth_date) = 12 AND EXTRACT(DAY FROM p_birth_date) <= 21) THEN
      RETURN 'sagittarius';
    WHEN (EXTRACT(MONTH FROM p_birth_date) = 12 AND EXTRACT(DAY FROM p_birth_date) >= 22) OR
         (EXTRACT(MONTH FROM p_birth_date) = 1 AND EXTRACT(DAY FROM p_birth_date) <= 19) THEN
      RETURN 'capricorn';
    WHEN (EXTRACT(MONTH FROM p_birth_date) = 1 AND EXTRACT(DAY FROM p_birth_date) >= 20) OR
         (EXTRACT(MONTH FROM p_birth_date) = 2 AND EXTRACT(DAY FROM p_birth_date) <= 18) THEN
      RETURN 'aquarius';
    WHEN (EXTRACT(MONTH FROM p_birth_date) = 2 AND EXTRACT(DAY FROM p_birth_date) >= 19) OR
         (EXTRACT(MONTH FROM p_birth_date) = 3 AND EXTRACT(DAY FROM p_birth_date) <= 20) THEN
      RETURN 'pisces';
    ELSE
      RETURN 'unknown';
  END CASE;
END;
$$ LANGUAGE plpgsql;

-- 7. Robust Match Insights Function V4
CREATE OR REPLACE FUNCTION public.generate_match_insights_v4(p_match_id UUID)
RETURNS JSONB AS $$
DECLARE
  u1_id UUID;
  u2_id UUID;
  user1_record RECORD;
  user2_record RECORD;
BEGIN
  -- Search in dating matches
  SELECT user_id_1, user_id_2 INTO u1_id, u2_id FROM public.matches WHERE id = p_match_id;
  
  -- Fallback if columns are user_id / other_user_id
  IF u1_id IS NULL THEN
    SELECT user_id, other_user_id INTO u1_id, u2_id FROM public.matches WHERE id = p_match_id;
  END IF;

  -- Fallback to BFF matches
  IF u1_id IS NULL THEN
    SELECT user_id_1, user_id_2 INTO u1_id, u2_id FROM public.bff_matches WHERE id = p_match_id;
  END IF;

  IF u1_id IS NULL OR u2_id IS NULL THEN
    RETURN jsonb_build_object('success', false, 'error', 'Match not found or participants missing');
  END IF;

  -- Get profile data
  SELECT id, name, age, zodiac_sign, hobbies, location, gender, birth_date INTO user1_record FROM public.profiles WHERE id = u1_id;
  SELECT id, name, age, zodiac_sign, hobbies, location, gender, birth_date INTO user2_record FROM public.profiles WHERE id = u2_id;

  IF user1_record.id IS NULL OR user2_record.id IS NULL THEN
    RETURN jsonb_build_object('success', false, 'error', 'Participant profiles not found');
  END IF;

  -- Auto-heal zodiac if empty
  IF user1_record.zodiac_sign IS NULL AND user1_record.birth_date IS NOT NULL THEN
    user1_record.zodiac_sign := public.calculate_zodiac_sign(user1_record.birth_date);
    UPDATE public.profiles SET zodiac_sign = user1_record.zodiac_sign WHERE id = u1_id;
  END IF;

  IF user2_record.zodiac_sign IS NULL AND user2_record.birth_date IS NOT NULL THEN
    user2_record.zodiac_sign := public.calculate_zodiac_sign(user2_record.birth_date);
    UPDATE public.profiles SET zodiac_sign = user2_record.zodiac_sign WHERE id = u2_id;
  END IF;

  RETURN jsonb_build_object(
    'success', true,
    'user1', jsonb_build_object(
      'id', user1_record.id,
      'name', user1_record.name,
      'age', user1_record.age,
      'zodiac_sign', COALESCE(user1_record.zodiac_sign, 'unknown'),
      'hobbies', COALESCE(to_jsonb(user1_record.hobbies), '[]'::jsonb),
      'location', COALESCE(user1_record.location, 'Earth'),
      'gender', COALESCE(user1_record.gender, 'not specified')
    ),
    'user2', jsonb_build_object(
      'id', user2_record.id,
      'name', user2_record.name,
      'age', user2_record.age,
      'zodiac_sign', COALESCE(user2_record.zodiac_sign, 'unknown'),
      'hobbies', COALESCE(to_jsonb(user2_record.hobbies), '[]'::jsonb),
      'location', COALESCE(user2_record.location, 'Earth'),
      'gender', COALESCE(user2_record.gender, 'not specified')
    )
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 8. Final Grants
GRANT EXECUTE ON FUNCTION public.generate_match_insights_v4(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.generate_match_insights_v4(UUID) TO service_role;
GRANT ALL ON public.match_enhancements TO authenticated;
GRANT ALL ON public.match_enhancements TO service_role;
GRANT ALL ON public.ice_breaker_usage TO authenticated;
GRANT ALL ON public.ice_breaker_usage TO service_role;
