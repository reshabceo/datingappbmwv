import 'dart:io';
import 'package:lovebug/services/supabase_service.dart';

/// Service to handle server-side notification clearing
/// This ensures notifications are cleared even when the app is closed
class NotificationClearingService {
  
  /// Clear call notification for a specific user
  static Future<void> clearCallNotification({
    required String userId,
    required String callId,
    String? callerName,
  }) async {
    try {
      print('🧹 NOTIFICATION_CLEARING: Clearing call notification for user: $userId, call: $callId');
      
      final response = await SupabaseService.client.functions.invoke(
        'send-push-notification',
        body: {
          'userId': userId,
          'type': 'clear_notification',
          'title': 'Call Ended',
          'body': 'Call has ended',
          'data': {
            'call_id': callId,
            'caller_name': callerName ?? 'Unknown',
            'action': 'clear_notification',
            'clear_type': 'call_ended',
          },
        },
      );
      
      if (response.status == 200) {
        print('✅ NOTIFICATION_CLEARING: Call notification cleared successfully');
      } else {
        print('❌ NOTIFICATION_CLEARING: Failed to clear notification: ${response.data}');
      }
    } catch (e) {
      print('❌ NOTIFICATION_CLEARING: Error clearing notification: $e');
    }
  }
  
  /// Clear all notifications for a user (when they accept/decline)
  static Future<void> clearAllNotifications({
    required String userId,
    required String callId,
  }) async {
    try {
      print('🧹 NOTIFICATION_CLEARING: Clearing all notifications for user: $userId');
      
      final response = await SupabaseService.client.functions.invoke(
        'send-push-notification',
        body: {
          'userId': userId,
          'type': 'clear_notification',
          'title': 'Call Action',
          'body': 'Call action taken',
          'data': {
            'call_id': callId,
            'action': 'clear_all',
            'clear_type': 'call_action',
          },
        },
      );
      
      if (response.status == 200) {
        print('✅ NOTIFICATION_CLEARING: All notifications cleared successfully');
      } else {
        print('❌ NOTIFICATION_CLEARING: Failed to clear all notifications: ${response.data}');
      }
    } catch (e) {
      print('❌ NOTIFICATION_CLEARING: Error clearing all notifications: $e');
    }
  }
  
  /// Send missed call notification
  static Future<void> sendMissedCallNotification({
    required String userId,
    required String callId,
    required String callerName,
    required String callType,
  }) async {
    try {
      print('📞 MISSED_CALL: Sending missed call notification for user: $userId, caller: $callerName');
      
      final response = await SupabaseService.client.functions.invoke(
        'send-push-notification',
        body: {
          'userId': userId,
          'type': 'missed_call',
          'title': '📞 Missed Call',
          'body': 'You missed a call from $callerName',
          'data': {
            'call_id': callId,
            'caller_name': callerName,
            'call_type': callType,
            'action': 'missed_call',
          },
        },
      );
      
      if (response.status == 200) {
        print('✅ MISSED_CALL: Missed call notification sent successfully');
      } else {
        print('❌ MISSED_CALL: Failed to send missed call notification: ${response.data}');
      }
    } catch (e) {
      print('❌ MISSED_CALL: Error sending missed call notification: $e');
    }
  }
}
