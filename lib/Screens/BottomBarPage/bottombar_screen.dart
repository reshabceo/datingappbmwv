import 'package:lovebug/Common/common_gradient_appbar.dart';
import 'package:lovebug/Common/text_constant.dart';
import 'package:lovebug/Common/widget_constant.dart';
import 'package:lovebug/Constant/app_assets.dart';
import 'package:lovebug/Screens/BottomBarPage/controller_bottombar_screen.dart';
import 'package:lovebug/ThemeController/theme_controller.dart';
import 'package:lovebug/Screens/ProfileFormPage/multi_step_profile_form.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:glassmorphism/glassmorphism.dart';

class BottombarScreen extends StatelessWidget {
  BottombarScreen({super.key});

  final BottomBarController controller = Get.put(BottomBarController());
  final ThemeController themeController = Get.find<ThemeController>();

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          if (controller.currentIndex.value != 0) {
            controller.currentIndex.value = 0;
          } else {
            SystemNavigator.pop(animated: true);
          }
        }
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
          systemNavigationBarColor: Colors.black,
          systemNavigationBarIconBrightness: Brightness.light,
        ),
        child: Scaffold(
          backgroundColor: themeController.blackColor,
          extendBodyBehindAppBar: true,
          appBar: PreferredSize(
            preferredSize: Size.fromHeight(kToolbarHeight),
            child: GradientCommonAppBar(
              isCenterTitle: false,
              isActionWidget: true,
              isNotificationShow: false,
            ),
          ),
          body: Container(
          width: Get.width,
          height: Get.height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                themeController.blackColor,
                themeController.bgGradient1,
                themeController.blackColor,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Stack(
            children: [
              // Main content column with safe padding at top so under-appbar spacing is clean
              Positioned.fill(
                child: Column(
                  children: [
                    SizedBox(height: kToolbarHeight),
                    Expanded(
                      child: Obx(() {
                        return IndexedStack(
                          index: controller.currentIndex.value,
                          children: controller.pages,
                        );
                      }),
                    ),
                  ],
                ),
              ),
              // Floating banner overlay on Discover only
              Obx(() => controller.currentIndex.value == 0 ? _buildProfileCompletionBanner() : SizedBox.shrink()),
            ],
          ),
        ),
        bottomNavigationBar: Obx(() {
          return GlassmorphicContainer(
            blur: 15,
            border: 0,
            height: 60.h,
            borderRadius: 0,
            width: Get.width,
            alignment: Alignment.center,
            linearGradient: LinearGradient(
              stops: [0.1, 1],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                themeController.whiteColor.withValues(alpha: 0.15),
                themeController.whiteColor.withValues(alpha: 0.05),
              ],
            ),
            borderGradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.white30, Colors.white10],
            ),

            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 17.w),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  buildNavItem(AppAssets.discover, 'discover'.tr, 0),
                  buildNavItem(AppAssets.stories, 'stories'.tr, 1),
                  buildNavItem(AppAssets.chat, 'chat'.tr, 2),
                  buildNavItem(AppAssets.profile, 'profile'.tr, 3),
                  buildNavItem(AppAssets.notificationIcon, 'activity'.tr, 4),
                ],
              ),
            ),
          );
        }),
        ),
      ),
    );
  }

  Widget buildNavItem(String icon, String title, int index) {
    return InkWell(
      splashColor: themeController.transparentColor,
      onTap: () {
        controller.currentIndex.value = index;
      },
      child: Column(
        spacing: 5.h,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          svgIconWidget(
            width: 17.h,
            height: 17.h,
            icon: icon,
            color: controller.currentIndex.value == index
                ? themeController.lightPinkColor
                : themeController.unselectedColor,
          ),
          TextConstant(
            title: title,
            fontSize: 12,
            color: controller.currentIndex.value == index
                ? themeController.lightPinkColor
                : themeController.unselectedColor,
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCompletionBanner() {
    return Obx(() {
      // For demo purposes, show banner if profile is incomplete
      // In production, check actual profile completion status
      final showBanner = controller.showProfileCompletionBanner.value;
      
      if (!showBanner) return SizedBox.shrink();
      
      return AnimatedPositioned(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        top: kToolbarHeight + 8.h,
        left: 8.w,
        right: 8.w,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 300),
          opacity: 1,
          child: GlassmorphicContainer(
              blur: 12,
              border: 0.5,
              borderRadius: 14.r,
              width: Get.width - 16.w,
              height: 64.h,
              linearGradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  themeController.whiteColor.withValues(alpha: 0.12),
                  themeController.whiteColor.withValues(alpha: 0.04),
                ],
              ),
              borderGradient: LinearGradient(
                colors: [
                  themeController.whiteColor.withValues(alpha: 0.25),
                  themeController.whiteColor.withValues(alpha: 0.10),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 12.w),
                child: Row(
          children: [
            Icon(
              Icons.person_add,
              color: themeController.lightPinkColor,
              size: 20.sp,
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Complete Your Profile',
                    style: TextStyle(
                      color: themeController.whiteColor,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Add photos and details to get more matches',
                    style: TextStyle(
                      color: themeController.whiteColor.withOpacity(0.7),
                      fontSize: 12.sp,
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () {
                Get.to(() => MultiStepProfileForm());
              },
              child: Text(
                'Complete',
                style: TextStyle(
                  color: themeController.lightPinkColor,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            IconButton(
              onPressed: () {
                controller.showProfileCompletionBanner.value = false;
              },
              icon: Icon(
                Icons.close,
                color: themeController.whiteColor.withOpacity(0.7),
                size: 16.sp,
              ),
            ),
          ],
                ),
              ),
            ),
          ),
        );
    });
  }
}
