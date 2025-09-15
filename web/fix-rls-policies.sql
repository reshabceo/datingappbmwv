-- Drop the problematic policies that try to access auth.users
DROP POLICY IF EXISTS "Admin users can view conversation metadata" ON conversation_metadata;
DROP POLICY IF EXISTS "Admin users can view message analytics" ON message_analytics;
DROP POLICY IF EXISTS "Admin users can view message flags" ON message_flags;
DROP POLICY IF EXISTS "Admin users can create message flags" ON message_flags;
DROP POLICY IF EXISTS "Admin users can update message flags" ON message_flags;

-- Create simpler policies that check for the specific admin user ID
CREATE POLICY "Admin can view conversation metadata" ON conversation_metadata
FOR SELECT USING (auth.uid() = '0d535be0-df84-442d-a11f-1fd5107bd6ea'::uuid);

CREATE POLICY "Admin can view message analytics" ON message_analytics
FOR SELECT USING (auth.uid() = '0d535be0-df84-442d-a11f-1fd5107bd6ea'::uuid);

CREATE POLICY "Admin can view message flags" ON message_flags
FOR SELECT USING (auth.uid() = '0d535be0-df84-442d-a11f-1fd5107bd6ea'::uuid);

CREATE POLICY "Admin can create message flags" ON message_flags
FOR INSERT WITH CHECK (auth.uid() = '0d535be0-df84-442d-a11f-1fd5107bd6ea'::uuid);

CREATE POLICY "Admin can update message flags" ON message_flags
FOR UPDATE USING (auth.uid() = '0d535be0-df84-442d-a11f-1fd5107bd6ea'::uuid);

-- Also add policies for matches and messages to allow admin to view all
CREATE POLICY "Admin can view all matches" ON matches
FOR SELECT USING (auth.uid() = '0d535be0-df84-442d-a11f-1fd5107bd6ea'::uuid);

CREATE POLICY "Admin can view all messages" ON messages
FOR SELECT USING (auth.uid() = '0d535be0-df84-442d-a11f-1fd5107bd6ea'::uuid);
