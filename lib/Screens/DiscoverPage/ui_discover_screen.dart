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
                      
                      print('🔍 DEBUG: UI - profiles.length=$count, isLoading=$isLoading, mode=${controller.currentMode.value}');

                      if (isLoading && count == 0) {
                        return SizedBox(
                          height: Get.height * 0.6,
                          child: Center(
                            child: CircularProgressIndicator(
                              color: themeController.lightPinkColor,
                            ),
                          ),
                        );
                      }

                      // Show empty state if no profiles
                      if (count == 0) {
                        print('🔍 DEBUG: UI - Showing empty state for mode: ${controller.currentMode.value}');
                        return _buildEmptyState();
                      }

                      return SizedBox(
                        height: Get.height - 320.h,
                        child: CardSwiper(
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
                          onSwipe: (previousIndex, currentIndex, direction) {
                            print(
                                '🔍 DEBUG: onSwipe called - previousIndex=$previousIndex, currentIndex=$currentIndex, direction=$direction');

                            if (previousIndex < controller.profiles.length) {
                              final profile =
                                  controller.profiles[previousIndex];
                              print(
                                  '🔍 DEBUG: Swiping profile - ID=${profile.id}, Name="${profile.name}", Age=${profile.age}');

                              if (direction == CardSwiperDirection.left) {
                                controller.onSwipeLeft(profile);
                              } else if (direction ==
                                  CardSwiperDirection.right) {
                                controller.onSwipeRight(profile);
                              } else if (direction ==
                                  CardSwiperDirection.top) {
                                controller.onSuperLike(profile);
                              }
                            }

                            if (currentIndex != null &&
                                currentIndex >= 0 &&
                                currentIndex <
                                    controller.profiles.length) {
                              controller.currentIndex.value = currentIndex;
                            }
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

                            final px = ((percentX ?? 0.0)
                                    .clamp(-1.0, 1.0) as num)
                                .toDouble();
                            final py = ((percentY ?? 0.0)
                                    .clamp(-1.0, 1.0) as num)
                                .toDouble();

                            const deadZone = 0.03;
                            final ax = (px.abs() < deadZone) ? 0.0 : px;
                            final isTopCard =
                                index == controller.currentIndex.value;
                            final t = ax.abs().clamp(0.0, 1.0);
                            final upT = (-py).clamp(0.0, 1.0);
                            final dragProgress = (t + upT).clamp(0.0, 1.0);

                            final baseScale = 1.0;
                            final baseDy = 0.0;
                            final baseAngle = 0.0;

                            final angle =
                                isTopCard ? (ax * (12 * math.pi / 180)) : 0;
                            final dx = isTopCard ? ax * 18.w : 0.0;
                            final cardHeight = Get.height - 320.h;
                            final arc = isTopCard
                                ? (-0.10 *
                                    cardHeight *
                                    (1 - math.cos(math.pi * t)))
                                : 0.0;
                            final dy = isTopCard
                                ? (arc + (py < 0 ? py * 28.h : 0.0))
                                : baseDy;

                            final card = OpenContainer(
                              transitionDuration:
                                  const Duration(milliseconds: 350),
                              openElevation: 0,
                              closedElevation: 0,
                              closedColor: Colors.transparent,
                              openColor: Colors.transparent,
                              transitionType:
                                  ContainerTransitionType.fadeThrough,
                              closedShape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20.r),
                              ),
                              openShape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20.r),
                              ),
                              openBuilder: (context, _) =>
                                  ProfileDetailScreen(profile: profile),
                              closedBuilder: (context, open) => GestureDetector(
                                onTap: open,
                                behavior: HitTestBehavior.opaque,
                                child: RepaintBoundary(
                                  key: ValueKey(profile.id),
                                  child: ProfileCard(
                                    profile: profile,
                                    themeController: themeController,
                                  ),
                                ),
                              ),
                            );

                            Widget transformed = card;
                            transformed = Transform.scale(
                              scale: baseScale,
                              child: transformed,
                            );
                            transformed = Transform.rotate(
                              angle: angle.toDouble(),
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
            _buildNameOverlay(),
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
        final currentProfile = controller.currentProfile;

        if (currentProfile == null || controller.profiles.isEmpty) {
          return const SizedBox.shrink();
        }

        return FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            '${currentProfile.name}, ${currentProfile.age}',
            style: GoogleFonts.dancingScript(
              fontSize: 38.sp,
              fontWeight: FontWeight.w700,
              color: themeController.getAccentColor(),
              shadows: [
                Shadow(
                  color:
                      themeController.getAccentColor().withValues(alpha: 0.8),
                  blurRadius: 15.r,
                ),
                Shadow(
                  color:
                      themeController.getAccentColor().withValues(alpha: 0.4),
                  blurRadius: 30.r,
                ),
              ],
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
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
        onTap: () => _swiperController.swipe(CardSwiperDirection.top),
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
          child: Icon(Icons.star_rounded, color: Colors.white, size: 28.sp),
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
    ];
  }

  List<Widget> _buildBFFActionButtons() {
    return [
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
    ];
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
    if (!Get.isRegistered<DiscoverController>()) return;
    final controller = Get.find<DiscoverController>();
    final intents = ['Casual', 'Serious', 'Just Chatting'];
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      builder: (_) {
        return Obx(() => ClipRRect(
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
        ));
      },
    );
  }
}
