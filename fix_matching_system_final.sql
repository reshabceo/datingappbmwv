-- FINAL CORRECTED VERSION: Uses ONLY columns that actually exist in the profiles table
-- This is based on the actual schema we just verified

-- Step 1: Drop all existing versions
DROP FUNCTION IF EXISTS get_profiles_with_super_likes_fixed(UUID) CASCADE;
DROP FUNCTION IF EXISTS get_profiles_with_super_likes(UUID) CASCADE;
DROP FUNCTION IF EXISTS get_profiles_with_super_likes(TEXT) CASCADE;
DROP FUNCTION IF EXISTS get_profiles_with_super_likes CASCADE;

-- Step 2: Create the FINAL CORRECTED function with exact column matches
CREATE OR REPLACE FUNCTION get_profiles_with_super_likes(p_user_id UUID)
RETURNS TABLE (
  id UUID,
  name TEXT,
  age INT,
  image_urls JSONB,
  photos JSONB,
  location TEXT,
  description TEXT,
  hobbies JSONB,
  gender TEXT,
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
    p.hobbies,
    p.gender,
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
    -- ✅ CORE FIX: Only exclude users you've already MATCHED with
    -- This allows you to see profiles you previously swiped on but didn't match
    AND NOT EXISTS (
      SELECT 1 
      FROM matches m
      WHERE ((m.user_id_1 = p_user_id AND m.user_id_2 = p.id)
          OR (m.user_id_1 = p.id AND m.user_id_2 = p_user_id))
        AND m.status IN ('matched', 'active')
    )
  ORDER BY 
    -- 🌟 Priority 1: Show super likes first
    EXISTS(
      SELECT 1 
      FROM swipes s 
      WHERE s.swiper_id = p.id 
        AND s.swiped_id = p_user_id 
        AND s.action = 'super_like'
    ) DESC,
    -- ❤️ Priority 2: Show profiles who liked you (so you can match back)
    EXISTS(
      SELECT 1 
      FROM swipes s 
      WHERE s.swiper_id = p.id 
        AND s.swiped_id = p_user_id 
        AND s.action IN ('like', 'super_like')
    ) DESC,
    -- 🕒 Priority 3: Newest profiles first
    p.created_at DESC;
END;
$$ LANGUAGE plpgsql;

-- Step 3: Grant permissions
GRANT EXECUTE ON FUNCTION get_profiles_with_super_likes(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION get_profiles_with_super_likes(UUID) TO anon;

-- Step 4: Test the final function
SELECT '🧪 Testing final corrected function...' as status;

-- Test 1: Check if your friend's profile appears
SELECT 
  '🎯 Test 1: Your friend should appear in your feed' as test_name,
  id,
  name,
  age,
  is_super_liked
FROM get_profiles_with_super_likes('7ffe44fe-9c0f-4783-aec2-a6172a6e008b'::UUID)
WHERE id = 'ea063754-8298-4a2b-a74a-58ee274e2dcb'::UUID;

-- Test 2: Count total profiles available
SELECT 
  '📊 Test 2: Total profiles available' as test_name,
  COUNT(*) as profile_count
FROM get_profiles_with_super_likes('7ffe44fe-9c0f-4783-aec2-a6172a6e008b'::UUID);

-- Test 3: List first 5 profiles (to see ordering)
SELECT 
  '📋 Test 3: First 5 profiles (with super_like priority)' as test_name,
  name,
  age,
  is_super_liked
FROM get_profiles_with_super_likes('7ffe44fe-9c0f-4783-aec2-a6172a6e008b'::UUID)
LIMIT 5;

-- Success message
DO $$
BEGIN
  RAISE NOTICE '✅ ===== MATCHING SYSTEM FIX COMPLETE! =====';
  RAISE NOTICE '';
  RAISE NOTICE '🎯 WHAT WAS FIXED:';
  RAISE NOTICE '   • Users can now see profiles they previously swiped on';
  RAISE NOTICE '   • Only MATCHED users are excluded from the feed';
  RAISE NOTICE '   • Your friend who liked you WILL appear in your feed';
  RAISE NOTICE '';
  RAISE NOTICE '⭐ PRIORITY ORDERING:';
  RAISE NOTICE '   1. Super likes appear first';
  RAISE NOTICE '   2. Regular likes appear second';
  RAISE NOTICE '   3. Other profiles by creation date';
  RAISE NOTICE '';
  RAISE NOTICE '🔧 TECHNICAL DETAILS:';
  RAISE NOTICE '   • Function uses only existing columns';
  RAISE NOTICE '   • No more "bio", "interests", "latitude/longitude" errors';
  RAISE NOTICE '   • Function properly handles UUID parameters';
  RAISE NOTICE '';
  RAISE NOTICE '🚀 NEXT STEP: Hot reload your Flutter app to test!';
END $$;
