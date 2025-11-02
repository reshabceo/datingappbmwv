-- Upgrade Profile to Premium for Testing
-- This script upgrades your profile to premium status to test rewind and message functionality

DO $$
DECLARE
  v_target_user_id UUID := '7ffe44fe-9c0f-4783-aec2-a6172a6e008b'; -- Your user ID
  v_premium_until TIMESTAMP WITH TIME ZONE := NOW() + INTERVAL '1 year'; -- Premium for 1 year
BEGIN
  -- Check if target user exists
  IF NOT EXISTS (SELECT 1 FROM profiles WHERE id = v_target_user_id) THEN
    RAISE NOTICE '❌ Target user profile does not exist.';
    RETURN;
  END IF;
  
  -- Update profiles table to set premium status (direct method)
  UPDATE profiles
  SET is_premium = true,
      premium_until = v_premium_until,
      updated_at = NOW()
  WHERE id = v_target_user_id;
  
  -- Try to insert/update premium_subscriptions if table exists
  BEGIN
    INSERT INTO premium_subscriptions (
      user_id,
      plan_type,
      status,
      start_date,
      end_date,
      payment_method,
      created_at,
      updated_at
    ) VALUES (
      v_target_user_id,
      '1_month',
      'active',
      NOW(),
      v_premium_until,
      'test',
      NOW(),
      NOW()
    )
    ON CONFLICT (user_id) DO UPDATE SET
      status = 'active',
      start_date = NOW(),
      end_date = v_premium_until,
      updated_at = NOW();
  EXCEPTION
    WHEN undefined_table THEN
      RAISE NOTICE '⚠️ premium_subscriptions table does not exist, skipping...';
    WHEN OTHERS THEN
      RAISE NOTICE '⚠️ Could not update premium_subscriptions: %', SQLERRM;
  END;
  
  RAISE NOTICE '✅ Premium subscription activated successfully!';
  RAISE NOTICE '   User ID: %', v_target_user_id;
  RAISE NOTICE '   Premium until: %', v_premium_until;
  RAISE NOTICE '';
  RAISE NOTICE '💡 Premium features now available:';
  RAISE NOTICE '   - Unlimited swipes';
  RAISE NOTICE '   - Unlimited super likes';
  RAISE NOTICE '   - Unlimited messages';
  RAISE NOTICE '   - Rewind functionality';
  RAISE NOTICE '   - Send premium messages';
  RAISE NOTICE '   - See who liked you';
  RAISE NOTICE '   - View all activity notifications clearly';
  RAISE NOTICE '';
  RAISE NOTICE '🔄 Please reload your app to see the premium status update!';
  
END $$;

-- Verify the upgrade
SELECT 
  p.id,
  p.name,
  p.is_premium,
  p.premium_until,
  CASE 
    WHEN p.is_premium = true AND (p.premium_until IS NULL OR p.premium_until > NOW()) 
    THEN '✅ ACTIVE PREMIUM'
    ELSE '❌ NOT PREMIUM'
  END as premium_status
FROM profiles p
WHERE p.id = '7ffe44fe-9c0f-4783-aec2-a6172a6e008b';

