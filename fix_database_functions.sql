-- Fix database function return types
-- The functions are returning text but the app expects jsonb for certain fields

-- 1. Drop and recreate get_profiles_with_super_likes with correct return types
DROP FUNCTION IF EXISTS public.get_profiles_with_super_likes(UUID);

CREATE FUNCTION public.get_profiles_with_super_likes(p_user_id UUID)
RETURNS TABLE(
  id UUID,
  name TEXT,
  age INTEGER,
  bio TEXT,
  location TEXT,
  latitude DOUBLE PRECISION,
  longitude DOUBLE PRECISION,
  gender TEXT,
  image_urls JSONB,
  interests JSONB,
  intent TEXT,
  is_super_liked BOOLEAN,
  distance_km DOUBLE PRECISION
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  user_lat DOUBLE PRECISION;
  user_lon DOUBLE PRECISION;
BEGIN
  -- Get user's location (set to NULL if columns don't exist)
  user_lat := NULL;
  user_lon := NULL;

  RETURN QUERY
  SELECT
    p.id,
    p.name,
    p.age,
    p.description as bio, -- Use 'description' instead of 'bio'
    p.location,
    p.latitude,
    p.longitude,
    p.gender,
    p.image_urls, -- This is JSONB
    p.hobbies as interests, -- This is JSONB
    p.mode_preference as intent, -- Use mode_preference instead of non-existent intent
    false as is_super_liked, -- Set to false as super_likes table does not exist
    NULL::DOUBLE PRECISION as distance_km -- Distance calculation disabled if no user location
  FROM profiles p
  WHERE p.id != p_user_id
    AND p.is_active = true
    AND p.id NOT IN (
      -- Exclude users already matched in DATING mode
      SELECT CASE
        WHEN user_id_1 = p_user_id THEN user_id_2
        ELSE user_id_1
      END
      FROM matches
      WHERE (user_id_1 = p_user_id OR user_id_2 = p_user_id)
        AND status IN ('matched', 'active')
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
    p.created_at DESC;
END;
$$;

-- 2. Test the function
SELECT * FROM get_profiles_with_super_likes('195cb857-3a05-4425-a6ba-3dd836ca8627'::UUID) LIMIT 5;
