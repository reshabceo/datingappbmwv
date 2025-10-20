import 'package:lovebug/Screens/ActivityPage/ui_activity_screen.dart';
import 'package:lovebug/Screens/ChatPage/ui_chat_screen.dart';
import 'package:lovebug/Screens/ChatPage/controller_chat_screen.dart';
import 'package:lovebug/Screens/DiscoverPage/ui_discover_screen.dart';
import 'package:lovebug/Screens/ProfilePage/ui_profile_screen.dart';
import 'package:lovebug/Screens/StoriesPage/ui_stories_screen.dart';
import 'package:lovebug/services/supabase_service.dart';
import 'package:lovebug/services/analytics_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

class BottomBarController extends GetxController {
  RxInt currentIndex = 0.obs;
  RxBool showProfileCompletionBanner = true.obs;

  @override
  void onInit() {
    super.onInit();
    _checkProfileCompletion();
    _requestPermissions();
    // Refresh chats whenever Chat tab selected
    ever<int>(currentIndex, (idx) {
      if (idx == 2) {
        final chat = Get.isRegistered<EnhancedChatController>()
            ? Get.find<EnhancedChatController>()
            : Get.put(EnhancedChatController());
        chat.loadChats();
        // Update last seen when opening chat tab
        SupabaseService.updateLastSeen();
      }
      
      // Track feature usage for tab navigation
      _trackTabUsage(idx);
    });
  }

  /// Request camera and photo permissions when app starts
  Future<void> _requestPermissions() async {
    try {
      print('🔍 DEBUG: Requesting camera and photo permissions...');
      
      // Request camera permission using permission_handler (doesn't open camera interface)
      final PermissionStatus cameraStatus = await Permission.camera.request();
      print('🔍 DEBUG: Camera permission status: $cameraStatus');
      
      if (cameraStatus.isGranted) {
        print('✅ Camera permission granted');
      } else {
        print('❌ Camera permission denied: $cameraStatus');
      }
      
      // Request photo library permission using permission_handler
      final PermissionStatus photosStatus = await Permission.photos.request();
      print('🔍 DEBUG: Photos permission status: $photosStatus');
      
      if (photosStatus.isGranted) {
        print('✅ Photos permission granted');
      } else {
        print('❌ Photos permission denied: $photosStatus');
      }
      
    } catch (e) {
      print('❌ Error requesting permissions: $e');
    }
  }

  Future<void> _checkProfileCompletion() async {
    try {
      final user = SupabaseService.currentUser;
      if (user != null) {
        final profile = await SupabaseService.getProfile(user.id);
        if (profile != null && profile['name'] != null && profile['photos'] != null && (profile['photos'] as List).isNotEmpty) {
          showProfileCompletionBanner.value = false;
        }
      }
    } catch (e) {
      print('Error checking profile completion: $e');
    }
  }
  
  // Track tab usage for analytics
  void _trackTabUsage(int tabIndex) {
    final tabNames = ['discover', 'stories', 'chat', 'profile'];
    if (tabIndex >= 0 && tabIndex < tabNames.length) {
      AnalyticsService.trackFeatureUsage('tab_navigation', {
        'tab_name': tabNames[tabIndex],
        'tab_index': tabIndex,
      });
    }
  }

  List<Widget> pages = [
    DiscoverScreen(),
    StoriesScreen(),
    ChatScreen(),
    ProfileScreen(),
    ActivityScreen(),
  ];
}
