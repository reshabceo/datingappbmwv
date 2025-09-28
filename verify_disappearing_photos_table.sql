-- Verify that the disappearing_photos table exists and has the right structure
-- Run this in Supabase SQL Editor

-- Check if table exists
SELECT table_name, column_name, data_type, is_nullable
FROM information_schema.columns 
WHERE table_name = 'disappearing_photos' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- Check if policies exist
SELECT policyname, cmd, roles 
FROM pg_policies 
WHERE tablename = 'disappearing_photos' 
AND schemaname = 'public';

-- Test insert (this should work if everything is set up correctly)
-- Uncomment the lines below to test:
/*
INSERT INTO public.disappearing_photos (
    match_id, 
    sender_id, 
    photo_url, 
    view_duration, 
    expires_at
) VALUES (
    '00000000-0000-0000-0000-000000000000',  -- dummy match_id
    '00000000-0000-0000-0000-000000000000',  -- dummy sender_id  
    'https://example.com/test.jpg',
    10,
    '2024-12-31T23
);
*/
