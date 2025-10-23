-- Filter BFF Profiles to Only Show Active Users
-- Only show BFF profiles of users who have actually swiped/interacted in BFF mode
-- This ensures users don't see inactive profiles cluttering their feed

-- Drop existing function
DROP FUNCTION IF EXISTS public.get_bff_profiles(UUID);

-- Create updated function with activity filter
CREATE OR REPLACE FUNCTION public.get_bff_profiles(
  p_user_id UUID
)
RETURNS TABLE(
  id UUID,
  name TEXT,
  age INTEGER,
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
    p.id, p.name, p.age, p.photos, p.location, p.description, p.hobbies, p.created_at
  FROM profiles p
  WHERE p.id != p_user_id
    AND p.mode_preferences->>'bff' = 'true'  -- BFF mode enabled
    AND (
      -- CRITICAL: Only show users who have actually used BFF mode
      p.bff_swipes_count > 0 OR  -- Has made at least 1 BFF swipe
      p.bff_last_active IS NOT NULL  -- Or has been active in BFF mode
    )
    -- Exclude already interacted users
    AND p.id NOT IN (
      SELECT target_user_id 
      FROM bff_interactions 
      WHERE user_id = p_user_id
    )
    AND p.id NOT IN (
      SELECT swiped_id 
      FROM bff_swipes 
      WHERE swiper_id = p_user_id
    )
    -- Exclude existing matches
    AND p.id NOT IN (
      SELECT CASE 
        WHEN user_id_1 = p_user_id THEN user_id_2 
        ELSE user_id_1 
      END 
      FROM bff_matches 
      WHERE (user_id_1 = p_user_id OR user_id_2 = p_user_id) 
        AND status IN ('matched', 'active')
    )
  ORDER BY 
    p.bff_last_active DESC NULLS LAST,  -- Prioritize recently active users
    p.created_at DESC
  LIMIT 20;
END;
$$;

-- Grant permissions
GRANT EXECUTE ON FUNCTION public.get_bff_profiles(UUID) TO anon, authenticated;

-- Verification query
DO $$
BEGIN
  RAISE NOTICE '=== BFF Profile Filtering Updated ===';
  RAISE NOTICE 'Now only showing users who have:';
  RAISE NOTICE '  1. BFF mode enabled';
  RAISE NOTICE '  2. Made at least 1 BFF swipe (bff_swipes_count > 0)';
  RAISE NOTICE '  3. Profiles sorted by recent activity';
  RAISE NOTICE '';
  RAISE NOTICE '✅ Function updated successfully!';
END $$;

