-- -----------------------------------------------------------------------------
-- add_flame_chat_test_profile.sql
--
-- Creates a premium female profile that super-likes your account so she shows
-- up at the very top of the discovery deck.  Replace the placeholder user ID
-- below with your own profile ID (the account you are testing with) before
-- running this script in the Supabase SQL editor/service role connection.
-- -----------------------------------------------------------------------------

DO $$
DECLARE
  v_target_user UUID := '7ffe44fe-9c0f-4783-aec2-a6172a6e008b'; -- <-- update this!
  v_profile_id UUID := '11111111-aaaa-4444-8888-555555555555';
BEGIN
  IF v_target_user::TEXT LIKE 'REPLACE_WITH_%' THEN
    RAISE EXCEPTION 'Please set v_target_user to your actual profile ID before running add_flame_chat_test_profile.sql';
  END IF;

  -- Clean up any previous test data with the same ID
  -- Delete swipes in both directions
  DELETE FROM swipes WHERE swiper_id = v_profile_id OR swiped_id = v_profile_id;
  DELETE FROM swipes WHERE (swiper_id = v_target_user AND swiped_id = v_profile_id)
                          OR (swiped_id = v_target_user AND swiper_id = v_profile_id);
  
  -- Delete matches in both directions (including unmatched ones)
  DELETE FROM matches WHERE user_id_1 = v_profile_id OR user_id_2 = v_profile_id;
  DELETE FROM matches WHERE (user_id_1 = v_target_user AND user_id_2 = v_profile_id)
                          OR (user_id_2 = v_target_user AND user_id_1 = v_profile_id);
  
  -- Delete any bff matches
  DELETE FROM bff_matches WHERE user_id_1 = v_profile_id OR user_id_2 = v_profile_id;
  DELETE FROM bff_matches WHERE (user_id_1 = v_target_user AND user_id_2 = v_profile_id)
                              OR (user_id_2 = v_target_user AND user_id_1 = v_profile_id);
  
  -- Delete any messages between the two users
  DELETE FROM messages WHERE match_id IN (
    SELECT id FROM matches WHERE 
      (user_id_1 = v_profile_id AND user_id_2 = v_target_user) OR
      (user_id_2 = v_profile_id AND user_id_1 = v_target_user)
  );
  
  -- Finally delete the profile
  DELETE FROM profiles WHERE id = v_profile_id;

  -- Insert the new premium female profile (dating only)
  INSERT INTO profiles (
    id,
    email,
    name,
    age,
    location,
    description,
    latitude,
    longitude,
    image_urls,
    photos,
    hobbies,
    mode_preferences,
    is_active,
    is_premium,
    created_at,
    updated_at,
    last_seen
  ) VALUES (
    v_profile_id,
    'flame.tester@example.com',
    'Luna',
    27,
    'San Francisco, CA',
    'Product designer who loves last-minute adventures, latte art, and deep chats after midnight.',
    37.7749,
    -122.4194,
    to_jsonb(ARRAY['https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=900&auto=format&fit=crop']),
    to_jsonb(ARRAY['https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=900&auto=format&fit=crop']),
    to_jsonb(ARRAY['Design', 'Coffee', 'Night drives', 'Live music']),
    '{"dating": true, "bff": false}'::jsonb,
    true,
    true,
    NOW(),
    NOW(),
    NOW()
  ) ON CONFLICT (id) DO UPDATE
  SET
    email = EXCLUDED.email,
    name = EXCLUDED.name,
    age = EXCLUDED.age,
    location = EXCLUDED.location,
    description = EXCLUDED.description,
    latitude = EXCLUDED.latitude,
    longitude = EXCLUDED.longitude,
    image_urls = EXCLUDED.image_urls,
    photos = EXCLUDED.photos,
    hobbies = EXCLUDED.hobbies,
    mode_preferences = EXCLUDED.mode_preferences,
    is_active = EXCLUDED.is_active,
    is_premium = EXCLUDED.is_premium,
    created_at = NOW(),
    updated_at = NOW(),
    last_seen = NOW();

  -- Make sure your account hasn’t already swiped on this test profile
  DELETE FROM swipes WHERE swiper_id = v_target_user AND swiped_id = v_profile_id;

  -- Have the test profile super-like you so she appears first in the deck
  INSERT INTO swipes (swiper_id, swiped_id, action, created_at)
  VALUES (v_profile_id, v_target_user, 'super_like', NOW())
  ON CONFLICT (swiper_id, swiped_id)
  DO UPDATE SET action = 'super_like', created_at = EXCLUDED.created_at;

  RAISE NOTICE '🔥 Flame test profile created (ID: %). She has super-liked user %.', v_profile_id, v_target_user;
EXCEPTION
  WHEN others THEN
    RAISE; -- bubble up any unexpected error so it’s visible in the SQL console
END $$;

