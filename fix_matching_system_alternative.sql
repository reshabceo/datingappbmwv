-- ALTERNATIVE APPROACH: Use completely different function name
-- This avoids any conflicts with existing function definitions

-- Step 1: Create function with completely new name
CREATE OR REPLACE FUNCTION get_discover_profiles_v2(p_user_id UUID)
RETURNS TABLE (
  id UUID,
  name TEXT,
  age INT,
  image_urls JSONB,
  photos JSONB,
  location TEXT,
  bio TEXT,
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
    p.bio,
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

-- Step 2: Grant permissions
GRANT EXECUTE ON FUNCTION get_discover_profiles_v2(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION get_discover_profiles_v2(UUID) TO anon;

-- Step 3: Test the new function
SELECT 'Testing alternative function...' as status;

-- Test with the new function name
SELECT 
  id,
  name,
  age,
  is_super_liked
FROM get_discover_profiles_v2('7ffe44fe-9c0f-4783-aec2-a6172a6e008b'::UUID)
WHERE id = 'ea063754-8298-4a2b-a74a-58ee274e2dcb'::UUID;

-- Test total count
SELECT 
  'Total profiles available for you' as test_name,
  COUNT(*) as profile_count
FROM get_discover_profiles_v2('7ffe44fe-9c0f-4783-aec2-a6172a6e008b'::UUID);

-- Success message
DO $$
BEGIN
  RAISE NOTICE '✅ ALTERNATIVE FUNCTION CREATED!';
  RAISE NOTICE '🆕 Function name: get_discover_profiles_v2';
  RAISE NOTICE '🎯 Your friend should now appear in your feed!';
  RAISE NOTICE '⚠️  You will need to update your Flutter code to use the new function name';
END $$;
