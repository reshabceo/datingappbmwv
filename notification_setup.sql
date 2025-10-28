-- Create notifications table
CREATE TABLE IF NOT EXISTS notifications (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  type VARCHAR(50) NOT NULL,
  title VARCHAR(255) NOT NULL,
  body TEXT NOT NULL,
  data JSONB DEFAULT '{}',
  fcm_token TEXT,
  sent BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  read_at TIMESTAMP WITH TIME ZONE
);

-- Add notification preference columns to profiles table
ALTER TABLE profiles 
ADD COLUMN IF NOT EXISTS notification_matches BOOLEAN DEFAULT true,
ADD COLUMN IF NOT EXISTS notification_messages BOOLEAN DEFAULT true,
ADD COLUMN IF NOT EXISTS notification_stories BOOLEAN DEFAULT true,
ADD COLUMN IF NOT EXISTS notification_likes BOOLEAN DEFAULT true,
ADD COLUMN IF NOT EXISTS notification_admin BOOLEAN DEFAULT true;

-- Create index for better performance
CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_sent ON notifications(sent);
CREATE INDEX IF NOT EXISTS idx_notifications_created_at ON notifications(created_at);

-- Enable RLS
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
CREATE POLICY "Users can view their own notifications" ON notifications
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can update their own notifications" ON notifications
  FOR UPDATE USING (auth.uid() = user_id);

-- Create function to get pending notifications
CREATE OR REPLACE FUNCTION get_pending_notifications(p_user_id UUID)
RETURNS TABLE (
  id UUID,
  type VARCHAR(50),
  title VARCHAR(255),
  body TEXT,
  data JSONB,
  created_at TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    n.id,
    n.type,
    n.title,
    n.body,
    n.data,
    n.created_at
  FROM notifications n
  WHERE n.user_id = p_user_id
    AND n.sent = false
  ORDER BY n.created_at DESC
  LIMIT 10;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create function to mark notification as sent
CREATE OR REPLACE FUNCTION mark_notification_sent(p_notification_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
  UPDATE notifications 
  SET sent = true 
  WHERE id = p_notification_id;
  
  RETURN FOUND;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
