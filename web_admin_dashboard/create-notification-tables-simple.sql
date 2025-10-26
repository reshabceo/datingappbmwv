-- Create notification tables for admin dashboard (Simplified version)

-- 1. Notification Templates Table
CREATE TABLE IF NOT EXISTS notification_templates (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  template_name VARCHAR(255) NOT NULL,
  template_content TEXT NOT NULL,
  template_type VARCHAR(50) DEFAULT 'system' CHECK (template_type IN ('promotional', 'automated', 'marketing', 'security', 'system')),
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_by UUID DEFAULT '0d535be0-df84-442d-a11f-1fd5107bd6ea'::uuid
);

-- 2. Admin Notifications Table (for tracking sent notifications)
CREATE TABLE IF NOT EXISTS admin_notifications (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  template_id UUID REFERENCES notification_templates(id) ON DELETE CASCADE,
  title VARCHAR(255) NOT NULL,
  content TEXT NOT NULL,
  notification_type VARCHAR(50) DEFAULT 'push' CHECK (notification_type IN ('push', 'in_app', 'email', 'sms')),
  status VARCHAR(20) DEFAULT 'draft' CHECK (status IN ('draft', 'scheduled', 'sent', 'failed', 'cancelled')),
  recipients_count INTEGER DEFAULT 0,
  open_rate DECIMAL(5,2) DEFAULT 0.00,
  click_rate DECIMAL(5,2) DEFAULT 0.00,
  sent_at TIMESTAMP WITH TIME ZONE,
  scheduled_for TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_by UUID DEFAULT '0d535be0-df84-442d-a11f-1fd5107bd6ea'::uuid
);

-- 3. User Notifications Table (for individual user notifications)
CREATE TABLE IF NOT EXISTS user_notifications (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  admin_notification_id UUID REFERENCES admin_notifications(id) ON DELETE CASCADE,
  user_id UUID DEFAULT '0d535be0-df84-442d-a11f-1fd5107bd6ea'::uuid,
  is_read BOOLEAN DEFAULT false,
  is_clicked BOOLEAN DEFAULT false,
  read_at TIMESTAMP WITH TIME ZONE,
  clicked_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 4. Notification Analytics Table (for daily stats)
CREATE TABLE IF NOT EXISTS notification_analytics (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  date DATE NOT NULL UNIQUE,
  total_sent INTEGER DEFAULT 0,
  total_opened INTEGER DEFAULT 0,
  total_clicked INTEGER DEFAULT 0,
  avg_open_rate DECIMAL(5,2) DEFAULT 0.00,
  avg_click_rate DECIMAL(5,2) DEFAULT 0.00,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_notification_templates_created_by ON notification_templates(created_by);
CREATE INDEX IF NOT EXISTS idx_notification_templates_type ON notification_templates(template_type);
CREATE INDEX IF NOT EXISTS idx_admin_notifications_status ON admin_notifications(status);
CREATE INDEX IF NOT EXISTS idx_admin_notifications_created_by ON admin_notifications(created_by);
CREATE INDEX IF NOT EXISTS idx_admin_notifications_sent_at ON admin_notifications(sent_at);
CREATE INDEX IF NOT EXISTS idx_user_notifications_user_id ON user_notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_user_notifications_admin_id ON user_notifications(admin_notification_id);
CREATE INDEX IF NOT EXISTS idx_notification_analytics_date ON notification_analytics(date);

-- Enable RLS
ALTER TABLE notification_templates ENABLE ROW LEVEL SECURITY;
ALTER TABLE admin_notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE notification_analytics ENABLE ROW LEVEL SECURITY;

-- RLS Policies for Admin Access
-- Allow admin user to access all notification data
CREATE POLICY "Admin can view all notification templates" ON notification_templates
FOR SELECT USING (auth.uid() = '0d535be0-df84-442d-a11f-1fd5107bd6ea'::uuid);

CREATE POLICY "Admin can create notification templates" ON notification_templates
FOR INSERT WITH CHECK (auth.uid() = '0d535be0-df84-442d-a11f-1fd5107bd6ea'::uuid);

CREATE POLICY "Admin can update notification templates" ON notification_templates
FOR UPDATE USING (auth.uid() = '0d535be0-df84-442d-a11f-1fd5107bd6ea'::uuid);

CREATE POLICY "Admin can delete notification templates" ON notification_templates
FOR DELETE USING (auth.uid() = '0d535be0-df84-442d-a11f-1fd5107bd6ea'::uuid);

CREATE POLICY "Admin can view all admin notifications" ON admin_notifications
FOR SELECT USING (auth.uid() = '0d535be0-df84-442d-a11f-1fd5107bd6ea'::uuid);

CREATE POLICY "Admin can create admin notifications" ON admin_notifications
FOR INSERT WITH CHECK (auth.uid() = '0d535be0-df84-442d-a11f-1fd5107bd6ea'::uuid);

CREATE POLICY "Admin can update admin notifications" ON admin_notifications
FOR UPDATE USING (auth.uid() = '0d535be0-df84-442d-a11f-1fd5107bd6ea'::uuid);

CREATE POLICY "Admin can delete admin notifications" ON admin_notifications
FOR DELETE USING (auth.uid() = '0d535be0-df84-442d-a11f-1fd5107bd6ea'::uuid);

CREATE POLICY "Admin can view all user notifications" ON user_notifications
FOR SELECT USING (auth.uid() = '0d535be0-df84-442d-a11f-1fd5107bd6ea'::uuid);

CREATE POLICY "Admin can view notification analytics" ON notification_analytics
FOR SELECT USING (auth.uid() = '0d535be0-df84-442d-a11f-1fd5107bd6ea'::uuid);

CREATE POLICY "Admin can create notification analytics" ON notification_analytics
FOR INSERT WITH CHECK (auth.uid() = '0d535be0-df84-442d-a11f-1fd5107bd6ea'::uuid);

CREATE POLICY "Admin can update notification analytics" ON notification_analytics
FOR UPDATE USING (auth.uid() = '0d535be0-df84-442d-a11f-1fd5107bd6ea'::uuid);
