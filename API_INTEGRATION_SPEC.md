# API Integration Specification for Admin Panel & Flutter App

## Overview

This document outlines the API endpoints, data flows, and integration requirements for connecting the React admin panel with the Flutter dating app through Supabase.

## Database Schema Extensions

### New Tables for Admin Integration

```sql
-- Admin notifications table
CREATE TABLE admin_notifications (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id uuid REFERENCES profiles(id) ON DELETE CASCADE,
  type varchar(50) NOT NULL, -- 'user_suspended', 'subscription_updated', 'content_moderated'
  message text NOT NULL,
  data jsonb,
  is_read boolean DEFAULT false,
  created_at timestamp with time zone DEFAULT now()
);

-- Analytics events table
CREATE TABLE analytics_events (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id uuid REFERENCES profiles(id) ON DELETE CASCADE,
  event_name varchar(100) NOT NULL,
  properties jsonb,
  platform varchar(50) DEFAULT 'flutter_ios',
  session_id varchar(100),
  timestamp timestamp with time zone DEFAULT now()
);

-- Content reports table
CREATE TABLE content_reports (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  reporter_id uuid REFERENCES profiles(id) ON DELETE CASCADE,
  content_id uuid NOT NULL,
  content_type varchar(50) NOT NULL, -- 'profile', 'message', 'story', 'photo'
  reason varchar(100) NOT NULL,
  description text,
  status varchar(20) DEFAULT 'pending', -- 'pending', 'approved', 'rejected'
  moderator_id uuid REFERENCES profiles(id),
  moderator_notes text,
  created_at timestamp with time zone DEFAULT now(),
  resolved_at timestamp with time zone
);

-- User activity logs table
CREATE TABLE user_activity_logs (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id uuid REFERENCES profiles(id) ON DELETE CASCADE,
  activity_type varchar(50) NOT NULL, -- 'login', 'swipe', 'match', 'message', 'profile_update'
  activity_data jsonb,
  ip_address inet,
  user_agent text,
  created_at timestamp with time zone DEFAULT now()
);

-- Admin actions log table
CREATE TABLE admin_actions_log (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  admin_id uuid REFERENCES profiles(id) ON DELETE CASCADE,
  action_type varchar(50) NOT NULL, -- 'user_suspend', 'user_activate', 'content_moderate'
  target_id uuid NOT NULL,
  action_data jsonb,
  created_at timestamp with time zone DEFAULT now()
);
```

## API Endpoints Specification

### 1. User Management APIs

#### Get User Analytics
```typescript
// Admin Panel → Supabase
GET /rest/v1/profiles?select=*,user_subscriptions(*),analytics_events(*)
```

#### Update User Status
```typescript
// Admin Panel → Supabase
PATCH /rest/v1/profiles
{
  "id": "user-uuid",
  "is_active": false,
  "suspension_reason": "Violation of terms"
}
```

#### Get User Activity Logs
```typescript
// Admin Panel → Supabase
GET /rest/v1/user_activity_logs?user_id=eq.{user-uuid}&order=created_at.desc
```

### 2. Analytics APIs

#### Track User Event (Flutter → Supabase)
```dart
// Flutter App → Supabase
POST /rest/v1/analytics_events
{
  "user_id": "user-uuid",
  "event_name": "profile_view",
  "properties": {
    "viewed_user_id": "target-user-uuid",
    "session_duration": 45
  },
  "platform": "flutter_ios"
}
```

#### Get Platform Analytics (Admin Panel → Supabase)
```typescript
// Admin Panel → Supabase
GET /rest/v1/analytics_events?select=event_name,properties,created_at&order=created_at.desc
```

### 3. Content Moderation APIs

#### Report Content (Flutter → Supabase)
```dart
// Flutter App → Supabase
POST /rest/v1/content_reports
{
  "reporter_id": "user-uuid",
  "content_id": "content-uuid",
  "content_type": "profile",
  "reason": "inappropriate_content",
  "description": "User reported for fake photos"
}
```

#### Moderate Content (Admin Panel → Supabase)
```typescript
// Admin Panel → Supabase
PATCH /rest/v1/content_reports
{
  "id": "report-uuid",
  "status": "approved",
  "moderator_id": "admin-uuid",
  "moderator_notes": "Content reviewed and approved"
}
```

### 4. Subscription Management APIs

#### Get Subscription Status (Flutter → Supabase)
```dart
// Flutter App → Supabase
GET /rest/v1/user_subscriptions?user_id=eq.{user-uuid}&select=*,subscription_plans(*)
```

#### Update Subscription (Admin Panel → Supabase)
```typescript
// Admin Panel → Supabase
PATCH /rest/v1/user_subscriptions
{
  "id": "subscription-uuid",
  "status": "active",
  "plan_id": "new-plan-uuid"
}
```

### 5. Notification APIs

#### Send Admin Notification (Admin Panel → Supabase)
```typescript
// Admin Panel → Supabase
POST /rest/v1/admin_notifications
{
  "user_id": "user-uuid",
  "type": "user_suspended",
  "message": "Your account has been temporarily suspended",
  "data": {
    "suspension_reason": "Inappropriate behavior",
    "suspension_duration": "7 days"
  }
}
```

#### Get User Notifications (Flutter → Supabase)
```dart
// Flutter App → Supabase
GET /rest/v1/admin_notifications?user_id=eq.{user-uuid}&is_read=eq.false&order=created_at.desc
```

## Real-time Subscriptions

### 1. User Status Changes
```dart
// Flutter App - Listen for user status changes
SupabaseService.client
  .channel('user_status_changes')
  .onPostgresChanges(
    event: PostgresChangeEvent.update,
    schema: 'public',
    table: 'profiles',
    filter: PostgresChangeFilter(
      type: PostgresChangeFilterType.eq,
      column: 'id',
      value: currentUserId
    ),
    callback: (payload) {
      // Handle user status change
      handleUserStatusUpdate(payload.newRecord);
    }
  )
  .subscribe();
```

### 2. Admin Notifications
```dart
// Flutter App - Listen for admin notifications
SupabaseService.client
  .channel('admin_notifications')
  .onPostgresChanges(
    event: PostgresChangeEvent.insert,
    schema: 'public',
    table: 'admin_notifications',
    filter: PostgresChangeFilter(
      type: PostgresChangeFilterType.eq,
      column: 'user_id',
      value: currentUserId
    ),
    callback: (payload) {
      // Handle new admin notification
      handleAdminNotification(payload.newRecord);
    }
  )
  .subscribe();
```

### 3. Content Moderation Updates
```typescript
// Admin Panel - Listen for content reports
supabase
  .channel('content_reports')
  .onPostgresChanges(
    event: 'INSERT',
    schema: 'public',
    table: 'content_reports',
    callback: (payload) => {
      // Handle new content report
      handleNewContentReport(payload.new);
    }
  )
  .subscribe();
```

## Flutter Service Layer Implementation

### Enhanced SupabaseService
```dart
class AdminIntegrationService {
  // Track user activity
  static Future<void> trackActivity(String activityType, Map<String, dynamic> data) async {
    try {
      await SupabaseService.client.from('user_activity_logs').insert({
        'user_id': SupabaseService.currentUser?.id,
        'activity_type': activityType,
        'activity_data': data,
        'created_at': DateTime.now().toIso8601String()
      });
    } catch (e) {
      print('Error tracking activity: $e');
    }
  }

  // Report content
  static Future<void> reportContent({
    required String contentId,
    required String contentType,
    required String reason,
    String? description,
  }) async {
    try {
      await SupabaseService.client.from('content_reports').insert({
        'reporter_id': SupabaseService.currentUser?.id,
        'content_id': contentId,
        'content_type': contentType,
        'reason': reason,
        'description': description,
        'status': 'pending'
      });
    } catch (e) {
      print('Error reporting content: $e');
    }
  }

  // Get admin notifications
  static Future<List<Map<String, dynamic>>> getAdminNotifications() async {
    try {
      final response = await SupabaseService.client
          .from('admin_notifications')
          .select('*')
          .eq('user_id', SupabaseService.currentUser?.id)
          .eq('is_read', false)
          .order('created_at', ascending: false);
      
      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      print('Error fetching notifications: $e');
      return [];
    }
  }

  // Mark notification as read
  static Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await SupabaseService.client
          .from('admin_notifications')
          .update({'is_read': true})
          .eq('id', notificationId);
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  // Get subscription status
  static Future<Map<String, dynamic>?> getSubscriptionStatus() async {
    try {
      final response = await SupabaseService.client
          .from('user_subscriptions')
          .select('*, subscription_plans(*)')
          .eq('user_id', SupabaseService.currentUser?.id)
          .eq('status', 'active')
          .maybeSingle();
      
      return response;
    } catch (e) {
      print('Error fetching subscription: $e');
      return null;
    }
  }
}
```

### Analytics Service Enhancement
```dart
class AnalyticsService {
  // Track feature usage
  static Future<void> trackFeatureUsage(String feature, Map<String, dynamic> properties) async {
    try {
      await SupabaseService.client.from('analytics_events').insert({
        'user_id': SupabaseService.currentUser?.id,
        'event_name': 'feature_usage',
        'properties': {
          'feature': feature,
          ...properties
        },
        'platform': 'flutter_ios',
        'timestamp': DateTime.now().toIso8601String()
      });
    } catch (e) {
      print('Error tracking feature usage: $e');
    }
  }

  // Track user engagement
  static Future<void> trackEngagement(String engagementType, Map<String, dynamic> data) async {
    try {
      await SupabaseService.client.from('analytics_events').insert({
        'user_id': SupabaseService.currentUser?.id,
        'event_name': 'user_engagement',
        'properties': {
          'engagement_type': engagementType,
          ...data
        },
        'platform': 'flutter_ios',
        'timestamp': DateTime.now().toIso8601String()
      });
    } catch (e) {
      print('Error tracking engagement: $e');
    }
  }
}
```

## Admin Panel API Integration

### User Management Service
```typescript
// Admin Panel - User Management
class UserManagementService {
  static async getUsers(filters: UserFilters) {
    const { data, error } = await supabase
      .from('profiles')
      .select(`
        *,
        user_subscriptions(*),
        analytics_events(*),
        user_activity_logs(*)
      `)
      .order('created_at', { ascending: false });

    if (error) throw error;
    return data;
  }

  static async updateUserStatus(userId: string, status: 'active' | 'suspended', reason?: string) {
    const { error } = await supabase
      .from('profiles')
      .update({ 
        is_active: status === 'active',
        suspension_reason: reason 
      })
      .eq('id', userId);

    if (error) throw error;

    // Log admin action
    await supabase.from('admin_actions_log').insert({
      admin_id: getCurrentAdminId(),
      action_type: 'user_suspend',
      target_id: userId,
      action_data: { status, reason }
    });
  }
}
```

### Analytics Service
```typescript
// Admin Panel - Analytics
class AnalyticsService {
  static async getPlatformAnalytics(dateRange: DateRange) {
    const { data, error } = await supabase
      .from('analytics_events')
      .select('*')
      .gte('timestamp', dateRange.start.toISOString())
      .lte('timestamp', dateRange.end.toISOString());

    if (error) throw error;
    return data;
  }

  static async getRealTimeMetrics() {
    const { data, error } = await supabase
      .from('analytics_events')
      .select('*')
      .gte('timestamp', new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString());

    if (error) throw error;
    return data;
  }
}
```

## Security Considerations

### Row Level Security (RLS) Policies

```sql
-- Admin notifications RLS
CREATE POLICY "Users can view their own notifications"
ON admin_notifications FOR SELECT
TO authenticated
USING (auth.uid() = user_id);

-- Analytics events RLS
CREATE POLICY "Users can insert their own analytics events"
ON analytics_events FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = user_id);

-- Content reports RLS
CREATE POLICY "Users can report content"
ON content_reports FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = reporter_id);

-- Admin actions log RLS
CREATE POLICY "Admins can view all admin actions"
ON admin_actions_log FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM profiles 
    WHERE profiles.id = auth.uid() 
    AND profiles.role = 'admin'
  )
);
```

### API Rate Limiting
```typescript
// Implement rate limiting for analytics events
const RATE_LIMITS = {
  analytics_events: 100, // per hour
  content_reports: 10,   // per hour
  user_activity: 1000    // per hour
};
```

## Error Handling

### Flutter Error Handling
```dart
class AdminIntegrationError extends Error {
  final String message;
  final String? code;
  
  AdminIntegrationError(this.message, [this.code]);
  
  @override
  String toString() => 'AdminIntegrationError: $message';
}

// Usage in services
try {
  await AdminIntegrationService.trackActivity('login', {});
} on AdminIntegrationError catch (e) {
  print('Admin integration error: ${e.message}');
} catch (e) {
  print('Unexpected error: $e');
}
```

### Admin Panel Error Handling
```typescript
// Error handling for admin operations
const handleAdminError = (error: any, operation: string) => {
  console.error(`Admin ${operation} error:`, error);
  
  if (error.code === 'PGRST301') {
    toast.error('Permission denied');
  } else if (error.code === 'PGRST116') {
    toast.error('Resource not found');
  } else {
    toast.error(`Failed to ${operation}`);
  }
};
```

## Testing Endpoints

### Flutter Integration Tests
```dart
// Test admin integration
void main() {
  group('Admin Integration Tests', () {
    test('should track user activity', () async {
      await AdminIntegrationService.trackActivity('test', {});
      // Verify data was inserted
    });
    
    test('should report content', () async {
      await AdminIntegrationService.reportContent(
        contentId: 'test-id',
        contentType: 'profile',
        reason: 'inappropriate'
      );
      // Verify report was created
    });
  });
}
```

### Admin Panel Integration Tests
```typescript
// Test admin panel integration
describe('Admin Integration', () => {
  it('should update user status', async () => {
    await UserManagementService.updateUserStatus('user-id', 'suspended');
    // Verify user status was updated
  });
  
  it('should get analytics data', async () => {
    const data = await AnalyticsService.getPlatformAnalytics(dateRange);
    expect(data).toBeDefined();
  });
});
```

## Performance Optimization

### Database Indexes
```sql
-- Indexes for performance
CREATE INDEX idx_analytics_events_user_id ON analytics_events(user_id);
CREATE INDEX idx_analytics_events_timestamp ON analytics_events(timestamp);
CREATE INDEX idx_admin_notifications_user_id ON admin_notifications(user_id);
CREATE INDEX idx_content_reports_status ON content_reports(status);
CREATE INDEX idx_user_activity_logs_user_id ON user_activity_logs(user_id);
```

### Caching Strategy
```typescript
// Admin panel caching
const cacheConfig = {
  userData: { ttl: 300 }, // 5 minutes
  analytics: { ttl: 600 }, // 10 minutes
  subscriptions: { ttl: 900 } // 15 minutes
};
```

This API integration specification provides a comprehensive foundation for connecting the admin panel with the Flutter app, ensuring real-time data synchronization, proper security, and optimal performance.
