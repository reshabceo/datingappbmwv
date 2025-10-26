-- Add sample notification data for testing

-- Insert sample notification templates
INSERT INTO notification_templates (template_name, template_content, template_type, created_by) VALUES
('Welcome Message', 'Welcome to our dating app! Start connecting with amazing people today.', 'automated', '0d535be0-df84-442d-a11f-1fd5107bd6ea'),
('New Match Alert', 'You have a new match! Check out your new connection.', 'automated', '0d535be0-df84-442d-a11f-1fd5107bd6ea'),
('Profile Reminder', 'Complete your profile to get more matches!', 'promotional', '0d535be0-df84-442d-a11f-1fd5107bd6ea'),
('Safety Tips', 'Stay safe while dating online. Here are some important safety tips.', 'security', '0d535be0-df84-442d-a11f-1fd5107bd6ea'),
('Premium Features', 'Unlock premium features to boost your dating success!', 'marketing', '0d535be0-df84-442d-a11f-1fd5107bd6ea'),
('App Update', 'New features available! Update your app to enjoy the latest improvements.', 'system', '0d535be0-df84-442d-a11f-1fd5107bd6ea');

-- Insert sample admin notifications
INSERT INTO admin_notifications (template_id, title, content, notification_type, status, recipients_count, open_rate, click_rate, sent_at, created_by) VALUES
((SELECT id FROM notification_templates WHERE template_name = 'Welcome Message'), 'Welcome to Our App!', 'Welcome to our dating app! Start connecting with amazing people today.', 'push', 'sent', 150, 75.5, 12.3, NOW() - INTERVAL '2 days', '0d535be0-df84-442d-a11f-1fd5107bd6ea'),
((SELECT id FROM notification_templates WHERE template_name = 'New Match Alert'), 'You Have a New Match!', 'You have a new match! Check out your new connection.', 'push', 'sent', 89, 82.1, 18.7, NOW() - INTERVAL '1 day', '0d535be0-df84-442d-a11f-1fd5107bd6ea'),
((SELECT id FROM notification_templates WHERE template_name = 'Profile Reminder'), 'Complete Your Profile', 'Complete your profile to get more matches!', 'in_app', 'sent', 234, 65.2, 8.9, NOW() - INTERVAL '3 hours', '0d535be0-df84-442d-a11f-1fd5107bd6ea'),
((SELECT id FROM notification_templates WHERE template_name = 'Safety Tips'), 'Safety First', 'Stay safe while dating online. Here are some important safety tips.', 'push', 'sent', 200, 70.8, 15.2, NOW() - INTERVAL '5 days', '0d535be0-df84-442d-a11f-1fd5107bd6ea'),
((SELECT id FROM notification_templates WHERE template_name = 'Premium Features'), 'Unlock Premium', 'Unlock premium features to boost your dating success!', 'push', 'scheduled', 0, 0, 0, NULL, '0d535be0-df84-442d-a11f-1fd5107bd6ea'),
((SELECT id FROM notification_templates WHERE template_name = 'App Update'), 'App Update Available', 'New features available! Update your app to enjoy the latest improvements.', 'system', 'draft', 0, 0, 0, NULL, '0d535be0-df84-442d-a11f-1fd5107bd6ea');

-- Insert sample notification analytics for the last 7 days
INSERT INTO notification_analytics (date, total_sent, total_opened, total_clicked, avg_open_rate, avg_click_rate) VALUES
(CURRENT_DATE, 150, 113, 18, 75.33, 12.00),
(CURRENT_DATE - INTERVAL '1 day', 89, 73, 17, 81.97, 19.10),
(CURRENT_DATE - INTERVAL '2 days', 234, 153, 21, 65.38, 8.97),
(CURRENT_DATE - INTERVAL '3 days', 200, 142, 30, 71.00, 15.00),
(CURRENT_DATE - INTERVAL '4 days', 120, 96, 14, 80.00, 11.67),
(CURRENT_DATE - INTERVAL '5 days', 180, 126, 22, 70.00, 12.22),
(CURRENT_DATE - INTERVAL '6 days', 95, 76, 12, 80.00, 12.63);

-- Insert sample user notifications (for a few users)
INSERT INTO user_notifications (admin_notification_id, user_id, is_read, is_clicked, read_at, clicked_at) VALUES
((SELECT id FROM admin_notifications WHERE title = 'Welcome to Our App!'), '7ffe44fe-9c0f-4783-aec2-a6172a6e008b', true, true, NOW() - INTERVAL '2 days', NOW() - INTERVAL '2 days'),
((SELECT id FROM admin_notifications WHERE title = 'You Have a New Match!'), '7ffe44fe-9c0f-4783-aec2-a6172a6e008b', true, false, NOW() - INTERVAL '1 day', NULL),
((SELECT id FROM admin_notifications WHERE title = 'Complete Your Profile'), '7ffe44fe-9c0f-4783-aec2-a6172a6e008b', false, false, NULL, NULL),
((SELECT id FROM admin_notifications WHERE title = 'Welcome to Our App!'), '935a30da-647e-416c-8b20-4b82d9dab4eb', true, false, NOW() - INTERVAL '2 days', NULL),
((SELECT id FROM admin_notifications WHERE title = 'You Have a New Match!'), '935a30da-647e-416c-8b20-4b82d9dab4eb', true, true, NOW() - INTERVAL '1 day', NOW() - INTERVAL '1 day');
