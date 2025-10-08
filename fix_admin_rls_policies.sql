-- Fix RLS policies for admin to read early access emails
-- Run this in Supabase SQL Editor

-- Drop existing policies
DROP POLICY IF EXISTS "Authenticated users can read early access emails" ON early_access_emails;
DROP POLICY IF EXISTS "Admins can read early access emails" ON early_access_emails;

-- Create a simple policy that allows any authenticated user to read
-- This should work for the admin panel
CREATE POLICY "Allow authenticated users to read early access emails" ON early_access_emails
  FOR SELECT USING (auth.role() = 'authenticated');

-- Alternative: Create a policy that allows service role to read
CREATE POLICY "Allow service role to read early access emails" ON early_access_emails
  FOR SELECT USING (auth.role() = 'service_role');

-- Test the policies
SELECT 'RLS policies updated successfully' as status;

-- Verify the table is accessible
SELECT COUNT(*) as total_emails FROM early_access_emails;