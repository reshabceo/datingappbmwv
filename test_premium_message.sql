-- Test Premium Message Script
-- This creates a dummy premium message from Luna to test the notification display
-- NOTE: Premium messages are for BEFORE matching. If you're already matched with Luna,
--       the premium message will be filtered out. To test premium messages:
--       1. Unmatch with Luna first, OR
--       2. Use a different test profile who you're not matched with

-- User IDs
DO $$
DECLARE
  v_luna_id UUID := '11111111-aaaa-4444-8888-555555555555'; -- Luna (premium user)
  v_target_user_id UUID := '7ffe44fe-9c0f-4783-aec2-a6172a6e008b'; -- Your user ID
  v_message_content TEXT := 'Hey! I saw your profile and thought you seem really interesting. Would love to chat! 😊';
  v_existing_count INTEGER;
  v_is_matched BOOLEAN := false;
BEGIN
  -- Check if Luna profile exists
  IF NOT EXISTS (SELECT 1 FROM profiles WHERE id = v_luna_id) THEN
    RAISE NOTICE '❌ Luna profile does not exist. Run add_flame_chat_test_profile.sql first.';
    RETURN;
  END IF;
  
  -- Check if target user exists
  IF NOT EXISTS (SELECT 1 FROM profiles WHERE id = v_target_user_id) THEN
    RAISE NOTICE '❌ Target user profile does not exist.';
    RETURN;
  END IF;
  
  -- Check if already matched with Luna
  SELECT EXISTS (
    SELECT 1 FROM matches 
    WHERE (user_id_1 = v_target_user_id AND user_id_2 = v_luna_id)
       OR (user_id_1 = v_luna_id AND user_id_2 = v_target_user_id)
    AND status IN ('matched', 'active')
  ) INTO v_is_matched;
  
  IF v_is_matched THEN
    RAISE NOTICE '⚠️ WARNING: You are already matched with Luna!';
    RAISE NOTICE '   Premium messages are filtered out for matched users (they should use regular chat).';
    RAISE NOTICE '   To test premium messages, you need to UNMATCH with Luna first.';
    RAISE NOTICE '';
    RAISE NOTICE '   Would you like to:';
    RAISE NOTICE '   1. Unmatch with Luna and create premium message (recommended for testing)';
    RAISE NOTICE '   2. Create premium message anyway (it will be filtered out)';
    RAISE NOTICE '';
    RAISE NOTICE '   For now, creating the premium message anyway...';
  END IF;
  
  -- Check if there's already a premium message (avoid duplicates)
  SELECT COUNT(*) INTO v_existing_count
  FROM premium_messages
  WHERE sender_id = v_luna_id 
    AND recipient_id = v_target_user_id
    AND created_at > NOW() - INTERVAL '1 hour'; -- Only check recent messages
  
  IF v_existing_count > 0 THEN
    RAISE NOTICE '⚠️ A recent premium message from Luna already exists. Deleting old ones...';
    -- Delete old test messages from Luna
    DELETE FROM premium_messages
    WHERE sender_id = v_luna_id 
      AND recipient_id = v_target_user_id;
  END IF;
  
  -- Insert test premium message
  INSERT INTO premium_messages (
    sender_id,
    recipient_id,
    message_content,
    is_blurred,
    created_at
  ) VALUES (
    v_luna_id,
    v_target_user_id,
    v_message_content,
    true, -- Always blurred until recipient upgrades
    NOW()
  );
  
  RAISE NOTICE '✅ Premium message created successfully!';
  RAISE NOTICE '   From: Luna (ID: %)', v_luna_id;
  RAISE NOTICE '   To: Your user (ID: %)', v_target_user_id;
  RAISE NOTICE '   Message: "%"', v_message_content;
  RAISE NOTICE '';
  IF v_is_matched THEN
    RAISE NOTICE '⚠️ NOTE: Since you are matched with Luna, this premium message will NOT appear in Activity.';
    RAISE NOTICE '   Premium messages are only shown for users you are NOT matched with.';
    RAISE NOTICE '   To see the premium message notification, unmatch with Luna first.';
  ELSE
    RAISE NOTICE '💡 Now check your Activity screen:';
    RAISE NOTICE '   - As a FREE user: You will see "Someone sent you a message" with blurred photo';
    RAISE NOTICE '   - As a PREMIUM user: You will see "Luna sent you: Hey! I saw your profile..." with clear photo';
  END IF;
  
END $$;

-- Verify the message was created
SELECT 
  pm.id,
  sender.name as sender_name,
  recipient.name as recipient_name,
  LEFT(pm.message_content, 50) || '...' as message_preview,
  pm.is_blurred,
  pm.created_at
FROM premium_messages pm
JOIN profiles sender ON sender.id = pm.sender_id
JOIN profiles recipient ON recipient.id = pm.recipient_id
WHERE pm.sender_id = '11111111-aaaa-4444-8888-555555555555'
  AND pm.recipient_id = '7ffe44fe-9c0f-4783-aec2-a6172a6e008b'
ORDER BY pm.created_at DESC
LIMIT 1;

