-- ============================================
-- WebRTC Call System - Complete Database Setup
-- ============================================
-- Run this entire script in Supabase SQL Editor
-- It's idempotent (safe to run multiple times)

-- Step 1: Create call_sessions table
CREATE TABLE IF NOT EXISTS call_sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  match_id UUID NOT NULL REFERENCES matches(id) ON DELETE CASCADE,
  caller_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  receiver_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  type TEXT NOT NULL CHECK (type IN ('audio', 'video')),
  state TEXT NOT NULL DEFAULT 'initial' CHECK (state IN ('initial', 'connecting', 'connected', 'disconnected', 'failed')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  ended_at TIMESTAMP WITH TIME ZONE,
  is_bff_match BOOLEAN DEFAULT FALSE,
  duration_seconds INTEGER DEFAULT 0
);

-- Step 2: Create webrtc_rooms table
CREATE TABLE IF NOT EXISTS webrtc_rooms (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  room_id TEXT UNIQUE NOT NULL,
  offer JSONB,
  answer JSONB,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  expires_at TIMESTAMP WITH TIME ZONE DEFAULT (NOW() + INTERVAL '1 hour')
);

-- Step 3: Create webrtc_ice_candidates table
CREATE TABLE IF NOT EXISTS webrtc_ice_candidates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  room_id TEXT NOT NULL,
  candidate TEXT NOT NULL,
  sdp_mid TEXT,
  sdp_mline_index INTEGER,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Step 4: Create call_debug_logs table
CREATE TABLE IF NOT EXISTS call_debug_logs (
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

-- Step 5: Create indexes
CREATE INDEX IF NOT EXISTS idx_call_sessions_match_id ON call_sessions(match_id);
CREATE INDEX IF NOT EXISTS idx_call_sessions_caller_id ON call_sessions(caller_id);
CREATE INDEX IF NOT EXISTS idx_call_sessions_receiver_id ON call_sessions(receiver_id);
CREATE INDEX IF NOT EXISTS idx_call_sessions_created_at ON call_sessions(created_at);
CREATE INDEX IF NOT EXISTS idx_webrtc_rooms_room_id ON webrtc_rooms(room_id);
CREATE INDEX IF NOT EXISTS idx_webrtc_ice_candidates_room_id ON webrtc_ice_candidates(room_id);
CREATE INDEX IF NOT EXISTS idx_call_debug_logs_call_id ON call_debug_logs(call_id);
CREATE INDEX IF NOT EXISTS idx_call_debug_logs_user_id ON call_debug_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_call_debug_logs_created_at ON call_debug_logs(created_at DESC);

-- Step 6: Enable RLS
ALTER TABLE call_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE webrtc_rooms ENABLE ROW LEVEL SECURITY;
ALTER TABLE webrtc_ice_candidates ENABLE ROW LEVEL SECURITY;
ALTER TABLE call_debug_logs ENABLE ROW LEVEL SECURITY;

-- Step 7: RLS Policies for call_sessions
DO $$ 
BEGIN
  -- Drop existing policies if they exist
  DROP POLICY IF EXISTS "Users can view their own call sessions" ON call_sessions;
  DROP POLICY IF EXISTS "Users can create call sessions" ON call_sessions;
  DROP POLICY IF EXISTS "Users can update their own call sessions" ON call_sessions;
EXCEPTION WHEN undefined_object THEN NULL;
END $$;

CREATE POLICY "Users can view their own call sessions" ON call_sessions
  FOR SELECT USING (
    auth.uid() = caller_id OR auth.uid() = receiver_id
  );

CREATE POLICY "Users can create call sessions" ON call_sessions
  FOR INSERT WITH CHECK (
    auth.uid() = caller_id
  );

CREATE POLICY "Users can update their own call sessions" ON call_sessions
  FOR UPDATE USING (
    auth.uid() = caller_id OR auth.uid() = receiver_id
  );

-- Step 8: RLS Policies for webrtc_rooms (wide open for simplicity)
DO $$ 
BEGIN
  DROP POLICY IF EXISTS "Anyone can create webrtc rooms" ON webrtc_rooms;
  DROP POLICY IF EXISTS "Anyone can read webrtc rooms" ON webrtc_rooms;
  DROP POLICY IF EXISTS "Anyone can update webrtc rooms" ON webrtc_rooms;
  DROP POLICY IF EXISTS "Anyone can delete webrtc rooms" ON webrtc_rooms;
EXCEPTION WHEN undefined_object THEN NULL;
END $$;

CREATE POLICY "Anyone can create webrtc rooms" ON webrtc_rooms
  FOR INSERT WITH CHECK (true);

CREATE POLICY "Anyone can read webrtc rooms" ON webrtc_rooms
  FOR SELECT USING (true);

CREATE POLICY "Anyone can update webrtc rooms" ON webrtc_rooms
  FOR UPDATE USING (true);

CREATE POLICY "Anyone can delete webrtc rooms" ON webrtc_rooms
  FOR DELETE USING (true);

-- Step 9: RLS Policies for webrtc_ice_candidates (wide open)
DO $$ 
BEGIN
  DROP POLICY IF EXISTS "Anyone can manage ice candidates" ON webrtc_ice_candidates;
EXCEPTION WHEN undefined_object THEN NULL;
END $$;

CREATE POLICY "Anyone can manage ice candidates" ON webrtc_ice_candidates
  FOR ALL USING (true);

-- Step 10: RLS Policies for call_debug_logs
DO $$ 
BEGIN
  DROP POLICY IF EXISTS "Users can insert their own debug logs" ON call_debug_logs;
  DROP POLICY IF EXISTS "Users can view their own debug logs" ON call_debug_logs;
  DROP POLICY IF EXISTS "Service role can do everything" ON call_debug_logs;
EXCEPTION WHEN undefined_object THEN NULL;
END $$;

CREATE POLICY "Users can insert their own debug logs"
  ON call_debug_logs
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id OR user_id IS NULL);

CREATE POLICY "Users can view their own debug logs"
  ON call_debug_logs
  FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id OR user_id IS NULL);

CREATE POLICY "Service role can do everything"
  ON call_debug_logs
  FOR ALL
  TO service_role
  USING (true)
  WITH CHECK (true);

-- Step 11: Helper functions
CREATE OR REPLACE FUNCTION cleanup_expired_webrtc_rooms()
RETURNS void AS $$
BEGIN
  DELETE FROM webrtc_rooms WHERE expires_at < NOW();
  DELETE FROM webrtc_ice_candidates WHERE created_at < NOW() - INTERVAL '1 hour';
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION update_call_duration()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.state = 'disconnected' AND OLD.state != 'disconnected' THEN
    NEW.duration_seconds = EXTRACT(EPOCH FROM (NOW() - NEW.created_at))::INTEGER;
    NEW.ended_at = NOW();
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Step 12: Create trigger
DO $$ 
BEGIN
  DROP TRIGGER IF EXISTS trigger_update_call_duration ON call_sessions;
EXCEPTION WHEN undefined_object THEN NULL;
END $$;

CREATE TRIGGER trigger_update_call_duration
  BEFORE UPDATE ON call_sessions
  FOR EACH ROW
  EXECUTE FUNCTION update_call_duration();

-- Step 13: Add fcm_token to profiles if needed
DO $$ 
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                 WHERE table_name = 'profiles' AND column_name = 'fcm_token') THEN
    ALTER TABLE profiles ADD COLUMN fcm_token TEXT;
  END IF;
END $$;

-- Step 14: Create view for call statistics
CREATE OR REPLACE VIEW call_statistics AS
SELECT 
  cs.caller_id,
  cs.receiver_id,
  COUNT(*) as total_calls,
  COUNT(CASE WHEN cs.state = 'connected' THEN 1 END) as successful_calls,
  AVG(cs.duration_seconds) as avg_duration,
  MAX(cs.created_at) as last_call_time
FROM call_sessions cs
GROUP BY cs.caller_id, cs.receiver_id;

-- Step 15: Grant permissions
GRANT ALL ON call_sessions TO authenticated;
GRANT ALL ON webrtc_rooms TO authenticated;
GRANT ALL ON webrtc_ice_candidates TO authenticated;
GRANT ALL ON call_debug_logs TO authenticated;
GRANT SELECT ON call_statistics TO authenticated;

-- ============================================
-- Verification Queries
-- ============================================

-- Check all tables exist
SELECT 
  table_name,
  CASE 
    WHEN table_name IN (
      SELECT tablename 
      FROM pg_tables 
      WHERE schemaname = 'public' 
      AND tablename IN ('call_sessions', 'webrtc_rooms', 'webrtc_ice_candidates', 'call_debug_logs')
    ) THEN '✅ EXISTS'
    ELSE '❌ MISSING'
  END as status
FROM (VALUES 
  ('call_sessions'),
  ('webrtc_rooms'),
  ('webrtc_ice_candidates'),
  ('call_debug_logs')
) AS expected(table_name);

-- Check RLS is enabled
SELECT 
  tablename,
  CASE WHEN rowsecurity THEN '✅ ENABLED' ELSE '❌ DISABLED' END as rls_status
FROM pg_tables
WHERE schemaname = 'public'
AND tablename IN ('call_sessions', 'webrtc_rooms', 'webrtc_ice_candidates', 'call_debug_logs');

-- Check policies exist
SELECT 
  tablename,
  COUNT(*) as policy_count
FROM pg_policies
WHERE schemaname = 'public'
AND tablename IN ('call_sessions', 'webrtc_rooms', 'webrtc_ice_candidates', 'call_debug_logs')
GROUP BY tablename;

-- Success message
DO $$
BEGIN
  RAISE NOTICE '✅ WebRTC Call System Database Setup Complete!';
  RAISE NOTICE '📋 Tables created: call_sessions, webrtc_rooms, webrtc_ice_candidates, call_debug_logs';
  RAISE NOTICE '🔒 RLS enabled and policies applied';
  RAISE NOTICE '📊 Run the verification queries above to confirm';
END $$;

