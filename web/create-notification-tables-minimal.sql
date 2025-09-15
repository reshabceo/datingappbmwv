-- Create notification tables for admin dashboard (Minimal version - no foreign keys)

-- Drop tables if they exist to start fresh
DROP TABLE IF EXISTS user_notifications CASCADE;
DROP TABLE IF EXISTS admin_notifications CASCADE;
DROP TABLE IF EXISTS notification_templates CASCADE;
DROP TABLE IF EXISTS notification_analytics CASCADE;

-- 1. Notification Templates Table
CREATE TABLE notification_templates (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  template_name VARCHAR(255) NOT NULL,
  template_content TEXT NOT NULL,
  template_type VARCHAR(50) DEFAULT 'system',
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. Admin Notifications Table
CREATE TABLE admin_notifications (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  template_id UUID REFERENCES notification_templates(id) ON DELETE CASCADE,
  title VARCHAR(255) NOT NULL,
  content TEXT NOT NULL,
  notification_type VARCHAR(50) DEFAULT 'push',
  status VARCHAR(20) DEFAULT 'draft',
  recipients_count INTEGER DEFAULT 0,
  open_rate DECIMAL(5,2) DEFAULT 0.00,
  click_rate DECIMAL(5,2) DEFAULT 0.00,
  sent_at TIMESTAMP WITH TIME ZONE,
  scheduled_for TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. User Notifications Table
CREATE TABLE user_notifications (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  admin_notification_id UUID REFERENCES admin_notifications(id) ON DELETE CASCADE,
  user_id UUID,
  is_read BOOLEAN DEFAULT false,
  is_clicked BOOLEAN DEFAULT false,
  read_at TIMESTAMP WITH TIME ZONE,
  clicked_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 4. Notification Analytics Table
CREATE TABLE notification_analytics (
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

-- Create indexes
CREATE INDEX idx_notification_templates_type ON notification_templates(template_type);
CREATE INDEX idx_admin_notifications_status ON admin_notifications(status);
CREATE INDEX idx_admin_notifications_sent_at ON admin_notifications(sent_at);
CREATE INDEX idx_user_notifications_user_id ON user_notifications(user_id);
CREATE INDEX idx_notification_analytics_date ON notification_analytics(date);

-- Enable RLS
ALTER TABLE notification_templates ENABLE ROW LEVEL SECURITY;
ALTER TABLE admin_notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE notification_analytics ENABLE ROW LEVEL SECURITY;

-- Simple RLS Policies - Allow all for admin
CREATE POLICY "Allow all for admin" ON notification_templates
FOR ALL USING (true);

CREATE POLICY "Allow all for admin" ON admin_notifications
FOR ALL USING (true);

CREATE POLICY "Allow all for admin" ON user_notifications
FOR ALL USING (true);

CREATE POLICY "Allow all for admin" ON notification_analytics
FOR ALL USING (true);
