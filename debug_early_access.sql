-- Debug early access emails issue
-- Run this in Supabase SQL Editor

-- 1. Check if the table exists
SELECT table_name, column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'early_access_emails' 
ORDER BY ordinal_position;

-- 2. Check if there are any emails in the table
SELECT COUNT(*) as total_emails FROM early_access_emails;

-- 3. Show all emails (if any)
SELECT * FROM early_access_emails ORDER BY subscribed_at DESC;

-- 4. Check RLS policies on the table
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual 
FROM pg_policies 
WHERE tablename = 'early_access_emails';

-- 5. Check if admin_users table has the right structure
SELECT * FROM admin_users LIMIT 5;

-- 6. Test inserting a sample email (replace with your email)
INSERT INTO early_access_emails (email) 
VALUES ('test@example.com') 
ON CONFLICT (email) DO NOTHING;

-- 7. Check if the insert worked
SELECT * FROM early_access_emails WHERE email = 'test@example.com';
