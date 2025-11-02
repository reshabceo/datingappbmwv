-- Unmatch Luna for Premium Message Testing
-- This script unmatchs you with Luna so you can test premium message notifications
-- Run this BEFORE running test_premium_message.sql

DO $$
DECLARE
  v_luna_id UUID := '11111111-aaaa-4444-8888-555555555555'; -- Luna
  v_target_user_id UUID := '7ffe44fe-9c0f-4783-aec2-a6172a6e008b'; -- Your user ID
  v_match_id UUID;
BEGIN
  -- Find the match
  SELECT id INTO v_match_id
  FROM matches
  WHERE ((user_id_1 = v_target_user_id AND user_id_2 = v_luna_id)
      OR (user_id_1 = v_luna_id AND user_id_2 = v_target_user_id))
    AND status IN ('matched', 'active')
  LIMIT 1;
  
  IF v_match_id IS NULL THEN
    RAISE NOTICE '✅ No match found with Luna - you are already unmatched!';
  ELSE
    -- Delete the match
    DELETE FROM matches WHERE id = v_match_id;
    RAISE NOTICE '✅ Unmatched with Luna successfully!';
    RAISE NOTICE '   Match ID: %', v_match_id;
    RAISE NOTICE '';
    RAISE NOTICE '💡 Now you can run test_premium_message.sql to see the premium message notification!';
  END IF;
END $$;

