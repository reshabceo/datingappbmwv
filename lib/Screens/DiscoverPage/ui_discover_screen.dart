import 'package:lovebug/Common/text_constant.dart';
import 'package:lovebug/Common/widget_constant.dart';
import 'package:lovebug/Constant/app_assets.dart';
import 'package:lovebug/Screens/ChatPage/ui_message_screen.dart';
import 'package:lovebug/Screens/DiscoverPage/Widget/profile_card_widget.dart';
import 'package:lovebug/Screens/DiscoverPage/controller_discover_screen.dart';
import 'package:lovebug/Screens/DiscoverPage/profile_detail_screen.dart';
import 'package:lovebug/ThemeController/theme_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:get/get.dart';
import 'package:animations/animations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;

class DiscoverScreen extends StatelessWidget {
  DiscoverScreen({super.key});

  final DiscoverController controller = Get.put(DiscoverController());
  final ThemeController themeController = Get.find<ThemeController>();
  final CardSwiperController _swiperController = CardSwiperController();

  @override
  Widget build(BuildContext context) {
    // AppBar button opens its own sheet now; no event bus
    return Scaffold(
      backgroundColor: themeController.blackColor,
      body: Container(
          width: Get.width,
          height: Get.height,
          decoration: BoxDecoration(
          gradient: LinearGradient(
              colors: [themeController.blackColor, themeController.bgGradient1, themeController.blackColor],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
          ),
        ),
        child: Stack(
          children: [
            // Removed top row chips; Filters square in AppBar handles it now
            // Main content with padding
            screenPadding(
              child: SingleChildScrollView(
            child: Column(
                  children: [
                    heightBox(120), // Push cards down to create space above buttons
                    Obx(() {
                          final count = controller.profiles.length;
                          if (count == 0) {
                            return SizedBox(
                              height: Get.height * 0.6,
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'You\'re out of profiles for now',
                                      style: TextStyle(color: themeController.whiteColor, fontSize: 18.sp, fontWeight: FontWeight.w600),
                                      textAlign: TextAlign.center,
                                    ),
                                    SizedBox(height: 8.h),
                                    Text(
                                      'Check back later or tweak your filters to discover more.',
                                      style: TextStyle(color: themeController.whiteColor.withValues(alpha: 0.8), fontSize: 14.sp),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }
                          return SizedBox(
                            height: Get.height * 0.6, // Make card area smaller
                            child: CardSwiper(
                              controller: _swiperController,
                              isLoop: true,
                              padding: EdgeInsets.zero,
                              numberOfCardsDisplayed: count.clamp(1, 3),
                              cardsCount: count,
                              allowedSwipeDirection: AllowedSwipeDirection.only(left: true, right: true, up: true),
                              onSwipe: (previousIndex, currentIndex, direction) {
                                if (previousIndex < controller.profiles.length) {
                                  final profile = controller.profiles[previousIndex];
                                  if (direction == CardSwiperDirection.left) {
                                    controller.onSwipeLeft(profile);
                                  } else if (direction == CardSwiperDirection.right) {
                                    controller.onSwipeRight(profile);
                                  } else if (direction == CardSwiperDirection.top) {
                                    controller.onSuperLike(profile);
                                  }
                                }
                                // Track the currently visible index for overlay text
                                if (currentIndex != null && currentIndex >= 0 && currentIndex < controller.profiles.length) {
                                  controller.currentIndex.value = currentIndex;
                                }
                                return true;
                              },
                              cardBuilder: (context, index, percentX, percentY) {
                                final int listLen = controller.profiles.length;
                                if (listLen == 0) {
                                  return const SizedBox.shrink();
                                }
                                final int idx = index % listLen;
                                final profile = controller.profiles[idx];
                                final double px = ((percentX ?? 0.0).clamp(-1.0, 1.0) as num).toDouble();
                                final double py = ((percentY ?? 0.0).clamp(-1.0, 1.0) as num).toDouble();
                                // Dead-zone to ensure card is perfectly straight at rest
                                const double deadZone = 0.03; // ~3% drag ignored
                                final double ax = (px.abs() < deadZone) ? 0.0 : px;
                                final bool isTopCard = idx == controller.currentIndex.value;
                                final bool hasSecond = listLen >= 2;
                                final bool isSecondCard = hasSecond && idx == ((controller.currentIndex.value + 1) % listLen);

                                // Progress derived from horizontal drag and upward drag (super-like)
                                final double t = ax.abs().clamp(0.0, 1.0);
                                final double upT = (-py).clamp(0.0, 1.0);
                                final double dragProgress = (t + upT).clamp(0.0, 1.0);

                                // Base depth transform for stacked cards
                                double baseScale = 1.0;
                                double baseDy = 0.0;
                                double baseAngle = 0.0;
                                if (!isTopCard) {
                                  if (isSecondCard) {
                                    // Second card reveals with depth as drag progresses
                                    baseScale = 0.96 + (0.04 * dragProgress);
                                    baseDy = 14.h - (10.h * dragProgress);
                                    baseAngle = (-2 + (2 * dragProgress)) * (math.pi / 180);
                                  } else {
                                    baseScale = 0.92;
                                    baseDy = 26.h;
                                    baseAngle = 0.0;
                                  }
                                }

                                // Motion-style arc for the top card
                                final double angle = isTopCard ? (ax * (12 * math.pi / 180)) : baseAngle;
                                final double dx = isTopCard ? ax * 18.w : 0.0;
                                // Arc bow upward during left/right drag; only apply vertical rise for up-swipe
                                final double cardHeight = Get.height * 0.6;
                                final double arc = isTopCard ? (-0.10 * cardHeight * (1 - math.cos(math.pi * t))) : 0.0;
                                final double dy = isTopCard
                                    ? (arc + (py < 0 ? py * 28.h : 0.0))
                                    : baseDy;

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
                                      child: ProfileCard(profile: profile, themeController: themeController),
                                    ),
                                  ),
                                );

                                // Apply transforms
                                Widget transformed = card;
                                transformed = Transform.scale(
                                  scale: baseScale,
                                  child: transformed,
                                );
                                transformed = Transform.rotate(
                                  angle: angle,
                                  child: transformed,
                                );
                                transformed = Transform.translate(
                                  offset: Offset(dx, dy),
                                  child: transformed,
                                );
                                return transformed;
                              },
                            ),
                          );
                        }),
                                  heightBox(20),
                  ],
                ),
              ),
            ),
            // Name overlay - TRULY OUTSIDE the card area
            _buildNameOverlay(),
            // Action buttons overlay - TRULY OUTSIDE the card area
            _buildActionButtonsOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _chip({required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: themeController.whiteColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: themeController.lightPinkColor.withValues(alpha: 0.35)),
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
      top: 120.h - 52.h, // Nudged ~10px higher above the card
      left: 0,
      right: 0,
      child: Center(
        child: Obx(() {
          final currentProfile = controller.currentProfile;
          return Text(
            currentProfile != null ? '${currentProfile.name}, ${currentProfile.age}' : 'No profiles',
          style: GoogleFonts.dancingScript(
            fontSize: 50.sp,
            fontWeight: FontWeight.w700,
            color: themeController.lightPinkColor,
            shadows: [
              Shadow(
                color: themeController.lightPinkColor.withValues(alpha: 0.9),
                blurRadius: 30.r,
                offset: Offset(0, 0),
              ),
              Shadow(
                color: themeController.lightPinkColor.withValues(alpha: 0.6),
                blurRadius: 60.r,
                offset: Offset(0, 0),
              ),
              Shadow(
                color: themeController.lightPinkColor.withValues(alpha: 0.3),
                blurRadius: 90.r,
                offset: Offset(0, 0),
              ),
                                ],
                              ),
                            );
                          }),
      ),
    );
  }

  Widget _buildActionButtonsOverlay() {
    return Positioned(
      bottom: 20.h, // Keep buttons at bottom but not overlapping cards
      left: 0,
      right: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Dislike button
          GestureDetector(
            onTap: () {
              _swiperController.swipe(CardSwiperDirection.left);
            },
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
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(
                Icons.close_rounded,
                color: Colors.white,
                size: 28.sp,
              ),
            ),
          ),
          // Super like button
          GestureDetector(
            onTap: () {
              _swiperController.swipe(CardSwiperDirection.top);
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
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(
                Icons.star_rounded,
                color: Colors.white,
                size: 28.sp,
              ),
            ),
          ),
          // Like button
          GestureDetector(
            onTap: () {
              _swiperController.swipe(CardSwiperDirection.right);
            },
            child: Container(
              width: 60.w,
              height: 60.w,
              decoration: BoxDecoration(
                color: themeController.lightPinkColor,
                borderRadius: BorderRadius.circular(30.r),
                boxShadow: [
                  BoxShadow(
                    color: themeController.lightPinkColor.withValues(alpha: 0.3),
                    blurRadius: 10.r,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(
                Icons.favorite_outlined,
                color: Colors.white,
                size: 28.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openFilters() {
    final intents = ['Casual', 'Serious', 'Just Chatting'];
    showModalBottomSheet(
      context: Get.context!,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        return Obx(() => Container(
          padding: EdgeInsets.only(bottom: MediaQuery.of(Get.context!).viewInsets.bottom),
          decoration: BoxDecoration(
            color: themeController.blackColor.withValues(alpha: 0.9),
            borderRadius: BorderRadius.vertical(top: Radius.circular(22.r)),
            border: Border.all(color: themeController.lightPinkColor.withValues(alpha: 0.3)),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('Filters', style: TextStyle(color: themeController.whiteColor, fontWeight: FontWeight.w700, fontSize: 16.sp)),
                      Spacer(),
                      TextButton(
                        onPressed: () {
                          controller.minAge.value = 18;
                          controller.maxAge.value = 99;
                          controller.maxDistanceKm.value = 100;
                          controller.gender.value = 'Everyone';
                          controller.selectedIntents.clear();
                          controller.reloadWithFilters();
                        },
                        child: Text('Reset', style: TextStyle(color: themeController.lightPinkColor)),
                      )
                    ],
                  ),
                  SizedBox(height: 8.h),
                  Text('Age range', style: TextStyle(color: themeController.whiteColor.withValues(alpha: 0.8))),
                  RangeSlider(
                    min: 18,
                    max: 99,
                    divisions: 81,
                    values: RangeValues(controller.minAge.value.toDouble(), controller.maxAge.value.toDouble()),
                    onChanged: (v) async {
                      controller.minAge.value = v.start.round();
                      controller.maxAge.value = v.end.round();
                      await controller.saveFilters();
                      await controller.reloadWithFilters();
                    },
                  ),
                  SizedBox(height: 8.h),
                  Text('Distance (km)', style: TextStyle(color: themeController.whiteColor.withValues(alpha: 0.8))),
                  Slider(
                    min: 1,
                    max: 200,
                    divisions: 199,
                    value: controller.maxDistanceKm.value.clamp(1.0, 200.0),
                    onChanged: (v) async {
                      controller.maxDistanceKm.value = v;
                      await controller.saveFilters();
                      await controller.reloadWithFilters();
                    },
                  ),
                  SizedBox(height: 8.h),
                  Text('Gender', style: TextStyle(color: themeController.whiteColor.withValues(alpha: 0.8))),
                  Wrap(
                    spacing: 8.w,
                    children: ['Everyone','Male','Female','Non-binary'].map((g) => ChoiceChip(
                      label: Text(g),
                      selected: controller.gender.value == g,
                      onSelected: (_) async {
                        controller.gender.value = g;
                        await controller.saveFilters();
                        await controller.reloadWithFilters();
                      },
                    )).toList(),
                  ),
                  SizedBox(height: 8.h),
                  Text('Intent', style: TextStyle(color: themeController.whiteColor.withValues(alpha: 0.8))),
                  Wrap(
                    spacing: 8.w,
                    children: intents.map((i) => FilterChip(
                      label: Text(i),
                      selected: controller.selectedIntents.contains(i),
                      onSelected: (sel) async {
                        if (sel) {
                          controller.selectedIntents.add(i);
                        } else {
                          controller.selectedIntents.remove(i);
                        }
                        await controller.saveFilters();
                        await controller.reloadWithFilters();
                      },
                    )).toList(),
                  ),
                  SizedBox(height: 8.h),
                ],
              ),
            ),
          ),
        ));
      },
    );
  }
}
