// Notification Service for Web Admin
import { supabase } from '../admin-integrations/supabase/client';

export interface NotificationPayload {
  title: string;
  content: string;
  notification_type: 'push' | 'in_app' | 'email' | 'sms';
  template_type: 'system' | 'promotional' | 'automated' | 'marketing' | 'security';
  status: 'draft' | 'scheduled' | 'sent' | 'failed' | 'cancelled';
  recipients_count: number;
  scheduled_for?: string;
}

export class NotificationService {
  // Create a new notification
  static async createNotification(payload: NotificationPayload) {
    try {
      console.log('📧 Creating notification:', payload);

      // First create a template
      const { data: template, error: templateError } = await supabase
        .from('notification_templates')
        .insert({
          template_name: payload.title,
          template_content: payload.content,
          template_type: payload.template_type
        })
        .select()
        .single();

      if (templateError) {
        console.error('❌ Error creating template:', templateError);
        throw new Error('Failed to create notification template');
      }

      // Then create the admin notification
      const { data: notification, error: notificationError } = await supabase
        .from('admin_notifications')
        .insert({
          template_id: template.id,
          title: payload.title,
          content: payload.content,
          notification_type: payload.notification_type,
          status: payload.status,
          recipients_count: payload.recipients_count,
          scheduled_for: payload.scheduled_for ? new Date(payload.scheduled_for).toISOString() : null
        })
        .select()
        .single();

      if (notificationError) {
        console.error('❌ Error creating notification:', notificationError);
        throw new Error('Failed to create notification');
      }

      console.log('✅ Notification created successfully:', notification);
      return notification;
    } catch (error) {
      console.error('❌ Error in createNotification:', error);
      throw error;
    }
  }

  // Send notification immediately (simulate sending)
  static async sendNotification(notificationId: string) {
    try {
      console.log('📤 Sending notification:', notificationId);

      // Update status to sent and set sent_at timestamp
      const { data, error } = await supabase
        .from('admin_notifications')
        .update({
          status: 'sent',
          sent_at: new Date().toISOString(),
          open_rate: Math.random() * 30 + 50, // Simulate open rate 50-80%
          click_rate: Math.random() * 20 + 5  // Simulate click rate 5-25%
        })
        .eq('id', notificationId)
        .select()
        .single();

      if (error) {
        console.error('❌ Error sending notification:', error);
        throw new Error('Failed to send notification');
      }

      console.log('✅ Notification sent successfully:', data);
      return data;
    } catch (error) {
      console.error('❌ Error in sendNotification:', error);
      throw error;
    }
  }

  // Schedule notification for later
  static async scheduleNotification(notificationId: string, scheduledFor: string) {
    try {
      console.log('⏰ Scheduling notification:', notificationId, 'for', scheduledFor);

      const { data, error } = await supabase
        .from('admin_notifications')
        .update({
          status: 'scheduled',
          scheduled_for: new Date(scheduledFor).toISOString()
        })
        .eq('id', notificationId)
        .select()
        .single();

      if (error) {
        console.error('❌ Error scheduling notification:', error);
        throw new Error('Failed to schedule notification');
      }

      console.log('✅ Notification scheduled successfully:', data);
      return data;
    } catch (error) {
      console.error('❌ Error in scheduleNotification:', error);
      throw error;
    }
  }

  // Get all notifications
  static async getNotifications() {
    try {
      const { data, error } = await supabase
        .from('admin_notifications')
        .select(`
          *,
          notification_templates (
            template_name,
            template_type
          )
        `)
        .order('created_at', { ascending: false });

      if (error) {
        console.error('❌ Error fetching notifications:', error);
        throw new Error('Failed to fetch notifications');
      }

      return data;
    } catch (error) {
      console.error('❌ Error in getNotifications:', error);
      throw error;
    }
  }

  // Get notification stats
  static async getNotificationStats() {
    try {
      // Get total sent notifications
      const { count: totalSent } = await supabase
        .from('admin_notifications')
        .select('*', { count: 'exact', head: true })
        .eq('status', 'sent');

      // Get average open rate
      const { data: openRateData } = await supabase
        .from('admin_notifications')
        .select('open_rate')
        .eq('status', 'sent')
        .not('open_rate', 'is', null);

      const avgOpenRate = openRateData?.length > 0 
        ? openRateData.reduce((sum, item) => sum + (item.open_rate || 0), 0) / openRateData.length 
        : 0;

      // Get scheduled count
      const { count: scheduled } = await supabase
        .from('admin_notifications')
        .select('*', { count: 'exact', head: true })
        .eq('status', 'scheduled');

      // Get average click rate
      const { data: clickRateData } = await supabase
        .from('admin_notifications')
        .select('click_rate')
        .eq('status', 'sent')
        .not('click_rate', 'is', null);

      const avgClickRate = clickRateData?.length > 0 
        ? clickRateData.reduce((sum, item) => sum + (item.click_rate || 0), 0) / clickRateData.length 
        : 0;

      return {
        totalSent: totalSent || 0,
        openRate: Math.round(avgOpenRate * 100) / 100,
        scheduled: scheduled || 0,
        clickRate: Math.round(avgClickRate * 100) / 100
      };
    } catch (error) {
      console.error('❌ Error in getNotificationStats:', error);
      throw error;
    }
  }

  // Delete notification
  static async deleteNotification(notificationId: string) {
    try {
      console.log('🗑️ Deleting notification:', notificationId);

      const { error } = await supabase
        .from('admin_notifications')
        .delete()
        .eq('id', notificationId);

      if (error) {
        console.error('❌ Error deleting notification:', error);
        throw new Error('Failed to delete notification');
      }

      console.log('✅ Notification deleted successfully');
      return true;
    } catch (error) {
      console.error('❌ Error in deleteNotification:', error);
      throw error;
    }
  }
}
