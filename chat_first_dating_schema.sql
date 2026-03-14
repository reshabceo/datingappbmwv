-- Chat-First Dating Feature Schema
-- This implements the unique "Chat-First" dating approach where profiles are locked
-- until users have meaningful conversations (10+ messages exchanged)

-- Table to track conversation-based profile unlocks
CREATE TABLE IF NOT EXISTS profile_unlocks (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  viewer_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  profile_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  match_id UUID REFERENCES matches(id) ON DELETE CASCADE,
  message_count INTEGER DEFAULT 0,
  is_unlocked BOOLEAN DEFAULT FALSE,
  unlocked_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(viewer_id, profile_id)
);

-- Index for faster lookups
CREATE INDEX IF NOT EXISTS idx_profile_unlocks_viewer ON profile_unlocks(viewer_id);
CREATE INDEX IF NOT EXISTS idx_profile_unlocks_profile ON profile_unlocks(profile_id);
CREATE INDEX IF NOT EXISTS idx_profile_unlocks_match ON profile_unlocks(match_id);

-- Function to check if a profile is unlocked for a viewer
CREATE OR REPLACE FUNCTION is_profile_unlocked(
  p_viewer_id UUID,
  p_profile_id UUID
) RETURNS BOOLEAN AS $$
DECLARE
  v_unlocked BOOLEAN;
BEGIN
  SELECT COALESCE(is_unlocked, FALSE) INTO v_unlocked
  FROM profile_unlocks
  WHERE viewer_id = p_viewer_id AND profile_id = p_profile_id;
  
  RETURN COALESCE(v_unlocked, FALSE);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to increment message count and unlock if threshold reached
CREATE OR REPLACE FUNCTION increment_conversation_count(
  p_viewer_id UUID,
  p_profile_id UUID,
  p_match_id UUID
) RETURNS JSONB AS $$
DECLARE
  v_unlock_record profile_unlocks%ROWTYPE;
  v_message_count INTEGER;
  v_is_unlocked BOOLEAN;
  v_unlocked_now BOOLEAN := FALSE;
BEGIN
  -- Get or create unlock record
  INSERT INTO profile_unlocks (viewer_id, profile_id, match_id, message_count)
  VALUES (p_viewer_id, p_profile_id, p_match_id, 1)
  ON CONFLICT (viewer_id, profile_id)
  DO UPDATE SET
    message_count = profile_unlocks.message_count + 1,
    updated_at = NOW()
  RETURNING * INTO v_unlock_record;
  
  -- Get current count
  SELECT message_count, is_unlocked INTO v_message_count, v_is_unlocked
  FROM profile_unlocks
  WHERE viewer_id = p_viewer_id AND profile_id = p_profile_id;
  
  -- Unlock if threshold reached (10 messages) and not already unlocked
  IF v_message_count >= 10 AND NOT v_is_unlocked THEN
    UPDATE profile_unlocks
    SET is_unlocked = TRUE, unlocked_at = NOW()
    WHERE viewer_id = p_viewer_id AND profile_id = p_profile_id;
    v_unlocked_now := TRUE;
  END IF;
  
  RETURN jsonb_build_object(
    'message_count', v_message_count,
    'is_unlocked', COALESCE(v_is_unlocked, FALSE) OR v_unlocked_now,
    'unlocked_now', v_unlocked_now
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to automatically increment conversation count when messages are sent
CREATE OR REPLACE FUNCTION trigger_increment_conversation()
RETURNS TRIGGER AS $$
DECLARE
  v_match_record RECORD;
  v_user_a_id UUID;
  v_user_b_id UUID;
BEGIN
  -- Get match details
  SELECT user_id_1, user_id_2 INTO v_user_a_id, v_user_b_id
  FROM matches
  WHERE id = NEW.match_id;
  
  -- Increment count for both users viewing each other's profiles
  IF v_user_a_id IS NOT NULL AND v_user_b_id IS NOT NULL THEN
    -- User A viewing User B's profile
    PERFORM increment_conversation_count(
      v_user_a_id,
      v_user_b_id,
      NEW.match_id
    );
    
    -- User B viewing User A's profile
    PERFORM increment_conversation_count(
      v_user_b_id,
      v_user_a_id,
      NEW.match_id
    );
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger on messages table
DROP TRIGGER IF EXISTS messages_increment_conversation ON messages;
CREATE TRIGGER messages_increment_conversation
  AFTER INSERT ON messages
  FOR EACH ROW
  EXECUTE FUNCTION trigger_increment_conversation();

-- RLS Policies
ALTER TABLE profile_unlocks ENABLE ROW LEVEL SECURITY;

-- Users can only see their own unlock records
CREATE POLICY profile_unlocks_select ON profile_unlocks
  FOR SELECT
  USING (auth.uid() = viewer_id);

-- Users can insert their own unlock records
CREATE POLICY profile_unlocks_insert ON profile_unlocks
  FOR INSERT
  WITH CHECK (auth.uid() = viewer_id);

-- Users can update their own unlock records
CREATE POLICY profile_unlocks_update ON profile_unlocks
  FOR UPDATE
  USING (auth.uid() = viewer_id);

