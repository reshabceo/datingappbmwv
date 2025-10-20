-- Update verification challenges to be simpler and single-hand only
-- Remove complex challenges and keep only simple, single-hand gestures

-- First, deactivate all current challenges
UPDATE verification_challenges SET is_active = FALSE;

-- Insert new simplified challenges (single-hand gestures only)
INSERT INTO verification_challenges (challenge_text, is_active) VALUES
('Wink with your left eye'),
('Hold up 2 fingers'),
('Make a peace sign'),
('Thumbs up'),
('Hold up 1 finger'),
('Close your eyes'),
('Stick out your tongue'),
('Smile and show your teeth'),
('Hold up 3 fingers'),
('Make a fist');

-- Verify the changes
SELECT challenge_text, is_active FROM verification_challenges WHERE is_active = TRUE ORDER BY created_at;
