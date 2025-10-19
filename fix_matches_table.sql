-- Fix the matches table to support BFF matches
-- Add match_type column to distinguish between dating and BFF matches

-- Add match_type column to matches table
ALTER TABLE matches 
ADD COLUMN IF NOT EXISTS match_type TEXT DEFAULT 'dating';

-- Update existing matches to have 'dating' type
UPDATE matches 
SET match_type = 'dating' 
WHERE match_type IS NULL;

-- Create an index for better performance
CREATE INDEX IF NOT EXISTS idx_matches_match_type ON matches(match_type);

-- Test the updated schema
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'matches' 
ORDER BY ordinal_position;
