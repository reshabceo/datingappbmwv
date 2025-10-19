import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../services/supabase_service.dart';
import '../ChatPage/chat_integration_helper.dart';
import './models/activity_model.dart';

class ActivityController extends GetxController {
  final RxList<Activity> activities = <Activity>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool hasError = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadActivities();
  }

  Future<void> loadActivities() async {
    try {
      isLoading.value = true;
      hasError.value = false;
      
      print('📊 Loading activities...');
      final response = await SupabaseService.getUserActivities();
      
      activities.value = response
          .map((data) => Activity.fromMap(data))
          .toList();
      
      print('✅ Loaded ${activities.length} activities');
    } catch (e) {
      print('❌ Error loading activities: $e');
      hasError.value = true;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refresh() async {
    await loadActivities();
  }

  void onActivityTap(Activity activity) {
    print('🔔 Activity tapped: ${activity.type} - ${activity.otherUserName}');
    
    // Mark message as read if it's a message
    if (activity.type == ActivityType.message && activity.isUnread) {
      SupabaseService.markMessageAsRead(activity.id);
      // Reload activities to update read status
      loadActivities();
    }

    // Navigate based on activity type
    switch (activity.type) {
      case ActivityType.like:
      case ActivityType.superLike:
        // Navigate to discover screen (where they can see this person's profile)
        Get.toNamed('/discover');
        Get.snackbar(
          '💡 Tip',
          'Swipe right on ${activity.otherUserName} to match!',
          backgroundColor: Get.theme.colorScheme.primary.withOpacity(0.9),
          colorText: Get.theme.colorScheme.onPrimary,
          duration: Duration(seconds: 3),
        );
        break;
      
      case ActivityType.match:
      case ActivityType.bffMatch:
      case ActivityType.message:
      case ActivityType.bffMessage:
      case ActivityType.storyReply:
        // Navigate to chat - need to find the match ID first
        _navigateToChat(activity);
        break;
    }
  }

  Future<void> _navigateToChat(Activity activity) async {
    try {
      final currentUserId = SupabaseService.currentUser?.id;
      String? matchId;
      
      // Handle BFF matches and messages
      if (activity.type == ActivityType.bffMatch || activity.type == ActivityType.bffMessage) {
        final bffMatches = await SupabaseService.getBFFMatches();
        
        for (final match in bffMatches) {
          final userId1 = match['user_id_1']?.toString();
          final userId2 = match['user_id_2']?.toString();
          
          if ((userId1 == currentUserId && userId2 == activity.otherUserId) ||
              (userId1 == activity.otherUserId && userId2 == currentUserId)) {
            matchId = match['id']?.toString();
            break;
          }
        }
      } else {
        // Handle regular dating matches and messages
        final matches = await SupabaseService.getMatches();
        
        for (final match in matches) {
          final userId1 = match['user_id_1']?.toString();
          final userId2 = match['user_id_2']?.toString();
          
          if ((userId1 == currentUserId && userId2 == activity.otherUserId) ||
              (userId1 == activity.otherUserId && userId2 == currentUserId)) {
            matchId = match['id']?.toString();
            break;
          }
        }
      }
      
      if (matchId != null) {
        // Navigate to chat screen using the proper helper
        ChatIntegrationHelper.navigateToChat(
          userImage: activity.otherUserPhoto ?? '',
          userName: activity.otherUserName,
          matchId: matchId,
        );
      } else {
        Get.snackbar(
          'Error',
          'Could not find chat with ${activity.otherUserName}',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      print('Error navigating to chat: $e');
      Get.snackbar(
        'Error',
        'Could not open chat',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
}

// Keep old ActivityItem for backward compatibility (in case it's used elsewhere)
class ActivityItem {
  final String message;
  final String time;
  final IconData icon;

  ActivityItem({required this.message, required this.time, required this.icon});
}
