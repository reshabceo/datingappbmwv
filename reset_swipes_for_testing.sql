-- Reset Swipes for Testing - Remove all your swipes to make profiles available again
-- This is useful for testing rewind functionality

DO $$
DECLARE
  v_target_user_id UUID := '7ffe44fe-9c0f-4783-aec2-a6172a6e008b'; -- Your user ID
  v_deleted_count INTEGER;
BEGIN
  RAISE NOTICE '🔄 Resetting swipes for user %...', v_target_user_id;
  
  -- Delete all swipes made by this user
  DELETE FROM swipes
  WHERE swiper_id = v_target_user_id;
  
  GET DIAGNOSTICS v_deleted_count = ROW_COUNT;
  
  RAISE NOTICE '✅ Deleted % swipes', v_deleted_count;
  RAISE NOTICE '';
  RAISE NOTICE '💡 Now profiles should be available again:';
  RAISE NOTICE '   - All previously swiped profiles will reappear';
  RAISE NOTICE '   - You can test rewind functionality';
  RAISE NOTICE '   - Run check_available_profiles.sql to verify';
  
END $$;

-- Verify available profiles after reset
SELECT 
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
LIMIT 10;

