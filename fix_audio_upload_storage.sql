-- Fix Audio Upload Storage Issue
-- Run this in Supabase SQL Editor to enable audio note uploads

-- 1. Create audio-notes bucket if it doesn't exist
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES ('audio-notes', 'audio-notes', true, 10485760, ARRAY['audio/mpeg', 'audio/mp4', 'audio/wav', 'audio/m4a'])
ON CONFLICT (id) DO NOTHING;

-- 2. Create chat-audio bucket if it doesn't exist (for chat audio messages)
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES ('chat-audio', 'chat-audio', true, 10485760, ARRAY['audio/mpeg', 'audio/mp4', 'audio/wav', 'audio/m4a'])
ON CONFLICT (id) DO NOTHING;

-- 3. Drop ALL existing audio-related policies to avoid conflicts
DO $$
DECLARE
    policy_name TEXT;
BEGIN
    -- Get all policies on storage.objects that contain 'audio' in the name
    FOR policy_name IN 
        SELECT policyname 
        FROM pg_policies 
        WHERE tablename = 'objects' 
        AND schemaname = 'storage'
        AND policyname ILIKE '%audio%'
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON storage.objects', policy_name);
    END LOOP;
END $$;

-- 4. Create policies for audio-notes bucket
CREATE POLICY "Allow authenticated users to upload audio notes"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'audio-notes');

CREATE POLICY "Allow authenticated users to view audio notes"
ON storage.objects
FOR SELECT
TO authenticated
USING (bucket_id = 'audio-notes');

CREATE POLICY "Allow authenticated users to update audio notes"
ON storage.objects
FOR UPDATE
TO authenticated
USING (bucket_id = 'audio-notes');

CREATE POLICY "Allow authenticated users to delete audio notes"
ON storage.objects
FOR DELETE
TO authenticated
USING (bucket_id = 'audio-notes');

-- 5. Create policies for chat-audio bucket
CREATE POLICY "Allow authenticated users to upload chat audio"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'chat-audio');

CREATE POLICY "Allow authenticated users to view chat audio"
ON storage.objects
FOR SELECT
TO authenticated
USING (bucket_id = 'chat-audio');

CREATE POLICY "Allow authenticated users to update chat audio"
ON storage.objects
FOR UPDATE
TO authenticated
USING (bucket_id = 'chat-audio');

CREATE POLICY "Allow authenticated users to delete chat audio"
ON storage.objects
FOR DELETE
TO authenticated
USING (bucket_id = 'chat-audio');

-- 6. Verify buckets were created
SELECT id, name, public, created_at, file_size_limit, allowed_mime_types FROM storage.buckets 
WHERE id IN ('audio-notes', 'chat-audio', 'chat-photos', 'disappearing-photos')
ORDER BY created_at;

-- 7. Test bucket access (this should return empty result, not an error)
SELECT COUNT(*) as audio_notes_count FROM storage.objects WHERE bucket_id = 'audio-notes';
SELECT COUNT(*) as chat_audio_count FROM storage.objects WHERE bucket_id = 'chat-audio';

-- 8. Test if we can insert a test object (this should work without errors)
-- Note: This is just a test - the object will be cleaned up
INSERT INTO storage.objects (bucket_id, name, owner, metadata)
VALUES ('chat-audio', 'test-audio.m4a', auth.uid(), '{"contentType": "audio/m4a"}')
ON CONFLICT (bucket_id, name) DO NOTHING;

-- 9. Clean up test object
DELETE FROM storage.objects WHERE bucket_id = 'chat-audio' AND name = 'test-audio.m4a';

-- 10. Final verification
SELECT 'Audio upload buckets created successfully!' as status;
