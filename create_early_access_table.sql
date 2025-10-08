-- Create early access emails table
-- Run this in Supabase SQL Editor

CREATE TABLE IF NOT EXISTS early_access_emails (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email TEXT NOT NULL UNIQUE,
  subscribed_at TIMESTAMPTZ DEFAULT NOW(),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE early_access_emails ENABLE ROW LEVEL SECURITY;

-- Allow anyone to insert (for signup)
CREATE POLICY "Anyone can insert early access emails" ON early_access_emails
  FOR INSERT WITH CHECK (true);

-- Allow admins to read all emails
CREATE POLICY "Admins can read early access emails" ON early_access_emails
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM admin_users 
      WHERE admin_users.id = auth.uid() 
      AND admin_users.role = 'super_admin'
    )
  );

-- Create index for better performance
CREATE INDEX IF NOT EXISTS idx_early_access_emails_email ON early_access_emails(email);
CREATE INDEX IF NOT EXISTS idx_early_access_emails_subscribed_at ON early_access_emails(subscribed_at);
