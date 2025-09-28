import 'package:lovebug/Common/text_constant.dart';
import 'package:lovebug/Common/widget_constant.dart';
import 'package:lovebug/Screens/ProfilePage/controller_profile_screen.dart';
import 'package:lovebug/Screens/ProfilePage/ui_edit_profile_screen.dart';
import 'package:lovebug/ThemeController/theme_controller.dart';
import 'package:lovebug/services/supabase_service.dart';
import 'package:lovebug/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:gradient_borders/box_borders/gradient_box_border.dart';
import 'package:image_picker/image_picker.dart';
import '../Verification/ui_verification_screen.dart';
import '../WelcomePage/welcome_screen.dart';
import '../Setting/Screens/setting_page.dart';
import '../Setting/Screens/account_screen.dart';

class _NoGlowBehavior extends ScrollBehavior {
  const _NoGlowBehavior();

  @override
  Widget buildOverscrollIndicator(BuildContext context, Widget child, ScrollableDetails details) {
    return child;
  }
}

class ProfileScreen extends StatelessWidget {
  ProfileScreen({super.key});

  final ProfileController controller = Get.put(ProfileController());
  final ThemeController themeController = Get.find<ThemeController>();

  @override
  Widget build(BuildContext context) {
    // Initialize controller if needed
    controller.loadUserProfile();
    
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
          child: ScrollConfiguration(
            behavior: const _NoGlowBehavior(),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: EdgeInsets.fromLTRB(15.w, 59.h, 15.w, 20.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with profile info and action buttons
                    Row(
                      children: [
                        Container(
                          height: 60.h,
                          width: 60.h,
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
                        widthBox(12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: TextConstant(
                                      title: controller.userProfile['name']?.toString() ?? 'User',
                                      fontSize: 18.sp,
                                      fontWeight: FontWeight.w700,
                                      color: themeController.whiteColor,
                                    ),
                                  ),
                                  TextConstant(
                                    title: ', ${controller.userProfile['age']?.toString() ?? '25'}',
                                    fontSize: 18.sp,
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
                                    size: 14.sp,
                                  ),
                                  widthBox(3),
                                  Flexible(
                                    child: TextConstant(
                                      fontSize: 12.sp,
                                      title: controller.userProfile['location']?.toString() ?? 'New York',
                                      fontWeight: FontWeight.w400,
                                      color: themeController.whiteColor,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    heightBox(16),
                    
                    // Stats row
                    Row(
                      spacing: 10.w,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Container(
                            alignment: Alignment.center,
                            padding: EdgeInsets.all(12.w),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  themeController.lightPinkColor.withValues(alpha: 0.2),
                                  themeController.purpleColor.withValues(alpha: 0.1),
                                ],
                              ),
                              border: Border.all(
                                color: themeController.lightPinkColor.withValues(alpha: 0.6),
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
                              gradient: LinearGradient(
                                colors: [
                                  themeController.lightPinkColor.withValues(alpha: 0.2),
                                  themeController.purpleColor.withValues(alpha: 0.1),
                                ],
                              ),
                              border: Border.all(
                                color: themeController.lightPinkColor.withValues(alpha: 0.6),
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
                              gradient: LinearGradient(
                                colors: [
                                  themeController.lightPinkColor.withValues(alpha: 0.2),
                                  themeController.purpleColor.withValues(alpha: 0.1),
                                ],
                              ),
                              border: Border.all(
                                color: themeController.lightPinkColor.withValues(alpha: 0.6),
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
                                  title: controller.userProfile['active_status']?.toString() ?? '0',
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: themeController.lightPinkColor,
                                ),
                                TextConstant(
                                  fontSize: 11,
                                  title: 'active'.tr,
                                  fontWeight: FontWeight.w400,
                                  color: themeController.whiteColor,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    heightBox(20),
                    
                    // My Photos section with simplified layout
                    TextConstant(
                      title: 'My Photos',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: themeController.whiteColor,
                    ),
                    
                    // Clean 2-column grid layout for photos
                    Padding(
                      padding: EdgeInsets.only(top: 15.h),
                      child: GridView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        padding: EdgeInsets.zero,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 1.0,
                        crossAxisSpacing: 8.w,
                        mainAxisSpacing: 8.h,
                      ),
                        itemCount: controller.myPhotos.length + 1, // +1 for add button
                        itemBuilder: (context, index) {
                          if (index == controller.myPhotos.length) {
                            // Add photo button
                            return GestureDetector(
                              onTap: () {
                                controller.pickImageFromCamera(ImageSource.gallery);
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      themeController.lightPinkColor.withValues(alpha: 0.1),
                                      themeController.purpleColor.withValues(alpha: 0.05),
                                    ],
                                  ),
                                  border: Border.all(
                                    color: themeController.lightPinkColor.withValues(alpha: 0.3),
                                    width: 1.w,
                                  ),
                                  borderRadius: BorderRadius.circular(12.r),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.add,
                                      color: themeController.lightPinkColor,
                                      size: 30.sp,
                                    ),
                                    heightBox(4),
                                    TextConstant(
                                      title: 'Add Photo',
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: themeController.whiteColor,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }
                          // Display actual photos
                          return Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12.r),
                              image: DecorationImage(
                                image: NetworkImage(controller.myPhotos[index]),
                                fit: BoxFit.cover,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    heightBox(16),
                    
                    // About Me section
                    TextConstant(
                      title: 'About Me',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: themeController.whiteColor,
                    ),
                    heightBox(8),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            themeController.purpleColor.withValues(alpha: 0.1),
                            themeController.lightPinkColor.withValues(alpha: 0.05),
                          ],
                        ),
                        border: Border.all(
                          color: themeController.purpleColor.withValues(alpha: 0.3),
                          width: 1.w,
                        ),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: TextConstant(
                        title: controller.userProfile['bio']?.toString() ?? 
                               controller.userProfile['description']?.toString() ?? 
                               'Tell us about yourself',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: themeController.whiteColor,
                      ),
                    ),
                    heightBox(16),
                    
                    // My Interests section
                    TextConstant(
                      title: 'My Interests',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: themeController.whiteColor,
                    ),
                    heightBox(8),
                    Wrap(
                      spacing: 8.w,
                      runSpacing: 8.h,
                      children: (controller.myInterestList.isNotEmpty 
                        ? controller.myInterestList 
                        : ['Sports', 'Travel', 'Food', 'Music', 'Movies']
                      ).map((interest) => Container(
                        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              themeController.lightPinkColor.withValues(alpha: 0.1),
                              themeController.purpleColor.withValues(alpha: 0.05),
                            ],
                          ),
                          border: Border.all(
                            color: themeController.lightPinkColor.withValues(alpha: 0.3),
                            width: 1.w,
                          ),
                          borderRadius: BorderRadius.circular(20.r),
                        ),
                        child: TextConstant(
                          title: interest,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: themeController.whiteColor,
                        ),
                      )).toList(),
                    ),
                    heightBox(20),
                    
                    // Edit Profile button
                    Container(
                      width: double.infinity,
                      height: 50.h,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            themeController.lightPinkColor,
                            themeController.purpleColor,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(25.r),
                        boxShadow: [
                          BoxShadow(
                            color: themeController.lightPinkColor.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            controller.textInputEmoji.value = false;
                            controller.textInputBold.value = false;
                            controller.textInputItalic.value = false;
                            Get.to(() => EditProfileScreen());
                          },
                          borderRadius: BorderRadius.circular(25.r),
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.settings_rounded,
                                  color: Colors.white,
                                  size: 20.sp,
                                ),
                                widthBox(8),
                                TextConstant(
                                  title: 'edit_profile'.tr,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    
                    // Settings and Logout buttons - styled like Edit Profile button
                    heightBox(16),
                    
                    // Settings button
                    Container(
                      width: double.infinity,
                      height: 50.h,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            themeController.lightPinkColor,
                            themeController.purpleColor,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(25.r),
                        boxShadow: [
                          BoxShadow(
                            color: themeController.lightPinkColor.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            print('🔄 DEBUG: Settings button tapped - START');
                            try {
                              print('🔄 DEBUG: About to show snackbar');
                              Get.snackbar('Settings', 'Opening settings...');
                              print('🔄 DEBUG: About to navigate to AccountSettingsScreen');
                              Get.to(() => AccountSettingsScreen());
                              print('🔄 DEBUG: Navigation completed');
                            } catch (e) {
                              print('❌ DEBUG: Settings button error: $e');
                              Get.snackbar('Error', 'Settings error: $e');
                            }
                          },
                          borderRadius: BorderRadius.circular(25.r),
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.settings,
                                  color: Colors.white,
                                  size: 20.sp,
                                ),
                                widthBox(8),
                                TextConstant(
                                  title: 'Settings',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    
                    heightBox(12),
                    
                    // Logout button
                    Container(
                      width: double.infinity,
                      height: 50.h,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.red,
                            Colors.red.shade700,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(25.r),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () async {
                            print('🔄 DEBUG: Logout button tapped');
                            Get.snackbar('Logout', 'Opening logout dialog...');
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
                                        print('🔄 DEBUG: Starting logout process...');
                                        await SupabaseService.signOut();
                                        print('✅ DEBUG: Logout successful, auth state should change');
                                        // The _AuthGate will automatically handle navigation when auth state changes
                                        // No need to manually navigate - the auth listener will trigger
                                      } catch (e) {
                                        print('❌ DEBUG: Logout error: $e');
                                        // Even if there's an error, try to clear local state
                                        Get.back();
                                      }
                                    },
                                    child: Text('Logout'),
                                  ),
                                ],
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(25.r),
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.logout,
                                  color: Colors.white,
                                  size: 20.sp,
                                ),
                                widthBox(8),
                                TextConstant(
                                  title: 'Logout',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ],
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
        );
      }),
    );
  }
}