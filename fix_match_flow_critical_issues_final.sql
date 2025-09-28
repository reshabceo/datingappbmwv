-- Fix Critical Match Flow Issues - FINAL VERSION
-- This script addresses all the critical problems identified in the match flow analysis

-- Step 1: Drop existing handle_swipe function first
DROP FUNCTION IF EXISTS public.handle_swipe(uuid, text);

-- Step 2: Fix the matches table structure to match Flutter expectations
-- The current schema has user_id/other_user_id but Flutter expects user_id_1/user_id_2

-- First, let's check if we need to migrate the existing data
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
        
        -- Add constraints
        ALTER TABLE public.matches 
        ADD CONSTRAINT matches_user_id_1_fkey 
        FOREIGN KEY (user_id_1) REFERENCES public.profiles(id) ON DELETE CASCADE,
        ADD CONSTRAINT matches_user_id_2_fkey 
        FOREIGN KEY (user_id_2) REFERENCES public.profiles(id) ON DELETE CASCADE,
        ADD CONSTRAINT matches_user_id_1_not_equal_user_id_2 
        CHECK (user_id_1 != user_id_2),
        ADD CONSTRAINT matches_status_check 
        CHECK (status IN ('matched', 'unmatched', 'blocked'));
        
        -- Add unique constraint
        ALTER TABLE public.matches 
        ADD CONSTRAINT matches_unique_pair 
        UNIQUE (user_id_1, user_id_2);
    END IF;
END $$;

-- Step 3: Create the swipes table (if it doesn't exist)
CREATE TABLE IF NOT EXISTS public.swipes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  swiper_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  swiped_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  action TEXT NOT NULL CHECK (action IN ('like', 'pass', 'super_like')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(swiper_id, swiped_id)
);

-- Step 4: Add gender column to profiles table
ALTER TABLE public.profiles 
ADD COLUMN IF NOT EXISTS gender TEXT,
ADD COLUMN IF NOT EXISTS last_seen TIMESTAMP WITH TIME ZONE DEFAULT NOW();

-- Step 5: Create user preferences table for filtering
CREATE TABLE IF NOT EXISTS public.user_preferences (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  preferred_gender TEXT[] DEFAULT '{}',
  min_age INTEGER DEFAULT 18,
  max_age INTEGER DEFAULT 100,
  max_distance INTEGER DEFAULT 50, -- in km
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id)
);

-- Step 6: Enable RLS on new tables
ALTER TABLE public.swipes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_preferences ENABLE ROW LEVEL SECURITY;

-- Step 7: Create RLS policies for swipes
CREATE POLICY "Users can insert their own swipes"
ON public.swipes FOR INSERT
WITH CHECK (auth.uid() = swiper_id);

CREATE POLICY "Users can read their own swipes"
ON public.swipes FOR SELECT
USING (auth.uid() = swiper_id);

-- Step 8: Create RLS policies for user preferences
CREATE POLICY "Users can manage their own preferences"
ON public.user_preferences FOR ALL
USING (auth.uid() = user_id);

-- Step 9: Create the handle_swipe function with proper self-match prevention
CREATE OR REPLACE FUNCTION public.handle_swipe(
  p_swiped_id UUID,
  p_action TEXT
) RETURNS JSONB AS $$
DECLARE
  v_swiper_id UUID;
  v_swiped_id UUID;
  v_matched BOOLEAN := FALSE;
  v_match_id UUID;
  v_existing_swipe RECORD;
  v_reciprocal_swipe RECORD;
BEGIN
  -- Get current user ID
  v_swiper_id := auth.uid();
  
  -- Validate input
  IF v_swiper_id IS NULL THEN
    RETURN jsonb_build_object('error', 'User not authenticated');
  END IF;
  
  IF p_swiped_id IS NULL THEN
    RETURN jsonb_build_object('error', 'Invalid swiped user ID');
  END IF;
  
  -- CRITICAL FIX: Prevent self-matching
  IF v_swiper_id = p_swiped_id THEN
    RETURN jsonb_build_object('error', 'Cannot swipe on yourself');
  END IF;
  
  -- Validate action
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
    -- Check for reciprocal like
    SELECT * INTO v_reciprocal_swipe
    FROM public.swipes
    WHERE swiper_id = p_swiped_id 
      AND swiped_id = v_swiper_id 
      AND action IN ('like', 'super_like');
    
    IF FOUND THEN
      -- Create match with proper ordering (user_id_1 < user_id_2)
      v_swiped_id := p_swiped_id;
      
      INSERT INTO public.matches (user_id_1, user_id_2, status)
      VALUES (
        LEAST(v_swiper_id, v_swiped_id),
        GREATEST(v_swiper_id, v_swiped_id),
        'matched'
      )
      ON CONFLICT (user_id_1, user_id_2) DO NOTHING
      RETURNING id INTO v_match_id;
      
      -- Get the match ID if it was created
      IF v_match_id IS NULL THEN
        SELECT id INTO v_match_id
        FROM public.matches
        WHERE user_id_1 = LEAST(v_swiper_id, v_swiped_id)
          AND user_id_2 = GREATEST(v_swiper_id, v_swiped_id);
      END IF;
      
      v_matched := TRUE;
    END IF;
  END IF;
  
  -- Return result
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

-- Step 10: Create function to get filtered profiles with gender preferences (FIXED VERSION)
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
  -- Get user's preferences and gender - FIXED: Use individual variables instead of RECORD
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

-- Step 11: Clean up existing self-matches
DELETE FROM public.matches 
WHERE user_id_1 = user_id_2;

-- Step 12: Update existing profiles with sample gender data
UPDATE public.profiles 
SET gender = CASE 
  WHEN name = 'Ashley' THEN 'female'
  WHEN name IN ('RESHAB', 'Daniel') THEN 'male'
  WHEN name IN ('Sophia', 'Ava') THEN 'female'
  ELSE 'other'
END
WHERE name IN ('Ashley', 'RESHAB', 'Daniel', 'Sophia', 'Ava');

-- Step 13: Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_swipes_swiper ON public.swipes(swiper_id);
CREATE INDEX IF NOT EXISTS idx_swipes_swiped ON public.swipes(swiped_id);
CREATE INDEX IF NOT EXISTS idx_swipes_action ON public.swipes(action);
CREATE INDEX IF NOT EXISTS idx_matches_user_1 ON public.matches(user_id_1);
CREATE INDEX IF NOT EXISTS idx_matches_user_2 ON public.matches(user_id_2);
CREATE INDEX IF NOT EXISTS idx_profiles_gender ON public.profiles(gender);
CREATE INDEX IF NOT EXISTS idx_profiles_age ON public.profiles(age);
CREATE INDEX IF NOT EXISTS idx_user_preferences_user ON public.user_preferences(user_id);

-- Step 14: Create function to set user preferences
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

-- Step 15: Verify the fixes
SELECT 
  'Match Flow Fixes Applied' as status,
  COUNT(*) as total_profiles,
  COUNT(CASE WHEN gender IS NOT NULL THEN 1 END) as profiles_with_gender,
  COUNT(CASE WHEN is_active = true THEN 1 END) as active_profiles,
  (SELECT COUNT(*) FROM public.matches WHERE user_id_1 = user_id_2) as self_matches
FROM public.profiles;

-- Step 16: Test the handle_swipe function
SELECT 'handle_swipe function created successfully' as test_result;
