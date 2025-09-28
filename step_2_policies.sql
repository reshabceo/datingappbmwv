-- STEP 2: Create policies after buckets are created
-- Run this after step 1 completes successfully

CREATE POLICY "chat_photos_upload"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'chat-photos');

CREATE POLICY "chat_photos_view"
ON storage.objects
FOR SELECT
TO authenticated
USING (bucket_id = 'chat-photos');

CREATE POLICY "disappearing_photos_upload"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'disappearing-photos');

CREATE POLICY "disappearing_photos_view"
ON storage.objects
FOR SELECT
TO authenticated
USING (bucket_id = 'disappearing-photos');
