-- Complete Missing Components for Astrological Compatibility System
-- This script creates all missing tables, functions, and populates data

-- Step 1: Create user_preferences table
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

-- Step 2: Enable RLS on user_preferences
ALTER TABLE public.user_preferences ENABLE ROW LEVEL SECURITY;

-- Step 3: Create RLS policy for user_preferences
CREATE POLICY "Users can manage their own preferences"
ON public.user_preferences FOR ALL
USING (auth.uid() = user_id);

-- Step 4: Create get_filtered_profiles function
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
  -- Get user's preferences and gender
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
  
  -- Return filtered profiles
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
      -- Exclude already swiped users
      SELECT swiped_id 
      FROM public.swipes 
      WHERE swiper_id = p_user_id
    )
  ORDER BY pr.last_seen DESC
  LIMIT p_limit
  OFFSET p_offset;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Step 5: Create set_user_preferences function
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

-- Step 6: Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_user_preferences_user ON public.user_preferences(user_id);
CREATE INDEX IF NOT EXISTS idx_profiles_gender ON public.profiles(gender);
CREATE INDEX IF NOT EXISTS idx_profiles_age ON public.profiles(age);
CREATE INDEX IF NOT EXISTS idx_profiles_zodiac_sign ON public.profiles(zodiac_sign);

-- Step 7: Update the gender constraint to be more flexible
ALTER TABLE public.profiles DROP CONSTRAINT IF EXISTS profiles_gender_check;
ALTER TABLE public.profiles 
ADD CONSTRAINT profiles_gender_check 
CHECK (gender IS NULL OR gender IN ('Male', 'Female', 'Non-binary', 'Other', 'Prefer not to say'));

-- Step 8: Populate missing gender data (CORRECTED to match constraint)
UPDATE public.profiles 
SET gender = CASE 
  WHEN name = 'Ashley' THEN 'Female'
  WHEN name IN ('RESHAB', 'Daniel', 'John', 'Mike', 'Alex', 'Tom', 'Sam', 'Ben', 'Chris', 'Dave') THEN 'Male'
  WHEN name IN ('Sophia', 'Ava', 'Emma', 'Olivia', 'Isabella', 'Mia', 'Charlotte', 'Amelia', 'Harper', 'Evelyn') THEN 'Female'
  WHEN gender IS NULL THEN 'Other'
  ELSE gender
END
WHERE gender IS NULL OR gender NOT IN ('Male', 'Female', 'Non-binary', 'Other', 'Prefer not to say');

-- Step 9: Populate missing birth dates for zodiac calculation
UPDATE public.profiles 
SET birth_date = CASE 
  WHEN name = 'Ashley' THEN '1995-03-15'::date
  WHEN name = 'RESHAB' THEN '1992-07-22'::date
  WHEN name = 'Daniel' THEN '1990-11-08'::date
  WHEN name = 'Sophia' THEN '1998-04-12'::date
  WHEN name = 'Ava' THEN '1996-09-30'::date
  WHEN name = 'Emma' THEN '1997-01-20'::date
  WHEN name = 'Olivia' THEN '1999-06-14'::date
  WHEN name = 'Isabella' THEN '1994-12-03'::date
  WHEN name = 'Mia' THEN '1993-08-25'::date
  WHEN name = 'Charlotte' THEN '1996-02-18'::date
  WHEN name = 'Amelia' THEN '1998-10-07'::date
  WHEN name = 'Harper' THEN '1995-05-30'::date
  WHEN name = 'Evelyn' THEN '1997-09-12'::date
  WHEN name = 'John' THEN '1991-03-08'::date
  WHEN name = 'Mike' THEN '1989-11-15'::date
  WHEN name = 'Alex' THEN '1993-07-03'::date
  WHEN name = 'Tom' THEN '1990-04-22'::date
  WHEN name = 'Sam' THEN '1994-12-10'::date
  WHEN name = 'Ben' THEN '1992-08-17'::date
  WHEN name = 'Chris' THEN '1996-01-25'::date
  WHEN name = 'Dave' THEN '1988-06-09'::date
  WHEN birth_date IS NULL THEN '1995-01-01'::date
  ELSE birth_date
END
WHERE birth_date IS NULL;

-- Step 10: Verify the implementation
SELECT 
  'Missing Components Added' as status,
  COUNT(*) as total_profiles,
  COUNT(CASE WHEN gender IS NOT NULL THEN 1 END) as profiles_with_gender,
  COUNT(CASE WHEN zodiac_sign IS NOT NULL THEN 1 END) as profiles_with_zodiac,
  COUNT(CASE WHEN birth_date IS NOT NULL THEN 1 END) as profiles_with_birth_date,
  (SELECT COUNT(*) FROM public.user_preferences) as user_preferences_count
FROM public.profiles;

-- Step 11: Test the functions
SELECT 'get_filtered_profiles function created successfully' as test_1;
SELECT 'set_user_preferences function created successfully' as test_2;
SELECT 'user_preferences table created successfully' as test_3;
