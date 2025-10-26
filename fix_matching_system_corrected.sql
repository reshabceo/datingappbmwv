-- CORRECTED VERSION: Fixed function with correct column names
-- This removes the non-existent 'bio' column and uses only existing columns

-- Step 1: Drop the problematic function
DROP FUNCTION IF EXISTS get_profiles_with_super_likes_fixed(UUID) CASCADE;
DROP FUNCTION IF EXISTS get_profiles_with_super_likes(UUID) CASCADE;

-- Step 2: Create function with correct column structure
CREATE OR REPLACE FUNCTION get_profiles_with_super_likes(p_user_id UUID)
RETURNS TABLE (
  id UUID,
  name TEXT,
  age INT,
  image_urls JSONB,
  photos JSONB,
  location TEXT,
  description TEXT,
  interests JSONB,
  hobbies JSONB,
  gender TEXT,
  latitude DECIMAL,
  longitude DECIMAL,
  is_super_liked BOOLEAN
)
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    p.id,
    p.name,
    p.age,
    p.image_urls,
    p.photos,
    p.location,
    p.description,
    p.interests,
    p.hobbies,
    p.gender,
    p.latitude,
    p.longitude,
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
    -- FIXED: Only exclude users you've already MATCHED with
    AND NOT EXISTS (
      SELECT 1 
      FROM matches m
      WHERE ((m.user_id_1 = p_user_id AND m.user_id_2 = p.id)
          OR (m.user_id_1 = p.id AND m.user_id_2 = p_user_id))
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
    -- Show profiles who liked you first (so you can match back)
    EXISTS(
      SELECT 1 
      FROM swipes s 
      WHERE s.swiper_id = p.id 
        AND s.swiped_id = p_user_id 
        AND s.action IN ('like', 'super_like')
    ) DESC,
    p.created_at DESC;
END;
$$ LANGUAGE plpgsql;

-- Step 3: Grant permissions
GRANT EXECUTE ON FUNCTION get_profiles_with_super_likes(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION get_profiles_with_super_likes(UUID) TO anon;

-- Step 4: Test the corrected function
SELECT 'Testing corrected function...' as status;

-- Test with the corrected function
SELECT 
  id,
  name,
  age,
  is_super_liked
FROM get_profiles_with_super_likes('7ffe44fe-9c0f-4783-aec2-a6172a6e008b'::UUID)
WHERE id = 'ea063754-8298-4a2b-a74a-58ee274e2dcb'::UUID;

-- Test total count
SELECT 
  'Total profiles available for you' as test_name,
  COUNT(*) as profile_count
FROM get_profiles_with_super_likes('7ffe44fe-9c0f-4783-aec2-a6172a6e008b'::UUID);

-- Success message
DO $$
BEGIN
  RAISE NOTICE '✅ CORRECTED FUNCTION CREATED!';
  RAISE NOTICE '🔧 Removed non-existent bio column';
  RAISE NOTICE '🎯 Your friend should now appear in your feed!';
  RAISE NOTICE '⚠️  Function now uses only existing columns from profiles table';
END $$;
