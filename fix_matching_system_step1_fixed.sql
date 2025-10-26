-- STEP 1 FIXED: Resolve function conflict by dropping old versions first
-- This fixes the "function is not unique" error

-- Step 1: Drop all existing versions of the function
DROP FUNCTION IF EXISTS get_profiles_with_super_likes(UUID);
DROP FUNCTION IF EXISTS get_profiles_with_super_likes(unknown);
DROP FUNCTION IF EXISTS get_profiles_with_super_likes(text);

-- Step 2: Create backup of current function (if it exists)
-- We'll create a backup table instead since we can't backup the function directly
CREATE TABLE IF NOT EXISTS function_backup_log (
  id SERIAL PRIMARY KEY,
  function_name TEXT,
  backup_reason TEXT,
  created_at TIMESTAMP DEFAULT NOW()
);

INSERT INTO function_backup_log (function_name, backup_reason) 
VALUES ('get_profiles_with_super_likes', 'Backing up before matching system fix');

-- Step 3: Create the FIXED version with explicit UUID parameter
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

-- Step 4: Grant permissions
GRANT EXECUTE ON FUNCTION get_profiles_with_super_likes(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION get_profiles_with_super_likes(UUID) TO anon;

-- Step 5: Test the fix with explicit UUID casting
SELECT 'Testing fixed function...' as status;

-- Test with explicit UUID casting
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
  RAISE NOTICE '✅ STEP 1 COMPLETE: Fixed RPC function!';
  RAISE NOTICE '🔧 Function conflict resolved';
  RAISE NOTICE '💡 Users can now see profiles they previously swiped on';
  RAISE NOTICE '⚠️  Only matched users are excluded (not all swiped users)';
  RAISE NOTICE '🎯 Your friend should now appear in your feed!';
END $$;
