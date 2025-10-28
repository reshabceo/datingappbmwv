-- Safe fix for database functions with column existence checks
-- This version handles missing columns gracefully

-- 1. Drop existing function first
DROP FUNCTION IF EXISTS public.get_profiles_with_super_likes(UUID);

-- 2. Create function with safe column references
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
  has_latitude BOOLEAN;
  has_longitude BOOLEAN;
  has_description BOOLEAN;
BEGIN
  -- Check if columns exist
  SELECT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'profiles' AND column_name = 'latitude'
  ) INTO has_latitude;
  
  SELECT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'profiles' AND column_name = 'longitude'
  ) INTO has_longitude;
  
  SELECT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'profiles' AND column_name = 'description'
  ) INTO has_description;

  -- Get user's location if columns exist
  IF has_latitude AND has_longitude THEN
    SELECT p.latitude, p.longitude INTO user_lat, user_lon
    FROM profiles p WHERE p.id = p_user_id;
  ELSE
    user_lat := NULL;
    user_lon := NULL;
  END IF;

  RETURN QUERY
  SELECT
    p.id,
    p.name,
    p.age,
    CASE 
      WHEN has_description THEN p.description 
      ELSE NULL 
    END as bio,
    p.location,
    CASE WHEN has_latitude THEN p.latitude ELSE NULL END as latitude,
    CASE WHEN has_longitude THEN p.longitude ELSE NULL END as longitude,
    p.gender,
    p.image_urls, -- This is JSONB
    p.hobbies as interests, -- This is JSONB
    p.mode_preference as intent, -- Use mode_preference instead of non-existent intent
    false as is_super_liked,
    NULL::DOUBLE PRECISION as distance_km
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

-- 3. Test the function
SELECT * FROM get_profiles_with_super_likes('195cb857-3a05-4425-a6ba-3dd836ca8627'::UUID) LIMIT 5;
