-- Fix RLS policies for admin_users table
-- Run this in Supabase SQL Editor

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Admin users can view admin_users" ON admin_users;
DROP POLICY IF EXISTS "Admin users can insert admin_users" ON admin_users;
DROP POLICY IF EXISTS "Admin users can update admin_users" ON admin_users;

-- Create new policies for admin_users table
CREATE POLICY "Admin users can view admin_users" ON admin_users
  FOR SELECT USING (true);

CREATE POLICY "Admin users can insert admin_users" ON admin_users
  FOR INSERT WITH CHECK (true);

CREATE POLICY "Admin users can update admin_users" ON admin_users
  FOR UPDATE USING (true);

-- Also ensure the admin_users table exists with proper structure
CREATE TABLE IF NOT EXISTS admin_users (
  id UUID REFERENCES auth.users(id) PRIMARY KEY,
  email TEXT NOT NULL,
  full_name TEXT NOT NULL,
  role TEXT NOT NULL DEFAULT 'admin',
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS on admin_users table
ALTER TABLE admin_users ENABLE ROW LEVEL SECURITY;

-- Verify the table structure
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns
WHERE table_name = 'admin_users'
AND table_schema = 'public'
ORDER BY ordinal_position;
