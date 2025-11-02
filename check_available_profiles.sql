-- Check why no profiles are available for the user
-- This will help diagnose why get_profiles_with_super_likes returns empty results

DO $$
DECLARE
  v_target_user_id UUID := '7ffe44fe-9c0f-4783-aec2-a6172a6e008b'; -- Your user ID
  v_total_profiles INTEGER;
  v_swiped_profiles INTEGER;
  v_matched_profiles INTEGER;
  v_available_profiles INTEGER;
  rec RECORD;
BEGIN
  RAISE NOTICE '🔍 DEBUGGING: Why are there no profiles available?';
  RAISE NOTICE '================================================';
  
  -- Count total active profiles (excluding self)
  SELECT COUNT(*) INTO v_total_profiles
  FROM profiles p
  WHERE p.id != v_target_user_id
    AND p.is_active = true;
  
  RAISE NOTICE '📊 Total active profiles (excluding self): %', v_total_profiles;
  
  -- Count profiles you've swiped on
  SELECT COUNT(*) INTO v_swiped_profiles
  FROM swipes s
  WHERE s.swiper_id = v_target_user_id;
  
  RAISE NOTICE '📊 Profiles you have swiped on: %', v_swiped_profiles;
  
  -- Count profiles you're matched with
  SELECT COUNT(*) INTO v_matched_profiles
  FROM matches m
  WHERE (m.user_id_1 = v_target_user_id OR m.user_id_2 = v_target_user_id)
    AND m.status IN ('matched', 'active');
  
  RAISE NOTICE '📊 Profiles you are matched with: %', v_matched_profiles;
  
  -- Count available profiles (what get_profiles_with_super_likes should return)
  SELECT COUNT(*) INTO v_available_profiles
  FROM profiles p
  WHERE p.id != v_target_user_id
    AND p.is_active = true
    AND NOT EXISTS (
      SELECT 1 
      FROM swipes s2 
      WHERE s2.swiper_id = v_target_user_id 
        AND s2.swiped_id = p.id
    )
    AND NOT EXISTS (
      SELECT 1 
      FROM matches m 
      WHERE ((m.user_id_1 = v_target_user_id AND m.user_id_2 = p.id)
          OR (m.user_id_1 = p.id AND m.user_id_2 = v_target_user_id))
        AND m.status IN ('matched', 'active')
    );
  
  RAISE NOTICE '📊 Available profiles (not swiped, not matched): %', v_available_profiles;
  RAISE NOTICE '';
  RAISE NOTICE '🔍 Detailed breakdown:';
  RAISE NOTICE '================================================';
  
  -- Show all profiles you've swiped on
  RAISE NOTICE '';
  RAISE NOTICE '📋 Profiles you have swiped on:';
  FOR rec IN 
    SELECT s.swiped_id, p.name, s.action, s.created_at, s.can_rewind
    FROM swipes s
    JOIN profiles p ON p.id = s.swiped_id
    WHERE s.swiper_id = v_target_user_id
    ORDER BY s.created_at DESC
  LOOP
    RAISE NOTICE '   - % (%) - Action: %, Can Rewind: %, Swiped: %', 
      rec.name, rec.swiped_id, rec.action, rec.can_rewind, rec.created_at;
  END LOOP;
  
  -- Show all available profiles
  RAISE NOTICE '';
  RAISE NOTICE '📋 Available profiles (should appear in discover):';
  FOR rec IN 
    SELECT p.id, p.name, p.is_active, p.gender
    FROM profiles p
    WHERE p.id != v_target_user_id
      AND p.is_active = true
      AND NOT EXISTS (
        SELECT 1 
        FROM swipes s2 
        WHERE s2.swiper_id = v_target_user_id 
          AND s2.swiped_id = p.id
      )
      AND NOT EXISTS (
        SELECT 1 
        FROM matches m 
        WHERE ((m.user_id_1 = v_target_user_id AND m.user_id_2 = p.id)
            OR (m.user_id_1 = p.id AND m.user_id_2 = v_target_user_id))
          AND m.status IN ('matched', 'active')
      )
    ORDER BY p.created_at DESC
    LIMIT 10
  LOOP
    RAISE NOTICE '   ✅ % (ID: %, Gender: %, Active: %)', 
      rec.name, rec.id, rec.gender, rec.is_active;
  END LOOP;
  
  RAISE NOTICE '';
  RAISE NOTICE '💡 SOLUTION:';
  IF v_available_profiles = 0 AND v_total_profiles > 0 THEN
    RAISE NOTICE '   ⚠️ All profiles have been swiped on or matched!';
    RAISE NOTICE '   💡 To test rewind, you need to either:';
    RAISE NOTICE '      1. Create new test profiles';
    RAISE NOTICE '      2. Delete some of your swipes to make profiles available again';
    RAISE NOTICE '      3. Run reset_swipes_for_testing.sql to delete all your swipes';
  ELSIF v_total_profiles = 0 THEN
    RAISE NOTICE '   ⚠️ No active profiles exist in the database (excluding yourself)';
    RAISE NOTICE '   💡 You need to create test profiles first';
  ELSE
    RAISE NOTICE '   ✅ There should be % profiles available', v_available_profiles;
    RAISE NOTICE '   💡 If none are showing, check the function get_profiles_with_super_likes';
  END IF;
  
END $$;

-- Return summary as a table (easier to view in Supabase)
SELECT 
  'Summary' as category,
  COUNT(DISTINCT p.id) as total_active_profiles,
  (SELECT COUNT(*) FROM swipes WHERE swiper_id = '7ffe44fe-9c0f-4783-aec2-a6172a6e008b') as swiped_profiles,
  (SELECT COUNT(*) FROM matches 
   WHERE (user_id_1 = '7ffe44fe-9c0f-4783-aec2-a6172a6e008b' OR user_id_2 = '7ffe44fe-9c0f-4783-aec2-a6172a6e008b')
     AND status IN ('matched', 'active')) as matched_profiles,
  (SELECT COUNT(*) 
   FROM profiles p2
   WHERE p2.id != '7ffe44fe-9c0f-4783-aec2-a6172a6e008b'
     AND p2.is_active = true
     AND NOT EXISTS (
       SELECT 1 FROM swipes s2 
       WHERE s2.swiper_id = '7ffe44fe-9c0f-4783-aec2-a6172a6e008b' 
         AND s2.swiped_id = p2.id
     )
     AND NOT EXISTS (
       SELECT 1 FROM matches m2 
       WHERE ((m2.user_id_1 = '7ffe44fe-9c0f-4783-aec2-a6172a6e008b' AND m2.user_id_2 = p2.id)
           OR (m2.user_id_1 = p2.id AND m2.user_id_2 = '7ffe44fe-9c0f-4783-aec2-a6172a6e008b'))
         AND m2.status IN ('matched', 'active')
     )
  ) as available_profiles
FROM profiles p
WHERE p.id != '7ffe44fe-9c0f-4783-aec2-a6172a6e008b'
  AND p.is_active = true;

-- Show all swiped profiles
SELECT 
  'Swiped Profiles' as category,
  p.name,
  s.action,
  s.created_at as swiped_at,
  s.can_rewind,
  s.id as swipe_id
FROM swipes s
JOIN profiles p ON p.id = s.swiped_id
WHERE s.swiper_id = '7ffe44fe-9c0f-4783-aec2-a6172a6e008b'
ORDER BY s.created_at DESC;

-- Show available profiles (should appear in discover)
SELECT 
  'Available Profiles' as category,
  p.id,
  p.name,
  p.age,
  p.gender,
  p.is_active
FROM profiles p
WHERE p.id != '7ffe44fe-9c0f-4783-aec2-a6172a6e008b'
  AND p.is_active = true
  AND NOT EXISTS (
    SELECT 1 
    FROM swipes s2 
    WHERE s2.swiper_id = '7ffe44fe-9c0f-4783-aec2-a6172a6e008b'
      AND s2.swiped_id = p.id
  )
  AND NOT EXISTS (
    SELECT 1 
    FROM matches m 
    WHERE ((m.user_id_1 = '7ffe44fe-9c0f-4783-aec2-a6172a6e008b' AND m.user_id_2 = p.id)
        OR (m.user_id_1 = p.id AND m.user_id_2 = '7ffe44fe-9c0f-4783-aec2-a6172a6e008b'))
      AND m.status IN ('matched', 'active')
  )
ORDER BY p.created_at DESC
LIMIT 20;

