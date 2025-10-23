-- VERIFY FREEMIUM SETUP (SUPABASE SQL EDITOR COMPATIBLE)
-- Run this script in Supabase SQL Editor after applying the fix

-- =============================================================================
-- 1. CHECK TABLES
-- =============================================================================

SELECT 
  'Tables Check' as test_category,
  table_name,
  CASE 
    WHEN EXISTS (
      SELECT 1 FROM information_schema.tables 
      WHERE table_schema = 'public' AND table_name = t.table_name
    ) THEN '✅ EXISTS'
    ELSE '❌ MISSING'
  END as status
FROM (
  VALUES 
    ('user_daily_limits'),
    ('premium_messages'),
    ('in_app_purchases'),
    ('premium_subscriptions')
) AS t(table_name);

-- =============================================================================
-- 2. CHECK FOREIGN KEY CONSTRAINTS
-- =============================================================================

SELECT
  'Foreign Keys' as test_category,
  tc.table_name,
  tc.constraint_name,
  kcu.column_name || ' → ' || ccu.table_name || '(' || ccu.column_name || ')' as reference,
  '✅ OK' as status
FROM information_schema.table_constraints AS tc
JOIN information_schema.key_column_usage AS kcu
  ON tc.constraint_name = kcu.constraint_name
JOIN information_schema.constraint_column_usage AS ccu
  ON ccu.constraint_name = tc.constraint_name
WHERE tc.constraint_type = 'FOREIGN KEY'
  AND tc.table_name IN (
    'user_daily_limits',
    'premium_messages',
    'in_app_purchases',
    'premium_subscriptions'
  )
ORDER BY tc.table_name;

-- =============================================================================
-- 3. CHECK FUNCTIONS
-- =============================================================================

SELECT 
  'Functions' as test_category,
  routine_name,
  routine_type,
  '✅ EXISTS' as status
FROM information_schema.routines
WHERE routine_schema = 'public'
  AND routine_name IN (
    'can_perform_action',
    'increment_daily_usage',
    'add_super_likes',
    'activate_premium_subscription'
  )
ORDER BY routine_name;

-- =============================================================================
-- 4. CHECK INDEXES
-- =============================================================================

SELECT
  'Indexes' as test_category,
  tablename,
  indexname,
  '✅ EXISTS' as status
FROM pg_indexes
WHERE schemaname = 'public'
  AND (
    indexname LIKE 'idx_user_daily_limits%' OR
    indexname LIKE 'idx_premium_messages%' OR
    indexname LIKE 'idx_in_app_purchases%' OR
    indexname LIKE 'idx_premium_subscriptions%'
  )
ORDER BY tablename, indexname;

-- =============================================================================
-- 5. CHECK RLS POLICIES
-- =============================================================================

SELECT
  'RLS Policies' as test_category,
  tablename,
  policyname,
  cmd as operation,
  '✅ EXISTS' as status
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename IN (
    'user_daily_limits',
    'premium_messages',
    'in_app_purchases',
    'premium_subscriptions'
  )
ORDER BY tablename, policyname;

-- =============================================================================
-- 6. CHECK RLS IS ENABLED
-- =============================================================================

SELECT
  'RLS Status' as test_category,
  tablename,
  CASE 
    WHEN rowsecurity THEN '✅ ENABLED'
    ELSE '❌ DISABLED'
  END as status
FROM pg_tables
WHERE schemaname = 'public'
  AND tablename IN (
    'user_daily_limits',
    'premium_messages',
    'in_app_purchases',
    'premium_subscriptions'
  )
ORDER BY tablename;

-- =============================================================================
-- 7. CHECK FOR ORPHANED DATA
-- =============================================================================

SELECT 
  'Orphaned Data Check' as test_category,
  'user_daily_limits' as table_name,
  COUNT(*) as orphaned_records,
  CASE WHEN COUNT(*) = 0 THEN '✅ CLEAN' ELSE '⚠️ HAS ORPHANS' END as status
FROM user_daily_limits 
WHERE user_id NOT IN (SELECT id FROM profiles)
UNION ALL
SELECT 
  'Orphaned Data Check',
  'premium_messages',
  COUNT(*),
  CASE WHEN COUNT(*) = 0 THEN '✅ CLEAN' ELSE '⚠️ HAS ORPHANS' END
FROM premium_messages 
WHERE sender_id NOT IN (SELECT id FROM profiles) 
   OR recipient_id NOT IN (SELECT id FROM profiles)
UNION ALL
SELECT 
  'Orphaned Data Check',
  'in_app_purchases',
  COUNT(*),
  CASE WHEN COUNT(*) = 0 THEN '✅ CLEAN' ELSE '⚠️ HAS ORPHANS' END
FROM in_app_purchases 
WHERE user_id NOT IN (SELECT id FROM profiles)
UNION ALL
SELECT 
  'Orphaned Data Check',
  'premium_subscriptions',
  COUNT(*),
  CASE WHEN COUNT(*) = 0 THEN '✅ CLEAN' ELSE '⚠️ HAS ORPHANS' END
FROM premium_subscriptions 
WHERE user_id NOT IN (SELECT id FROM profiles);

-- =============================================================================
-- 8. CHECK TRIGGERS
-- =============================================================================

SELECT
  'Triggers' as test_category,
  event_object_table as table_name,
  trigger_name,
  event_manipulation as trigger_event,
  '✅ EXISTS' as status
FROM information_schema.triggers
WHERE event_object_schema = 'public'
  AND event_object_table IN (
    'user_daily_limits',
    'premium_messages',
    'in_app_purchases',
    'premium_subscriptions'
  )
ORDER BY event_object_table, trigger_name;

-- =============================================================================
-- 9. CHECK PROFILES TABLE HAS is_premium COLUMN
-- =============================================================================

SELECT 
  'Profiles Table' as test_category,
  'is_premium column' as check_item,
  CASE 
    WHEN EXISTS (
      SELECT 1 FROM information_schema.columns 
      WHERE table_name = 'profiles' AND column_name = 'is_premium'
    ) THEN '✅ EXISTS'
    ELSE '❌ MISSING'
  END as status;

-- =============================================================================
-- 10. SUMMARY
-- =============================================================================

SELECT 
  '====== SUMMARY ======' as summary,
  (SELECT COUNT(*) FROM information_schema.tables 
   WHERE table_schema = 'public' 
   AND table_name IN ('user_daily_limits', 'premium_messages', 'in_app_purchases', 'premium_subscriptions')
  ) as tables_created,
  (SELECT COUNT(*) FROM information_schema.routines
   WHERE routine_schema = 'public'
   AND routine_name IN ('can_perform_action', 'increment_daily_usage', 'add_super_likes', 'activate_premium_subscription')
  ) as functions_created,
  (SELECT COUNT(*) FROM pg_policies
   WHERE schemaname = 'public'
   AND tablename IN ('user_daily_limits', 'premium_messages', 'in_app_purchases', 'premium_subscriptions')
  ) as policies_created,
  (SELECT COUNT(*) FROM pg_indexes
   WHERE schemaname = 'public'
   AND (indexname LIKE 'idx_user_daily_limits%' OR
        indexname LIKE 'idx_premium_messages%' OR
        indexname LIKE 'idx_in_app_purchases%' OR
        indexname LIKE 'idx_premium_subscriptions%')
  ) as indexes_created;

-- =============================================================================
-- 11. FINAL STATUS MESSAGE
-- =============================================================================

SELECT 
  CASE 
    WHEN (
      SELECT COUNT(*) FROM information_schema.tables 
      WHERE table_schema = 'public' 
      AND table_name IN ('user_daily_limits', 'premium_messages', 'in_app_purchases', 'premium_subscriptions')
    ) = 4 
    AND (
      SELECT COUNT(*) FROM information_schema.routines
      WHERE routine_schema = 'public'
      AND routine_name IN ('can_perform_action', 'increment_daily_usage', 'add_super_likes', 'activate_premium_subscription')
    ) = 4
    THEN '✅ FREEMIUM SYSTEM SETUP COMPLETE! All tables, functions, and policies are in place. Ready to use! 🚀'
    ELSE '⚠️ SETUP INCOMPLETE. Please check the results above for missing components.'
  END as final_status;
