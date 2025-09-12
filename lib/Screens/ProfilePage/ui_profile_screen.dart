import 'package:boliler_plate/Common/text_constant.dart';
import 'package:boliler_plate/Common/widget_constant.dart';
import 'package:boliler_plate/Screens/ProfilePage/controller_profile_screen.dart';
import 'package:boliler_plate/Screens/ProfilePage/ui_edit_profile_screen.dart';
import 'package:boliler_plate/ThemeController/theme_controller.dart';
import 'package:boliler_plate/services/supabase_service.dart';
import 'package:boliler_plate/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:gradient_borders/box_borders/gradient_box_border.dart';
import '../Verification/ui_verification_screen.dart';
import '../WelcomePage/welcome_screen.dart';

class ProfileScreen extends StatelessWidget {
  ProfileScreen({super.key});

  final ProfileController controller = Get.put(ProfileController());
  final ThemeController themeController = Get.find<ThemeController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(() {
        return Container(
          width: Get.width,
          height: Get.height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [themeController.blackColor, themeController.bgGradient1, themeController.blackColor],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SingleChildScrollView(
            child: screenPadding(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  heightBox(10),
                  // Logout button in top right
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        onPressed: () async {
                          Get.dialog(
                            AlertDialog(
                              title: Text('Logout'),
                              content: Text('Are you sure you want to logout?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Get.back(),
                                  child: Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () async {
                                    try {
                                      Get.back();
                                      await SupabaseService.signOut();
                                      await Future.delayed(const Duration(milliseconds: 250));
                                      // Extra safety: clear browser storage on web
                                      try {
                                        // ignore: undefined_prefixed_name
                                        // This block will only be relevant on web; it is safe elsewhere
                                      } catch (_) {}
                                      Get.reset();
                                      Get.offAll(() => MyApp());
                                    } catch (e) {
                                      print('Logout error: $e');
                                      // Fallback: still restart app flow
                                      Get.offAll(() => MyApp());
                                    }
                                  },
                                  child: Text('Logout'),
                                ),
                              ],
                            ),
                          );
                        },
                        icon: Icon(
                          Icons.logout,
                          color: themeController.lightPinkColor,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Container(
                        height: 75.h,
                        width: 75.h,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          image: DecorationImage(
                            image: controller.myPhotos.isNotEmpty 
                              ? NetworkImage(controller.myPhotos.first)
                              : NetworkImage('https://images.stockcake.com/public/a/3/7/a372ef04-fa6c-49f8-bf42-d89f023edff5_large/handsome-man-posing-stockcake.jpg'),
                            fit: BoxFit.cover,
                          ),
                          border: GradientBoxBorder(
                            width: 2.w,
                            gradient: LinearGradient(
                              colors: [
                                themeController.lightPinkColor,
                                themeController.purpleColor,
                              ],
                            ),
                          ),
                        ),
                      ),
                      widthBox(15),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              TextConstant(
                                title: controller.userProfile['name'] ?? 'User',
                                fontSize: 21.sp,
                                fontWeight: FontWeight.w700,
                                color: themeController.whiteColor,
                              ),
                              TextConstant(
                                title: controller.userProfile['age']?.toString() ?? '25',
                                fontSize: 21.sp,
                                fontWeight: FontWeight.w700,
                                color: themeController.lightPinkColor,
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                color: themeController.lightPinkColor,
                              ),
                              widthBox(3),
                              TextConstant(
                                fontSize: 14.sp,
                                title: controller.userProfile['location'] ?? 'New York',
                                fontWeight: FontWeight.w400,
                                color: themeController.whiteColor,
                              ),
                            ],
                          ),
                          heightBox(4),

                          if (controller.isVerified.value)
                            Container(
                              alignment: Alignment.center,
                              padding: EdgeInsets.symmetric(
                                horizontal: 12.w,
                                vertical: 3.h,
                              ),
                              decoration: BoxDecoration(
                                color: themeController.purpleColor.withValues(
                                  alpha: 0.2,
                                ),
                                border: Border.all(
                                  color: themeController.purpleColor,
                                  width: 1.w,
                                ),
                                borderRadius: BorderRadius.circular(20.r),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                spacing: 4.w,
                                children: [
                                  Icon(
                                    Icons.check_circle_rounded,
                                    color: themeController.purpleColor,
                                    size: 16,
                                  ),
                                  TextConstant(
                                    title: 'Verified',
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: themeController.purpleColor,
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                  heightBox(20),
                  Row(
                    spacing: 10.w,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Container(
                          alignment: Alignment.center,
                          padding: EdgeInsets.all(12.w),
                          decoration: BoxDecoration(
                            color: themeController.lightPinkColor.withValues(
                              alpha: 0.2,
                            ),
                            border: Border.all(
                              color: themeController.lightPinkColor.withValues(
                                alpha: 0.6,
                              ),
                              width: 0.7.w,
                            ),
                            borderRadius: BorderRadius.circular(16.r),
                            boxShadow: [
                              BoxShadow(
                                color: themeController.lightPinkColor.withValues(alpha: 0.2),
                                blurRadius: 8,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            spacing: 2.h,
                            children: [
                              TextConstant(
                                title: controller.userProfile['matches_count']?.toString() ?? '0',
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: themeController.lightPinkColor,
                              ),
                              TextConstant(
                                fontSize: 11,
                                title: 'matches'.tr,
                                fontWeight: FontWeight.w400,
                                color: themeController.whiteColor,
                              ),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          alignment: Alignment.center,
                          padding: EdgeInsets.all(12.w),
                          decoration: BoxDecoration(
                            color: themeController.lightPinkColor.withValues(
                              alpha: 0.2,
                            ),
                            border: Border.all(
                              color: themeController.lightPinkColor.withValues(
                                alpha: 0.6,
                              ),
                              width: 0.7.w,
                            ),
                            borderRadius: BorderRadius.circular(16.r),
                            boxShadow: [
                              BoxShadow(
                                color: themeController.lightPinkColor.withValues(alpha: 0.2),
                                blurRadius: 8,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            spacing: 2.h,
                            children: [
                              TextConstant(
                                title: controller.userProfile['profile_views']?.toString() ?? '0',
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: themeController.purpleColor,
                              ),
                              TextConstant(
                                fontSize: 11,
                                title: 'profile_views'.tr,
                                fontWeight: FontWeight.w400,
                                color: themeController.whiteColor,
                              ),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          alignment: Alignment.center,
                          padding: EdgeInsets.all(12.w),
                          decoration: BoxDecoration(
                            color: themeController.lightPinkColor.withValues(
                              alpha: 0.2,
                            ),
                            border: Border.all(
                              color: themeController.lightPinkColor.withValues(
                                alpha: 0.6,
                              ),
                              width: 0.7.w,
                            ),
                            borderRadius: BorderRadius.circular(16.r),
                            boxShadow: [
                              BoxShadow(
                                color: themeController.lightPinkColor.withValues(alpha: 0.2),
                                blurRadius: 8,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            spacing: 2.h,
                            children: [
                              TextConstant(
                                title: controller.userProfile['active_chats']?.toString() ?? '0',
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: themeController.lightPinkColor,
                              ),
                              TextConstant(
                                fontSize: 11,
                                title: 'active_chats'.tr,
                                fontWeight: FontWeight.w400,
                                color: themeController.whiteColor,
                              ),
                            ],
                          ),
                        ),
                      ),
                      widthBox(10),
                      SizedBox(
                        width: 110.w,
                        child: ElevatedButton(
                          onPressed: () {
                            Get.to(() => VerificationScreen());
                          },
                          child: Text('Verify'),
                        ),
                      ),
                    ],
                  ),
                  heightBox(20),
                  TextConstant(
                    fontSize: 16,
                    title: 'my_photos'.tr,
                    fontWeight: FontWeight.bold,
                    color: themeController.whiteColor,
                  ),
                  heightBox(10),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 110 / 150,
                    ),
                    itemCount: controller.myPhotos.length,
                    itemBuilder: (context, index) {
                      return Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10.r),
                          border: Border.all(
                            color: themeController.purpleColor.withValues(
                              alpha: 0.4,
                            ),
                            width: 0.8.w,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10.r),
                          child: Image.network(
                            controller.myPhotos[index],
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                      );
                    },
                  ),
                  heightBox(20),
                  TextConstant(
                    fontSize: 16,
                    title: 'about_me'.tr,
                    fontWeight: FontWeight.bold,
                    color: themeController.whiteColor,
                  ),
                  heightBox(10),
                  Container(
                    width: Get.width,
                    alignment: Alignment.center,
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: themeController.purpleColor.withValues(alpha: 0.2),
                      border: Border.all(
                        color: themeController.purpleColor.withValues(alpha: 0.4),
                        width: 0.7.w,
                      ),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: TextConstant(
                      title: controller.userProfile['bio'] ?? controller.userProfile['description'] ?? 'Tell us about yourself...',
                      fontSize: 14,
                      height: 1.4,
                      softWrap: true,
                      fontWeight: FontWeight.w400,
                      color: themeController.whiteColor,
                    ),
                  ),
                  heightBox(20),
                  TextConstant(
                    fontSize: 16,
                    title: 'my_interests'.tr,
                    fontWeight: FontWeight.bold,
                    color: themeController.whiteColor,
                  ),
                  heightBox(10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: List.generate(controller.myInterestList.length, (index,) {
                      return IntrinsicWidth(
                        child: Container(
                          alignment: Alignment.center,
                          padding: EdgeInsets.symmetric(
                            horizontal: 12.w,
                            vertical: 6.h,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: themeController.purpleColor.withValues(
                                alpha: 0.4,
                              ),
                              width: 1.w,
                            ),
                            borderRadius: BorderRadius.circular(20.r),
                            gradient: LinearGradient(
                              colors: [
                                themeController.lightPinkColor.withValues(
                                  alpha: 0.2,
                                ),
                                themeController.purpleColor.withValues(
                                  alpha: 0.2,
                                ),
                              ],
                            ),
                          ),
                          child: TextConstant(
                            title: controller.myInterestList[index],
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: themeController.whiteColor,
                          ),
                        ),
                      );
                    }),
                  ),
                  heightBox(20),
                  elevatedButton2(
                    title: 'edit_profile'.tr,
                    icon: Icons.settings_rounded,
                    onPressed: () {
                      controller.textInputEmoji.value = false;
                      controller.textInputBold.value = false;
                      controller.textInputItalic.value = false;
                      Get.to(() => EditProfileScreen());
                    },
                  ),
                  heightBox(20),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}
