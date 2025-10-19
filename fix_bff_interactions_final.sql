-- Final Fix for BFF Interactions Recording
-- This script completely fixes the BFF interaction recording issue

-- 1. Drop ALL existing record_bff_interaction functions to avoid any conflicts
DROP FUNCTION IF EXISTS public.record_bff_interaction(UUID, UUID, TEXT);
DROP FUNCTION IF EXISTS public.record_bff_interaction(UUID, UUID, VARCHAR);
DROP FUNCTION IF EXISTS public.record_bff_interaction(UUID, UUID, CHARACTER VARYING);
DROP FUNCTION IF EXISTS public.record_bff_interaction(UUID, UUID, VARCHAR(255));
DROP FUNCTION IF EXISTS public.record_bff_interaction(UUID, UUID, VARCHAR(50));

-- 2. Ensure bff_interactions table exists with correct structure
CREATE TABLE IF NOT EXISTS public.bff_interactions (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  target_user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  interaction_type TEXT NOT NULL CHECK (interaction_type IN ('like', 'pass')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, target_user_id)
);

-- 3. Create a single, clean record_bff_interaction function
CREATE OR REPLACE FUNCTION public.record_bff_interaction(
  p_user_id UUID,
  p_target_user_id UUID,
  p_interaction_type TEXT
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Validate interaction type
  IF p_interaction_type NOT IN ('like', 'pass') THEN
    RAISE EXCEPTION 'Invalid BFF interaction type: %', p_interaction_type;
  END IF;
  
  -- Record the BFF interaction
  INSERT INTO public.bff_interactions (
    user_id,
    target_user_id,
    interaction_type,
    created_at
  ) VALUES (
    p_user_id,
    p_target_user_id,
    p_interaction_type,
    NOW()
  )
  ON CONFLICT (user_id, target_user_id) 
  DO UPDATE SET 
    interaction_type = EXCLUDED.interaction_type,
    created_at = NOW();
  
  -- Update user's BFF activity counters
  UPDATE public.profiles
  SET 
    bff_last_active = NOW(),
    bff_swipes_count = COALESCE(bff_swipes_count, 0) + 1
  WHERE id = p_user_id;
  
  -- Log success
  RAISE NOTICE 'BFF interaction recorded: user_id=%, target_user_id=%, type=%', 
    p_user_id, p_target_user_id, p_interaction_type;
    
END;
$$;

-- 4. Enable RLS on bff_interactions table
ALTER TABLE public.bff_interactions ENABLE ROW LEVEL SECURITY;

-- 5. Create RLS policies for bff_interactions
DROP POLICY IF EXISTS "Users can view their own BFF interactions" ON public.bff_interactions;
CREATE POLICY "Users can view their own BFF interactions" ON public.bff_interactions
  FOR SELECT USING (auth.uid() = user_id OR auth.uid() = target_user_id);

DROP POLICY IF EXISTS "Users can insert their own BFF interactions" ON public.bff_interactions;
CREATE POLICY "Users can insert their own BFF interactions" ON public.bff_interactions
  FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update their own BFF interactions" ON public.bff_interactions;
CREATE POLICY "Users can update their own BFF interactions" ON public.bff_interactions
  FOR UPDATE USING (auth.uid() = user_id);

-- 6. Grant permissions
GRANT USAGE ON SCHEMA public TO anon, authenticated;
GRANT ALL ON public.bff_interactions TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.record_bff_interaction(UUID, UUID, TEXT) TO anon, authenticated;

-- 7. Test the function
DO $$
DECLARE
    test_user_id UUID := '7ffe44fe-9c0f-4783-aec2-a6172a6e008b';
    test_target_id UUID := 'bcb1c077-1b71-4d78-b30b-717393f65fb7';
BEGIN
    -- Test recording a BFF interaction
    BEGIN
        PERFORM record_bff_interaction(test_user_id, test_target_id, 'like');
        RAISE NOTICE 'SUCCESS: BFF interaction function works correctly';
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE 'ERROR: BFF interaction function failed: %', SQLERRM;
    END;
END $$;

-- 8. Check the result
SELECT COUNT(*) as total_interactions FROM bff_interactions;
SELECT * FROM bff_interactions ORDER BY created_at DESC LIMIT 3;

-- 9. Final status
DO $$
BEGIN
  RAISE NOTICE '=== BFF Interactions Fix Complete ===';
  RAISE NOTICE 'All conflicting functions removed';
  RAISE NOTICE 'Single clean function created';
  RAISE NOTICE 'RLS policies configured';
  RAISE NOTICE 'Permissions granted';
  RAISE NOTICE 'BFF interactions should now record properly';
END $$;
