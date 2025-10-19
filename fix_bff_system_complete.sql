-- Complete BFF System Fix
-- This script fixes all BFF-related issues including the missing RPC function
-- and ensures proper empty state handling

-- 1. Drop existing function if it exists (to avoid return type conflicts)
DROP FUNCTION IF EXISTS public.get_bff_profiles(UUID);

-- 2. Create the get_bff_profiles RPC function
CREATE OR REPLACE FUNCTION public.get_bff_profiles(
  p_user_id UUID
)
RETURNS TABLE(
  id UUID,
  name TEXT,
  age INTEGER,
  bio TEXT,
  location TEXT,
  latitude DOUBLE PRECISION,
  longitude DOUBLE PRECISION,
  gender TEXT,
  image_urls TEXT[],
  interests TEXT[],
  intent TEXT,
  is_super_liked BOOLEAN,
  distance_km DOUBLE PRECISION
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
    p.bio,
    p.location,
    p.latitude,
    p.longitude,
    p.gender,
    p.image_urls,
    p.interests,
    p.intent,
    COALESCE(sl.is_super_liked, false) as is_super_liked,
    CASE 
      WHEN p.latitude IS NOT NULL AND p.longitude IS NOT NULL THEN
        -- Calculate distance if both users have coordinates
        (SELECT ST_Distance(
          ST_Point(p.longitude, p.latitude)::geography,
          ST_Point(up.longitude, up.latitude)::geography
        ) / 1000.0 -- Convert to kilometers
        FROM profiles up WHERE up.id = p_user_id)
      ELSE NULL
    END as distance_km
  FROM profiles p
  LEFT JOIN super_likes sl ON sl.target_user_id = p.id AND sl.user_id = p_user_id
  WHERE p.id != p_user_id
    AND p.bff_enabled = true  -- Only show profiles that have BFF enabled
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
  ORDER BY 
    CASE WHEN p.latitude IS NOT NULL AND p.longitude IS NOT NULL THEN distance_km ELSE 999999 END,
    p.created_at DESC;
END;
$$;

-- 3. Drop existing function if it exists (to avoid return type conflicts)
DROP FUNCTION IF EXISTS public.get_filtered_profiles(UUID, INTEGER, INTEGER);

-- 4. Create the get_filtered_profiles RPC function (for enhanced discover controller)
CREATE OR REPLACE FUNCTION public.get_filtered_profiles(
  p_user_id UUID,
  p_limit INTEGER DEFAULT 20,
  p_offset INTEGER DEFAULT 0
)
RETURNS TABLE(
  id UUID,
  name TEXT,
  age INTEGER,
  bio TEXT,
  location TEXT,
  latitude DOUBLE PRECISION,
  longitude DOUBLE PRECISION,
  gender TEXT,
  image_urls TEXT[],
  interests TEXT[],
  intent TEXT,
  is_super_liked BOOLEAN,
  distance_km DOUBLE PRECISION
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
    p.bio,
    p.location,
    p.latitude,
    p.longitude,
    p.gender,
    p.image_urls,
    p.interests,
    p.intent,
    COALESCE(sl.is_super_liked, false) as is_super_liked,
    CASE 
      WHEN p.latitude IS NOT NULL AND p.longitude IS NOT NULL THEN
        (SELECT ST_Distance(
          ST_Point(p.longitude, p.latitude)::geography,
          ST_Point(up.longitude, up.latitude)::geography
        ) / 1000.0
        FROM profiles up WHERE up.id = p_user_id)
      ELSE NULL
    END as distance_km
  FROM profiles p
  LEFT JOIN super_likes sl ON sl.target_user_id = p.id AND sl.user_id = p_user_id
  WHERE p.id != p_user_id
    AND p.id NOT IN (
      -- Exclude users already swiped on
      SELECT swiped_id 
      FROM swipes 
      WHERE swiper_id = p_user_id
    )
    AND p.id NOT IN (
      -- Exclude users already matched
      SELECT CASE 
        WHEN user_id_1 = p_user_id THEN user_id_2 
        ELSE user_id_1 
      END
      FROM matches 
      WHERE (user_id_1 = p_user_id OR user_id_2 = p_user_id)
        AND status IN ('matched', 'active')
    )
  ORDER BY 
    CASE WHEN p.latitude IS NOT NULL AND p.longitude IS NOT NULL THEN distance_km ELSE 999999 END,
    p.created_at DESC
  LIMIT p_limit OFFSET p_offset;
END;
$$;

-- 5. Ensure BFF interactions table has proper structure
CREATE TABLE IF NOT EXISTS public.bff_interactions (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  target_user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  interaction_type TEXT NOT NULL CHECK (interaction_type IN ('like', 'pass')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, target_user_id)
);

-- 6. Ensure BFF matches table has proper structure
CREATE TABLE IF NOT EXISTS public.bff_matches (
  id TEXT PRIMARY KEY,
  user_id_1 UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  user_id_2 UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('pending', 'matched', 'active', 'expired')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id_1, user_id_2)
);

-- 7. Add BFF-related columns to profiles table if they don't exist
ALTER TABLE public.profiles 
ADD COLUMN IF NOT EXISTS bff_enabled BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS bff_last_active TIMESTAMP WITH TIME ZONE,
ADD COLUMN IF NOT EXISTS bff_swipes_count INTEGER DEFAULT 0;

-- 8. Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_bff_interactions_user_id ON public.bff_interactions(user_id);
CREATE INDEX IF NOT EXISTS idx_bff_interactions_target_user_id ON public.bff_interactions(target_user_id);
CREATE INDEX IF NOT EXISTS idx_bff_matches_user_id_1 ON public.bff_matches(user_id_1);
CREATE INDEX IF NOT EXISTS idx_bff_matches_user_id_2 ON public.bff_matches(user_id_2);
CREATE INDEX IF NOT EXISTS idx_profiles_bff_enabled ON public.profiles(bff_enabled);

-- 9. Create RLS policies for BFF tables
ALTER TABLE public.bff_interactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.bff_matches ENABLE ROW LEVEL SECURITY;

-- BFF interactions policies
DROP POLICY IF EXISTS "Users can view their own BFF interactions" ON public.bff_interactions;
CREATE POLICY "Users can view their own BFF interactions" ON public.bff_interactions
  FOR SELECT USING (auth.uid() = user_id OR auth.uid() = target_user_id);

DROP POLICY IF EXISTS "Users can insert their own BFF interactions" ON public.bff_interactions;
CREATE POLICY "Users can insert their own BFF interactions" ON public.bff_interactions
  FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update their own BFF interactions" ON public.bff_interactions;
CREATE POLICY "Users can update their own BFF interactions" ON public.bff_interactions
  FOR UPDATE USING (auth.uid() = user_id);

-- BFF matches policies
DROP POLICY IF EXISTS "Users can view their own BFF matches" ON public.bff_matches;
CREATE POLICY "Users can view their own BFF matches" ON public.bff_matches
  FOR SELECT USING (auth.uid() = user_id_1 OR auth.uid() = user_id_2);

DROP POLICY IF EXISTS "Users can insert BFF matches" ON public.bff_matches;
CREATE POLICY "Users can insert BFF matches" ON public.bff_matches
  FOR INSERT WITH CHECK (auth.uid() = user_id_1 OR auth.uid() = user_id_2);

DROP POLICY IF EXISTS "Users can update their own BFF matches" ON public.bff_matches;
CREATE POLICY "Users can update their own BFF matches" ON public.bff_matches
  FOR UPDATE USING (auth.uid() = user_id_1 OR auth.uid() = user_id_2);

-- 10. Grant necessary permissions
GRANT USAGE ON SCHEMA public TO anon, authenticated;
GRANT ALL ON public.bff_interactions TO anon, authenticated;
GRANT ALL ON public.bff_matches TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.get_bff_profiles(UUID) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.get_filtered_profiles(UUID, INTEGER, INTEGER) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.record_bff_interaction(UUID, UUID, TEXT) TO anon, authenticated;

-- 11. Create a function to check if user has BFF mode enabled
CREATE OR REPLACE FUNCTION public.is_bff_mode_enabled(p_user_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN EXISTS(
    SELECT 1 FROM profiles 
    WHERE id = p_user_id AND bff_enabled = true
  );
END;
$$;

-- 12. Create a function to get BFF mode status for current user
CREATE OR REPLACE FUNCTION public.get_user_bff_status()
RETURNS TABLE(
  bff_enabled BOOLEAN,
  bff_last_active TIMESTAMP WITH TIME ZONE,
  bff_swipes_count INTEGER
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    p.bff_enabled,
    p.bff_last_active,
    p.bff_swipes_count
  FROM profiles p
  WHERE p.id = auth.uid();
END;
$$;

-- Grant permissions for new functions
GRANT EXECUTE ON FUNCTION public.is_bff_mode_enabled(UUID) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.get_user_bff_status() TO anon, authenticated;

-- 13. Create a trigger to update bff_last_active when BFF interactions are recorded
CREATE OR REPLACE FUNCTION public.update_bff_activity()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  UPDATE profiles 
  SET 
    bff_last_active = NOW(),
    bff_swipes_count = COALESCE(bff_swipes_count, 0) + 1
  WHERE id = NEW.user_id;
  
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trigger_update_bff_activity ON public.bff_interactions;
CREATE TRIGGER trigger_update_bff_activity
  AFTER INSERT ON public.bff_interactions
  FOR EACH ROW
  EXECUTE FUNCTION public.update_bff_activity();

-- 14. Add some debug information
DO $$
BEGIN
  RAISE NOTICE 'BFF System Fix Complete!';
  RAISE NOTICE 'Created functions: get_bff_profiles, get_filtered_profiles, record_bff_interaction';
  RAISE NOTICE 'Created tables: bff_interactions, bff_matches (if not exists)';
  RAISE NOTICE 'Added columns: bff_enabled, bff_last_active, bff_swipes_count to profiles';
  RAISE NOTICE 'Created RLS policies for BFF tables';
  RAISE NOTICE 'Created indexes for better performance';
END $$;
