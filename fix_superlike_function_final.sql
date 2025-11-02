-- Fix get_profiles_with_super_likes function to work with 3 parameters
-- and ensure superlikes are detected correctly

-- Step 1: Drop ALL existing versions of the function (including reversed parameter order)
DROP FUNCTION IF EXISTS public.get_profiles_with_super_likes(UUID);
DROP FUNCTION IF EXISTS public.get_profiles_with_super_likes(UUID, INTEGER);
DROP FUNCTION IF EXISTS public.get_profiles_with_super_likes(UUID, INTEGER, INTEGER);
DROP FUNCTION IF EXISTS public.get_profiles_with_super_likes(INTEGER, UUID);
DROP FUNCTION IF EXISTS public.get_profiles_with_super_likes(INTEGER, UUID, INTEGER);
-- Also drop any versions with CASCADE to remove dependencies
DROP FUNCTION IF EXISTS public.get_profiles_with_super_likes CASCADE;

-- Step 2: Verify Luna's superlike exists
DO $$
DECLARE
  v_target_user UUID := '7ffe44fe-9c0f-4783-aec2-a6172a6e008b';
  v_luna_id UUID := '11111111-aaaa-4444-8888-555555555555';
  v_superlike_exists BOOLEAN;
BEGIN
  -- Check if superlike exists
  SELECT EXISTS(
    SELECT 1 
    FROM swipes 
    WHERE swiper_id = v_luna_id 
      AND swiped_id = v_target_user 
      AND action = 'super_like'
  ) INTO v_superlike_exists;
  
  IF v_superlike_exists THEN
    RAISE NOTICE '✅ Luna superlike EXISTS: Luna (%) superliked user (%)', v_luna_id, v_target_user;
  ELSE
    RAISE NOTICE '❌ Luna superlike MISSING: Creating it now...';
    -- Create the superlike
    INSERT INTO swipes (swiper_id, swiped_id, action, created_at)
    VALUES (v_luna_id, v_target_user, 'super_like', NOW())
    ON CONFLICT (swiper_id, swiped_id)
    DO UPDATE SET action = 'super_like', created_at = EXCLUDED.created_at;
    RAISE NOTICE '✅ Luna superlike CREATED';
  END IF;
END $$;

-- Step 3: Create the correct function with 3 parameters
CREATE OR REPLACE FUNCTION public.get_profiles_with_super_likes(
  p_user_id UUID,
  p_limit INTEGER DEFAULT 20,
  p_exclude_hours INTEGER DEFAULT 24
)
RETURNS TABLE (
  id UUID,
  name TEXT,
  age INTEGER,
  image_urls JSONB,
  photos JSONB,
  location TEXT,
  description TEXT,
  hobbies JSONB,
  gender TEXT,
  latitude DOUBLE PRECISION,
  longitude DOUBLE PRECISION,
  is_super_liked BOOLEAN
)
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    p.id,
    p.name,
    p.age,
    COALESCE(p.image_urls, '[]'::jsonb) as image_urls,
    COALESCE(p.photos, '[]'::jsonb) as photos,
    p.location,
    p.description,
    COALESCE(p.hobbies, '[]'::jsonb) as hobbies,
    p.gender,
    p.latitude,
    p.longitude,
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
      WHERE ((m.user_id_1 = p_user_id AND m.user_id_2 = p.id)
          OR (m.user_id_1 = p.id AND m.user_id_2 = p_user_id))
        AND m.status IN ('matched', 'active')
    )
  ORDER BY 
    -- Show super likes FIRST (this is critical!)
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

-- Step 4: Grant permissions
GRANT EXECUTE ON FUNCTION public.get_profiles_with_super_likes(UUID, INTEGER, INTEGER) TO anon, authenticated;

-- Step 4.5: Verify only ONE function version exists
DO $$
DECLARE
  v_function_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO v_function_count
  FROM pg_proc p
  JOIN pg_namespace n ON p.pronamespace = n.oid
  WHERE n.nspname = 'public'
    AND p.proname = 'get_profiles_with_super_likes';
  
  IF v_function_count > 1 THEN
    RAISE NOTICE '⚠️ WARNING: Found % versions of get_profiles_with_super_likes. Should be 1.', v_function_count;
    RAISE NOTICE '   Run: SELECT proname, pg_get_function_arguments(oid) FROM pg_proc WHERE proname = ''get_profiles_with_super_likes'';';
  ELSE
    RAISE NOTICE '✅ SUCCESS: Only 1 version of get_profiles_with_super_likes exists.';
  END IF;
END $$;

-- Step 5: Test the function and check why Luna might be excluded
DO $$
DECLARE
  v_target_user UUID := '7ffe44fe-9c0f-4783-aec2-a6172a6e008b';
  v_luna_id UUID := '11111111-aaaa-4444-8888-555555555555';
  v_test_result RECORD;
  v_luna_found BOOLEAN := false;
  v_luna_is_superliked BOOLEAN := false;
  v_luna_position INTEGER := 0;
  v_user_swiped_on_luna BOOLEAN;
  v_luna_matched BOOLEAN;
  v_luna_active BOOLEAN;
BEGIN
  -- Check why Luna might be excluded
  SELECT EXISTS(SELECT 1 FROM swipes WHERE swiper_id = v_target_user AND swiped_id = v_luna_id) 
    INTO v_user_swiped_on_luna;
  SELECT EXISTS(
    SELECT 1 FROM matches m 
    WHERE ((m.user_id_1 = v_target_user AND m.user_id_2 = v_luna_id)
        OR (m.user_id_1 = v_luna_id AND m.user_id_2 = v_target_user))
      AND m.status IN ('matched', 'active')
  ) INTO v_luna_matched;
  SELECT is_active INTO v_luna_active FROM profiles WHERE id = v_luna_id;
  
  RAISE NOTICE '🔍 Checking Luna exclusion reasons:';
  RAISE NOTICE '   - User swiped on Luna: %', v_user_swiped_on_luna;
  RAISE NOTICE '   - Luna matched with user: %', v_luna_matched;
  RAISE NOTICE '   - Luna is_active: %', v_luna_active;
  
  -- Test the function
  v_luna_position := 0;
  FOR v_test_result IN 
    SELECT *, ROW_NUMBER() OVER () as position
    FROM get_profiles_with_super_likes(v_target_user, 51, 24)
  LOOP
    v_luna_position := v_test_result.position;
    IF v_test_result.id = v_luna_id THEN
      v_luna_found := true;
      v_luna_is_superliked := v_test_result.is_super_liked;
      RAISE NOTICE '🎯 Luna found at position % - is_super_liked: %', v_luna_position, v_luna_is_superliked;
      EXIT;
    END IF;
  END LOOP;
  
  IF NOT v_luna_found THEN
    RAISE NOTICE '❌ Luna NOT found in results (excluded by filters)';
  ELSIF v_luna_position > 1 THEN
    RAISE NOTICE '⚠️ Luna found at position % (should be 1 if superliked)', v_luna_position;
    IF NOT v_luna_is_superliked THEN
      RAISE NOTICE '⚠️ Luna is NOT detected as superliked - checking swipe record...';
      IF EXISTS(
        SELECT 1 FROM swipes 
        WHERE swiper_id = v_luna_id
          AND swiped_id = v_target_user
          AND action = 'super_like'
      ) THEN
        RAISE NOTICE '✅ Swipe record EXISTS - function detection may have bug';
      ELSE
        RAISE NOTICE '❌ Swipe record MISSING - create it first';
      END IF;
    END IF;
  ELSE
    RAISE NOTICE '✅ SUCCESS: Luna is at position 1 and detected as superliked!';
  END IF;
END $$;

