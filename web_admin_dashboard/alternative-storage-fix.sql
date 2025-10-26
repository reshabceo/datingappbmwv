-- Alternative approach if you get permission errors
-- This uses a different method that might work better

-- Method 1: Try creating the bucket through the dashboard first
-- Go to Storage → New Bucket → Create "profile-photos" bucket as public

-- Method 2: If you can't run the above SQL, try this simpler approach
-- Just run this single line:
INSERT INTO storage.buckets (id, name, public) VALUES ('profile-photos', 'profile-photos', true) ON CONFLICT (id) DO UPDATE SET public = true;

-- Method 3: If you still get errors, try running this in smaller chunks:
-- Step 1: Create bucket
INSERT INTO storage.buckets (id, name, public) VALUES ('profile-photos', 'profile-photos', true) ON CONFLICT (id) DO UPDATE SET public = true;

-- Step 2: Enable RLS
ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;

-- Step 3: Create upload policy
CREATE POLICY "profile_photos_upload" ON storage.objects FOR INSERT TO authenticated WITH CHECK (bucket_id = 'profile-photos');

-- Step 4: Create view policy  
CREATE POLICY "profile_photos_view" ON storage.objects FOR SELECT TO public USING (bucket_id = 'profile-photos');

