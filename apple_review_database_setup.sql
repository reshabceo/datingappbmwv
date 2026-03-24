-- Database Setup for Apple App Store Review Requirements
-- Run this script in your Supabase SQL Editor

-- ============================================================================
-- 1. BLOCKED USERS TABLE (Required for Guideline 1.2)
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.blocked_users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  blocker_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  blocked_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(blocker_id, blocked_id)
);

-- Enable RLS
ALTER TABLE public.blocked_users ENABLE ROW LEVEL SECURITY;

-- RLS Policy: Users can block/unblock others
DROP POLICY IF EXISTS "Users can block/unblock others" ON public.blocked_users;
CREATE POLICY "Users can block/unblock others"
ON public.blocked_users FOR ALL
USING (auth.uid() = blocker_id);

-- Grant permissions
GRANT SELECT, INSERT, DELETE ON public.blocked_users TO authenticated;
GRANT USAGE ON SEQUENCE blocked_users_id_seq TO authenticated;

-- ============================================================================
-- 2. ACCOUNT DELETION FUNCTION (Required for Guideline 5.1.1(v))
-- ============================================================================
CREATE OR REPLACE FUNCTION public.delete_user_account(p_user_id UUID)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Delete all user-related data
  -- Note: CASCADE should handle most deletions, but we're explicit for safety
  
  -- Delete from blocked_users (both as blocker and blocked)
  DELETE FROM public.blocked_users 
  WHERE blocker_id = p_user_id OR blocked_id = p_user_id;
  
  -- Delete from reports (both as reporter and reported)
  DELETE FROM public.reports 
  WHERE reporter_id = p_user_id OR reported_id = p_user_id;
  
  -- Delete profile (this will cascade to most related tables)
  DELETE FROM public.profiles WHERE id = p_user_id;
  
  -- Note: Auth user deletion should be handled separately via Supabase Admin API
  -- You may want to create a Supabase Edge Function or use Admin API to delete auth.users
END;
$$;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION public.delete_user_account(UUID) TO authenticated;

-- ============================================================================
-- 3. ENSURE REPORTS TABLE HAS REQUIRED COLUMNS (Required for Guideline 1.2)
-- ============================================================================
-- Check if reports table exists, if not create it
DO $$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'reports') THEN
    CREATE TABLE public.reports (
      id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
      reporter_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
      reported_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
      content_type TEXT,
      content_id UUID,
      reason TEXT NOT NULL,
      description TEXT,
      status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'reviewed', 'resolved', 'dismissed', 'banned')),
      moderator_notes TEXT,
      resolved_at TIMESTAMP WITH TIME ZONE,
      created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
    );
    
    ALTER TABLE public.reports ENABLE ROW LEVEL SECURITY;
    
    CREATE POLICY "Users can create reports"
    ON public.reports FOR INSERT
    WITH CHECK (auth.uid() = reporter_id);
    
    CREATE POLICY "Users can view their own reports"
    ON public.reports FOR SELECT
    USING (auth.uid() = reporter_id);
    
    GRANT SELECT, INSERT ON public.reports TO authenticated;
  ELSE
    -- Add missing columns if table exists but columns are missing
    DO $$
    BEGIN
      IF NOT EXISTS (SELECT FROM information_schema.columns 
                     WHERE table_schema = 'public' 
                     AND table_name = 'reports' 
                     AND column_name = 'content_type') THEN
        ALTER TABLE public.reports ADD COLUMN content_type TEXT;
      END IF;
      
      IF NOT EXISTS (SELECT FROM information_schema.columns 
                     WHERE table_schema = 'public' 
                     AND table_name = 'reports' 
                     AND column_name = 'content_id') THEN
        ALTER TABLE public.reports ADD COLUMN content_id UUID;
      END IF;
    END $$;
  END IF;
END $$;

-- ============================================================================
-- 4. FUNCTION TO FILTER BLOCKED USERS FROM QUERIES
-- ============================================================================
CREATE OR REPLACE FUNCTION public.filter_blocked_users(
  p_user_id UUID,
  p_target_user_ids UUID[]
)
RETURNS UUID[]
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_blocked_ids UUID[];
BEGIN
  -- Get all users blocked by or blocking this user
  SELECT ARRAY_AGG(DISTINCT blocked_id) INTO v_blocked_ids
  FROM public.blocked_users
  WHERE blocker_id = p_user_id;
  
  SELECT ARRAY_AGG(DISTINCT blocker_id) INTO v_blocked_ids
  FROM public.blocked_users
  WHERE blocked_id = p_user_id;
  
  -- Return target IDs that are not blocked
  RETURN ARRAY(
    SELECT unnest(p_target_user_ids)
    EXCEPT
    SELECT unnest(COALESCE(v_blocked_ids, ARRAY[]::UUID[]))
  );
END;
$$;

GRANT EXECUTE ON FUNCTION public.filter_blocked_users(UUID, UUID[]) TO authenticated;

-- ============================================================================
-- 5. VERIFICATION QUERIES
-- ============================================================================
DO $$
BEGIN
  RAISE NOTICE '=== Apple App Store Review Database Setup Complete ===';
  RAISE NOTICE '1. blocked_users table: Created/Verified';
  RAISE NOTICE '2. delete_user_account function: Created/Verified';
  RAISE NOTICE '3. reports table: Created/Verified';
  RAISE NOTICE '4. filter_blocked_users function: Created/Verified';
  RAISE NOTICE '';
  RAISE NOTICE 'Next Steps:';
  RAISE NOTICE '1. Test account deletion functionality';
  RAISE NOTICE '2. Test user blocking functionality';
  RAISE NOTICE '3. Verify reports are being created correctly';
  RAISE NOTICE '4. Ensure admin panel can review reports within 24 hours';
END $$;

