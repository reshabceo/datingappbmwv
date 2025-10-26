import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../services/supabase_service.dart';
import '../../widgets/blurred_profile_widget.dart';
import '../ChatPage/chat_integration_helper.dart';
import './models/activity_model.dart';

class ActivityController extends GetxController {
  final RxList<Activity> activities = <Activity>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool hasError = false.obs;
  final RxBool isPremium = false.obs;

  @override
  void onInit() {
    super.onInit();
    _checkPremiumStatus();
    loadActivities();
  }

  Future<void> _checkPremiumStatus() async {
    try {
      final premium = await SupabaseService.isPremiumUser();
      isPremium.value = premium;
    } catch (e) {
      print('Error checking premium status: $e');
      isPremium.value = false;
    }
  }

  Future<void> loadActivities() async {
    try {
      isLoading.value = true;
      hasError.value = false;
      
      print('📊 Loading activities...');
      final response = await SupabaseService.getUserActivities();

      // Parse activities from RPC
      final parsed = response.map((data) => Activity.fromMap(data)).toList();
      // Filter OUT regular chat messages; Activity screen should not show them
      final filtered = parsed.where((a) => a.type != ActivityType.message && a.type != ActivityType.bffMessage).toList();

      // Append premium messages (paper-plane from Discover)
      final pmRows = await SupabaseService.getPremiumMessages();
      for (final row in pmRows) {
        final senderId = (row['sender_id'] ?? '').toString();
        final createdAt = DateTime.parse((row['created_at'] ?? DateTime.now().toIso8601String()).toString());
        String otherName = 'Someone';
        String? otherPhoto;
        if (isPremium.value) {
          // Fetch sender profile only for premium receivers
          try {
            final p = await SupabaseService.getProfileById(senderId);
            otherName = (p?['name'] ?? otherName).toString();
            // Try first image_urls entry if available
            final imgs = p?['image_urls'];
            if (imgs is List && imgs.isNotEmpty) {
              otherPhoto = imgs.first?.toString();
            }
          } catch (_) {}
        }
        filtered.add(Activity(
          id: (row['id'] ?? '').toString(),
          type: ActivityType.premiumMessage,
          otherUserId: senderId,
          otherUserName: otherName,
          otherUserPhoto: isPremium.value ? otherPhoto : null,
          messagePreview: isPremium.value ? (row['message_content']?.toString()) : null,
          createdAt: createdAt,
          isUnread: true,
        ));
      }

      // Sort newest first
      filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      activities.value = filtered;

      print('✅ Loaded ${activities.length} activities (after filtering & premium messages)');
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
    
    // Mark message as read if it's a regular message (not used now) or premium message viewed later
    if ((activity.type == ActivityType.message || activity.type == ActivityType.premiumMessage) && activity.isUnread) {
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
      case ActivityType.premiumMessage:
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
