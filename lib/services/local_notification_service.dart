import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lovebug/services/supabase_service.dart';

class LocalNotificationService {
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;
    
    try {
      // Skip on web
      if (kIsWeb) {
        _initialized = true;
        return;
      }

      _initialized = true;
      print('✅ LocalNotificationService initialized');
      
      // Start polling for notifications
      _startNotificationPolling();
    } catch (e) {
      print('❌ LocalNotificationService initialization failed: $e');
    }
  }

  static void _startNotificationPolling() {
    // Poll for notifications every 30 seconds
    Future.delayed(Duration(seconds: 30), () {
      _checkForNotifications();
      _startNotificationPolling(); // Continue polling
    });
  }

  static Future<void> _checkForNotifications() async {
    try {
      final userId = SupabaseService.currentUser?.id;
      if (userId == null) return;

      // Get pending notifications from database
      final response = await SupabaseService.client.rpc(
        'get_pending_notifications',
        params: {'p_user_id': userId}
      );

      if (response is List) {
        for (final notification in response) {
          await _showLocalNotification(notification);
          
          // Mark as sent
          await SupabaseService.client.rpc(
            'mark_notification_sent',
            params: {'p_notification_id': notification['id']}
          );
        }
      }
    } catch (e) {
      print('❌ Error checking notifications: $e');
    }
  }

  static Future<void> _showLocalNotification(Map<String, dynamic> notification) async {
    final title = notification['title'] ?? 'New Notification';
    final body = notification['body'] ?? '';
    final type = notification['type'] ?? '';
    final data = notification['data'] ?? {};

    print('🔔 Showing local notification: $title - $body');

    // Show in-app notification for active app
    Get.snackbar(
      title,
      body,
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.black87,
      colorText: Colors.white,
      duration: Duration(seconds: 6), // Longer duration for better visibility
      margin: EdgeInsets.all(16),
      borderRadius: 8,
      icon: _getNotificationIcon(type),
      onTap: (_) => _handleNotificationTap(type, data),
    );

    // Also show system notification if possible
    if (Platform.isAndroid || Platform.isIOS) {
      _showSystemNotification(title, body, type, data);
    }
  }

  static Icon _getNotificationIcon(String type) {
    switch (type) {
      case 'new_match':
        return Icon(Icons.local_fire_department, color: Colors.pink);
      case 'new_message':
        return Icon(Icons.chat_bubble, color: Colors.blue);
      case 'new_like':
        return Icon(Icons.favorite, color: Colors.red);
      case 'story_reply':
        return Icon(Icons.camera_alt, color: Colors.purple);
      case 'admin_message':
        return Icon(Icons.admin_panel_settings, color: Colors.orange);
      default:
        return Icon(Icons.notifications, color: Colors.grey);
    }
  }

  static void _handleNotificationTap(String type, Map<String, dynamic> data) {
    switch (type) {
      case 'new_match':
        Get.toNamed('/matches');
        break;
      case 'new_message':
        final chatId = data['chat_id'];
        if (chatId != null) {
          Get.toNamed('/chat', arguments: {'chatId': chatId});
        }
        break;
      case 'new_like':
        Get.toNamed('/discover');
        break;
      case 'story_reply':
        Get.toNamed('/stories');
        break;
      case 'account_suspended':
        _showAccountSuspendedDialog(data['message'] ?? 'Your account has been suspended');
        break;
      default:
        Get.toNamed('/home');
    }
  }

  static void _showSystemNotification(String title, String body, String type, Map<String, dynamic> data) {
    // For now, we'll just use the in-app notification
    // In the future, you can integrate with flutter_local_notifications
    // to show actual system notifications
    print('System notification: $title - $body');
  }

  static void _showAccountSuspendedDialog(String message) {
    Get.dialog(
      AlertDialog(
        title: Text('Account Suspended'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('OK'),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  // Method to manually trigger notification check
  static Future<void> checkNow() async {
    await _checkForNotifications();
  }
}
