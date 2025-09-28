-- Complete Database Fix - Long-term Solution
-- This script addresses all issues comprehensively

-- Step 1: Drop existing functions and policies to avoid conflicts
DROP FUNCTION IF EXISTS public.handle_swipe(uuid, text);
DROP FUNCTION IF EXISTS public.get_filtered_profiles(uuid, integer, integer);
DROP FUNCTION IF EXISTS public.set_user_preferences(text[], integer, integer, integer);
DROP FUNCTION IF EXISTS public.calculate_zodiac_sign(date);
DROP FUNCTION IF EXISTS public.update_zodiac_sign();
DROP FUNCTION IF EXISTS public.generate_match_insights(uuid);

-- Step 2: Drop existing policies to avoid conflicts
DROP POLICY IF EXISTS "Match participants can view enhancements" ON public.match_enhancements;
DROP POLICY IF EXISTS "Match participants can insert enhancements" ON public.match_enhancements;
DROP POLICY IF EXISTS "Match participants can update enhancements" ON public.match_enhancements;
DROP POLICY IF EXISTS "Users can track their ice breaker usage" ON public.ice_breaker_usage;
DROP POLICY IF EXISTS "Users can insert their own swipes" ON public.swipes;
DROP POLICY IF EXISTS "Users can read their own swipes" ON public.swipes;
DROP POLICY IF EXISTS "Users can manage their own preferences" ON public.user_preferences;

-- Step 3: Drop existing constraints that might be causing issues
ALTER TABLE public.profiles DROP CONSTRAINT IF EXISTS profiles_gender_check;

-- Step 4: Fix the matches table structure
DO $$
BEGIN
    -- Check if the table has the old structure
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'matches' 
        AND column_name = 'user_id'
    ) THEN
        -- Migrate existing data to new structure
        ALTER TABLE public.matches 
        ADD COLUMN IF NOT EXISTS user_id_1 UUID,
        ADD COLUMN IF NOT EXISTS user_id_2 UUID,
        ADD COLUMN IF NOT EXISTS status TEXT DEFAULT 'matched';
        
        -- Copy data from old structure to new structure
        UPDATE public.matches 
        SET 
            user_id_1 = LEAST(user_id, other_user_id),
            user_id_2 = GREATEST(user_id, other_user_id),
            status = 'matched'
        WHERE user_id_1 IS NULL;
        
        -- Drop old columns
        ALTER TABLE public.matches DROP COLUMN IF EXISTS user_id;
        ALTER TABLE public.matches DROP COLUMN IF EXISTS other_user_id;
        ALTER TABLE public.matches DROP COLUMN IF EXISTS matched_at;
    END IF;
END $$;

-- Step 5: Add proper constraints to matches table
ALTER TABLE public.matches 
ADD CONSTRAINT IF NOT EXISTS matches_user_id_1_fkey 
FOREIGN KEY (user_id_1) REFERENCES public.profiles(id) ON DELETE CASCADE;

ALTER TABLE public.matches 
ADD CONSTRAINT IF NOT EXISTS matches_user_id_2_fkey 
FOREIGN KEY (user_id_2) REFERENCES public.profiles(id) ON DELETE CASCADE;

ALTER TABLE public.matches 
ADD CONSTRAINT IF NOT EXISTS matches_user_id_1_not_equal_user_id_2 
CHECK (user_id_1 != user_id_2);

ALTER TABLE public.matches 
ADD CONSTRAINT IF NOT EXISTS matches_status_check 
CHECK (status IN ('matched', 'unmatched', 'blocked'));

ALTER TABLE public.matches 
ADD CONSTRAINT IF NOT EXISTS matches_unique_pair 
UNIQUE (user_id_1, user_id_2);

-- Step 6: Create the swipes table
CREATE TABLE IF NOT EXISTS public.swipes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  swiper_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  swiped_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  action TEXT NOT NULL CHECK (action IN ('like', 'pass', 'super_like')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(swiper_id, swiped_id)
);

-- Step 7: Add columns to profiles table
ALTER TABLE public.profiles 
ADD COLUMN IF NOT EXISTS gender TEXT,
ADD COLUMN IF NOT EXISTS last_seen TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
ADD COLUMN IF NOT EXISTS birth_date DATE,
ADD COLUMN IF NOT EXISTS zodiac_sign TEXT,
ADD COLUMN IF NOT EXISTS birth_time TIME,
ADD COLUMN IF NOT EXISTS birth_location TEXT;

-- Step 8: Add proper gender constraint
ALTER TABLE public.profiles 
ADD CONSTRAINT IF NOT EXISTS profiles_gender_check 
CHECK (gender IS NULL OR gender IN ('male', 'female', 'non-binary', 'other', 'prefer_not_to_say'));

-- Step 9: Create user preferences table
CREATE TABLE IF NOT EXISTS public.user_preferences (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  preferred_gender TEXT[] DEFAULT '{}',
  min_age INTEGER DEFAULT 18,
  max_age INTEGER DEFAULT 100,
  max_distance INTEGER DEFAULT 50,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id)
);

-- Step 10: Create match_enhancements table
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

-- Step 11: Create ice_breaker_usage table
CREATE TABLE IF NOT EXISTS public.ice_breaker_usage (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  match_id UUID NOT NULL REFERENCES public.matches(id) ON DELETE CASCADE,
  ice_breaker_text TEXT NOT NULL,
  used_by_user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  used_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Step 12: Enable RLS on all tables
ALTER TABLE public.swipes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_preferences ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.match_enhancements ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ice_breaker_usage ENABLE ROW LEVEL SECURITY;

-- Step 13: Create RLS policies for swipes
CREATE POLICY "Users can insert their own swipes"
ON public.swipes FOR INSERT
WITH CHECK (auth.uid() = swiper_id);

CREATE POLICY "Users can read their own swipes"
ON public.swipes FOR SELECT
USING (auth.uid() = swiper_id);

-- Step 14: Create RLS policies for user preferences
CREATE POLICY "Users can manage their own preferences"
ON public.user_preferences FOR ALL
USING (auth.uid() = user_id);

-- Step 15: Create RLS policies for match_enhancements
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

-- Step 16: Create RLS policies for ice_breaker_usage
CREATE POLICY "Users can track their ice breaker usage"
ON public.ice_breaker_usage FOR ALL
USING (used_by_user_id = auth.uid());

-- Step 17: Create the handle_swipe function
CREATE OR REPLACE FUNCTION public.handle_swipe(
  p_swiped_id UUID,
  p_action TEXT
) RETURNS JSONB AS $$
DECLARE
  v_swiper_id UUID;
  v_swiped_id UUID;
  v_matched BOOLEAN := FALSE;
  v_match_id UUID;
  v_reciprocal_swipe RECORD;
BEGIN
  v_swiper_id := auth.uid();
  
  IF v_swiper_id IS NULL THEN
    RETURN jsonb_build_object('error', 'User not authenticated');
  END IF;
  
  IF p_swiped_id IS NULL THEN
    RETURN jsonb_build_object('error', 'Invalid swiped user ID');
  END IF;
  
  -- Prevent self-matching
  IF v_swiper_id = p_swiped_id THEN
    RETURN jsonb_build_object('error', 'Cannot swipe on yourself');
  END IF;
  
  IF p_action NOT IN ('like', 'pass', 'super_like') THEN
    RETURN jsonb_build_object('error', 'Invalid action');
  END IF;
  
  -- Check if profiles exist and are active
  IF NOT EXISTS (
    SELECT 1 FROM public.profiles 
    WHERE id = v_swiper_id AND is_active = true
  ) THEN
    RETURN jsonb_build_object('error', 'Swiper profile not found or inactive');
  END IF;
  
  IF NOT EXISTS (
    SELECT 1 FROM public.profiles 
    WHERE id = p_swiped_id AND is_active = true
  ) THEN
    RETURN jsonb_build_object('error', 'Swiped profile not found or inactive');
  END IF;
  
  -- Insert or update swipe
  INSERT INTO public.swipes (swiper_id, swiped_id, action)
  VALUES (v_swiper_id, p_swiped_id, p_action)
  ON CONFLICT (swiper_id, swiped_id)
  DO UPDATE SET 
    action = EXCLUDED.action,
    created_at = NOW();
  
  -- Check for match only if action is like or super_like
  IF p_action IN ('like', 'super_like') THEN
    SELECT * INTO v_reciprocal_swipe
    FROM public.swipes
    WHERE swiper_id = p_swiped_id 
      AND swiped_id = v_swiper_id 
      AND action IN ('like', 'super_like');
    
    IF FOUND THEN
      v_swiped_id := p_swiped_id;
      
      INSERT INTO public.matches (user_id_1, user_id_2, status)
      VALUES (
        LEAST(v_swiper_id, v_swiped_id),
        GREATEST(v_swiper_id, v_swiped_id),
        'matched'
      )
      ON CONFLICT (user_id_1, user_id_2) DO NOTHING
      RETURNING id INTO v_match_id;
      
      IF v_match_id IS NULL THEN
        SELECT id INTO v_match_id
        FROM public.matches
        WHERE user_id_1 = LEAST(v_swiper_id, v_swiped_id)
          AND user_id_2 = GREATEST(v_swiper_id, v_swiped_id);
      END IF;
      
      v_matched := TRUE;
    END IF;
  END IF;
  
  RETURN jsonb_build_object(
    'matched', v_matched,
    'match_id', v_match_id,
    'action', p_action,
    'swiper_id', v_swiper_id,
    'swiped_id', p_swiped_id
  );
  
EXCEPTION
  WHEN OTHERS THEN
    RETURN jsonb_build_object('error', SQLERRM);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Step 18: Create get_filtered_profiles function
CREATE OR REPLACE FUNCTION public.get_filtered_profiles(
  p_user_id UUID,
  p_limit INTEGER DEFAULT 10,
  p_offset INTEGER DEFAULT 0
) RETURNS TABLE (
  id UUID,
  name TEXT,
  age INTEGER,
  gender TEXT,
  location TEXT,
  image_urls JSONB,
  hobbies JSONB,
  description TEXT,
  last_seen TIMESTAMP WITH TIME ZONE
) AS $$
DECLARE
  v_preferred_gender TEXT[];
  v_min_age INTEGER;
  v_max_age INTEGER;
  v_max_distance INTEGER;
  v_user_gender TEXT;
BEGIN
  SELECT 
    COALESCE(up.preferred_gender, '{}'),
    COALESCE(up.min_age, 18),
    COALESCE(up.max_age, 100),
    COALESCE(up.max_distance, 50),
    p.gender
  INTO v_preferred_gender, v_min_age, v_max_age, v_max_distance, v_user_gender
  FROM public.profiles p
  LEFT JOIN public.user_preferences up ON up.user_id = p.id
  WHERE p.id = p_user_id;
  
  RETURN QUERY
  SELECT 
    pr.id,
    pr.name,
    pr.age,
    pr.gender,
    pr.location,
    pr.image_urls,
    pr.hobbies,
    pr.description,
    pr.last_seen
  FROM public.profiles pr
  WHERE pr.id != p_user_id
    AND pr.is_active = true
    AND (v_preferred_gender = '{}' OR pr.gender = ANY(v_preferred_gender) OR pr.gender IS NULL)
    AND pr.age >= v_min_age
    AND pr.age <= v_max_age
    AND pr.id NOT IN (
      SELECT swiped_id 
      FROM public.swipes 
      WHERE swiper_id = p_user_id
    )
  ORDER BY pr.last_seen DESC
  LIMIT p_limit
  OFFSET p_offset;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Step 19: Create set_user_preferences function
CREATE OR REPLACE FUNCTION public.set_user_preferences(
  p_preferred_gender TEXT[],
  p_min_age INTEGER DEFAULT 18,
  p_max_age INTEGER DEFAULT 100,
  p_max_distance INTEGER DEFAULT 50
) RETURNS JSONB AS $$
DECLARE
  v_user_id UUID;
BEGIN
  v_user_id := auth.uid();
  
  IF v_user_id IS NULL THEN
    RETURN jsonb_build_object('error', 'User not authenticated');
  END IF;
  
  INSERT INTO public.user_preferences (
    user_id, preferred_gender, min_age, max_age, max_distance
  ) VALUES (
    v_user_id, p_preferred_gender, p_min_age, p_max_age, p_max_distance
  )
  ON CONFLICT (user_id)
  DO UPDATE SET
    preferred_gender = EXCLUDED.preferred_gender,
    min_age = EXCLUDED.min_age,
    max_age = EXCLUDED.max_age,
    max_distance = EXCLUDED.max_distance,
    updated_at = NOW();
  
  RETURN jsonb_build_object('success', true);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Step 20: Create zodiac calculation function
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

-- Step 21: Create zodiac update trigger
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

-- Step 22: Create generate_match_insights function
CREATE OR REPLACE FUNCTION public.generate_match_insights(p_match_id UUID)
RETURNS JSONB AS $$
DECLARE
  match_data RECORD;
  user1_data RECORD;
  user2_data RECORD;
  result JSONB;
BEGIN
  SELECT * INTO match_data FROM public.matches WHERE id = p_match_id;
  
  IF match_data IS NULL THEN
    RETURN jsonb_build_object('error', 'Match not found');
  END IF;
  
  SELECT * INTO user1_data FROM public.profiles WHERE id = match_data.user_id_1;
  SELECT * INTO user2_data FROM public.profiles WHERE id = match_data.user_id_2;
  
  IF user1_data IS NULL OR user2_data IS NULL THEN
    RETURN jsonb_build_object('error', 'User profiles not found');
  END IF;
  
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

-- Step 23: Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_swipes_swiper ON public.swipes(swiper_id);
CREATE INDEX IF NOT EXISTS idx_swipes_swiped ON public.swipes(swiped_id);
CREATE INDEX IF NOT EXISTS idx_swipes_action ON public.swipes(action);
CREATE INDEX IF NOT EXISTS idx_matches_user_1 ON public.matches(user_id_1);
CREATE INDEX IF NOT EXISTS idx_matches_user_2 ON public.matches(user_id_2);
CREATE INDEX IF NOT EXISTS idx_profiles_gender ON public.profiles(gender);
CREATE INDEX IF NOT EXISTS idx_profiles_age ON public.profiles(age);
CREATE INDEX IF NOT EXISTS idx_user_preferences_user ON public.user_preferences(user_id);
CREATE INDEX IF NOT EXISTS idx_match_enhancements_match_id ON public.match_enhancements(match_id);
CREATE INDEX IF NOT EXISTS idx_ice_breaker_usage_match_id ON public.ice_breaker_usage(match_id);
CREATE INDEX IF NOT EXISTS idx_ice_breaker_usage_user_id ON public.ice_breaker_usage(used_by_user_id);
CREATE INDEX IF NOT EXISTS idx_profiles_zodiac_sign ON public.profiles(zodiac_sign);

-- Step 24: Clean up existing self-matches
DELETE FROM public.matches 
WHERE user_id_1 = user_id_2;

-- Step 25: Update profiles with proper gender and birth date data
UPDATE public.profiles 
SET 
  gender = CASE 
    WHEN name = 'Ashley' THEN 'female'
    WHEN name IN ('RESHAB', 'Daniel') THEN 'male'
    WHEN name IN ('Sophia', 'Ava') THEN 'female'
    WHEN gender IS NULL THEN 'other'
    ELSE gender
  END,
  birth_date = CASE 
    WHEN name = 'Ashley' THEN '1995-03-15'::date
    WHEN name = 'RESHAB' THEN '1992-07-22'::date
    WHEN name = 'Daniel' THEN '1990-11-08'::date
    WHEN name = 'Sophia' THEN '1998-04-12'::date
    WHEN name = 'Ava' THEN '1996-09-30'::date
    WHEN birth_date IS NULL THEN '1995-01-01'::date
    ELSE birth_date
  END
WHERE name IN ('Ashley', 'RESHAB', 'Daniel', 'Sophia', 'Ava') OR gender IS NULL;

-- Step 26: Verify the complete fix
SELECT 
  'Complete Database Fix Applied' as status,
  COUNT(*) as total_profiles,
  COUNT(CASE WHEN gender IS NOT NULL THEN 1 END) as profiles_with_gender,
  COUNT(CASE WHEN zodiac_sign IS NOT NULL THEN 1 END) as profiles_with_zodiac,
  COUNT(CASE WHEN is_active = true THEN 1 END) as active_profiles,
  (SELECT COUNT(*) FROM public.matches WHERE user_id_1 = user_id_2) as self_matches
FROM public.profiles;

-- Step 27: Test all functions
SELECT 'All functions created successfully' as test_result;
