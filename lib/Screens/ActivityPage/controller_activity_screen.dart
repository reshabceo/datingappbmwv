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
        
        // Always fetch profile photo (even for free users) so we can blur it
        // But only reveal name and message content for premium users
        try {
          final p = await SupabaseService.getProfileById(senderId);
          if (isPremium.value) {
            // Premium users see name and message
            otherName = (p?['name'] ?? otherName).toString();
          }
          // Always fetch photo for blurring (free users see blurred, premium see clear)
          final imgs = p?['image_urls'];
          if (imgs is List && imgs.isNotEmpty) {
            otherPhoto = imgs.first?.toString();
          }
        } catch (_) {}
        
        filtered.add(Activity(
          id: (row['id'] ?? '').toString(),
          type: ActivityType.premiumMessage,
          otherUserId: senderId,
          otherUserName: otherName,
          otherUserPhoto: otherPhoto, // Always include photo for blurring
          messagePreview: isPremium.value ? (row['message_content']?.toString()) : null,
          createdAt: createdAt,
          isUnread: true,
        ));
      }

      // Sort newest first
      filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      // Reconcile blur entries once a match happens
      final normalized = _normalizeActivities(filtered);
      activities.value = normalized;

      print('✅ Loaded ${activities.length} activities (after filtering & premium messages)');
    } catch (e) {
      print('❌ Error loading activities: $e');
      hasError.value = true;
    } finally {
      isLoading.value = false;
    }
  }

  List<Activity> _normalizeActivities(List<Activity> items) {
    final Set<String> usersWithMatches = items
        .where((a) => a.type == ActivityType.match || a.type == ActivityType.bffMatch)
        .map((a) => a.otherUserId)
        .toSet();

    final List<Activity> normalized = [];
    final Set<String> matchAlreadyAdded = {};

    for (final activity in items) {
      final userId = activity.otherUserId;
      final isMatchActivity = activity.type == ActivityType.match || activity.type == ActivityType.bffMatch;
      if (isMatchActivity) {
        matchAlreadyAdded.add(userId);
        normalized.add(activity);
        continue;
      }

      final isLike = activity.type == ActivityType.like || activity.type == ActivityType.superLike;
      if (isLike && usersWithMatches.contains(userId)) {
        if (matchAlreadyAdded.contains(userId)) {
          // We already have a match entry for this user, skip the blurred like
          continue;
        }

        normalized.add(Activity(
          id: activity.id,
          type: ActivityType.match,
          otherUserId: activity.otherUserId,
          otherUserName: activity.otherUserName,
          otherUserPhoto: activity.otherUserPhoto,
          messagePreview: null,
          createdAt: activity.createdAt,
          isUnread: activity.isUnread,
        ));
        matchAlreadyAdded.add(userId);
        continue;
      }

      // Filter out premium messages if already matched with that user
      // Premium messages are meant for BEFORE matching - once matched, use regular chat
      if (activity.type == ActivityType.premiumMessage && usersWithMatches.contains(userId)) {
        print('🔕 Filtering premium message from ${activity.otherUserName} - already matched');
        continue;
      }

      normalized.add(activity);
    }

    return normalized;
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
