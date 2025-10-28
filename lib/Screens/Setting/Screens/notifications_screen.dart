import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lovebug/Common/text_constant.dart';
import 'package:lovebug/ThemeController/theme_controller.dart';
import 'package:lovebug/services/supabase_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationsSettingsScreen extends StatefulWidget {
  NotificationsSettingsScreen({super.key});

  @override
  State<NotificationsSettingsScreen> createState() => _NotificationsSettingsScreenState();
}

class _NotificationsSettingsScreenState extends State<NotificationsSettingsScreen> {
  final ThemeController theme = Get.find<ThemeController>();
  
  // Notification preferences
  bool _matchesEnabled = true;
  bool _messagesEnabled = true;
  bool _storiesEnabled = true;
  bool _likesEnabled = true;
  bool _adminMessagesEnabled = true;
  
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotificationPreferences();
  }

  Future<void> _loadNotificationPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _matchesEnabled = prefs.getBool('notification_matches') ?? true;
        _messagesEnabled = prefs.getBool('notification_messages') ?? true;
        _storiesEnabled = prefs.getBool('notification_stories') ?? true;
        _likesEnabled = prefs.getBool('notification_likes') ?? true;
        _adminMessagesEnabled = prefs.getBool('notification_admin') ?? true;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading notification preferences: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateNotificationPreference(String key, bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(key, value);
      
      // Also update in Supabase
      await SupabaseService.updateNotificationPreference(key, value);
      
      setState(() {
        switch (key) {
          case 'notification_matches':
            _matchesEnabled = value;
            break;
          case 'notification_messages':
            _messagesEnabled = value;
            break;
          case 'notification_stories':
            _storiesEnabled = value;
            break;
          case 'notification_likes':
            _likesEnabled = value;
            break;
          case 'notification_admin':
            _adminMessagesEnabled = value;
            break;
        }
      });
      
      Get.snackbar(
        'Settings Updated',
        'Notification preference updated',
        backgroundColor: theme.primaryColor.value,
        colorText: Colors.white,
        duration: Duration(seconds: 2),
      );
    } catch (e) {
      print('Error updating notification preference: $e');
      Get.snackbar(
        'Error',
        'Failed to update notification preference',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: Duration(seconds: 2),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: TextConstant(title: 'Notifications', color: theme.whiteColor),
          backgroundColor: theme.blackColor,
        ),
        backgroundColor: theme.blackColor,
        body: Center(
          child: CircularProgressIndicator(color: theme.primaryColor.value),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: TextConstant(title: 'Notifications', color: theme.whiteColor),
        backgroundColor: theme.blackColor,
      ),
      backgroundColor: theme.blackColor,
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          // General Notifications Section
          _buildSectionHeader('General Notifications'),
          SizedBox(height: 8),
          
          _buildNotificationTile(
            title: 'Matches',
            subtitle: 'Get notified when you match with someone',
            value: _matchesEnabled,
            onChanged: (value) => _updateNotificationPreference('notification_matches', value),
            icon: Icons.local_fire_department_rounded,
          ),
          
          _buildNotificationTile(
            title: 'Messages',
            subtitle: 'Get notified when you receive new messages',
            value: _messagesEnabled,
            onChanged: (value) => _updateNotificationPreference('notification_messages', value),
            icon: Icons.chat_bubble_rounded,
          ),
          
          _buildNotificationTile(
            title: 'Likes',
            subtitle: 'Get notified when someone likes your profile',
            value: _likesEnabled,
            onChanged: (value) => _updateNotificationPreference('notification_likes', value),
            icon: Icons.favorite_rounded,
          ),
          
          _buildNotificationTile(
            title: 'Stories',
            subtitle: 'Get notified about story interactions',
            value: _storiesEnabled,
            onChanged: (value) => _updateNotificationPreference('notification_stories', value),
            icon: Icons.camera_alt_rounded,
          ),
          
          SizedBox(height: 24),
          
          // System Notifications Section
          _buildSectionHeader('System Notifications'),
          SizedBox(height: 8),
          
          _buildNotificationTile(
            title: 'Admin Messages',
            subtitle: 'Important updates from LoveBug team',
            value: _adminMessagesEnabled,
            onChanged: (value) => _updateNotificationPreference('notification_admin', value),
            icon: Icons.admin_panel_settings_rounded,
          ),
          
          SizedBox(height: 32),
          
          // Test Notifications Button
          Center(
            child: ElevatedButton.icon(
              onPressed: _testNotifications,
              icon: Icon(Icons.notifications_active),
              label: Text('Test Notifications'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor.value,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        color: theme.whiteColor,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildNotificationTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required IconData icon,
  }) {
    return Card(
      color: theme.blackColor,
      margin: EdgeInsets.only(bottom: 8),
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        title: Row(
          children: [
            Icon(icon, color: theme.primaryColor.value, size: 20),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextConstant(title: title, color: theme.whiteColor),
                  SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: theme.whiteColor.withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        activeColor: theme.primaryColor.value,
      ),
    );
  }

  void _testNotifications() {
    Get.snackbar(
      'Test Notification',
      'This is how notifications will appear in your app',
      backgroundColor: theme.primaryColor.value,
      colorText: Colors.white,
      duration: Duration(seconds: 3),
      icon: Icon(Icons.notifications, color: Colors.white),
    );
  }
}
