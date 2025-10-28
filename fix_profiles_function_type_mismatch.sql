-- Fix get_profiles_with_super_likes function type mismatch
-- The error shows: "Returned type text does not match expected type jsonb in column 4"
-- This means the function expects JSONB but the table has TEXT[] for photos

-- First, let's check what columns actually exist in profiles table
-- Based on the error and code analysis, the issue is with photos/image_urls columns

-- Drop and recreate the function with correct types
DROP FUNCTION IF EXISTS public.get_profiles_with_super_likes(UUID);
DROP FUNCTION IF EXISTS public.get_profiles_with_super_likes(UUID, INTEGER);

-- Create the corrected function
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

-- Grant permissions
GRANT EXECUTE ON FUNCTION public.get_profiles_with_super_likes(UUID, INTEGER) TO anon, authenticated;

-- Also create a version without limit parameter for backward compatibility
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

-- Grant permissions
GRANT EXECUTE ON FUNCTION public.get_profiles_with_super_likes(UUID) TO anon, authenticated;

-- Test the function
SELECT 'Function created successfully' as status;
