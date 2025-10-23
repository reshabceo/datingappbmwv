import 'package:lovebug/Common/widget_constant.dart';
import 'package:lovebug/Constant/app_assets.dart';
import 'package:lovebug/Screens/Setting/Controller/setting_controller.dart';
import 'package:lovebug/Screens/Setting/Screens/setting_page.dart';
import 'package:lovebug/ThemeController/theme_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:lovebug/Screens/DiscoverPage/controller_discover_screen.dart';
import 'dart:ui';

class GradientCommonAppBar extends StatelessWidget implements PreferredSizeWidget {
  final List<Widget>? actions;
  final Widget? leading;
  final bool? showBackButton;
  final bool? isCenterTitle;
  final bool? isActionWidget;
  final bool? isNotificationShow;
  final Color? backButtonColor;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onSettingsTap;

  GradientCommonAppBar({
    super.key,
    this.actions,
    this.leading,
    this.showBackButton = false,
    this.isCenterTitle = false,
    this.isActionWidget = true,
    this.isNotificationShow = true,
    this.backButtonColor,
    this.onNotificationTap,
    this.onSettingsTap,
  });

  final ThemeController themeController = Get.find<ThemeController>();
  final SettingsController settingsController = Get.put(SettingsController());

  @override
  Widget build(BuildContext context) {
    return AppBar(
          backgroundColor: themeController.transparentColor,
          elevation: 0,
          leading: showBackButton == true
              ? IconButton(
            icon: Icon(Icons.arrow_back, color: backButtonColor ?? themeController.lightPinkColor),
            onPressed: () {
              Get.back();
            },
          )
              : null,
          automaticallyImplyLeading: showBackButton == true,
          leadingWidth: showBackButton == true ? null : 0,
          titleSpacing: showBackButton == true ? null : 10.w,
          centerTitle: false,
          title: Image.asset(
            'assets/images/lovebug_logo.png', 
            width: 140.w,
            height: 45.h,
            fit: BoxFit.contain,
            alignment: Alignment.centerLeft,
          ),
          actions: isActionWidget == true
              ? actions ??
              [
                // Add Dating/BFF toggle for discover page
                _buildModeToggle(),
                widthBox(8),
                // Replace settings gear with Filters square that opens bottom sheet via a global event
                _FiltersSquare(),
                widthBox(10),
              ]
              : [],
      );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  Widget _buildModeToggle() {
    // Only show toggle if DiscoverController is registered (only on discover page)
    if (!Get.isRegistered<DiscoverController>()) {
      return SizedBox.shrink();
    }
    
    return Obx(() {
      final controller = Get.find<DiscoverController>();
      
      return Container(
        width: 80.w,
        height: 35.h, // Match filter icon height
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
            stops: const [0.0, 0.3, 1.0],
          ),
          borderRadius: BorderRadius.circular(17.r),
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
              blurRadius: 10,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Row(
          children: [
            // Dating Button
            Expanded(
              child: GestureDetector(
                onTap: () {
                  print('Dating mode selected');
                  // Call setMode to properly refresh profiles
                  controller.setMode('dating');
                },
                behavior: HitTestBehavior.opaque,
                child: Container(
                  height: 35.h,
                  decoration: BoxDecoration(
                    gradient: controller.currentMode.value == 'dating'
                        ? LinearGradient(
                            colors: [
                              themeController.lightPinkColor,
                              themeController.purpleColor,
                            ],
                          )
                        : null,
                    borderRadius: BorderRadius.circular(17.r),
                  ),
                  child: Center(
                    child: controller.currentMode.value == 'dating'
                        ? Icon(
                            Icons.favorite,
                            color: Colors.white,
                            size: 14.sp,
                          )
                        : Text(
                            'Dating',
                            style: TextStyle(
                              color: themeController.whiteColor.withValues(alpha: 0.7),
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ),
            ),
            // BFF Button
            Expanded(
              child: GestureDetector(
                onTap: () {
                  print('BFF mode selected');
                  // Call setMode to properly refresh profiles
                  controller.setMode('bff');
                },
                behavior: HitTestBehavior.opaque,
                child: Container(
                  height: 35.h,
                  decoration: BoxDecoration(
                    gradient: controller.currentMode.value == 'bff'
                        ? LinearGradient(
                            colors: [
                              themeController.bffPrimaryColor,
                              themeController.bffSecondaryColor,
                            ],
                          )
                        : null,
                    borderRadius: BorderRadius.circular(17.r),
                  ),
                  child: Center(
                    child: controller.currentMode.value == 'bff'
                        ? Icon(
                            Icons.people,
                            color: Colors.white,
                            size: 14.sp,
                          )
                        : Text(
                            'BFF',
                            style: TextStyle(
                              color: themeController.whiteColor.withValues(alpha: 0.7),
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}

class _FiltersSquare extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final ThemeController themeController = Get.find<ThemeController>();
    return Obx(() {
      // Get the current mode from DiscoverController if available
      bool isBFFMode = false;
      if (Get.isRegistered<DiscoverController>()) {
        final discoverController = Get.find<DiscoverController>();
        isBFFMode = discoverController.currentMode.value == 'bff';
      }
      
      return GestureDetector(
        onTap: () {
          _showFiltersSheet(context, themeController);
        },
        child: Container(
          width: 35.h,
          height: 35.h,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isBFFMode 
                  ? [themeController.bffPrimaryColor, themeController.bffSecondaryColor]
                  : [themeController.lightPinkColor, themeController.purpleColor],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.tune, color: Colors.white, size: 18.sp),
        ),
      );
    });
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
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              margin: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
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
              child: SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 16.h),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Filters',
                          style: TextStyle(
                            color: themeController.whiteColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 20.sp,
                          ),
                        ),
                        TextButton(
                          onPressed: () async {
                            controller.minAge.value = 18;
                            controller.maxAge.value = 99;
                            controller.maxDistanceKm.value = 100;
                            controller.gender.value = 'Everyone';
                            controller.selectedIntents.clear();
                            await controller.saveFilters();
                            await controller.reloadWithFilters();
                          },
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                          ),
                          child: Text(
                            'Reset',
                            style: TextStyle(
                              color: controller.currentMode.value == 'bff'
                                  ? themeController.bffPrimaryColor
                                  : themeController.lightPinkColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 14.sp,
                            ),
                          ),
                        )
                      ],
                    ),
                    SizedBox(height: 16.h),
                    
                    // Age Range
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Age range',
                          style: TextStyle(
                            color: themeController.whiteColor.withValues(alpha: 0.9),
                            fontWeight: FontWeight.w600,
                            fontSize: 15.sp,
                          ),
                        ),
                        Text(
                          '${controller.minAge.value} - ${controller.maxAge.value}',
                          style: TextStyle(
                            color: controller.currentMode.value == 'bff'
                                ? themeController.bffPrimaryColor
                                : themeController.lightPinkColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 14.sp,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: controller.currentMode.value == 'bff'
                            ? themeController.bffPrimaryColor
                            : themeController.lightPinkColor,
                        inactiveTrackColor: themeController.whiteColor.withValues(alpha: 0.15),
                        thumbColor: controller.currentMode.value == 'bff'
                            ? themeController.bffPrimaryColor
                            : themeController.lightPinkColor,
                        overlayColor: controller.currentMode.value == 'bff'
                            ? themeController.bffPrimaryColor.withValues(alpha: 0.2)
                            : themeController.lightPinkColor.withValues(alpha: 0.2),
                        trackHeight: 4.h,
                        thumbShape: RoundSliderThumbShape(enabledThumbRadius: 10.r),
                      ),
                      child: RangeSlider(
                        min: 18,
                        max: 99,
                        divisions: 81,
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
                    ),
                    SizedBox(height: 16.h),
                    
                    // Distance
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Distance',
                          style: TextStyle(
                            color: themeController.whiteColor.withValues(alpha: 0.9),
                            fontWeight: FontWeight.w600,
                            fontSize: 15.sp,
                          ),
                        ),
                        Text(
                          '${controller.maxDistanceKm.value.round()} km',
                          style: TextStyle(
                            color: controller.currentMode.value == 'bff'
                                ? themeController.bffPrimaryColor
                                : themeController.lightPinkColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 14.sp,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: controller.currentMode.value == 'bff'
                            ? themeController.bffPrimaryColor
                            : themeController.lightPinkColor,
                        inactiveTrackColor: themeController.whiteColor.withValues(alpha: 0.15),
                        thumbColor: controller.currentMode.value == 'bff'
                            ? themeController.bffPrimaryColor
                            : themeController.lightPinkColor,
                        overlayColor: controller.currentMode.value == 'bff'
                            ? themeController.bffPrimaryColor.withValues(alpha: 0.2)
                            : themeController.lightPinkColor.withValues(alpha: 0.2),
                        trackHeight: 4.h,
                        thumbShape: RoundSliderThumbShape(enabledThumbRadius: 10.r),
                      ),
                      child: Slider(
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
                    ),
                    SizedBox(height: 16.h),
                    
                    // Gender (only show in dating mode)
                    if (controller.currentMode.value == 'dating') ...[
                      Text(
                        'Gender',
                        style: TextStyle(
                          color: themeController.whiteColor.withValues(alpha: 0.9),
                          fontWeight: FontWeight.w600,
                          fontSize: 15.sp,
                        ),
                      ),
                      SizedBox(height: 12.h),
                      Wrap(
                        spacing: 8.w,
                        runSpacing: 10.h,
                        children: ['Everyone', 'Male', 'Female', 'Non-binary'].map((g) {
                          final bool isSelected = controller.gender.value == g;
                          return GestureDetector(
                            onTap: () async {
                              controller.gender.value = g;
                              await controller.saveFilters();
                              await controller.reloadWithFilters();
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? themeController.lightPinkColor.withValues(alpha: 0.2)
                                    : themeController.whiteColor.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(20.r),
                                border: Border.all(
                                  color: isSelected
                                      ? themeController.lightPinkColor
                                      : themeController.whiteColor.withValues(alpha: 0.2),
                                  width: 1.5,
                                ),
                              ),
                              child: Text(
                                g,
                                style: TextStyle(
                                  color: isSelected
                                      ? themeController.whiteColor
                                      : themeController.whiteColor.withValues(alpha: 0.8),
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                  fontSize: 14.sp,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      SizedBox(height: 16.h),
                    ],
                    
                    // Intent / Interests & Activities
                    Text(
                      controller.currentMode.value == 'bff' ? 'Interests & Activities' : 'Intent',
                      style: TextStyle(
                        color: themeController.whiteColor.withValues(alpha: 0.9),
                        fontWeight: FontWeight.w600,
                        fontSize: 15.sp,
                      ),
                    ),
                    SizedBox(height: 12.h),
                    Wrap(
                      spacing: 8.w,
                      runSpacing: 10.h,
                      children: (controller.currentMode.value == 'bff' 
                          ? [
                              'Music', 'Movies', 'Sports', 'Fitness',
                              'Travel', 'Cooking', 'Gaming', 'Coffee'
                            ] 
                          : intents).map((i) {
                        final bool isSelected = controller.selectedIntents.contains(i);
                        return GestureDetector(
                          onTap: () async {
                            if (isSelected) {
                              controller.selectedIntents.remove(i);
                            } else {
                              controller.selectedIntents.add(i);
                            }
                            await controller.saveFilters();
                            await controller.reloadWithFilters();
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? (controller.currentMode.value == 'bff'
                                      ? themeController.bffPrimaryColor.withValues(alpha: 0.2)
                                      : themeController.lightPinkColor.withValues(alpha: 0.2))
                                  : themeController.whiteColor.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(20.r),
                              border: Border.all(
                                color: isSelected
                                    ? (controller.currentMode.value == 'bff'
                                        ? themeController.bffPrimaryColor
                                        : themeController.lightPinkColor)
                                    : themeController.whiteColor.withValues(alpha: 0.2),
                                width: 1.5,
                              ),
                            ),
                            child: Text(
                              i,
                              style: TextStyle(
                                color: isSelected
                                    ? themeController.whiteColor
                                    : themeController.whiteColor.withValues(alpha: 0.8),
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                fontSize: 14.sp,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    SizedBox(height: 16.h),
                    
                    // Life Stage (only for BFF mode)
                    if (controller.currentMode.value == 'bff') ...[
                      Text(
                        'Life Stage',
                        style: TextStyle(
                          color: themeController.whiteColor.withValues(alpha: 0.9),
                          fontWeight: FontWeight.w600,
                          fontSize: 15.sp,
                        ),
                      ),
                      SizedBox(height: 12.h),
                      Wrap(
                        spacing: 8.w,
                        runSpacing: 10.h,
                        children: ['Student', 'Working Professional', 'New to City', 'Parent'].map((stage) {
                          final bool isSelected = controller.selectedIntents.contains(stage);
                          return GestureDetector(
                            onTap: () async {
                              if (isSelected) {
                                controller.selectedIntents.remove(stage);
                              } else {
                                controller.selectedIntents.add(stage);
                              }
                              await controller.saveFilters();
                              await controller.reloadWithFilters();
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? themeController.bffPrimaryColor.withValues(alpha: 0.2)
                                    : themeController.whiteColor.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(20.r),
                                border: Border.all(
                                  color: isSelected
                                      ? themeController.bffPrimaryColor
                                      : themeController.whiteColor.withValues(alpha: 0.2),
                                  width: 1.5,
                                ),
                              ),
                              child: Text(
                                stage,
                                style: TextStyle(
                                  color: isSelected
                                      ? themeController.whiteColor
                                      : themeController.whiteColor.withValues(alpha: 0.8),
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                  fontSize: 14.sp,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      SizedBox(height: 16.h),
                      
                      // Availability (only for BFF mode)
                      Text(
                        'Availability',
                        style: TextStyle(
                          color: themeController.whiteColor.withValues(alpha: 0.9),
                          fontWeight: FontWeight.w600,
                          fontSize: 15.sp,
                        ),
                      ),
                      SizedBox(height: 12.h),
                      Wrap(
                        spacing: 8.w,
                        runSpacing: 10.h,
                        children: ['Weekends', 'Weekday Evenings', 'Morning Person', 'Night Owl'].map((avail) {
                          final bool isSelected = controller.selectedIntents.contains(avail);
                          return GestureDetector(
                            onTap: () async {
                              if (isSelected) {
                                controller.selectedIntents.remove(avail);
                              } else {
                                controller.selectedIntents.add(avail);
                              }
                              await controller.saveFilters();
                              await controller.reloadWithFilters();
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? themeController.bffPrimaryColor.withValues(alpha: 0.2)
                                    : themeController.whiteColor.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(20.r),
                                border: Border.all(
                                  color: isSelected
                                      ? themeController.bffPrimaryColor
                                      : themeController.whiteColor.withValues(alpha: 0.2),
                                  width: 1.5,
                                ),
                              ),
                              child: Text(
                                avail,
                                style: TextStyle(
                                  color: isSelected
                                      ? themeController.whiteColor
                                      : themeController.whiteColor.withValues(alpha: 0.8),
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                  fontSize: 14.sp,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                    SizedBox(height: 16.h),
                  ],
                ),
              ),
            ),
              ),
            ),
          ),
        ));
      },
    );
  }
}
