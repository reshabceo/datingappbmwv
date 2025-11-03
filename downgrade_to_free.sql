-- Downgrade Profile from Premium to Free
-- This script downgrades your profile from premium to free status

DO $$
DECLARE
  v_target_user_id UUID := '7ffe44fe-9c0f-4783-aec2-a6172a6e008b'; -- Your user ID
BEGIN
  -- Check if target user exists
  IF NOT EXISTS (SELECT 1 FROM profiles WHERE id = v_target_user_id) THEN
    RAISE NOTICE '❌ Target user profile does not exist.';
    RETURN;
  END IF;
  
  -- Update profiles table to set free status
  UPDATE profiles
  SET 
    is_premium = FALSE,
    premium_until = NULL,
    updated_at = NOW()
  WHERE id = v_target_user_id;
  
  -- Try to delete premium_subscriptions if table exists
  BEGIN
    DELETE FROM premium_subscriptions
    WHERE user_id = v_target_user_id;
  EXCEPTION
    WHEN undefined_table THEN
      RAISE NOTICE '⚠️ premium_subscriptions table does not exist, skipping...';
    WHEN OTHERS THEN
      RAISE NOTICE '⚠️ Could not delete premium_subscriptions: %', SQLERRM;
  END;
  
  RAISE NOTICE '✅ Account downgraded to free successfully!';
  RAISE NOTICE '   User ID: %', v_target_user_id;
  RAISE NOTICE '';
  RAISE NOTICE '💡 Free tier limitations now apply:';
  RAISE NOTICE '   - Limited swipes per day';
  RAISE NOTICE '   - Limited super likes per day';
  RAISE NOTICE '   - Limited messages per day';
  RAISE NOTICE '   - No rewind functionality';
  RAISE NOTICE '   - Blurred activity notifications';
  RAISE NOTICE '';
  RAISE NOTICE '🔄 Please reload your app to see the free status update!';
  
END $$;

-- Verify the downgrade
SELECT 
  p.id,
  p.name,
  p.is_premium,
  p.premium_until,
  CASE 
    WHEN p.is_premium = true AND (p.premium_until IS NULL OR p.premium_until > NOW()) 
    THEN '✅ ACTIVE PREMIUM'
    ELSE '❌ FREE USER'
  END as premium_status
FROM profiles p
WHERE p.id = '7ffe44fe-9c0f-4783-aec2-a6172a6e008b';


