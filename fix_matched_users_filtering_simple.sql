-- Fix Matched Users Filtering - Simplified Version
-- Run this in Supabase SQL Editor

-- 1. Drop existing functions first
DROP FUNCTION IF EXISTS public.get_bff_profiles(UUID);
DROP FUNCTION IF EXISTS public.get_profiles_with_super_likes(UUID);
DROP FUNCTION IF EXISTS public.get_all_matched_user_ids(UUID);

-- 2. Create simplified get_bff_profiles function
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
    p.hobbies as interests,
    p.intent,
    false as is_super_liked,  -- Super likes not available
    NULL as distance_km  -- Distance calculation disabled
  FROM profiles p
  WHERE p.id != p_user_id
    AND p.bff_enabled = true
    AND p.is_active = true
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

-- 3. Create simplified get_profiles_with_super_likes function
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
    p.hobbies as interests,
    p.intent,
    false as is_super_liked,  -- Super likes not available
    NULL as distance_km  -- Distance calculation disabled
  FROM profiles p
  WHERE p.id != p_user_id
    AND p.is_active = true
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

-- 4. Create helper function to get all matched user IDs across both modes
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

-- 5. Grant necessary permissions
GRANT EXECUTE ON FUNCTION public.get_bff_profiles(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_profiles_with_super_likes(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_all_matched_user_ids(UUID) TO authenticated;

-- 6. Test the fix
SELECT 'Functions created successfully!' as status;

-- 7. Test with a sample user ID (replace with actual user ID for testing)
-- SELECT name, id FROM public.get_bff_profiles('00000000-0000-0000-0000-000000000000'::UUID) LIMIT 5;
-- SELECT name, id FROM public.get_profiles_with_super_likes('00000000-0000-0000-0000-000000000000'::UUID) LIMIT 5;


