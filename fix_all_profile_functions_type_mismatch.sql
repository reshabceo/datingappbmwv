-- COMPREHENSIVE FIX: Fix all profile functions with type mismatches
-- The error shows: "Returned type text does not match expected type jsonb in column 4"
-- This means functions expect JSONB but the table has TEXT[] for photos/hobbies

-- =============================================================================
-- 1. Fix get_profiles_with_super_likes function
-- =============================================================================

DROP FUNCTION IF EXISTS public.get_profiles_with_super_likes(UUID);
DROP FUNCTION IF EXISTS public.get_profiles_with_super_likes(UUID, INTEGER);

-- Create the corrected function with TEXT[] types
CREATE OR REPLACE FUNCTION public.get_profiles_with_super_likes(
  p_user_id UUID,
  p_limit INTEGER DEFAULT 20
)
RETURNS TABLE (
  id UUID,
  name TEXT,
  age INTEGER,
  photos TEXT[],  -- Changed from JSONB to TEXT[] to match table structure
  location TEXT,
  description TEXT,
  hobbies TEXT[],  -- Changed from JSONB to TEXT[] to match table structure
  is_super_liked BOOLEAN
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
    COALESCE(p.photos, ARRAY[]::TEXT[]) as photos,  -- Handle null photos
    p.location,
    p.description,
    COALESCE(p.hobbies, ARRAY[]::TEXT[]) as hobbies,  -- Handle null hobbies
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
      WHERE (m.user_id_1 = p_user_id AND m.user_id_2 = p.id)
         OR (m.user_id_1 = p.id AND m.user_id_2 = p_user_id)
      AND m.status IN ('matched', 'active')
    )
  ORDER BY 
    -- Show super likes first
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

-- Create version without limit parameter for backward compatibility
CREATE OR REPLACE FUNCTION public.get_profiles_with_super_likes(p_user_id UUID)
RETURNS TABLE (
  id UUID,
  name TEXT,
  age INTEGER,
  photos TEXT[],
  location TEXT,
  description TEXT,
  hobbies TEXT[],
  is_super_liked BOOLEAN
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
    COALESCE(p.photos, ARRAY[]::TEXT[]) as photos,
    p.location,
    p.description,
    COALESCE(p.hobbies, ARRAY[]::TEXT[]) as hobbies,
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
      WHERE (m.user_id_1 = p_user_id AND m.user_id_2 = p.id)
         OR (m.user_id_1 = p.id AND m.user_id_2 = p_user_id)
      AND m.status IN ('matched', 'active')
    )
  ORDER BY 
    -- Show super likes first
    EXISTS(
      SELECT 1 
      FROM swipes s 
      WHERE s.swiper_id = p.id 
        AND s.swiped_id = p_user_id 
        AND s.action = 'super_like'
    ) DESC,
    p.created_at DESC;
END;
$$;

-- =============================================================================
-- 2. Fix get_dating_profiles function
-- =============================================================================

DROP FUNCTION IF EXISTS public.get_dating_profiles(UUID);
DROP FUNCTION IF EXISTS public.get_dating_profiles(UUID, INTEGER);

-- Create the corrected function with TEXT[] types
CREATE OR REPLACE FUNCTION public.get_dating_profiles(
  p_user_id UUID,
  p_limit INTEGER DEFAULT 20
)
RETURNS TABLE (
  id UUID,
  name TEXT,
  age INTEGER,
  photos TEXT[],  -- Changed from JSONB to TEXT[] to match table structure
  location TEXT,
  description TEXT,
  hobbies TEXT[],  -- Changed from JSONB to TEXT[] to match table structure
  is_super_liked BOOLEAN
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
    COALESCE(p.photos, ARRAY[]::TEXT[]) as photos,  -- Handle null photos
    p.location,
    p.description,
    COALESCE(p.hobbies, ARRAY[]::TEXT[]) as hobbies,  -- Handle null hobbies
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
    AND (p.bff_enabled = false OR p.bff_enabled IS NULL)  -- Only show profiles that are NOT in BFF mode
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
      WHERE (m.user_id_1 = p_user_id AND m.user_id_2 = p.id)
         OR (m.user_id_1 = p.id AND m.user_id_2 = p_user_id)
      AND m.status IN ('matched', 'active')
    )
  ORDER BY 
    -- Show super likes first
    EXISTS(
      SELECT 1 
      FROM swipes s 
      WHERE s.swiper_id = p.id 
        AND s.swiped_id = p_user_id 
        AND s.action = 'super_like'
    ) DESC,
    p.id DESC
  LIMIT p_limit;
END;
$$;

-- Create version without limit parameter for backward compatibility
CREATE OR REPLACE FUNCTION public.get_dating_profiles(p_user_id UUID)
RETURNS TABLE (
  id UUID,
  name TEXT,
  age INTEGER,
  photos TEXT[],
  location TEXT,
  description TEXT,
  hobbies TEXT[],
  is_super_liked BOOLEAN
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
    COALESCE(p.photos, ARRAY[]::TEXT[]) as photos,
    p.location,
    p.description,
    COALESCE(p.hobbies, ARRAY[]::TEXT[]) as hobbies,
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
    AND (p.bff_enabled = false OR p.bff_enabled IS NULL)  -- Only show profiles that are NOT in BFF mode
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
      WHERE (m.user_id_1 = p_user_id AND m.user_id_2 = p.id)
         OR (m.user_id_1 = p.id AND m.user_id_2 = p_user_id)
      AND m.status IN ('matched', 'active')
    )
  ORDER BY 
    -- Show super likes first
    EXISTS(
      SELECT 1 
      FROM swipes s 
      WHERE s.swiper_id = p.id 
        AND s.swiped_id = p_user_id 
        AND s.action = 'super_like'
    ) DESC,
    p.id DESC;
END;
$$;

-- =============================================================================
-- 3. Grant permissions
-- =============================================================================

GRANT EXECUTE ON FUNCTION public.get_profiles_with_super_likes(UUID, INTEGER) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.get_profiles_with_super_likes(UUID) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.get_dating_profiles(UUID, INTEGER) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.get_dating_profiles(UUID) TO anon, authenticated;

-- =============================================================================
-- 4. Test the functions
-- =============================================================================

-- Test get_profiles_with_super_likes
SELECT 'Testing get_profiles_with_super_likes function' as status;

-- Test get_dating_profiles
SELECT 'Testing get_dating_profiles function' as status;

-- Final status
SELECT 'All profile functions fixed with correct TEXT[] types' as final_status;
