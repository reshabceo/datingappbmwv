-- Detailed RLS debugging for payment_orders table
-- Run this in Supabase SQL Editor to get complete RLS information

-- 1. Check all policies with detailed information
SELECT 
    schemaname, 
    tablename, 
    policyname, 
    permissive, 
    roles, 
    cmd, 
    qual,
    with_check
FROM pg_policies 
WHERE tablename = 'payment_orders'
ORDER BY policyname;

-- 2. Check if RLS is enabled on the table
SELECT 
    schemaname, 
    tablename, 
    rowsecurity 
FROM pg_tables 
WHERE tablename = 'payment_orders';

-- 3. Check table permissions
SELECT 
    grantee, 
    privilege_type, 
    is_grantable
FROM information_schema.table_privileges 
WHERE table_name = 'payment_orders' 
AND table_schema = 'public';

-- 4. Check if there are any restrictive policies we missed
SELECT 
    schemaname, 
    tablename, 
    policyname, 
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE tablename = 'payment_orders' 
AND (qual IS NOT NULL OR with_check IS NOT NULL);

-- 5. Check current user context
SELECT 
    current_user,
    session_user,
    current_setting('role'),
    current_setting('request.jwt.claims', true) as jwt_claims;
