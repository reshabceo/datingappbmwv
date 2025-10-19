-- Safe fix for photo upload storage RLS policies
-- This script handles existing policies gracefully

-- First, drop existing policies if they exist (ignore errors)
DO $$ 
BEGIN
    -- Drop chat-photos policies
    DROP POLICY IF EXISTS "Allow authenticated users to upload chat photos" ON storage.objects;
    DROP POLICY IF EXISTS "Allow authenticated users to view chat photos" ON storage.objects;
    DROP POLICY IF EXISTS "Allow authenticated users to delete chat photos" ON storage.objects;
    DROP POLICY IF EXISTS "Allow authenticated users to delete own chat photos" ON storage.objects;
    
    -- Drop disappearing-photos policies
    DROP POLICY IF EXISTS "Allow authenticated users to upload disappearing photos" ON storage.objects;
    DROP POLICY IF EXISTS "Allow authenticated users to view disappearing photos" ON storage.objects;
    DROP POLICY IF EXISTS "Allow authenticated users to delete disappearing photos" ON storage.objects;
    DROP POLICY IF EXISTS "Allow authenticated users to delete own disappearing photos" ON storage.objects;
    
    -- Drop any other existing policies for these buckets
    DROP POLICY IF EXISTS "Allow authenticated users to update chat photos" ON storage.objects;
    DROP POLICY IF EXISTS "Allow authenticated users to update disappearing photos" ON storage.objects;
    
EXCEPTION
    WHEN OTHERS THEN
        -- Ignore errors if policies don't exist
        NULL;
END $$;

-- Create new, permissive policies for chat-photos bucket
CREATE POLICY "Allow authenticated users to upload chat photos"
ON storage.objects FOR INSERT 
WITH CHECK (bucket_id = 'chat-photos' AND auth.role() = 'authenticated');

CREATE POLICY "Allow authenticated users to view chat photos"
ON storage.objects FOR SELECT 
USING (bucket_id = 'chat-photos' AND auth.role() = 'authenticated');

CREATE POLICY "Allow authenticated users to delete chat photos"
ON storage.objects FOR DELETE 
USING (bucket_id = 'chat-photos' AND auth.role() = 'authenticated');

-- Create new, permissive policies for disappearing-photos bucket
CREATE POLICY "Allow authenticated users to upload disappearing photos"
ON storage.objects FOR INSERT 
WITH CHECK (bucket_id = 'disappearing-photos' AND auth.role() = 'authenticated');

CREATE POLICY "Allow authenticated users to view disappearing photos"
ON storage.objects FOR SELECT 
USING (bucket_id = 'disappearing-photos' AND auth.role() = 'authenticated');

CREATE POLICY "Allow authenticated users to delete disappearing photos"
ON storage.objects FOR DELETE 
USING (bucket_id = 'disappearing-photos' AND auth.role() = 'authenticated');

-- Ensure the buckets exist and are public
INSERT INTO storage.buckets (id, name, public) 
VALUES ('chat-photos', 'chat-photos', true)
ON CONFLICT (id) DO UPDATE SET public = true;

INSERT INTO storage.buckets (id, name, public) 
VALUES ('disappearing-photos', 'disappearing-photos', true)
ON CONFLICT (id) DO UPDATE SET public = true;

-- Verify the policies were created
SELECT schemaname, tablename, policyname 
FROM pg_policies 
WHERE tablename = 'objects' 
AND policyname LIKE '%chat%' OR policyname LIKE '%disappearing%'
ORDER BY policyname;
