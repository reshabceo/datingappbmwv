-- Fix reports table structure for Content Moderation
-- Run this in Supabase SQL Editor

-- Add status column if it doesn't exist
ALTER TABLE reports ADD COLUMN IF NOT EXISTS status VARCHAR(20) DEFAULT 'pending';

-- Update existing records to have proper status
UPDATE reports SET status = 'pending' WHERE status IS NULL;

-- Add index for better performance
CREATE INDEX IF NOT EXISTS idx_reports_status ON reports(status);
CREATE INDEX IF NOT EXISTS idx_reports_created_at ON reports(created_at);

-- Check the current structure
SELECT column_name, data_type, is_nullable, column_default 
FROM information_schema.columns 
WHERE table_name = 'reports' 
ORDER BY ordinal_position;

-- Check current data
SELECT id, type, reason, status, created_at 
FROM reports 
ORDER BY created_at DESC 
LIMIT 5;
