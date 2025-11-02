import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:ui';
import 'supabase_service.dart';
import '../widgets/upgrade_prompt_widget.dart';
import '../Screens/SubscriptionPage/ui_subscription_screen.dart';
import 'package:lovebug/ThemeController/theme_controller.dart';
import 'package:lovebug/Screens/DiscoverPage/controller_discover_screen.dart';

class RewindService {
  // Get the last swiped profile for rewind
  static Future<Map<String, dynamic>?> getLastSwipedProfile() async {
    try {
      // First, get the last swipe that can be rewound
      final swipeResponse = await SupabaseService.client
          .from('swipes')
          .select('id, swiped_id, action, created_at, can_rewind')
          .eq('swiper_id', SupabaseService.currentUser?.id ?? '')
          .eq('can_rewind', true)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (swipeResponse == null) {
        print('🔄 DEBUG: No swipes found with can_rewind=true');
        return null;
      }

      print('🔄 DEBUG: Found swipe - id: ${swipeResponse['id']}, swiped_id: ${swipeResponse['swiped_id']}, action: ${swipeResponse['action']}');

      // Then, fetch the profile separately
      final profileResponse = await SupabaseService.client
          .from('profiles')
          .select('id, name, age, photos, image_urls, location, description, hobbies')
          .eq('id', swipeResponse['swiped_id'])
          .maybeSingle();

      if (profileResponse == null) {
        print('🔄 DEBUG: Profile not found for swiped_id: ${swipeResponse['swiped_id']}');
        return null;
      }

      // Prioritize image_urls over photos
      final List<String> photos = [];
      if (profileResponse['image_urls'] != null) {
        photos.addAll(List<String>.from(profileResponse['image_urls']));
      } else if (profileResponse['photos'] != null) {
        photos.addAll(List<String>.from(profileResponse['photos']));
      }

      return {
        'swipe_id': swipeResponse['id'],
        'swiped_id': swipeResponse['swiped_id'],
        'action': swipeResponse['action'],
        'created_at': swipeResponse['created_at'],
        'profile': {
          ...profileResponse,
          'photos': photos,
          'image_urls': photos,
        },
      };
    } catch (e) {
      print('❌ Error getting last swiped profile: $e');
      return null;
    }
  }

  // Check if user can rewind
  static Future<bool> canRewind() async {
    try {
      // Check if user is premium
      final isPremium = await SupabaseService.isPremiumUser();
      if (!isPremium) return false;

      // Check if there's a rewindable swipe
      final lastSwipe = await getLastSwipedProfile();
      if (lastSwipe == null) return false;
      
      // Check if user sent a premium message to this profile
      // If so, rewind is not allowed
      final swipedId = lastSwipe['swiped_id'] as String;
      final currentUserId = SupabaseService.currentUser?.id;
      
      if (currentUserId != null) {
        try {
          final premiumMessages = await SupabaseService.client
              .from('premium_messages')
              .select('id')
              .eq('sender_id', currentUserId)
              .eq('recipient_id', swipedId)
              .maybeSingle();
          
          if (premiumMessages != null) {
            print('⚠️ DEBUG: Cannot rewind - premium message was sent to this profile');
            return false;
          }
        } catch (e) {
          print('Error checking premium messages: $e');
        }
      }
      
      return true;
    } catch (e) {
      print('Error checking rewind capability: $e');
      return false;
    }
  }

  // Perform rewind action
  static Future<Map<String, dynamic>> performRewind() async {
    try {
      // Check if user is premium
      final isPremium = await SupabaseService.isPremiumUser();
      if (!isPremium) {
        return {
          'error': 'Premium subscription required to rewind',
          'requires_premium': true,
        };
      }

      // Get last swiped profile
      final lastSwipe = await getLastSwipedProfile();
      if (lastSwipe == null) {
        print('🔄 DEBUG: No swipes available to rewind');
        return {
          'error': 'No swipes available to rewind',
        };
      }

      // Check if user sent a premium message to this profile
      // If so, rewind is not allowed
      final swipedId = lastSwipe['swiped_id'] as String;
      final currentUserId = SupabaseService.currentUser?.id;
      
      if (currentUserId != null) {
        try {
          final premiumMessages = await SupabaseService.client
              .from('premium_messages')
              .select('id')
              .eq('sender_id', currentUserId)
              .eq('recipient_id', swipedId)
              .maybeSingle();
          
          if (premiumMessages != null) {
            print('⚠️ DEBUG: Cannot rewind - premium message was sent to this profile');
            return {
              'error': 'Cannot rewind: You sent a message to this profile',
            };
          }
        } catch (e) {
          print('Error checking premium messages: $e');
        }
      }

      print('🔄 DEBUG: Rewinding swipe - id: ${lastSwipe['swipe_id']}, swiped_id: ${lastSwipe['swiped_id']}, action: ${lastSwipe['action']}');

      // DELETE the swipe so the profile can reappear in the discover feed
      // This is the correct behavior - rewinding should undo the swipe completely
      final deleteResponse = await SupabaseService.client
          .from('swipes')
          .delete()
          .eq('id', lastSwipe['swipe_id']);

      print('✅ DEBUG: Swipe deleted successfully');
      print('🔄 DEBUG: Deleted swipe - swiped_id: ${lastSwipe['swiped_id']}, profile name: ${lastSwipe['profile']['name']}');
      print('💡 DEBUG: Swipe deleted from database. Profile will be re-inserted via undoLastSwipe()');

      return {
        'success': true,
        'profile': lastSwipe['profile'],
        'swiped_id': lastSwipe['swiped_id'],
        'action': lastSwipe['action'],
      };
    } catch (e) {
      print('Error performing rewind: $e');
      return {
        'error': 'Failed to rewind: $e',
      };
    }
  }

  // Show rewind dialog
  static void showRewindDialog({
    required VoidCallback onRewind,
    required VoidCallback onUpgrade,
  }) {
    final themeController = Get.find<ThemeController>();
    
    // Detect current mode (dating/bff)
    bool isBffMode = false;
    if (Get.isRegistered<DiscoverController>()) {
      try {
        final d = Get.find<DiscoverController>();
        isBffMode = (d.currentMode.value == 'bff');
      } catch (_) {}
    }

    // Pick gradient colors based on mode (pink for dating, blue for BFF)
    final List<Color> bgColors = isBffMode
        ? [
            themeController.bffPrimaryColor.withValues(alpha: 0.15),
            themeController.bffSecondaryColor.withValues(alpha: 0.15),
          ]
        : [
            themeController.getAccentColor().withValues(alpha: 0.15),
            themeController.getSecondaryColor().withValues(alpha: 0.15),
          ];
    final Color borderColor = isBffMode
        ? themeController.bffPrimaryColor
        : themeController.getAccentColor();
    final Color iconColor = isBffMode
        ? themeController.bffPrimaryColor
        : themeController.getAccentColor();
    final List<Color> ctaColors = isBffMode
        ? [themeController.bffPrimaryColor, themeController.bffSecondaryColor]
        : [themeController.getAccentColor(), themeController.getSecondaryColor()];

    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.symmetric(horizontal: 24.w),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: bgColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22.r),
              border: Border.all(
                color: borderColor.withValues(alpha: 0.35),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: borderColor.withValues(alpha: 0.15),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.all(20.w),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Rewind icon
                    Container(
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        color: iconColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.undo,
                        size: 32.sp,
                        color: iconColor,
                      ),
                    ),
                    
                    SizedBox(height: 16.h),
                    
                    // Title
                    Text(
                      'Rewind Last Swipe',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: themeController.whiteColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    SizedBox(height: 8.h),
                    
                    // Message
                    Text(
                      'Take back your last swipe and give it another chance!',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: themeController.whiteColor.withValues(alpha: 0.8),
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    SizedBox(height: 20.h),
                    
                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => Get.back(),
                            child: Container(
                              padding: EdgeInsets.symmetric(vertical: 12.h),
                              decoration: BoxDecoration(
                                color: themeController.whiteColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20.r),
                                border: Border.all(
                                  color: themeController.whiteColor.withValues(alpha: 0.3),
                                  width: 1.5,
                                ),
                              ),
                              child: Text(
                                'Cancel',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: themeController.whiteColor,
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              Get.back();
                              onRewind();
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(vertical: 12.h),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(colors: ctaColors),
                                borderRadius: BorderRadius.circular(20.r),
                                border: Border.all(
                                  color: borderColor.withValues(alpha: 0.5),
                                  width: 1.5,
                                ),
                              ),
                              child: Text(
                                'Rewind',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      barrierDismissible: true,
    );
  }

  // Show upgrade dialog for rewind
  static void showRewindUpgradeDialog() {
    final themeController = Get.find<ThemeController>();
    // Detect current mode (dating/bff)
    bool isBffMode = false;
    if (Get.isRegistered<DiscoverController>()) {
      try {
        final d = Get.find<DiscoverController>();
        isBffMode = (d.currentMode.value == 'bff');
      } catch (_) {}
    }

    // Pick gradient colors based on mode
    final List<Color> bgColors = isBffMode
        ? [
            themeController.bffPrimaryColor.withValues(alpha: 0.15),
            themeController.bffSecondaryColor.withValues(alpha: 0.15),
          ]
        : [
            themeController.getAccentColor().withValues(alpha: 0.15),
            themeController.getSecondaryColor().withValues(alpha: 0.15),
          ];
    final Color borderColor = isBffMode
        ? themeController.bffPrimaryColor
        : themeController.getAccentColor();
    final List<Color> ctaColors = isBffMode
        ? [themeController.bffPrimaryColor, themeController.bffSecondaryColor]
        : [themeController.getAccentColor(), themeController.getSecondaryColor()];
    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.symmetric(horizontal: 24.w),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: bgColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22.r),
              border: Border.all(
                color: borderColor.withValues(alpha: 0.35),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: borderColor.withValues(alpha: 0.15),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.all(20.w),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Premium Feature',
                    style: TextStyle(
                      color: themeController.whiteColor,
                      fontSize: 22.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    'Rewind is a premium feature. Upgrade to take back your last swipe!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: themeController.whiteColor.withValues(alpha: 0.8),
                      fontSize: 15.sp,
                      height: 1.4,
                    ),
                  ),
                  SizedBox(height: 24.h),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => Get.back(),
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 12.h),
                            decoration: BoxDecoration(
                              color: themeController.whiteColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20.r),
                              border: Border.all(
                                color: themeController.whiteColor.withValues(alpha: 0.3),
                                width: 1.5,
                              ),
                            ),
                            child: Text(
                              'Maybe Later',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: themeController.whiteColor,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            Get.back();
                            Get.to(() => SubscriptionScreen());
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 12.h),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: ctaColors),
                              borderRadius: BorderRadius.circular(20.r),
                              border: Border.all(
                                color: borderColor.withValues(alpha: 0.5),
                                width: 1.5,
                              ),
                            ),
                            child: const Text(
                              'Upgrade Now',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      ),
      barrierDismissible: true,
    );
  }
}
