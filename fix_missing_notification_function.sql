-- Fix missing get_pending_notifications function
-- This function handles notification badges and in-app notifications

-- 1. Create the missing get_pending_notifications function
CREATE OR REPLACE FUNCTION public.get_pending_notifications(
  p_user_id UUID
)
RETURNS TABLE (
  id UUID,
  user_id UUID,
  title TEXT,
  message TEXT,
  type TEXT,
  is_read BOOLEAN,
  created_at TIMESTAMP WITH TIME ZONE,
  data JSONB
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    n.id,
    n.user_id,
    n.title,
    n.message,
    n.type,
    n.is_read,
    n.created_at,
    n.data
  FROM notifications n
  WHERE n.user_id = p_user_id
    AND n.is_read = false
  ORDER BY n.created_at DESC
  LIMIT 50;
END;
$$;

-- 2. Grant permissions
GRANT EXECUTE ON FUNCTION public.get_pending_notifications(UUID) TO anon, authenticated;

-- 3. Create notifications table if it doesn't exist
CREATE TABLE IF NOT EXISTS public.notifications (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  title TEXT NOT NULL,
  message TEXT NOT NULL,
  type TEXT DEFAULT 'general' CHECK (type IN ('match', 'message', 'like', 'super_like', 'story', 'general')),
  is_read BOOLEAN DEFAULT FALSE,
  data JSONB DEFAULT '{}',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 4. Enable RLS on notifications table
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

-- 5. Create RLS policy for notifications
CREATE POLICY notifications_user_access ON public.notifications
  FOR ALL USING (user_id = auth.uid());

-- 6. Test the function
SELECT 'get_pending_notifications function created successfully' as status;
