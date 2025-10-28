-- Fix Matched Users Filtering - Prevent users matched in one mode from showing in another
-- Run this in Supabase SQL Editor

-- 1. Drop existing function first to avoid return type conflicts
DROP FUNCTION IF EXISTS public.get_bff_profiles(UUID);

-- 2. Create get_bff_profiles function to exclude dating matches
CREATE FUNCTION public.get_bff_profiles(p_user_id UUID)
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
    p.bio,
    p.location,
    p.latitude,
    p.longitude,
    p.gender,
    p.image_urls,
    p.hobbies as interests,
    p.intent,
    COALESCE(sl.id IS NOT NULL, false) as is_super_liked,
    CASE 
      WHEN user_lat IS NOT NULL AND user_lon IS NOT NULL
      THEN NULL  -- Distance calculation disabled if no user location
      ELSE NULL
    END as distance_km
  FROM profiles p
  LEFT JOIN super_likes sl ON sl.target_user_id = p.id AND sl.user_id = p_user_id
  WHERE p.id != p_user_id
    AND p.bff_enabled = true
    AND p.is_active = true
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
    AND p.id NOT IN (
      -- CRITICAL FIX: Exclude users already matched in DATING mode
      SELECT CASE 
        WHEN user_id_1 = p_user_id THEN user_id_2 
        ELSE user_id_1 
      END
      FROM matches 
      WHERE (user_id_1 = p_user_id OR user_id_2 = p_user_id)
        AND status IN ('matched', 'active')
    )
  ORDER BY 
    p.created_at DESC;
END;
$$;

-- 3. Drop existing function first to avoid return type conflicts
DROP FUNCTION IF EXISTS public.get_profiles_with_super_likes(UUID);

-- 4. Create get_profiles_with_super_likes function to exclude BFF matches
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
  image_urls TEXT[],
  interests TEXT[],
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
    p.bio,
    p.location,
    p.latitude,
    p.longitude,
    p.gender,
    p.image_urls,
    p.hobbies as interests,
    p.intent,
    COALESCE(sl.id IS NOT NULL, false) as is_super_liked,
    CASE 
      WHEN user_lat IS NOT NULL AND user_lon IS NOT NULL
      THEN NULL  -- Distance calculation disabled if no user location
      ELSE NULL
    END as distance_km
  FROM profiles p
  LEFT JOIN super_likes sl ON sl.target_user_id = p.id AND sl.user_id = p_user_id
  WHERE p.id != p_user_id
    AND p.is_active = true
    AND p.id NOT IN (
      -- Exclude users already interacted with in dating mode
      SELECT target_user_id 
      FROM interactions 
      WHERE user_id = p_user_id
    )
    AND p.id NOT IN (
      -- Exclude users already matched in dating mode
      SELECT CASE 
        WHEN user_id_1 = p_user_id THEN user_id_2 
        ELSE user_id_1 
      END
      FROM matches 
      WHERE (user_id_1 = p_user_id OR user_id_2 = p_user_id)
        AND status IN ('matched', 'active')
    )
    AND p.id NOT IN (
      -- CRITICAL FIX: Exclude users already matched in BFF mode
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

-- 5. Drop existing helper function first
DROP FUNCTION IF EXISTS public.get_all_matched_user_ids(UUID);

-- 6. Create a helper function to get all matched user IDs across both modes
CREATE FUNCTION public.get_all_matched_user_ids(p_user_id UUID)
RETURNS TABLE(matched_user_id UUID)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  -- Get dating matches
  SELECT CASE 
    WHEN user_id_1 = p_user_id THEN user_id_2 
    ELSE user_id_1 
  END
  FROM matches 
  WHERE (user_id_1 = p_user_id OR user_id_2 = p_user_id)
    AND status IN ('matched', 'active')
  
  UNION
  
  -- Get BFF matches
  SELECT CASE 
    WHEN user_id_1 = p_user_id THEN user_id_2 
    ELSE user_id_1 
  END
  FROM bff_matches 
  WHERE (user_id_1 = p_user_id OR user_id_2 = p_user_id)
    AND status IN ('matched', 'active');
END;
$$;

-- 7. Grant necessary permissions
GRANT EXECUTE ON FUNCTION public.get_bff_profiles(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_profiles_with_super_likes(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_all_matched_user_ids(UUID) TO authenticated;

-- 8. Test the fix
SELECT 'Dating matches for test user:' as test_type;
SELECT * FROM public.get_all_matched_user_ids('00000000-0000-0000-0000-000000000000'::UUID) LIMIT 5;

SELECT 'BFF profiles (should exclude dating matches):' as test_type;
SELECT name, id FROM public.get_bff_profiles('00000000-0000-0000-0000-000000000000'::UUID) LIMIT 5;

SELECT 'Dating profiles (should exclude BFF matches):' as test_type;
SELECT name, id FROM public.get_profiles_with_super_likes('00000000-0000-0000-0000-000000000000'::UUID) LIMIT 5;
