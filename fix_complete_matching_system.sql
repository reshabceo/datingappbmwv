-- COMPLETE FIX FOR BFF MATCHING AND DATING PROFILE LOADING ISSUES
-- This fixes both the BFF matching problem and the dating mode profile loading issue

-- =============================================================================
-- PROBLEM 1: BFF MODE MATCHING ISSUE
-- =============================================================================
-- The app calls handleSwipe() for both dating and BFF modes, but handleSwipe()
-- only works with swipes/matches tables, not bff_interactions/bff_matches tables.
-- We need a separate handle_bff_swipe() function.

-- 1. Create handle_bff_swipe function for BFF mode
DROP FUNCTION IF EXISTS public.handle_bff_swipe(UUID, TEXT);

CREATE OR REPLACE FUNCTION public.handle_bff_swipe(
  p_swiped_id UUID,
  p_action TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_swiper_id UUID;
  v_matched BOOLEAN := FALSE;
  v_match_id UUID;
  v_reciprocal_interaction RECORD;
BEGIN
  -- Get current user ID
  v_swiper_id := auth.uid();
  
  -- Validate input
  IF v_swiper_id IS NULL THEN
    RETURN jsonb_build_object('error', 'User not authenticated');
  END IF;
  
  IF p_swiped_id IS NULL THEN
    RETURN jsonb_build_object('error', 'Invalid swiped user ID');
  END IF;
  
  -- Prevent self-matching
  IF v_swiper_id = p_swiped_id THEN
    RETURN jsonb_build_object('error', 'Cannot swipe on yourself');
  END IF;
  
  -- Validate action (BFF mode only uses 'like' and 'pass')
  IF p_action NOT IN ('like', 'pass') THEN
    RETURN jsonb_build_object('error', 'Invalid BFF action. Only "like" and "pass" are allowed');
  END IF;
  
  -- Check if profiles exist and are active
  IF NOT EXISTS (
    SELECT 1 FROM public.profiles 
    WHERE id = v_swiper_id AND is_active = true
  ) THEN
    RETURN jsonb_build_object('error', 'Swiper profile not found or inactive');
  END IF;
  
  IF NOT EXISTS (
    SELECT 1 FROM public.profiles 
    WHERE id = p_swiped_id AND is_active = true
  ) THEN
    RETURN jsonb_build_object('error', 'Swiped profile not found or inactive');
  END IF;
  
  -- Record the BFF interaction
  INSERT INTO public.bff_interactions (
    user_id,
    target_user_id,
    interaction_type,
    created_at
  ) VALUES (
    v_swiper_id,
    p_swiped_id,
    p_action,
    NOW()
  )
  ON CONFLICT (user_id, target_user_id) 
  DO UPDATE SET 
    interaction_type = EXCLUDED.interaction_type,
    created_at = NOW();
  
  -- Check for match only if action is 'like'
  IF p_action = 'like' THEN
    -- Check for reciprocal like in BFF interactions
    SELECT * INTO v_reciprocal_interaction
    FROM public.bff_interactions
    WHERE user_id = p_swiped_id 
      AND target_user_id = v_swiper_id 
      AND interaction_type = 'like';
    
    IF FOUND THEN
      -- Create BFF match with proper ordering (user_id_1 < user_id_2)
      INSERT INTO public.bff_matches (user_id_1, user_id_2, status)
      VALUES (
        LEAST(v_swiper_id, p_swiped_id),
        GREATEST(v_swiper_id, p_swiped_id),
        'matched'
      )
      ON CONFLICT (user_id_1, user_id_2) DO NOTHING
      RETURNING id INTO v_match_id;
      
      -- Get the match ID if it was created
      IF v_match_id IS NULL THEN
        SELECT id INTO v_match_id
        FROM public.bff_matches
        WHERE user_id_1 = LEAST(v_swiper_id, p_swiped_id)
          AND user_id_2 = GREATEST(v_swiper_id, p_swiped_id);
      END IF;
      
      v_matched := TRUE;
      
      -- Log the match creation
      RAISE NOTICE 'BFF match created: user_id_1=%, user_id_2=%, match_id=%', 
        LEAST(v_swiper_id, p_swiped_id), GREATEST(v_swiper_id, p_swiped_id), v_match_id;
    END IF;
  END IF;
  
  -- Update user's BFF activity
  UPDATE public.profiles
  SET 
    bff_last_active = NOW(),
    bff_swipes_count = COALESCE(bff_swipes_count, 0) + 1
  WHERE id = v_swiper_id;
  
  -- Return result
  RETURN jsonb_build_object(
    'matched', v_matched,
    'match_id', v_match_id,
    'action', p_action,
    'swiper_id', v_swiper_id,
    'swiped_id', p_swiped_id
  );
  
EXCEPTION
  WHEN OTHERS THEN
    RETURN jsonb_build_object('error', SQLERRM);
END;
$$;

-- Grant permissions
GRANT EXECUTE ON FUNCTION public.handle_bff_swipe(UUID, TEXT) TO anon, authenticated;

-- =============================================================================
-- PROBLEM 2: DATING MODE PROFILE LOADING ISSUE
-- =============================================================================
-- The get_profiles_with_super_likes function might be too restrictive.
-- Let's create a more flexible function that shows profiles even if you haven't
-- swiped on them yet.

-- 2. Create a better function for dating mode profiles
DROP FUNCTION IF EXISTS public.get_dating_profiles(UUID);

CREATE OR REPLACE FUNCTION public.get_dating_profiles(
  p_user_id UUID,
  p_limit INTEGER DEFAULT 20
)
RETURNS TABLE (
  id UUID,
  name TEXT,
  age INTEGER,
  photos JSONB,
  location TEXT,
  description TEXT,
  hobbies JSONB,
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
    p.photos,
    p.location,
    p.description,
    p.hobbies,
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
    p.id DESC  -- Use id instead of created_at
  LIMIT p_limit;
END;
$$;

-- Grant permissions
GRANT EXECUTE ON FUNCTION public.get_dating_profiles(UUID, INTEGER) TO anon, authenticated;

-- 3. Update the existing get_profiles_with_super_likes function to be less restrictive
DROP FUNCTION IF EXISTS public.get_profiles_with_super_likes(UUID);

CREATE OR REPLACE FUNCTION public.get_profiles_with_super_likes(
  p_user_id UUID,
  p_limit INTEGER DEFAULT 20
)
RETURNS TABLE (
  id UUID,
  name TEXT,
  age INTEGER,
  photos JSONB,
  location TEXT,
  description TEXT,
  hobbies JSONB,
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
    p.photos,
    p.location,
    p.description,
    p.hobbies,
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
    p.id DESC  -- Use id instead of created_at
  LIMIT p_limit;
END;
$$;

-- Grant permissions
GRANT EXECUTE ON FUNCTION public.get_profiles_with_super_likes(UUID, INTEGER) TO anon, authenticated;

-- =============================================================================
-- TESTING AND VERIFICATION
-- =============================================================================

-- Test the BFF swipe function
DO $$
DECLARE
    test_user_id UUID := '7ffe44fe-9c0f-4783-aec2-a6172a6e008b';
    test_target_id UUID := '33333333-3333-3333-3333-333333333333'; -- Emma
    result JSONB;
BEGIN
    -- Test BFF swipe
    BEGIN
        result := handle_bff_swipe(test_target_id, 'like');
        RAISE NOTICE 'BFF swipe test result: %', result;
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE 'BFF swipe test failed: %', SQLERRM;
    END;
END $$;

-- Test dating profiles function
SELECT 
    'Dating profiles available' as status,
    COUNT(*) as count
FROM get_dating_profiles('7ffe44fe-9c0f-4783-aec2-a6172a6e008b');

-- Show some dating profiles
SELECT 
    id,
    name,
    age,
    is_super_liked
FROM get_dating_profiles('7ffe44fe-9c0f-4783-aec2-a6172a6e008b', 5)
ORDER BY is_super_liked DESC, id DESC;

-- Test BFF profiles function
SELECT 
    'BFF profiles available' as status,
    COUNT(*) as count
FROM get_bff_profiles('7ffe44fe-9c0f-4783-aec2-a6172a6e008b');

-- Show some BFF profiles
SELECT 
    id,
    name,
    age
FROM get_bff_profiles('7ffe44fe-9c0f-4783-aec2-a6172a6e008b')
ORDER BY id DESC
LIMIT 5;

-- Final status
DO $$
BEGIN
  RAISE NOTICE '=== COMPLETE MATCHING SYSTEM FIX APPLIED ===';
  RAISE NOTICE '1. Created handle_bff_swipe() function for BFF mode';
  RAISE NOTICE '2. Fixed get_profiles_with_super_likes() for dating mode';
  RAISE NOTICE '3. Created get_dating_profiles() as alternative';
  RAISE NOTICE '4. BFF mutual likes should now create matches properly';
  RAISE NOTICE '5. Dating mode should now show profiles correctly';
  RAISE NOTICE 'Next: Update the Flutter app to use handle_bff_swipe() for BFF mode';
END $$;
