import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class PushNotificationService {
  static const String _edgeFunctionUrl = 'https://your-project.supabase.co/functions/v1/send-push-notification';

  /// Send a push notification to a specific user
  static Future<bool> sendNotification({
    required String userId,
    required String type,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      final client = Supabase.instance.client;
      
      final response = await client.functions.invoke(
        'send-push-notification',
        body: {
          'userId': userId,
          'type': type,
          'title': title,
          'body': body,
          'data': data ?? {},
        },
      );

      if (response.status == 200) {
        print('✅ Push notification sent successfully');
        return true;
      } else {
        print('❌ Failed to send push notification: ${response.data}');
        return false;
      }
    } catch (e) {
      print('❌ Error sending push notification: $e');
      return false;
    }
  }

  /// Send notification for new match
  static Future<bool> sendNewMatchNotification({
    required String userId,
    required String matchName,
    required String matchId,
  }) async {
    return await sendNotification(
      userId: userId,
      type: 'new_match',
      title: '🎉 New Match!',
      body: 'You matched with $matchName!',
      data: {
        'match_id': matchId,
        'match_name': matchName,
      },
    );
  }

  /// Send notification for new message
  static Future<bool> sendNewMessageNotification({
    required String userId,
    required String senderName,
    required String message,
    required String chatId,
  }) async {
    return await sendNotification(
      userId: userId,
      type: 'new_message',
      title: '💬 New message from $senderName',
      body: message.length > 50 ? '${message.substring(0, 50)}...' : message,
      data: {
        'chat_id': chatId,
        'sender_name': senderName,
      },
    );
  }

  /// Send notification for new like
  static Future<bool> sendNewLikeNotification({
    required String userId,
    required String likerName,
  }) async {
    return await sendNotification(
      userId: userId,
      type: 'new_like',
      title: '❤️ Someone likes you!',
      body: '$likerName liked your profile',
      data: {
        'liker_name': likerName,
      },
    );
  }

  /// Send notification for story reply
  static Future<bool> sendStoryReplyNotification({
    required String userId,
    required String replierName,
  }) async {
    return await sendNotification(
      userId: userId,
      type: 'story_reply',
      title: '📸 Story reply',
      body: '$replierName replied to your story',
      data: {
        'replier_name': replierName,
      },
    );
  }

  /// Send admin notification
  static Future<bool> sendAdminNotification({
    required String userId,
    required String title,
    required String message,
    String? type,
  }) async {
    return await sendNotification(
      userId: userId,
      type: type ?? 'admin_message',
      title: title,
      body: message,
      data: {
        'admin_notification': true,
      },
    );
  }

  /// Send account suspended notification
  static Future<bool> sendAccountSuspendedNotification({
    required String userId,
    required String reason,
  }) async {
    return await sendNotification(
      userId: userId,
      type: 'account_suspended',
      title: '⚠️ Account Suspended',
      body: reason,
      data: {
        'suspension_reason': reason,
      },
    );
  }

  // =============================================================================
  // CALL NOTIFICATION METHODS
  // =============================================================================

  /// Send incoming call notification
  static Future<bool> sendIncomingCallNotification({
    required String userId,
    required String callerName,
    required String callId,
    required String callType, // 'audio' or 'video'
  }) async {
    final callIcon = callType == 'video' ? '📹' : '📞';
    return await sendNotification(
      userId: userId,
      type: 'incoming_call',
      title: '$callIcon Incoming ${callType == 'video' ? 'Video' : 'Audio'} Call',
      body: '$callerName is calling you',
      data: {
        'call_id': callId,
        'caller_name': callerName,
        'call_type': callType,
        'action': 'incoming_call',
      },
    );
  }

  /// Send missed call notification
  static Future<bool> sendMissedCallNotification({
    required String userId,
    required String callerName,
    required String callType,
  }) async {
    final callIcon = callType == 'video' ? '📹' : '📞';
    return await sendNotification(
      userId: userId,
      type: 'missed_call',
      title: '$callIcon Missed ${callType == 'video' ? 'Video' : 'Audio'} Call',
      body: 'You missed a call from $callerName',
      data: {
        'caller_name': callerName,
        'call_type': callType,
        'action': 'missed_call',
      },
    );
  }

  /// Send call ended notification
  static Future<bool> sendCallEndedNotification({
    required String userId,
    required String callerName,
    required String callType,
    required String duration,
  }) async {
    final callIcon = callType == 'video' ? '📹' : '📞';
    return await sendNotification(
      userId: userId,
      type: 'call_ended',
      title: '$callIcon Call Ended',
      body: 'Call with $callerName ended (${duration})',
      data: {
        'caller_name': callerName,
        'call_type': callType,
        'duration': duration,
        'action': 'call_ended',
      },
    );
  }

  /// Send call rejected notification
  static Future<bool> sendCallRejectedNotification({
    required String userId,
    required String callerName,
    required String callType,
  }) async {
    final callIcon = callType == 'video' ? '📹' : '📞';
    return await sendNotification(
      userId: userId,
      type: 'call_rejected',
      title: '$callIcon Call Declined',
      body: '$callerName declined your ${callType == 'video' ? 'video' : 'audio'} call',
      data: {
        'caller_name': callerName,
        'call_type': callType,
        'action': 'call_rejected',
      },
    );
  }
}
