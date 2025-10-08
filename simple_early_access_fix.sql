-- Simple fix for early access emails
-- Run this in Supabase SQL Editor

-- Drop and recreate the table to ensure it's clean
DROP TABLE IF EXISTS early_access_emails CASCADE;

-- Create the table
CREATE TABLE early_access_emails (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email TEXT NOT NULL UNIQUE,
  subscribed_at TIMESTAMPTZ DEFAULT NOW(),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE early_access_emails ENABLE ROW LEVEL SECURITY;

-- Simple policy: allow anyone to insert
CREATE POLICY "Allow anyone to insert early access emails" ON early_access_emails
  FOR INSERT WITH CHECK (true);

-- Simple policy: allow authenticated users to read (for admin panel)
CREATE POLICY "Allow authenticated users to read early access emails" ON early_access_emails
  FOR SELECT USING (auth.role() = 'authenticated');

-- Create indexes
CREATE INDEX idx_early_access_emails_email ON early_access_emails(email);
CREATE INDEX idx_early_access_emails_subscribed_at ON early_access_emails(subscribed_at);

-- Test insert
INSERT INTO early_access_emails (email) VALUES ('test@example.com');

-- Verify it worked
SELECT * FROM early_access_emails;
