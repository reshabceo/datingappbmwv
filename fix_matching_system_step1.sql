-- STEP 1: Fix the matching system by updating the RPC function
-- This fixes the core issue where users can't see profiles they previously swiped on

-- First, let's backup the current function (for rollback if needed)
CREATE OR REPLACE FUNCTION get_profiles_with_super_likes_backup(p_user_id UUID)
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
    -- OLD BUGGY LOGIC: Excludes ALL profiles you've ever swiped on
    AND NOT EXISTS (
      SELECT 1 
      FROM swipes s2 
      WHERE s2.swiper_id = p_user_id 
        AND s2.swiped_id = p.id
    )
  ORDER BY 
    EXISTS(
      SELECT 1 
      FROM swipes s 
      WHERE s.swiper_id = p.id 
        AND s.swiped_id = p_user_id 
        AND s.action = 'super_like'
    ) DESC,
    p.created_at DESC;
END;
$$ LANGUAGE plpgsql;

-- Now create the FIXED version
CREATE OR REPLACE FUNCTION get_profiles_with_super_likes(p_user_id UUID)
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

-- Test the fix
SELECT 'Testing fixed function...' as status;

-- Test with your user ID to see if friend's profile now appears
SELECT 
  id,
  name,
  age,
  is_super_liked
FROM get_profiles_with_super_likes('7ffe44fe-9c0f-4783-aec2-a6172a6e008b')
WHERE id = 'ea063754-8298-4a2b-a74a-58ee274e2dcb';

-- Success message
DO $$
BEGIN
  RAISE NOTICE '✅ STEP 1 COMPLETE: Fixed RPC function!';
  RAISE NOTICE '🔧 Users can now see profiles they previously swiped on';
  RAISE NOTICE '💡 Profiles who liked you will appear first';
  RAISE NOTICE '⚠️  Only matched users are excluded (not all swiped users)';
END $$;
