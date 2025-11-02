-- Add Location Filtering to get_profiles_with_super_likes
-- This adds optional location filtering to the SQL function
-- If user location is provided, profiles will be filtered by distance
-- If not provided, all profiles are returned (backward compatible)

-- Step 1: Drop existing function
DROP FUNCTION IF EXISTS public.get_profiles_with_super_likes(UUID, INTEGER, INTEGER);

-- Step 2: Create function with optional location parameters
CREATE OR REPLACE FUNCTION public.get_profiles_with_super_likes(
  p_user_id UUID,
  p_limit INTEGER DEFAULT 20,
  p_exclude_hours INTEGER DEFAULT 24,
  p_user_latitude DOUBLE PRECISION DEFAULT NULL,
  p_user_longitude DOUBLE PRECISION DEFAULT NULL,
  p_max_distance_km DOUBLE PRECISION DEFAULT NULL
)
RETURNS TABLE (
  id UUID,
  name TEXT,
  age INTEGER,
  image_urls JSONB,
  photos JSONB,
  location TEXT,
  description TEXT,
  hobbies JSONB,
  gender TEXT,
  latitude DOUBLE PRECISION,
  longitude DOUBLE PRECISION,
  is_super_liked BOOLEAN
)
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
DECLARE
  -- Earth radius in kilometers for haversine formula
  earth_radius_km DOUBLE PRECISION := 6371.0;
  distance_km DOUBLE PRECISION;
BEGIN
  RETURN QUERY
  SELECT 
    p.id,
    p.name,
    p.age,
    COALESCE(p.image_urls, '[]'::jsonb) as image_urls,
    COALESCE(p.photos, '[]'::jsonb) as photos,
    p.location,
    p.description,
    COALESCE(p.hobbies, '[]'::jsonb) as hobbies,
    p.gender,
    p.latitude,
    p.longitude,
    -- Check if this profile super liked the current user
    EXISTS(
      SELECT 1 
      FROM swipes s 
      WHERE s.swiper_id = p.id 
        AND s.swiped_id = p_user_id 
        AND s.action = 'super_like'
    ) as is_super_liked
  FROM profiles p
  WHERE p.id != p_user_id
    AND p.is_active = true
    -- Exclude profiles the user has already swiped on
    AND NOT EXISTS (
      SELECT 1 
      FROM swipes s2 
      WHERE s2.swiper_id = p_user_id 
        AND s2.swiped_id = p.id
    )
    -- Exclude profiles already matched
    AND NOT EXISTS (
      SELECT 1 
      FROM matches m 
      WHERE ((m.user_id_1 = p_user_id AND m.user_id_2 = p.id)
          OR (m.user_id_1 = p.id AND m.user_id_2 = p_user_id))
        AND m.status IN ('matched', 'active')
    )
    -- Location filtering (only if all location parameters provided)
    AND (
      -- If no location filtering requested, show all profiles
      p_user_latitude IS NULL 
      OR p_user_longitude IS NULL 
      OR p_max_distance_km IS NULL 
      OR p_max_distance_km <= 0
      -- Or if profile has no location data, show it anyway
      OR p.latitude IS NULL 
      OR p.longitude IS NULL
      -- Or if profile is within distance
      OR (
        -- Haversine formula for distance calculation
        earth_radius_km * 2 * asin(
          sqrt(
            power(sin(radians(p.latitude - p_user_latitude) / 2), 2) +
            cos(radians(p_user_latitude)) * 
            cos(radians(p.latitude)) * 
            power(sin(radians(p.longitude - p_user_longitude) / 2), 2)
          )
        )
      ) <= p_max_distance_km
    )
  ORDER BY 
    -- Show super likes FIRST (this is critical!)
    EXISTS(
      SELECT 1 
      FROM swipes s 
      WHERE s.swiper_id = p.id 
        AND s.swiped_id = p_user_id 
        AND s.action = 'super_like'
    ) DESC,
    p.created_at DESC
  LIMIT p_limit;
END;
$$;

-- Step 3: Also create backward-compatible version without location params
CREATE OR REPLACE FUNCTION public.get_profiles_with_super_likes(
  p_user_id UUID
)
RETURNS TABLE (
  id UUID,
  name TEXT,
  age INTEGER,
  image_urls JSONB,
  photos JSONB,
  location TEXT,
  description TEXT,
  hobbies JSONB,
  gender TEXT,
  latitude DOUBLE PRECISION,
  longitude DOUBLE PRECISION,
  is_super_liked BOOLEAN
)
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  SELECT * FROM get_profiles_with_super_likes(p_user_id, 20, 24, NULL, NULL, NULL);
END;
$$;

CREATE OR REPLACE FUNCTION public.get_profiles_with_super_likes(
  p_user_id UUID,
  p_limit INTEGER
)
RETURNS TABLE (
  id UUID,
  name TEXT,
  age INTEGER,
  image_urls JSONB,
  photos JSONB,
  location TEXT,
  description TEXT,
  hobbies JSONB,
  gender TEXT,
  latitude DOUBLE PRECISION,
  longitude DOUBLE PRECISION,
  is_super_liked BOOLEAN
)
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  SELECT * FROM get_profiles_with_super_likes(p_user_id, p_limit, 24, NULL, NULL, NULL);
END;
$$;

-- Step 4: Grant permissions
GRANT EXECUTE ON FUNCTION public.get_profiles_with_super_likes(UUID, INTEGER, INTEGER, DOUBLE PRECISION, DOUBLE PRECISION, DOUBLE PRECISION) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.get_profiles_with_super_likes(UUID, INTEGER) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.get_profiles_with_super_likes(UUID) TO anon, authenticated;

-- Step 5: Verification
DO $$
BEGIN
  RAISE NOTICE '✅ Function get_profiles_with_super_likes updated with location filtering support';
  RAISE NOTICE '   - Location filtering is optional (backward compatible)';
  RAISE NOTICE '   - If location params are provided, profiles are filtered by distance';
  RAISE NOTICE '   - If location params are NULL, all profiles are returned';
END $$;

