-- COMPLETE BFF MODE FIX
-- This fixes all BFF mode issues to ensure it works properly

-- Step 1: Ensure BFF columns exist in profiles table
ALTER TABLE public.profiles 
ADD COLUMN IF NOT EXISTS bff_enabled BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS bff_last_active TIMESTAMP WITH TIME ZONE,
ADD COLUMN IF NOT EXISTS bff_swipes_count INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS bff_enabled_at TIMESTAMP WITH TIME ZONE;

-- Step 2: Create bff_interactions table if it doesn't exist
CREATE TABLE IF NOT EXISTS public.bff_interactions (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  target_user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  interaction_type TEXT NOT NULL CHECK (interaction_type IN ('like', 'pass')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, target_user_id)
);

-- Step 3: Create bff_matches table if it doesn't exist
CREATE TABLE IF NOT EXISTS public.bff_matches (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id_1 UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  user_id_2 UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  status TEXT NOT NULL DEFAULT 'matched' CHECK (status IN ('pending', 'matched', 'active', 'expired')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id_1, user_id_2)
);

-- Step 4: Create indexes
CREATE INDEX IF NOT EXISTS idx_bff_interactions_user_id ON public.bff_interactions(user_id);
CREATE INDEX IF NOT EXISTS idx_bff_interactions_target_user_id ON public.bff_interactions(target_user_id);
CREATE INDEX IF NOT EXISTS idx_bff_matches_user_id_1 ON public.bff_matches(user_id_1);
CREATE INDEX IF NOT EXISTS idx_bff_matches_user_id_2 ON public.bff_matches(user_id_2);

-- Step 5: Enable RLS
ALTER TABLE public.bff_interactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.bff_matches ENABLE ROW LEVEL SECURITY;

-- Step 6: Create RLS policies for bff_interactions
DROP POLICY IF EXISTS "Users can view their own BFF interactions" ON public.bff_interactions;
CREATE POLICY "Users can view their own BFF interactions" ON public.bff_interactions
  FOR SELECT USING (auth.uid() = user_id OR auth.uid() = target_user_id);

DROP POLICY IF EXISTS "Users can insert their own BFF interactions" ON public.bff_interactions;
CREATE POLICY "Users can insert their own BFF interactions" ON public.bff_interactions
  FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update their own BFF interactions" ON public.bff_interactions;
CREATE POLICY "Users can update their own BFF interactions" ON public.bff_interactions
  FOR UPDATE USING (auth.uid() = user_id);

-- Step 7: Create RLS policies for bff_matches
DROP POLICY IF EXISTS "Users can view their own BFF matches" ON public.bff_matches;
CREATE POLICY "Users can view their own BFF matches" ON public.bff_matches
  FOR SELECT USING (auth.uid() = user_id_1 OR auth.uid() = user_id_2);

DROP POLICY IF EXISTS "Users can insert their own BFF matches" ON public.bff_matches;
CREATE POLICY "Users can insert their own BFF matches" ON public.bff_matches
  FOR INSERT WITH CHECK (auth.uid() = user_id_1 OR auth.uid() = user_id_2);

-- Step 8: Drop and recreate get_bff_profiles function with correct structure
DROP FUNCTION IF EXISTS public.get_bff_profiles(UUID);

CREATE OR REPLACE FUNCTION public.get_bff_profiles(
  p_user_id UUID
)
RETURNS TABLE(
  id UUID,
  name TEXT,
  age INTEGER,
  gender TEXT,
  image_urls JSONB,
  photos JSONB,
  location TEXT,
  description TEXT,
  hobbies JSONB,
  created_at TIMESTAMP WITH TIME ZONE
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    p.id,
    p.name,
    p.age,
    p.gender,
    p.image_urls,
    p.photos,
    p.location,
    p.description,
    p.hobbies,
    p.created_at
  FROM profiles p
  WHERE p.id != p_user_id
    AND p.is_active = true  -- Only active profiles
    AND (p.mode_preferences->>'bff' = 'true' OR p.bff_enabled = true)  -- BFF mode enabled
    AND p.bff_swipes_count > 0  -- CRITICAL: Only show users who have been active in BFF (done at least one swipe)
    AND p.id NOT IN (
      -- Exclude users already interacted with in BFF mode
      SELECT target_user_id 
      FROM bff_interactions 
      WHERE user_id = p_user_id
    )
    AND p.id NOT IN (
      -- Exclude users already matched in BFF mode
      SELECT CASE 
        WHEN user_id_1 = p_user_id THEN user_id_2 
        ELSE user_id_1 
      END
      FROM bff_matches 
      WHERE (user_id_1 = p_user_id OR user_id_2 = p_user_id)
        AND status IN ('matched', 'active')
    )
  ORDER BY p.bff_last_active DESC NULLS LAST, p.created_at DESC
  LIMIT 50;
END;
$$;

-- Step 9: Grant permissions
GRANT EXECUTE ON FUNCTION public.get_bff_profiles(UUID) TO anon, authenticated;
GRANT ALL ON public.bff_interactions TO anon, authenticated;
GRANT ALL ON public.bff_matches TO anon, authenticated;

-- Step 10: Success message
DO $$
BEGIN
  RAISE NOTICE '=== BFF MODE FIXED SUCCESSFULLY ===';
  RAISE NOTICE 'BFF tables created/verified';
  RAISE NOTICE 'get_bff_profiles function created';
  RAISE NOTICE 'RLS policies configured';
  RAISE NOTICE '';
  RAISE NOTICE '=== BFF CARD VISIBILITY LOGIC ===';
  RAISE NOTICE 'BFF cards appear ONLY if:';
  RAISE NOTICE '1. User has bff_enabled=true OR mode_preferences->>bff=true';
  RAISE NOTICE '2. User has bff_swipes_count > 0 (active in BFF mode)';
  RAISE NOTICE '3. User is NOT in bff_interactions (not swiped on by current user)';
  RAISE NOTICE '4. User is NOT in bff_matches (not already matched)';
  RAISE NOTICE '5. Profiles ordered by bff_last_active DESC (most recent first)';
  RAISE NOTICE '';
  RAISE NOTICE 'This ensures only ACTIVE BFF users show up in the feed!';
END $$;
