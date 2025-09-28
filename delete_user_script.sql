-- Script to delete user from Supabase
-- Run this in Supabase SQL Editor

-- First, find the user ID
SELECT id, email, created_at 
FROM auth.users 
WHERE email = 'ceo@boostmysites.com';

-- Delete from profiles table first (due to foreign key constraints)
DELETE FROM public.profiles 
WHERE id IN (
  SELECT id FROM auth.users 
  WHERE email = 'ceo@boostmysites.com'
);

-- Delete from auth.users (this requires admin privileges)
DELETE FROM auth.users 
WHERE email = 'ceo@boostmysites.com';

-- Verify deletion
SELECT COUNT(*) as remaining_users 
FROM auth.users 
WHERE email = 'ceo@boostmysites.com';
