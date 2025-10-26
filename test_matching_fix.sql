-- Test script to verify the matching system fix
-- Run this after applying the RPC function fix

-- Test 1: Check if your friend's profile now appears in your feed
SELECT 
  'Testing if friend appears in your feed...' as test_name,
  id,
  name,
  age,
  is_super_liked
FROM get_profiles_with_super_likes('7ffe44fe-9c0f-4783-aec2-a6172a6e008b')
WHERE id = 'ea063754-8298-4a2b-a74a-58ee274e2dcb';

-- Test 2: Check if your profile appears in your friend's feed
SELECT 
  'Testing if you appear in friend feed...' as test_name,
  id,
  name,
  age,
  is_super_liked
FROM get_profiles_with_super_likes('ea063754-8298-4a2b-a74a-58ee274e2dcb')
WHERE id = '7ffe44fe-9c0f-4783-aec2-a6172a6e008b';

-- Test 3: Count total profiles available for you
SELECT 
  'Total profiles available for you' as test_name,
  COUNT(*) as profile_count
FROM get_profiles_with_super_likes('7ffe44fe-9c0f-4783-aec2-a6172a6e008b');

-- Test 4: Count total profiles available for your friend
SELECT 
  'Total profiles available for friend' as test_name,
  COUNT(*) as profile_count
FROM get_profiles_with_super_likes('ea063754-8298-4a2b-a74a-58ee274e2dcb');

-- Test 5: Check if profiles who liked you appear first
SELECT 
  'Profiles who liked you (should appear first)' as test_name,
  id,
  name,
  age,
  is_super_liked,
  -- Check if this profile liked you
  EXISTS(
    SELECT 1 
    FROM swipes s 
    WHERE s.swiper_id = id 
      AND s.swiped_id = '7ffe44fe-9c0f-4783-aec2-a6172a6e008b'
      AND s.action IN ('like', 'super_like')
  ) as they_liked_you
FROM get_profiles_with_super_likes('7ffe44fe-9c0f-4783-aec2-a6172a6e008b')
ORDER BY is_super_liked DESC, they_liked_you DESC
LIMIT 5;

-- Success message
DO $$
BEGIN
  RAISE NOTICE '✅ TESTING COMPLETE!';
  RAISE NOTICE '🔍 Check the results above:';
  RAISE NOTICE '   - Your friend should appear in your feed';
  RAISE NOTICE '   - You should appear in your friend feed';
  RAISE NOTICE '   - Profiles who liked you should appear first';
  RAISE NOTICE '   - Total profile counts should be reasonable';
END $$;
