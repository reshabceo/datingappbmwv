-- Add DELETE policy for stories table
-- Run this in Supabase SQL Editor

-- Add DELETE policy for stories - users can delete their own stories
CREATE POLICY "Users can delete their own stories" ON stories
  FOR DELETE USING (auth.uid() = user_id);

-- Verify the policy was created
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
WHERE tablename = 'stories'
AND policyname LIKE '%delete%'
ORDER BY policyname;
