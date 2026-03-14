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
import 'package:lovebug/Screens/DiscoverPage/filter_widget.dart';
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
              ? (actions ?? 
              [
                // Add Dating/BFF toggle for discover page
                _buildModeToggle(),
                widthBox(8),
                // Replace settings gear with Filters square that opens bottom sheet via a global event
                _FiltersSquare(),
                widthBox(10),
              ])
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
    
    // Only wrap in Obx if DiscoverController is registered
    if (!Get.isRegistered<DiscoverController>()) {
      return GestureDetector(
        onTap: () {
          _showFiltersSheet(context, themeController);
        },
        child: Container(
          width: 35.h,
          height: 35.h,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [themeController.lightPinkColor, themeController.purpleColor],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.tune, color: Colors.white, size: 18.sp),
        ),
      );
    }
    
    return Obx(() {
      // Get the current mode from DiscoverController
      final discoverController = Get.find<DiscoverController>();
      final isBFFMode = discoverController.currentMode.value == 'bff';
      
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
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: const FilterWidget(),
        );
      },
    );
  }
}
