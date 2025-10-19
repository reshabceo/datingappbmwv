-- Profile Verification System Schema
-- Add verification fields to existing profiles table

-- Add verification fields to profiles table
ALTER TABLE profiles 
ADD COLUMN IF NOT EXISTS verification_status TEXT DEFAULT 'unverified' CHECK (verification_status IN ('unverified', 'pending', 'verified', 'rejected')),
ADD COLUMN IF NOT EXISTS verification_photo_url TEXT,
ADD COLUMN IF NOT EXISTS verification_challenge TEXT,
ADD COLUMN IF NOT EXISTS verification_submitted_at TIMESTAMP WITH TIME ZONE,
ADD COLUMN IF NOT EXISTS verification_reviewed_at TIMESTAMP WITH TIME ZONE,
ADD COLUMN IF NOT EXISTS verification_reviewed_by UUID REFERENCES profiles(id),
ADD COLUMN IF NOT EXISTS verification_rejection_reason TEXT,
ADD COLUMN IF NOT EXISTS verification_confidence INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS verification_ai_reason TEXT;

-- Create verification challenges table
CREATE TABLE IF NOT EXISTS verification_challenges (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  challenge_text TEXT NOT NULL,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Insert some simple verification challenges
INSERT INTO verification_challenges (challenge_text) VALUES
('Hold up 3 fingers'),
('Make a peace sign'),
('Wink with your left eye'),
('Smile and show your teeth'),
('Hold up 2 fingers'),
('Make a thumbs up'),
('Close your eyes'),
('Stick out your tongue'),
('Make a heart shape with your hands'),
('Hold up 1 finger');

-- Create verification queue table for admin review
CREATE TABLE IF NOT EXISTS verification_queue (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  challenge_text TEXT NOT NULL,
  verification_photo_url TEXT NOT NULL,
  submitted_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  reviewed_at TIMESTAMP WITH TIME ZONE,
  reviewed_by UUID REFERENCES profiles(id),
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
  rejection_reason TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create index for faster admin queries
CREATE INDEX IF NOT EXISTS idx_verification_queue_pending ON verification_queue(status) WHERE status = 'pending';
CREATE INDEX IF NOT EXISTS idx_verification_queue_user ON verification_queue(user_id);

-- Function to get random verification challenge
CREATE OR REPLACE FUNCTION get_random_verification_challenge()
RETURNS TEXT AS $$
DECLARE
  challenge TEXT;
BEGIN
  SELECT challenge_text INTO challenge
  FROM verification_challenges 
  WHERE is_active = TRUE 
  ORDER BY RANDOM() 
  LIMIT 1;
  
  RETURN challenge;
END;
$$ LANGUAGE plpgsql;

-- Function to submit verification photo (now calls AI verification)
CREATE OR REPLACE FUNCTION submit_verification_photo(
  p_user_id UUID,
  p_photo_url TEXT,
  p_challenge TEXT
)
RETURNS BOOLEAN AS $$
BEGIN
  -- Update user's verification status to pending
  UPDATE profiles 
  SET 
    verification_status = 'pending',
    verification_photo_url = p_photo_url,
    verification_challenge = p_challenge,
    verification_submitted_at = NOW()
  WHERE id = p_user_id;
  
  -- Add to verification queue (for tracking)
  INSERT INTO verification_queue (user_id, challenge_text, verification_photo_url, status)
  VALUES (p_user_id, p_challenge, p_photo_url, 'pending');
  
  RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

-- Function to call AI verification edge function
CREATE OR REPLACE FUNCTION call_ai_verification(
  p_user_id UUID,
  p_photo_url TEXT,
  p_challenge TEXT
)
RETURNS JSONB AS $$
DECLARE
  result JSONB;
BEGIN
  -- This function will be called from the application layer
  -- The actual AI verification happens in the edge function
  RETURN jsonb_build_object(
    'status', 'processing',
    'message', 'AI verification in progress'
  );
END;
$$ LANGUAGE plpgsql;

-- Function for admin to review verification
CREATE OR REPLACE FUNCTION review_verification(
  p_queue_id UUID,
  p_reviewer_id UUID,
  p_approved BOOLEAN,
  p_rejection_reason TEXT DEFAULT NULL
)
RETURNS BOOLEAN AS $$
DECLARE
  v_user_id UUID;
BEGIN
  -- Get the user_id from the queue
  SELECT user_id INTO v_user_id
  FROM verification_queue 
  WHERE id = p_queue_id AND status = 'pending';
  
  IF v_user_id IS NULL THEN
    RETURN FALSE;
  END IF;
  
  -- Update the queue entry
  UPDATE verification_queue 
  SET 
    status = CASE WHEN p_approved THEN 'approved' ELSE 'rejected' END,
    reviewed_at = NOW(),
    reviewed_by = p_reviewer_id,
    rejection_reason = p_rejection_reason
  WHERE id = p_queue_id;
  
  -- Update user's verification status
  UPDATE profiles 
  SET 
    verification_status = CASE WHEN p_approved THEN 'verified' ELSE 'rejected' END,
    verification_reviewed_at = NOW(),
    verification_reviewed_by = p_reviewer_id,
    verification_rejection_reason = p_rejection_reason
  WHERE id = v_user_id;
  
  RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

-- RLS policies for verification system
ALTER TABLE verification_queue ENABLE ROW LEVEL SECURITY;
ALTER TABLE verification_challenges ENABLE ROW LEVEL SECURITY;

-- Users can see their own verification queue entries
CREATE POLICY verification_queue_user_read ON verification_queue
  FOR SELECT USING (user_id = auth.uid());

-- Admins can see all verification queue entries
CREATE POLICY verification_queue_admin_all ON verification_queue
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM profiles 
      WHERE id = auth.uid() 
      AND (email LIKE '%admin%' OR email LIKE '%@boostmysites.com')
    )
  );

-- Anyone can read active challenges
CREATE POLICY verification_challenges_read ON verification_challenges
  FOR SELECT USING (is_active = TRUE);
