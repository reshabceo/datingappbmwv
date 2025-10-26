-- Create call_debug_logs table for debugging WebRTC calls
CREATE TABLE IF NOT EXISTS public.call_debug_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  event TEXT NOT NULL,
  call_id TEXT,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  timestamp TIMESTAMPTZ DEFAULT NOW(),
  platform TEXT,
  app_version TEXT,
  build_number TEXT,
  data JSONB,
  device_info JSONB,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create index for faster queries
CREATE INDEX IF NOT EXISTS idx_call_debug_logs_call_id ON public.call_debug_logs(call_id);
CREATE INDEX IF NOT EXISTS idx_call_debug_logs_user_id ON public.call_debug_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_call_debug_logs_created_at ON public.call_debug_logs(created_at DESC);

-- Enable RLS
ALTER TABLE public.call_debug_logs ENABLE ROW LEVEL SECURITY;

-- Allow users to insert their own debug logs
CREATE POLICY "Users can insert their own debug logs"
  ON public.call_debug_logs
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id OR user_id IS NULL);

-- Allow users to view their own debug logs
CREATE POLICY "Users can view their own debug logs"
  ON public.call_debug_logs
  FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id OR user_id IS NULL);

-- Allow service role to do everything (for admin purposes)
CREATE POLICY "Service role can do everything"
  ON public.call_debug_logs
  FOR ALL
  TO service_role
  USING (true)
  WITH CHECK (true);

COMMENT ON TABLE public.call_debug_logs IS 'Debug logs for WebRTC call events and diagnostics';

