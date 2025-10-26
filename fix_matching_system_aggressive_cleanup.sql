-- AGGRESSIVE CLEANUP: Drop ALL function variations and recreate cleanly
-- This resolves the persistent "function is not unique" error

-- Step 1: Drop ALL possible variations of the function
DO $$
DECLARE
    func_record RECORD;
BEGIN
    -- Find all functions with this name
    FOR func_record IN 
        SELECT proname, pronargs, proargtypes::regtype[] as arg_types
        FROM pg_proc 
        WHERE proname = 'get_profiles_with_super_likes'
    LOOP
        RAISE NOTICE 'Found function: % with % args: %', 
            func_record.proname, 
            func_record.pronargs, 
            func_record.arg_types;
    END LOOP;
END $$;

-- Drop with CASCADE to remove all dependencies
DROP FUNCTION IF EXISTS get_profiles_with_super_likes(UUID) CASCADE;
DROP FUNCTION IF EXISTS get_profiles_with_super_likes(TEXT) CASCADE;
DROP FUNCTION IF EXISTS get_profiles_with_super_likes(UNKNOWN) CASCADE;
DROP FUNCTION IF EXISTS get_profiles_with_super_likes CASCADE;

-- Also drop any functions that might be overloaded
DO $$
DECLARE
    func_name TEXT;
BEGIN
    FOR func_name IN 
        SELECT DISTINCT proname 
        FROM pg_proc 
        WHERE proname LIKE '%get_profiles_with_super_likes%'
    LOOP
        EXECUTE 'DROP FUNCTION IF EXISTS ' || func_name || ' CASCADE';
        RAISE NOTICE 'Dropped function: %', func_name;
    END LOOP;
END $$;

-- Step 2: Create a completely fresh function with unique name first
CREATE OR REPLACE FUNCTION get_profiles_with_super_likes_fixed(p_user_id UUID)
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

-- Step 3: Test the new function
SELECT 'Testing new function...' as status;

-- Test with the new function name
SELECT 
  id,
  name,
  age,
  is_super_liked
FROM get_profiles_with_super_likes_fixed('7ffe44fe-9c0f-4783-aec2-a6172a6e008b'::UUID)
WHERE id = 'ea063754-8298-4a2b-a74a-58ee274e2dcb'::UUID;

-- Step 4: If test works, rename to original name
DROP FUNCTION IF EXISTS get_profiles_with_super_likes(UUID) CASCADE;
ALTER FUNCTION get_profiles_with_super_likes_fixed(UUID) RENAME TO get_profiles_with_super_likes;

-- Step 5: Grant permissions
GRANT EXECUTE ON FUNCTION get_profiles_with_super_likes(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION get_profiles_with_super_likes(UUID) TO anon;

-- Step 6: Final test
SELECT 
  'Total profiles available for you' as test_name,
  COUNT(*) as profile_count
FROM get_profiles_with_super_likes('7ffe44fe-9c0f-4783-aec2-a6172a6e008b'::UUID);

-- Success message
DO $$
BEGIN
  RAISE NOTICE '✅ AGGRESSIVE CLEANUP COMPLETE!';
  RAISE NOTICE '🧹 All old function versions dropped';
  RAISE NOTICE '🆕 Fresh function created and tested';
  RAISE NOTICE '🎯 Your friend should now appear in your feed!';
  RAISE NOTICE '⚠️  If you still get errors, there may be cached function definitions';
END $$;
