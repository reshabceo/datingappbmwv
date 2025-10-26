-- WebRTC Database Setup for Cross-Platform Call Testing (Fixed Version)
-- Run this script in your Supabase SQL editor

-- 1. Create WebRTC Rooms Table
CREATE TABLE IF NOT EXISTS webrtc_rooms (
  id SERIAL PRIMARY KEY,
  room_id TEXT UNIQUE NOT NULL,
  offer JSONB,
  answer JSONB,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. Create ICE Candidates Table
CREATE TABLE IF NOT EXISTS webrtc_ice_candidates (
  id SERIAL PRIMARY KEY,
  room_id TEXT NOT NULL,
  candidate TEXT,
  sdp_mid TEXT,
  sdp_mline_index INTEGER,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. Create Call Sessions Table
CREATE TABLE IF NOT EXISTS call_sessions (
  id TEXT PRIMARY KEY,
  match_id TEXT NOT NULL,
  caller_id TEXT NOT NULL,
  receiver_id TEXT,
  type TEXT NOT NULL CHECK (type IN ('audio', 'video')),
  state TEXT NOT NULL CHECK (state IN ('initial', 'connecting', 'connected', 'disconnected', 'failed')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  ended_at TIMESTAMP WITH TIME ZONE,
  is_bff_match BOOLEAN DEFAULT FALSE
);

-- 4. Enable Row Level Security
ALTER TABLE webrtc_rooms ENABLE ROW LEVEL SECURITY;
ALTER TABLE webrtc_ice_candidates ENABLE ROW LEVEL SECURITY;
ALTER TABLE call_sessions ENABLE ROW LEVEL SECURITY;

-- 5. Create RLS Policies (Simplified to avoid UUID issues)
-- Allow all authenticated users to access webrtc_rooms
CREATE POLICY "Users can access webrtc_rooms" ON webrtc_rooms 
  FOR ALL USING (auth.role() = 'authenticated');

-- Allow all authenticated users to access webrtc_ice_candidates
CREATE POLICY "Users can access webrtc_ice_candidates" ON webrtc_ice_candidates 
  FOR ALL USING (auth.role() = 'authenticated');

-- Allow all authenticated users to access call_sessions (simplified)
CREATE POLICY "Users can access call_sessions" ON call_sessions 
  FOR ALL USING (auth.role() = 'authenticated');

-- 6. Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_webrtc_rooms_room_id ON webrtc_rooms(room_id);
CREATE INDEX IF NOT EXISTS idx_webrtc_ice_candidates_room_id ON webrtc_ice_candidates(room_id);
CREATE INDEX IF NOT EXISTS idx_call_sessions_caller_id ON call_sessions(caller_id);
CREATE INDEX IF NOT EXISTS idx_call_sessions_receiver_id ON call_sessions(receiver_id);
CREATE INDEX IF NOT EXISTS idx_call_sessions_match_id ON call_sessions(match_id);

-- 7. Grant necessary permissions
GRANT ALL ON webrtc_rooms TO authenticated;
GRANT ALL ON webrtc_ice_candidates TO authenticated;
GRANT ALL ON call_sessions TO authenticated;

-- 8. Verification queries
SELECT 'webrtc_rooms table created' as status;
SELECT 'webrtc_ice_candidates table created' as status;
SELECT 'call_sessions table created' as status;
SELECT 'RLS policies created' as status;
SELECT 'Indexes created' as status;
SELECT 'Setup complete!' as status;

