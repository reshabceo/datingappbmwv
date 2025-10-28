-- Fix missing call_sessions table and call_type column
-- This fixes the video/audio call functionality

-- 1. Create call_sessions table if it doesn't exist
CREATE TABLE IF NOT EXISTS public.call_sessions (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  match_id UUID REFERENCES matches(id) ON DELETE CASCADE,
  caller_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  receiver_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  type TEXT NOT NULL CHECK (type IN ('initial', 'connecting', 'connected', 'disconnected', 'failed')),
  state TEXT NOT NULL DEFAULT 'initial' CHECK (state IN ('initial', 'connecting', 'connected', 'disconnected', 'failed')),
  call_type TEXT NOT NULL CHECK (call_type IN ('audio', 'video')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  ended_at TIMESTAMP WITH TIME ZONE,
  is_bff_match BOOLEAN DEFAULT FALSE,
  started_at TEXT NOT NULL
);

-- 2. Add missing columns if table exists but columns are missing
DO $$
BEGIN
  -- Add call_type column if it doesn't exist
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                 WHERE table_name = 'call_sessions' AND column_name = 'call_type') THEN
    ALTER TABLE public.call_sessions ADD COLUMN call_type TEXT CHECK (call_type IN ('audio', 'video'));
  END IF;
  
  -- Add type column if it doesn't exist
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                 WHERE table_name = 'call_sessions' AND column_name = 'type') THEN
    ALTER TABLE public.call_sessions ADD COLUMN type TEXT CHECK (type IN ('initial', 'connecting', 'connected', 'disconnected', 'failed'));
  END IF;
  
  -- Add state column if it doesn't exist
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                 WHERE table_name = 'call_sessions' AND column_name = 'state') THEN
    ALTER TABLE public.call_sessions ADD COLUMN state TEXT DEFAULT 'initial' CHECK (state IN ('initial', 'connecting', 'connected', 'disconnected', 'failed'));
  END IF;
  
  -- Add started_at column if it doesn't exist
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                 WHERE table_name = 'call_sessions' AND column_name = 'started_at') THEN
    ALTER TABLE public.call_sessions ADD COLUMN started_at TEXT;
  END IF;
  
  -- Add ended_at column if it doesn't exist
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                 WHERE table_name = 'call_sessions' AND column_name = 'ended_at') THEN
    ALTER TABLE public.call_sessions ADD COLUMN ended_at TIMESTAMP WITH TIME ZONE;
  END IF;
  
  -- Add is_bff_match column if it doesn't exist
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                 WHERE table_name = 'call_sessions' AND column_name = 'is_bff_match') THEN
    ALTER TABLE public.call_sessions ADD COLUMN is_bff_match BOOLEAN DEFAULT FALSE;
  END IF;
END $$;

-- 3. Enable RLS on call_sessions table
ALTER TABLE public.call_sessions ENABLE ROW LEVEL SECURITY;

-- 4. Create RLS policies for call_sessions
DROP POLICY IF EXISTS call_sessions_participants_access ON public.call_sessions;
CREATE POLICY call_sessions_participants_access ON public.call_sessions
  FOR ALL USING (
    caller_id = auth.uid() OR receiver_id = auth.uid()
  );

-- 5. Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_call_sessions_caller_id ON public.call_sessions(caller_id);
CREATE INDEX IF NOT EXISTS idx_call_sessions_receiver_id ON public.call_sessions(receiver_id);
CREATE INDEX IF NOT EXISTS idx_call_sessions_match_id ON public.call_sessions(match_id);
CREATE INDEX IF NOT EXISTS idx_call_sessions_state ON public.call_sessions(state);

-- 6. Test the table structure
SELECT 
  column_name, 
  data_type, 
  is_nullable,
  column_default
FROM information_schema.columns 
WHERE table_name = 'call_sessions' 
ORDER BY ordinal_position;

-- 7. Success message
SELECT 'call_sessions table and columns created/fixed successfully' as status;
