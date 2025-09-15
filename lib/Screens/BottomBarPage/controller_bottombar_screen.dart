import 'package:boliler_plate/Screens/ActivityPage/ui_activity_screen.dart';
import 'package:boliler_plate/Screens/ChatPage/ui_chat_screen.dart';
import 'package:boliler_plate/Screens/ChatPage/controller_chat_screen.dart';
import 'package:boliler_plate/Screens/DiscoverPage/ui_discover_screen.dart';
import 'package:boliler_plate/Screens/ProfilePage/ui_profile_screen.dart';
import 'package:boliler_plate/Screens/StoriesPage/ui_stories_screen.dart';
import 'package:boliler_plate/services/supabase_service.dart';
import 'package:boliler_plate/services/analytics_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class BottomBarController extends GetxController {
  RxInt currentIndex = 0.obs;
  RxBool showProfileCompletionBanner = true.obs;

  @override
  void onInit() {
    super.onInit();
    _checkProfileCompletion();
    // Refresh chats whenever Chat tab selected
    ever<int>(currentIndex, (idx) {
      if (idx == 2) {
        final chat = Get.isRegistered<ChatController>()
            ? Get.find<ChatController>()
            : Get.put(ChatController());
        chat.loadChats();
        // Update last seen when opening chat tab
        SupabaseService.updateLastSeen();
      }
      
      // Track feature usage for tab navigation
      _trackTabUsage(idx);
    });
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
