-- Create call debug logs table for remote debugging
CREATE TABLE IF NOT EXISTS call_debug_logs (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  event TEXT NOT NULL,
  call_id TEXT NOT NULL,
  user_id UUID REFERENCES auth.users(id),
  timestamp TIMESTAMPTZ DEFAULT NOW(),
  platform TEXT,
  app_version TEXT,
  build_number TEXT,
  device_info JSONB,
  data JSONB,
  error TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create index for faster queries
CREATE INDEX IF NOT EXISTS idx_call_debug_logs_call_id ON call_debug_logs(call_id);
CREATE INDEX IF NOT EXISTS idx_call_debug_logs_user_id ON call_debug_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_call_debug_logs_timestamp ON call_debug_logs(timestamp);
CREATE INDEX IF NOT EXISTS idx_call_debug_logs_event ON call_debug_logs(event);

-- Enable RLS (Row Level Security)
ALTER TABLE call_debug_logs ENABLE ROW LEVEL SECURITY;

-- Create policy to allow users to read their own debug logs
CREATE POLICY "Users can read their own debug logs" ON call_debug_logs
  FOR SELECT USING (auth.uid() = user_id);

-- Create policy to allow users to insert their own debug logs
CREATE POLICY "Users can insert their own debug logs" ON call_debug_logs
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Create policy for service role to read all logs (for debugging)
CREATE POLICY "Service role can read all debug logs" ON call_debug_logs
  FOR SELECT USING (auth.role() = 'service_role');

-- Create a function to clean up old debug logs (older than 7 days)
CREATE OR REPLACE FUNCTION cleanup_old_debug_logs()
RETURNS void AS $$
BEGIN
  DELETE FROM call_debug_logs 
  WHERE created_at < NOW() - INTERVAL '7 days';
END;
$$ LANGUAGE plpgsql;

-- Create a scheduled job to clean up old logs (run daily)
-- Note: This requires pg_cron extension to be enabled
-- SELECT cron.schedule('cleanup-debug-logs', '0 2 * * *', 'SELECT cleanup_old_debug_logs();');
