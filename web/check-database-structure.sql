-- Check the actual database structure for profiles table
-- Run this in Supabase SQL Editor to see the exact schema

-- 1. Check table structure
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns 
WHERE table_name = 'profiles' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- 2. Check Ashley's profile data
SELECT id, name, age, image_urls, photos, description, hobbies
FROM profiles 
WHERE name = 'Ashley' 
OR id = '63b22ccf-d6ad-4d08-b741-cc47156c2085';

-- 3. Check data types of image fields
SELECT 
  id, 
  name,
  image_urls,
  photos,
  pg_typeof(image_urls) as image_urls_type,
  pg_typeof(photos) as photos_type
FROM profiles 
WHERE name = 'Ashley' 
OR id = '63b22ccf-d6ad-4d08-b741-cc47156c2085';

-- 4. Check if both fields exist and have data
SELECT 
  id,
  name,
  CASE 
    WHEN image_urls IS NOT NULL THEN 'image_urls has data'
    ELSE 'image_urls is NULL'
  END as image_urls_status,
  CASE 
    WHEN photos IS NOT NULL THEN 'photos has data'
    ELSE 'photos is NULL'
  END as photos_status,
  jsonb_array_length(image_urls) as image_urls_count,
  array_length(photos, 1) as photos_count
FROM profiles 
WHERE name = 'Ashley' 
OR id = '63b22ccf-d6ad-4d08-b741-cc47156c2085';
