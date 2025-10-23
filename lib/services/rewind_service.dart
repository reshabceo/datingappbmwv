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
      final response = await SupabaseService.client
          .from('swipes')
          .select('''
            id,
            swiped_id,
            action,
            created_at,
            can_rewind,
            profiles!swipes_swiped_id_fkey(
              id,
              name,
              age,
              photos,
              location,
              description,
              hobbies
            )
          ''')
          .eq('swiper_id', SupabaseService.currentUser?.id ?? '')
          .eq('can_rewind', true)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response == null) return null;

      final profile = response['profiles'];
      if (profile == null) return null;

      return {
        'swipe_id': response['id'],
        'swiped_id': response['swiped_id'],
        'action': response['action'],
        'created_at': response['created_at'],
        'profile': profile,
      };
    } catch (e) {
      print('Error getting last swiped profile: $e');
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
      return lastSwipe != null;
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
        return {
          'error': 'No swipes available to rewind',
        };
      }

      // Mark swipe as rewinded
      await SupabaseService.client
          .from('swipes')
          .update({
            'can_rewind': false,
            'rewinded_at': DateTime.now().toIso8601String(),
          })
          .eq('id', lastSwipe['swipe_id']);

      return {
        'success': true,
        'profile': lastSwipe['profile'],
        'swipe_id': lastSwipe['swipe_id'],
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
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Container(
          padding: EdgeInsets.all(20.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Rewind icon
              Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.undo,
                  size: 32.sp,
                  color: Colors.blue,
                ),
              ),
              
              SizedBox(height: 16.h),
              
              // Title
              Text(
                'Rewind Last Swipe',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              
              SizedBox(height: 8.h),
              
              // Message
              Text(
                'Take back your last swipe and give it another chance!',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Colors.black54,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              
              SizedBox(height: 20.h),
              
              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Get.back(),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                      ),
                      child: Text('Cancel'),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Get.back();
                        onRewind();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                      ),
                      child: Text('Rewind'),
                    ),
                  ),
                ],
              ),
            ],
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
