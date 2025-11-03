import 'package:lovebug/Common/widget_constant.dart';
import 'package:lovebug/Screens/DiscoverPage/Widget/profile_card_widget.dart';
import 'package:lovebug/Screens/DiscoverPage/controller_discover_screen.dart';
import 'package:lovebug/Screens/DiscoverPage/profile_detail_screen.dart';
import 'package:lovebug/ThemeController/theme_controller.dart';
import 'package:lovebug/widgets/rewind_button.dart';
import 'package:lovebug/Widgets/premium_message_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:get/get.dart';
import 'package:lovebug/Widgets/upgrade_prompt_widget.dart';
import 'package:lovebug/widgets/super_like_purchase_dialog.dart';
import 'package:lovebug/services/supabase_service.dart';
import 'package:animations/animations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;
import 'package:lovebug/services/supabase_service.dart';
import 'package:lovebug/services/rewind_service.dart';
import 'package:lovebug/services/premium_message_service.dart';
import 'package:lovebug/Screens/SubscriptionPage/ui_subscription_screen.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class DiscoverScreen extends StatefulWidget {
  DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  final DiscoverController controller = Get.put(DiscoverController());
  final ThemeController themeController = Get.find<ThemeController>();
  final CardSwiperController _swiperController = CardSwiperController();

  @override
  void initState() {
    super.initState();
    // Set callback for programmatic swipe right (for premium messages)
    controller.setSwipeRightCallback(() {
      if (controller.currentProfile != null) {
        _swiperController.swipe(CardSwiperDirection.right);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    print('🔍 DEBUG: DiscoverScreen build() called');
    return Scaffold(
      backgroundColor: themeController.blackColor,
      body: Container(
        width: Get.width,
        height: Get.height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              themeController.blackColor,
              themeController.bgGradient1,
              themeController.blackColor
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Stack(
          children: [
            screenPadding(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    heightBox(135),
                    Obx(() {
                      final count = controller.profiles.length;
                      final isLoading = controller.isPreloading.value;
                      final isInitialLoading = controller.isInitialLoading.value;
                      // Depend on deck version to rebuild CardSwiper when deck mutates
                      final _deckVer = controller.deckVersion.value;
                      
                      print('🔍 DEBUG: UI - profiles.length=$count, isLoading=$isLoading, mode=${controller.currentMode.value}');

                      // Show loading state while profiles are being loaded initially
                      if (isInitialLoading || (isLoading && count == 0)) {
                        return SizedBox(
                          height: Get.height * 0.6,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircularProgressIndicator(
                                  color: themeController.lightPinkColor,
                                ),
                                SizedBox(height: 20.h),
                                Text(
                                  'Loading profiles...',
                                  style: TextStyle(
                                    color: themeController.whiteColor,
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      // Show empty state if no profiles
                      if (count == 0) {
                        print('🔍 DEBUG: UI - Showing empty state for mode: ${controller.currentMode.value}');
                        return _buildEmptyState();
                      }

                      // Show loading state if profiles are loading but we have some
                      if (isLoading && count > 0) {
                        return Stack(
                          children: [
                            _buildCardSwiper(count),
                            _buildLoadingOverlay(),
                          ],
                        );
                      }

                      // Guard: if all profiles are not displayable, show empty state
                      final allInvalid = controller.profiles.every((p) =>
                        (p.name.toString().trim().isEmpty) && (p.photos.isEmpty && (p.imageUrl.isEmpty))
                      );
                      if (allInvalid) {
                        return _buildEmptyState();
                      }

                      return _buildCardSwiper(count);
                    }),
                    heightBox(20),
                  ],
                ),
              ),
            ),
            _buildNameOverlay(),
            _buildActionButtonsOverlay(),
          ],
        ),
      ),
    );
  }

  // Track whether we've shown the upgrade prompt once during this session
  static bool _superLikeUpgradeShown = false;

  Widget _chip({required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: themeController.whiteColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: themeController.getAccentColor().withValues(alpha: 0.35),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: themeController.whiteColor,
            fontWeight: FontWeight.w600,
            fontSize: 12.sp,
          ),
        ),
      ),
    );
  }

  Widget _buildNameOverlay() {
    return Positioned(
      top: 90.h,
      left: 20.w,
      right: 20.w,
      child: Obx(() {
        // 🔧 CRITICAL FIX: Hide name overlay during loading states
        if (controller.profiles.isEmpty || 
            controller.isInitialLoading.value || 
            (controller.isPreloading.value && controller.profiles.length == 0)) {
          return const SizedBox.shrink();
        }

        // 🔧 CRITICAL FIX: Use currentIndex instead of overlayIndex to prevent mismatch
        // Only validate indices if there's a potential mismatch
        final int idx = controller.currentIndex.value;
        
        // Quick validation without expensive operations
        if (idx < 0 || idx >= controller.profiles.length) {
          return const SizedBox.shrink();
        }
        final currentProfile = controller.profiles[idx];
        
        // 🔧 ADDITIONAL VALIDATION: Ensure this is the same profile as the top card
        if (kDebugMode) {
          print('🔍 DEBUG: Name overlay - Index=$idx, Name="${currentProfile.name}", ID="${currentProfile.id}"');
        }

        // Hide overlay if name is missing/empty to avoid displaying ", 18"
        final String name = (currentProfile.name ?? '').toString().trim();
        if (name.isEmpty) {
          return const SizedBox.shrink();
        }

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: FittedBox(
            key: ValueKey(currentProfile.id),
            fit: BoxFit.scaleDown,
            child: Text(
              '${name}, ${currentProfile.age}',
              style: GoogleFonts.dancingScript(
                fontSize: 38.sp,
                fontWeight: FontWeight.w700,
                color: themeController.getAccentColor(),
                shadows: [
                  Shadow(
                    color: themeController.getAccentColor().withOpacity(0.8),
                    blurRadius: 15,
                  ),
                  Shadow(
                    color: themeController.getAccentColor().withOpacity(0.6),
                    blurRadius: 30,
                  ),
                  Shadow(
                    color: themeController.getAccentColor().withOpacity(0.3),
                    blurRadius: 45,
                  ),
                ],
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
            ),
          ),
        );
      }),
    );
  }

  Widget _buildActionButtonsOverlay() {
    return Positioned(
      bottom: 20.h,
      left: 0,
      right: 0,
      child: Obx(
        () => Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: controller.currentMode.value == 'bff'
              ? _buildBFFActionButtons()
              : _buildDatingActionButtons(),
        ),
      ),
    );
  }

  List<Widget> _buildDatingActionButtons() {
    return [
      _buildRewindMiniButton(),
      GestureDetector(
        onTap: () => _swiperController.swipe(CardSwiperDirection.left),
        child: Container(
          width: 60.w,
          height: 60.w,
          decoration: BoxDecoration(
            color: Colors.red,
            borderRadius: BorderRadius.circular(30.r),
            boxShadow: [
              BoxShadow(
                color: Colors.red.withValues(alpha: 0.3),
                blurRadius: 10.r,
              ),
            ],
          ),
          child: Icon(Icons.close_rounded, color: Colors.white, size: 28.sp),
        ),
      ),
      GestureDetector(
        onTap: () async {
          // Check super like limit for ALL users (free and premium both have 1 per day)
          final usage = await SupabaseService.getDailyUsage();
          final used = usage['super_likes_used'] ?? 0;
          final remaining = (1 - used).clamp(0, 1);
          if (remaining > 0) {
            // Allow super like if within daily limit
            _swiperController.swipe(CardSwiperDirection.top);
            return;
          }
          // Out of daily super likes:
          // First show upgrade prompt once; subsequent taps show purchase dialog
          // Show superlike limit prompt
          if (!_superLikeUpgradeShown) {
            _superLikeUpgradeShown = true;
            Get.dialog(
              Dialog(
                backgroundColor: Colors.transparent,
                insetPadding: EdgeInsets.zero,
                child: SuperLikeLimitWidget(),
              ),
              barrierDismissible: true,
            );
            return;
          }
          // After upgrade prompt is shown once, open purchase dialog
          Get.dialog(SuperLikePurchaseDialog(), barrierDismissible: true);
        },
        child: Container(
          width: 60.w,
          height: 60.w,
          decoration: BoxDecoration(
            color: Colors.blue,
            borderRadius: BorderRadius.circular(30.r),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withValues(alpha: 0.3),
                blurRadius: 10.r,
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(Icons.star_rounded, color: Colors.white, size: 28.sp),
              Positioned(
                top: 6.h,
                right: 8.w,
                child: FutureBuilder<Map<String, dynamic>>(
                  future: _getSuperLikeCount(),
                  key: ValueKey(controller.deckVersion.value), // Refresh when deck version changes
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SizedBox.shrink();
                    }
                    
                    final data = snapshot.data ?? {'isPremium': false, 'remaining': 0};
                    final bool isPremium = data['isPremium'] ?? false;
                    final int remaining = data['remaining'] ?? 0;
                    
                    // Don't show badge for premium users (unlimited) or if remaining is 0
                    if (isPremium || remaining == 0) {
                      return const SizedBox.shrink();
                    }
                    
                    return AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
                      child: Container(
                        key: ValueKey<int>(remaining),
                        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        child: Text(
                          '$remaining',
                          style: TextStyle(color: Colors.white, fontSize: 10.sp, fontWeight: FontWeight.bold),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      GestureDetector(
        onTap: () => _swiperController.swipe(CardSwiperDirection.right),
        child: Container(
          width: 60.w,
          height: 60.w,
          decoration: BoxDecoration(
            color: themeController.getAccentColor(),
            borderRadius: BorderRadius.circular(30.r),
            boxShadow: [
              BoxShadow(
                color: themeController.getAccentColor().withValues(alpha: 0.3),
                blurRadius: 10.r,
              ),
            ],
          ),
          child:
              Icon(Icons.favorite_outlined, color: Colors.white, size: 28.sp),
        ),
      ),
      _buildMessageMiniButton(),
    ];
  }

  List<Widget> _buildBFFActionButtons() {
    return [
      _buildRewindMiniButton(),
      GestureDetector(
        onTap: () => _swiperController.swipe(CardSwiperDirection.left),
        child: Container(
          width: 60.w,
          height: 60.w,
          decoration: BoxDecoration(
            color: Colors.red,
            borderRadius: BorderRadius.circular(30.r),
            boxShadow: [
              BoxShadow(
                color: Colors.red.withValues(alpha: 0.3),
                blurRadius: 10.r,
              ),
            ],
          ),
          child: Icon(Icons.close_rounded, color: Colors.white, size: 28.sp),
        ),
      ),
      GestureDetector(
        onTap: () => _swiperController.swipe(CardSwiperDirection.right),
        child: Container(
          width: 60.w,
          height: 60.w,
          decoration: BoxDecoration(
            color: themeController.getAccentColor(),
            borderRadius: BorderRadius.circular(30.r),
            boxShadow: [
              BoxShadow(
                color: themeController.getAccentColor().withValues(alpha: 0.3),
                blurRadius: 10.r,
              ),
            ],
          ),
          child: Icon(Icons.people, color: Colors.white, size: 28.sp),
        ),
      ),
      _buildMessageMiniButton(),
    ];
  }

  // Small rewind button to the left of Dislike
  Widget _buildRewindMiniButton() {
    return GestureDetector(
      onTap: () async {
        final isPremium = await SupabaseService.isPremiumUser();
        if (!isPremium) {
          RewindService.showRewindUpgradeDialog();
          return;
        }
        RewindService.showRewindDialog(
          onRewind: () async {
            print('🔄 DEBUG: Rewind button tapped');
            
            // First, delete the swipe from the database
            final result = await RewindService.performRewind();
            print('🔄 DEBUG: Rewind result: $result');
            
            if (result['success'] == true) {
              print('✅ DEBUG: Swipe deleted from database, undoing swipe animation...');
              
              // Undo the swipe animation - re-insert the profile at index 0
              final undone = controller.undoLastSwipe();
              
              if (undone) {
                print('✅ DEBUG: Profile re-inserted at index 0 - smooth animation!');
                Get.snackbar('Rewind', 'Profile restored!', duration: Duration(seconds: 1));
              } else {
                print('⚠️ DEBUG: Could not undo swipe - no last swiped profile found');
                // Fallback: reload profiles if undo fails
                await Future.delayed(Duration(milliseconds: 500));
                await controller.reloadWithFilters();
                print('✅ DEBUG: Profiles reloaded after rewind (fallback)');
              }
            } else {
              print('❌ DEBUG: Rewind failed: ${result['error']}');
              Get.snackbar('Rewind', result['error']?.toString() ?? 'Failed');
            }
          },
          onUpgrade: () => Get.to(() => SubscriptionScreen()),
        );
      },
      child: Container(
        width: 44.w,
        height: 44.w,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFFD700), Color(0xFFFFA500)], // Gold to Orange gradient
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Color(0xFFFFD700).withValues(alpha: 0.4),
              blurRadius: 8.r,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Icon(Icons.undo, color: Colors.white, size: 20.sp),
      ),
    );
  }

  // Small message button to the right of Like
  Widget _buildMessageMiniButton() {
    return GestureDetector(
      onTap: () async {
        final p = controller.currentProfile;
        if (p == null) {
          Get.snackbar('Message', 'No profile selected');
          return;
        }
        // Service handles premium check and shows appropriate dialog
        PremiumMessageService.showPremiumMessageDialog(
          recipientId: p.id,
          recipientName: p.name,
          recipientPhoto: p.photos.isNotEmpty ? p.photos.first : '',
        );
      },
      child: Container(
        width: 44.w,
        height: 44.w,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF9C27B0), Color(0xFF673AB7)], // Purple to Deep Purple gradient
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Color(0xFF9C27B0).withValues(alpha: 0.4),
              blurRadius: 8.r,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Icon(LucideIcons.send, color: Colors.white, size: 18.sp),
      ),
    );
  }

  void _openFilters() {
    showModalBottomSheet(
      context: Get.context!,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        return Obx(() {
          print('🔍 DEBUG: Current mode in filters: ${controller.currentMode.value}');
          return Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(Get.context!).viewInsets.bottom,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: controller.currentMode.value == 'bff'
                    ? [
                        themeController.getSecondaryColor().withValues(alpha: 0.9),
                        themeController.blackColor.withValues(alpha: 0.9),
                      ]
                    : [
                        themeController.lightPinkColor.withValues(alpha: 0.9),
                        themeController.blackColor.withValues(alpha: 0.9),
                      ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(22.r)),
              border: Border.all(
                color: controller.currentMode.value == 'bff'
                    ? themeController
                        .getSecondaryColor()
                        .withValues(alpha: 0.3)
                    : themeController.lightPinkColor
                        .withValues(alpha: 0.3),
              ),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        Text(
                          'Filters',
                          style: TextStyle(
                            color: themeController.whiteColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 16.sp,
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () {
                            controller.minAge.value = 18;
                            controller.maxAge.value = 99;
                            controller.maxDistanceKm.value = 100;
                            controller.gender.value = 'Everyone';
                            controller.selectedIntents.clear();
                            controller.reloadWithFilters();
                          },
                          child: Text(
                            'Reset',
                            style: TextStyle(
                              color: controller.currentMode.value == 'bff'
                                  ? themeController.getSecondaryColor()
                                  : themeController.lightPinkColor,
                            ),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 8.h),

                    // Age Range
                    Text(
                      'Age range',
                      style: TextStyle(
                        color: themeController.whiteColor
                            .withValues(alpha: 0.8),
                      ),
                    ),
                    RangeSlider(
                      min: 18,
                      max: 99,
                      divisions: 81,
                      activeColor: controller.currentMode.value == 'bff'
                          ? themeController.getSecondaryColor()
                          : themeController.lightPinkColor,
                      values: RangeValues(
                        controller.minAge.value.toDouble(),
                        controller.maxAge.value.toDouble(),
                      ),
                      onChanged: (v) async {
                        controller.minAge.value = v.start.round();
                        controller.maxAge.value = v.end.round();
                        await controller.saveFilters();
                        await controller.reloadWithFilters();
                      },
                    ),

                    SizedBox(height: 8.h),

                    // Distance
                    Text(
                      'Distance (km)',
                      style: TextStyle(
                        color: themeController.whiteColor
                            .withValues(alpha: 0.8),
                      ),
                    ),
                    Slider(
                      min: 1,
                      max: 200,
                      divisions: 199,
                      activeColor: controller.currentMode.value == 'bff'
                          ? themeController.getSecondaryColor()
                          : themeController.lightPinkColor,
                      value:
                          controller.maxDistanceKm.value.clamp(1.0, 200.0),
                      onChanged: (v) async {
                        controller.maxDistanceKm.value = v;
                        await controller.saveFilters();
                        await controller.reloadWithFilters();
                      },
                    ),

                    SizedBox(height: 8.h),

                    // Location Refresh Button
                    Row(
                      children: [
                        Text(
                          'Location',
                          style: TextStyle(
                            color: themeController.whiteColor
                                .withValues(alpha: 0.8),
                          ),
                        ),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: () async {
                            // Show loading indicator
                            Get.dialog(
                              Center(
                                child: Container(
                                  padding: EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.8),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      CircularProgressIndicator(
                                        color: controller.currentMode.value == 'bff'
                                            ? themeController.getSecondaryColor()
                                            : themeController.lightPinkColor,
                                      ),
                                      SizedBox(height: 10),
                                      Text(
                                        'Updating location...',
                                        style: TextStyle(
                                          color: themeController.whiteColor,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              barrierDismissible: false,
                            );
                            
                            // Update location
                            final success = await controller.refreshLocation();
                            
                            // Close loading dialog
                            Get.back();
                            
                            if (success) {
                              Get.snackbar(
                                'Location Updated',
                                'Your location has been refreshed successfully!',
                                backgroundColor: Colors.green,
                                colorText: Colors.white,
                                duration: Duration(seconds: 2),
                              );
                            } else {
                              Get.snackbar(
                                'Location Update Failed',
                                'Could not update location. Please check your GPS settings.',
                                backgroundColor: Colors.red,
                                colorText: Colors.white,
                                duration: Duration(seconds: 3),
                              );
                            }
                          },
                          icon: Icon(
                            Icons.my_location,
                            size: 16,
                            color: controller.currentMode.value == 'bff'
                                ? themeController.getSecondaryColor()
                                : themeController.lightPinkColor,
                          ),
                          label: Text(
                            'Refresh',
                            style: TextStyle(
                              color: controller.currentMode.value == 'bff'
                                  ? themeController.getSecondaryColor()
                                  : themeController.lightPinkColor,
                            ),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 8.h),

                    // Gender
                    Text(
                      'Gender',
                      style: TextStyle(
                        color: themeController.whiteColor
                            .withValues(alpha: 0.8),
                      ),
                    ),
                    Wrap(
                      spacing: 8.w,
                      children: ['Everyone', 'Male', 'Female', 'Non-binary']
                          .map(
                            (g) => ChoiceChip(
                              label: Text(g),
                              selected: controller.gender.value == g,
                              selectedColor:
                                  controller.currentMode.value == 'bff'
                                      ? themeController
                                          .getSecondaryColor()
                                          .withValues(alpha: 0.3)
                                      : themeController.lightPinkColor
                                          .withValues(alpha: 0.3),
                              checkmarkColor:
                                  controller.currentMode.value == 'bff'
                                      ? themeController.getSecondaryColor()
                                      : themeController.lightPinkColor,
                              onSelected: (_) async {
                                controller.gender.value = g;
                                await controller.saveFilters();
                                await controller.reloadWithFilters();
                              },
                            ),
                          )
                          .toList(),
                    ),

                    SizedBox(height: 8.h),

                    // Intent / Activity filters
                    if (controller.currentMode.value == 'dating') ...[
                      Text(
                        'Intent',
                        style: TextStyle(
                          color: themeController.whiteColor
                              .withValues(alpha: 0.8),
                        ),
                      ),
                      Wrap(
                        spacing: 8.w,
                        children: ['Casual', 'Serious', 'Just Chatting']
                            .map(
                              (i) => FilterChip(
                                label: Text(i),
                                selected:
                                    controller.selectedIntents.contains(i),
                                selectedColor:
                                    controller.currentMode.value == 'bff'
                                        ? themeController.getSecondaryColor()
                                            .withValues(alpha: 0.3)
                                        : themeController.lightPinkColor
                                            .withValues(alpha: 0.3),
                                checkmarkColor:
                                    controller.currentMode.value == 'bff'
                                        ? themeController.getSecondaryColor()
                                        : themeController.lightPinkColor,
                                onSelected: (sel) async {
                                  if (sel) {
                                    controller.selectedIntents.add(i);
                                  } else {
                                    controller.selectedIntents.remove(i);
                                  }
                                  await controller.saveFilters();
                                  await controller.reloadWithFilters();
                                },
                              ),
                            )
                            .toList(),
                      ),
                    ] else ...[
                      Text(
                        'Activity Level',
                        style: TextStyle(
                          color: themeController.whiteColor
                              .withValues(alpha: 0.8),
                        ),
                      ),
                      Wrap(
                        spacing: 8.w,
                        children: ['Active', 'Moderate', 'Casual']
                            .map(
                              (i) => FilterChip(
                                label: Text(i),
                                selected:
                                    controller.selectedIntents.contains(i),
                                selectedColor:
                                    controller.currentMode.value == 'bff'
                                        ? themeController.getSecondaryColor()
                                            .withValues(alpha: 0.3)
                                        : themeController.lightPinkColor
                                            .withValues(alpha: 0.3),
                                checkmarkColor:
                                    controller.currentMode.value == 'bff'
                                        ? themeController.getSecondaryColor()
                                        : themeController.lightPinkColor,
                                onSelected: (sel) async {
                                  if (sel) {
                                    controller.selectedIntents.add(i);
                                  } else {
                                    controller.selectedIntents.remove(i);
                                  }
                                  await controller.saveFilters();
                                  await controller.reloadWithFilters();
                                },
                              ),
                            )
                            .toList(),
                      ),
                    ],

                    SizedBox(height: 16.h),
                  ],
                ),
              ),
            ),
          );
        });
      },
    );
  }

  Widget _buildEmptyState() {
    return Container(
      height: Get.height - 320.h,
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 40.h),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon
          Container(
            width: 120.w,
            height: 120.w,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: controller.currentMode.value == 'bff'
                    ? [
                        themeController.bffPrimaryColor.withValues(alpha: 0.2),
                        themeController.bffSecondaryColor.withValues(alpha: 0.3),
                      ]
                    : [
                        themeController.lightPinkColor.withValues(alpha: 0.2),
                        Colors.purple.withValues(alpha: 0.3),
                      ],
              ),
              borderRadius: BorderRadius.circular(60.r),
            ),
            child: Icon(
              controller.currentMode.value == 'bff' 
                  ? Icons.people_outline 
                  : Icons.favorite_outline,
              size: 60.sp,
              color: controller.currentMode.value == 'bff'
                  ? themeController.bffPrimaryColor
                  : themeController.lightPinkColor,
            ),
          ),
          
          SizedBox(height: 32.h),
          
          // Title
          Text(
            controller.currentMode.value == 'bff' 
                ? 'No More BFF Profiles'
                : 'No More Dating Profiles',
            style: TextStyle(
              fontFamily: 'AppFont',
              fontSize: 24.sp,
              fontWeight: FontWeight.w700,
              color: themeController.whiteColor,
            ),
            textAlign: TextAlign.center,
          ),
          
          SizedBox(height: 16.h),
          
          // Subtitle
          Text(
            controller.currentMode.value == 'bff'
                ? 'You\'ve seen all the available friends in your area!'
                : 'You\'ve seen all the available matches in your area!',
            style: TextStyle(
              fontFamily: 'AppFont',
              fontSize: 16.sp,
              fontWeight: FontWeight.w400,
              color: themeController.whiteColor.withValues(alpha: 0.8),
            ),
            textAlign: TextAlign.center,
          ),
          
          SizedBox(height: 32.h),
          
          // Refresh button
          GestureDetector(
            onTap: () => controller.reloadWithFilters(),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 16.h),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: controller.currentMode.value == 'bff'
                      ? [
                          themeController.bffPrimaryColor,
                          themeController.bffSecondaryColor,
                        ]
                      : [
                          themeController.lightPinkColor,
                          Colors.purple,
                        ],
                ),
                borderRadius: BorderRadius.circular(25.r),
                boxShadow: [
                  BoxShadow(
                    color: (controller.currentMode.value == 'bff'
                            ? themeController.bffPrimaryColor
                            : themeController.lightPinkColor)
                        .withValues(alpha: 0.3),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.refresh,
                    color: Colors.white,
                    size: 20.sp,
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    'Refresh',
                    style: TextStyle(
                      fontFamily: 'AppFont',
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionChip({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: themeController.whiteColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: themeController.whiteColor.withValues(alpha: 0.15),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40.w,
              height: 40.w,
              decoration: BoxDecoration(
                color: controller.currentMode.value == 'bff'
                    ? themeController.bffPrimaryColor.withValues(alpha: 0.2)
                    : themeController.lightPinkColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Icon(
                icon,
                color: controller.currentMode.value == 'bff'
                    ? themeController.bffPrimaryColor
                    : themeController.lightPinkColor,
                size: 20.sp,
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: themeController.whiteColor,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w400,
                      color: themeController.whiteColor.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: themeController.whiteColor.withValues(alpha: 0.5),
              size: 16.sp,
            ),
          ],
        ),
      ),
    );
  }

  void _showFiltersSheet(BuildContext context, ThemeController themeController) {
    // Minimal, safe bottom sheet to restore build; original body kept below
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      isScrollControlled: true,
      builder: (_) => Container(
        constraints: BoxConstraints(maxHeight: Get.height * 0.5),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.85),
          borderRadius: BorderRadius.vertical(top: Radius.circular(22.r)),
        ),
        padding: EdgeInsets.all(16.w),
        child: Center(
          child: Text('filters'.tr, style: TextStyle(color: Colors.white, fontSize: 18.sp, fontWeight: FontWeight.w600)),
        ),
      ),
    );
    return;
    /*
          children: [
            ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(22.r)),
              child: Container(
            constraints: BoxConstraints(
              maxHeight: Get.height * 0.85,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: controller.currentMode.value == 'bff'
                    ? [
                        themeController.bffPrimaryColor.withValues(alpha: 0.15),
                        themeController.bffSecondaryColor.withValues(alpha: 0.2),
                        themeController.blackColor.withValues(alpha: 0.85),
                      ]
                    : [
                        Colors.pink.withValues(alpha: 0.15),
                        Colors.purple.withValues(alpha: 0.2),
                        themeController.blackColor.withValues(alpha: 0.85),
                      ],
                stops: [0.0, 0.3, 1.0],
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(22.r)),
              border: Border.all(
                color: controller.currentMode.value == 'bff'
                    ? themeController.bffPrimaryColor.withValues(alpha: 0.35)
                    : themeController.lightPinkColor.withValues(alpha: 0.35),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: controller.currentMode.value == 'bff'
                      ? themeController.bffPrimaryColor.withValues(alpha: 0.15)
                      : themeController.lightPinkColor.withValues(alpha: 0.15),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 40.w,
                      height: 4.h,
                      decoration: BoxDecoration(
                        color: themeController.whiteColor.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2.r),
                      ),
                    ),
                  ),
                  SizedBox(height: 16.h),
                  
                  // Title
                  Text(
                    'Filters',
                    style: TextStyle(
                      color: themeController.whiteColor,
                      fontSize: 24.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  
                  // Age Range
                  Text(
                    'Age Range',
                    style: TextStyle(
                      color: themeController.whiteColor.withValues(alpha: 0.9),
                      fontWeight: FontWeight.w600,
                      fontSize: 15.sp,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Obx(() => SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: controller.currentMode.value == 'bff'
                          ? themeController.bffPrimaryColor
                          : themeController.lightPinkColor,
                      thumbColor: controller.currentMode.value == 'bff'
                          ? themeController.bffPrimaryColor
                          : themeController.lightPinkColor,
                      overlayColor: (controller.currentMode.value == 'bff'
                          ? themeController.bffPrimaryColor
                          : themeController.lightPinkColor).withValues(alpha: 0.2),
                    ),
                    child: RangeSlider(
                      values: RangeValues(
                        controller.minAge.value.toDouble(),
                        controller.maxAge.value.toDouble(),
                      ),
                      min: 18,
                      max: 99,
                      divisions: 81,
                      onChanged: (values) async {
                        controller.minAge.value = values.start.round();
                        controller.maxAge.value = values.end.round();
                        await controller.saveFilters();
                        await controller.reloadWithFilters();
                      },
                    ),
                  )),
                  Obx(() => Text(
                    '${controller.minAge.value} - ${controller.maxAge.value} years old',
                    style: TextStyle(
                      color: controller.currentMode.value == 'bff'
                          ? themeController.bffPrimaryColor
                          : themeController.lightPinkColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 14.sp,
                    ),
                  )),
                  SizedBox(height: 16.h),
                  
                  // Distance
                  Text(
                    'Distance',
                    style: TextStyle(
                      color: themeController.whiteColor.withValues(alpha: 0.9),
                      fontWeight: FontWeight.w600,
                      fontSize: 15.sp,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Obx(() => SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: controller.currentMode.value == 'bff'
                          ? themeController.bffPrimaryColor
                          : themeController.lightPinkColor,
                      thumbColor: controller.currentMode.value == 'bff'
                          ? themeController.bffPrimaryColor
                          : themeController.lightPinkColor,
                      overlayColor: (controller.currentMode.value == 'bff'
                          ? themeController.bffPrimaryColor
                          : themeController.lightPinkColor).withValues(alpha: 0.2),
                    ),
                    child: Slider(
                      value: controller.maxDistanceKm.value,
                      min: 1,
                      max: 100,
                      divisions: 99,
                      onChanged: (value) async {
                        controller.maxDistanceKm.value = value;
                        await controller.saveFilters();
                        await controller.reloadWithFilters();
                      },
                    ),
                  )),
                  Obx(() => Text(
                    'Within ${controller.maxDistanceKm.value.round()} km',
                    style: TextStyle(
                      color: controller.currentMode.value == 'bff'
                          ? themeController.bffPrimaryColor
                          : themeController.lightPinkColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 14.sp,
                    ),
                  )),
                  SizedBox(height: 16.h),
                  
                  // Reset button
                  Center(
                    child: GestureDetector(
                      onTap: () async {
                        controller.resetFilters();
                        await controller.saveFilters();
                        await controller.reloadWithFilters();
                        Get.back();
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                        decoration: BoxDecoration(
                          color: themeController.whiteColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20.r),
                          border: Border.all(
                            color: controller.currentMode.value == 'bff'
                                ? themeController.bffPrimaryColor.withValues(alpha: 0.5)
                                : themeController.lightPinkColor.withValues(alpha: 0.5),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          'Reset Filters',
                          style: TextStyle(
                            color: controller.currentMode.value == 'bff'
                                ? themeController.bffPrimaryColor
                                : themeController.lightPinkColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 14.sp,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Rewind button for premium users
        DiscoverRewindButton(
          onRewindSuccess: () async {
            print('🔄 DEBUG: Rewind success callback - undoing swipe...');
            
            // Undo the swipe animation - re-insert the profile at index 0
            final undone = controller.undoLastSwipe();
            
            if (undone) {
              print('✅ DEBUG: Profile re-inserted at index 0 - smooth animation!');
            } else {
              print('⚠️ DEBUG: Could not undo swipe - no last swiped profile found');
              // Fallback: reload profiles if undo fails
              await Future.delayed(Duration(milliseconds: 500));
              await controller.reloadWithFilters();
              print('✅ DEBUG: Profiles reloaded after rewind (fallback)');
            }
          },
        ),

        // Global Premium Message button overlay (visible but blocked for free users)
        Obx(() {
          final p = controller.currentProfile;
          if (p == null) return const SizedBox.shrink();
          final photo = (p.photos.isNotEmpty) ? p.photos.first : '';
          return PremiumMessageButton(
            recipientId: p.id,
            recipientName: p.name,
            recipientPhoto: photo,
          );
        }),
      ],
    );
  }

  */
  }

  Widget _buildCardSwiper(int count) {
    // Enforce stable Tinder-like aspect ratio for consistent card sizing
    const double cardAspectRatio = 0.74; // width : height ~ 0.74
    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;
        final double height = width / cardAspectRatio;
        return SizedBox(
          height: height,
          child: CardSwiper(
            key: ValueKey('${controller.deckVersion.value}_${count}'),
            controller: _swiperController,
            isLoop: false,
            padding: EdgeInsets.zero,
            numberOfCardsDisplayed: count.clamp(1, 3),
            cardsCount: count,
            allowedSwipeDirection: AllowedSwipeDirection.only(
              left: true,
              right: true,
              up: true,
            ),
            onSwipe: (previousIndex, currentIndex, direction) async {
              if (kDebugMode) {
                print('🔍 DEBUG: onSwipe called - previousIndex=$previousIndex, currentIndex=$currentIndex, direction=$direction');
              }

              // Validate indices before processing
              if (previousIndex != null && 
                  previousIndex >= 0 && 
                  previousIndex < controller.profiles.length) {
                final profile = controller.profiles[previousIndex];
                if (kDebugMode) {
                  print('🔍 DEBUG: Swiping profile - ID=${profile.id}, Name="${profile.name}", Age=${profile.age}');
                }

                bool allowed = false;
                if (direction == CardSwiperDirection.left) {
                  allowed = await controller.onSwipeLeft(profile);
                } else if (direction == CardSwiperDirection.right) {
                  allowed = await controller.onSwipeRight(profile);
                } else if (direction == CardSwiperDirection.top) {
                  allowed = await controller.onSuperLike(profile);
                }

                if (!allowed) {
                  if (kDebugMode) {
                    print('⛔ Swipe blocked for profile ID=${profile.id}, action=$direction');
                  }
                  return false;
                }
              } else {
                if (kDebugMode) {
                  print('🔍 DEBUG: Invalid previousIndex: $previousIndex, profiles.length: ${controller.profiles.length}');
                }
              }

              // 🔧 FIX: Delay index updates to avoid name overlay mismatch
              // Keep neon overlay bound to the top card index post-animation
              Future.delayed(const Duration(milliseconds: 180), () {
                if (currentIndex != null &&
                    currentIndex >= 0 &&
                    currentIndex < controller.profiles.length) {
                  controller.currentIndex.value = currentIndex;
                  controller.overlayIndex.value = currentIndex;
                  if (kDebugMode) {
                    print('🔄 DEBUG: Updated currentIndex to $currentIndex after swipe animation');
                  }
                }
                // Finalize deck change after animation to keep UI/data in sync
                // Pass direction for rewind animation
                if (previousIndex != null) {
                  controller.finalizeSwipeAtIndex(previousIndex, direction: direction);
                }
              });
              return true;
            },
            cardBuilder: (context, index, percentX, percentY) {
              final listLen = controller.profiles.length;

              if (listLen == 0) {
                return const SizedBox.shrink();
              }

              final profile = controller.profiles[index];

              if (profile.name.isEmpty || profile.id.isEmpty) {
                return const SizedBox.shrink();
              }

              final px = ((percentX ?? 0.0).clamp(-1.0, 1.0) as num).toDouble();
              final py = ((percentY ?? 0.0).clamp(-1.0, 1.0) as num).toDouble();

              // 🔧 FIX: Improved animation system for all cards
              const deadZone = 0.01; // Reduced dead zone for more responsive animation
              final ax = (px.abs() < deadZone) ? 0.0 : px;
              
              // 🔧 FIX: Progressive animation based on card position
              final cardPosition = index - controller.currentIndex.value;
              final isTopCard = cardPosition == 0;
              final isSecondCard = cardPosition == 1;
              final isThirdCard = cardPosition == 2;
              
              // 🔧 FIX: Calculate animation intensity based on position
              // All cards should have some animation, not just top card
              final animationIntensity = isTopCard ? 1.0 : 
                                       isSecondCard ? 0.7 : 
                                       isThirdCard ? 0.4 : 0.2;
              
              final t = ax.abs().clamp(0.0, 1.0);
              final upT = (-py).clamp(0.0, 1.0);
              final dragProgress = (t + upT).clamp(0.0, 1.0);

              // 🔧 FIX: Progressive scaling for card stack effect with interpolation
              final baseScale = isTopCard ? 1.0 : 
                               isSecondCard ? 0.95 : 
                               isThirdCard ? 0.90 : 0.85;
              final scale = isTopCard
                  ? (1.0 - 0.05 * dragProgress)
                  : isSecondCard
                      ? (0.95 + 0.05 * dragProgress)
                      : isThirdCard
                          ? (0.90 + 0.03 * dragProgress)
                          : baseScale;
              
              // 🔧 FIX: Enhanced rotation for all cards
              final angle = animationIntensity * (ax * (15 * math.pi / 180));
              final dx = animationIntensity * ax * 20.w;
              
              final cardHeight = Get.height - 320.h;
              
              // 🔧 FIX: Arc calculation for all cards with different intensities
              final arc = animationIntensity * (-0.12 * cardHeight * (1 - math.cos(math.pi * t)));
              final dy = arc + (py < 0 ? py * 30.h * animationIntensity : 0.0);
              
              // 🔧 FIX: Add subtle rotation for non-top cards
              final additionalRotation = isSecondCard ? 0.5 * math.pi / 180 : 
                                        isThirdCard ? 1.0 * math.pi / 180 : 0.0;
              final finalAngle = angle + additionalRotation;

              final card = OpenContainer(
                transitionDuration: const Duration(milliseconds: 350),
                openElevation: 0,
                closedElevation: 0,
                closedColor: Colors.transparent,
                openColor: Colors.transparent,
                transitionType: ContainerTransitionType.fadeThrough,
                closedShape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20.r),
                ),
                openShape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20.r),
                ),
                openBuilder: (context, _) => ProfileDetailScreen(profile: profile),
                closedBuilder: (context, open) => GestureDetector(
                  onTap: open,
                  behavior: HitTestBehavior.opaque,
                  child: RepaintBoundary(
                    key: ValueKey('repaint_${profile.id}'),
                    child: ProfileCard(
                      key: ValueKey('card_${profile.id}'),
                      profile: profile,
                      themeController: themeController,
                    ),
                  ),
                ),
              );

              // 🔧 FIX: Apply progressive transforms for smooth card stack animation
              Widget transformed = card;
              
              // Check if this is a rewinding card (first card during rewind animation)
              // Use Obx to react to isRewinding changes
              if (isTopCard && controller.isRewinding.value && controller.lastSwipeDirection != null) {
                final direction = controller.lastSwipeDirection!;
                
                // Calculate starting offset based on swipe direction
                double startOffsetX = 0.0;
                double startOffsetY = 0.0;
                double startAngle = 0.0;
                
                switch (direction) {
                  case CardSwiperDirection.left:
                    startOffsetX = -Get.width;
                    startAngle = -15 * math.pi / 180;
                    break;
                  case CardSwiperDirection.right:
                    startOffsetX = Get.width;
                    startAngle = 15 * math.pi / 180;
                    break;
                  case CardSwiperDirection.top:
                    startOffsetY = -Get.height;
                    break;
                  default:
                    break;
                }
                
                // Animate card sliding back from the direction it was swiped
                transformed = TweenAnimationBuilder<double>(
                  duration: Duration(milliseconds: 400),
                  tween: Tween(begin: 0.0, end: 1.0),
                  curve: Curves.easeOut,
                  builder: (context, animValue, child) {
                    // Interpolate from start position to center
                    final animOffsetX = startOffsetX * (1 - animValue);
                    final animOffsetY = startOffsetY * (1 - animValue);
                    final animAngle = startAngle * (1 - animValue);
                    
                    // Apply reverse animation transforms
                    Widget animCard = Transform.rotate(
                      angle: animAngle,
                      child: Transform.translate(
                        offset: Offset(animOffsetX, animOffsetY),
                        child: child!,
                      ),
                    );
                    
                    return animCard;
                  },
                  child: transformed,
                );
              }
              
              final isRewindingCard = isTopCard && controller.isRewinding.value && controller.lastSwipeDirection != null;
              
              // Scale transform with smooth progression
              transformed = Transform.scale(
                scale: scale,
                child: transformed,
              );
              
              // Rotation transform with enhanced angle (only if not rewinding)
              if (!isRewindingCard) {
                transformed = Transform.rotate(
                  angle: finalAngle,
                  child: transformed,
                );
              }
              
              // Translation transform with improved positioning (only if not rewinding)
              if (!isRewindingCard) {
                transformed = Transform.translate(
                  offset: Offset(dx, dy),
                  child: transformed,
                );
              }
              
              return transformed;
            },
          ),
        );
      },
    );
  }

  Widget _buildLoadingOverlay() {
    return Positioned(
      bottom: 100.h,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
        margin: EdgeInsets.symmetric(horizontal: 40.w),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(25.r),
          border: Border.all(
            color: themeController.lightPinkColor.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 20.w,
              height: 20.w,
              child: CircularProgressIndicator(
                color: themeController.lightPinkColor,
                strokeWidth: 2.0,
              ),
            ),
            SizedBox(width: 12.w),
            Text(
              'Loading more profiles...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Get superlike count for badge display
  Future<Map<String, dynamic>> _getSuperLikeCount() async {
    try {
      // Check if user is premium - premium users have unlimited
      final isPremium = await SupabaseService.isPremiumUser();
      if (isPremium) {
        return {'isPremium': true, 'remaining': 0};
      }

      // Get daily usage for free users
      final usage = await SupabaseService.getDailyUsage();
      final used = usage['super_likes_used'] ?? 0;
      
      // Free users get 1 super like per day
      // Calculate remaining: 1 free - used
      final remaining = (1 - used).clamp(0, 1);
      
      // If remaining is 0, the badge will be hidden
      return {'isPremium': false, 'remaining': remaining};
    } catch (e) {
      print('Error getting superlike count: $e');
      // On error, assume 0 remaining to hide badge
      return {'isPremium': false, 'remaining': 0};
    }
  }
}
