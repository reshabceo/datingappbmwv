-- Reset Daily Usage for Testing
-- This script resets the daily swipe/limit counters for a specific user
-- Use this when you hit your daily limit during testing

-- Replace this UUID with your actual user ID
-- Current user ID from logs: 7ffe44fe-9c0f-4783-aec2-a6172a6e008b

DO $$
DECLARE
  v_user_id UUID := '7ffe44fe-9c0f-4783-aec2-a6172a6e008b'; -- Your user ID
  v_today DATE := CURRENT_DATE;
BEGIN
  -- Delete today's usage record (if exists)
  DELETE FROM user_daily_limits 
  WHERE user_id = v_user_id 
    AND date = v_today;
  
  RAISE NOTICE '✅ Reset daily usage for user % on date %', v_user_id, v_today;
  RAISE NOTICE '   - Swipes used: 0';
  RAISE NOTICE '   - Super likes used: 0';
  RAISE NOTICE '   - Messages sent: 0';
  RAISE NOTICE '';
  RAISE NOTICE '💡 You can now swipe again!';
END $$;

-- Verify the reset
SELECT 
  user_id,
  date,
  COALESCE(swipes_used, 0) as swipes_used,
  COALESCE(super_likes_used, 0) as super_likes_used,
  COALESCE(messages_sent, 0) as messages_sent
FROM user_daily_limits
WHERE user_id = '7ffe44fe-9c0f-4783-aec2-a6172a6e008b'
  AND date = CURRENT_DATE;

