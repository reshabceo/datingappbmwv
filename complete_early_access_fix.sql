-- Complete fix for early access emails
-- Run this in Supabase SQL Editor

-- Step 1: Drop existing table and policies
DROP TABLE IF EXISTS early_access_emails CASCADE;

-- Step 2: Create the table with proper structure
CREATE TABLE early_access_emails (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email TEXT NOT NULL UNIQUE,
  subscribed_at TIMESTAMPTZ DEFAULT NOW(),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Step 3: Enable RLS
ALTER TABLE early_access_emails ENABLE ROW LEVEL SECURITY;

-- Step 4: Create policies
-- Allow anyone to insert emails
CREATE POLICY "Anyone can insert early access emails" ON early_access_emails
  FOR INSERT WITH CHECK (true);

-- Allow authenticated users to read (this should work for admin panel)
CREATE POLICY "Authenticated users can read early access emails" ON early_access_emails
  FOR SELECT USING (auth.role() = 'authenticated');

-- Step 5: Create indexes
CREATE INDEX idx_early_access_emails_email ON early_access_emails(email);
CREATE INDEX idx_early_access_emails_subscribed_at ON early_access_emails(subscribed_at);

-- Step 6: Test the setup
INSERT INTO early_access_emails (email) VALUES ('test@example.com');

-- Step 7: Verify everything works
SELECT 
  'Table created successfully' as status,
  COUNT(*) as total_emails 
FROM early_access_emails;

-- Step 8: Show the test email
SELECT * FROM early_access_emails;
