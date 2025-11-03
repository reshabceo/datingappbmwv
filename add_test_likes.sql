-- Add 4 Dummy Profiles Who Liked You
-- This script creates 4 test profiles and adds likes from them to your profile

DO $$
DECLARE
  v_target_user_id UUID := '7ffe44fe-9c0f-4783-aec2-a6172a6e008b'; -- Your user ID
  v_profile_ids UUID[];
  v_profile_id UUID;
BEGIN
  -- Check if target user exists
  IF NOT EXISTS (SELECT 1 FROM profiles WHERE id = v_target_user_id) THEN
    RAISE NOTICE '❌ Target user profile does not exist.';
    RETURN;
  END IF;
  
  -- Create 4 dummy profiles
  v_profile_ids := ARRAY[
    gen_random_uuid(),
    gen_random_uuid(),
    gen_random_uuid(),
    gen_random_uuid()
  ];
  
  -- Profile 1: Emma
  v_profile_id := v_profile_ids[1];
  INSERT INTO profiles (
    id, name, age, gender, is_active, created_at, updated_at
  ) VALUES (
    v_profile_id,
    'Emma',
    24,
    'Female',
    true,
    NOW(),
    NOW()
  )
  ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    age = EXCLUDED.age,
    updated_at = NOW();
  
  -- Profile 2: Olivia
  v_profile_id := v_profile_ids[2];
  INSERT INTO profiles (
    id, name, age, gender, is_active, created_at, updated_at
  ) VALUES (
    v_profile_id,
    'Olivia',
    26,
    'Female',
    true,
    NOW(),
    NOW()
  )
  ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    age = EXCLUDED.age,
    updated_at = NOW();
  
  -- Profile 3: Sophia
  v_profile_id := v_profile_ids[3];
  INSERT INTO profiles (
    id, name, age, gender, is_active, created_at, updated_at
  ) VALUES (
    v_profile_id,
    'Sophia',
    25,
    'Female',
    true,
    NOW(),
    NOW()
  )
  ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    age = EXCLUDED.age,
    updated_at = NOW();
  
  -- Profile 4: Isabella
  v_profile_id := v_profile_ids[4];
  INSERT INTO profiles (
    id, name, age, gender, is_active, created_at, updated_at
  ) VALUES (
    v_profile_id,
    'Isabella',
    23,
    'Female',
    true,
    NOW(),
    NOW()
  )
  ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    age = EXCLUDED.age,
    updated_at = NOW();
  
  -- Delete any existing swipes from these profiles to you (to avoid duplicates)
  DELETE FROM swipes
  WHERE swiper_id = ANY(v_profile_ids)
    AND swiped_id = v_target_user_id
    AND action IN ('like', 'super_like');
  
  -- Add likes from these profiles to you
  -- Profile 1: Emma - regular like
  INSERT INTO swipes (swiper_id, swiped_id, action, created_at)
  VALUES (v_profile_ids[1], v_target_user_id, 'like', NOW() - INTERVAL '2 hours')
  ON CONFLICT DO NOTHING;
  
  -- Profile 2: Olivia - super like
  INSERT INTO swipes (swiper_id, swiped_id, action, created_at)
  VALUES (v_profile_ids[2], v_target_user_id, 'super_like', NOW() - INTERVAL '1 hour')
  ON CONFLICT DO NOTHING;
  
  -- Profile 3: Sophia - regular like
  INSERT INTO swipes (swiper_id, swiped_id, action, created_at)
  VALUES (v_profile_ids[3], v_target_user_id, 'like', NOW() - INTERVAL '30 minutes')
  ON CONFLICT DO NOTHING;
  
  -- Profile 4: Isabella - regular like (most recent)
  INSERT INTO swipes (swiper_id, swiped_id, action, created_at)
  VALUES (v_profile_ids[4], v_target_user_id, 'like', NOW() - INTERVAL '5 minutes')
  ON CONFLICT DO NOTHING;
  
  RAISE NOTICE '✅ Successfully added 4 dummy profiles who liked you!';
  RAISE NOTICE '';
  RAISE NOTICE '📋 Profile Details:';
  RAISE NOTICE '   1. Emma (24, Female) - Liked 2 hours ago';
  RAISE NOTICE '   2. Olivia (26, Female) - Super liked 1 hour ago';
  RAISE NOTICE '   3. Sophia (25, Female) - Liked 30 minutes ago';
  RAISE NOTICE '   4. Isabella (23, Female) - Liked 5 minutes ago (Most Recent)';
  RAISE NOTICE '';
  RAISE NOTICE '🔄 The potential matches notification bar should now show:';
  RAISE NOTICE '   - Blurred profile picture of Isabella (last liker)';
  RAISE NOTICE '   - "+3" badge';
  RAISE NOTICE '   - "You have 4 potential matches" message';
  RAISE NOTICE '';
  RAISE NOTICE '💡 Reload your app to see the changes!';
  
END $$;

-- Verify the likes were added
SELECT 
  p.name,
  p.age,
  p.gender,
  s.action,
  s.created_at as liked_at
FROM swipes s
JOIN profiles p ON p.id = s.swiper_id
WHERE s.swiped_id = '7ffe44fe-9c0f-4783-aec2-a6172a6e008b'
  AND s.action IN ('like', 'super_like')
  AND NOT EXISTS (
    SELECT 1 FROM matches m 
    WHERE (m.user_id_1 = '7ffe44fe-9c0f-4783-aec2-a6172a6e008b' AND m.user_id_2 = s.swiper_id)
       OR (m.user_id_2 = '7ffe44fe-9c0f-4783-aec2-a6172a6e008b' AND m.user_id_1 = s.swiper_id)
  )
ORDER BY s.created_at DESC
LIMIT 10;

