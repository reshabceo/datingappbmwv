import 'package:lovebug/Common/text_constant.dart';
import 'package:lovebug/Common/widget_constant.dart';
import 'package:lovebug/Screens/ProfilePage/controller_profile_screen.dart';
import 'package:lovebug/Screens/DiscoverPage/controller_discover_screen.dart';
import 'package:lovebug/ThemeController/theme_controller.dart';
import 'package:lovebug/services/supabase_service.dart';
import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:gradient_borders/box_borders/gradient_box_border.dart';
import 'package:image_picker/image_picker.dart';
import '../Setting/Screens/account_screen.dart';
import '../VerificationPage/verification_screen.dart';
import '../../Widgets/optimized_toggle_button.dart';
import '../VerificationPage/test_verification_screen.dart';
import '../WelcomePage/welcome_screen.dart';

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
  
  // Get DiscoverController to access current mode
  DiscoverController get discoverController => Get.isRegistered<DiscoverController>() 
      ? Get.find<DiscoverController>() 
      : Get.put(DiscoverController());

  // Helper method to get gradient colors based on current mode
  List<Color> _getGradientColors() {
    return discoverController.currentMode.value == 'bff'
        ? [themeController.bffPrimaryColor, themeController.bffSecondaryColor]
        : [themeController.lightPinkColor, themeController.purpleColor];
  }

  // Helper method to get shadow color based on current mode
  Color _getShadowColor() {
    return discoverController.currentMode.value == 'bff'
        ? themeController.bffPrimaryColor.withValues(alpha: 0.3)
        : themeController.lightPinkColor.withValues(alpha: 0.3);
  }

  @override
  Widget build(BuildContext context) {
    controller.loadUserProfile();

    return Scaffold(
      body: Obx(() {
        return Container(
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
              // Scrollable content
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                bottom: 0,
                child: ScrollConfiguration(
                  behavior: const _NoGlowBehavior(),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(15.w, 60.h, 15.w, 20.h),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                           // Header with profile info (consistent in both modes)
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
                                         : const NetworkImage(
                                             'https://images.stockcake.com/public/a/3/7/a372ef04-fa6c-49f8-bf42-d89f023edff5_large/handsome-man-posing-stockcake.jpg'),
                                     fit: BoxFit.cover,
                                   ),
                                   border: GradientBoxBorder(
                                     width: 2.w,
                                     gradient: LinearGradient(
                                       colors: _getGradientColors(),
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
                                           color: discoverController.currentMode.value == 'bff'
                                               ? themeController.bffPrimaryColor
                                               : themeController.lightPinkColor,
                                         ),
                                       ],
                                     ),
                                     Row(
                                       children: [
                                         Icon(
                                           Icons.location_on,
                                           color: discoverController.currentMode.value == 'bff'
                                               ? themeController.bffPrimaryColor
                                               : themeController.lightPinkColor,
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
                                         widthBox(4),
                                         // Location update button
                                         GestureDetector(
                                           onTap: () async {
                                             // Show loading
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
                                                         color: discoverController.currentMode.value == 'bff'
                                                             ? themeController.bffPrimaryColor
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
                                             final success = await controller.updateLocation();
                                             
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
                                           child: Icon(
                                             Icons.my_location,
                                             color: discoverController.currentMode.value == 'bff'
                                                 ? themeController.bffPrimaryColor
                                                 : themeController.lightPinkColor,
                                             size: 16.sp,
                                           ),
                                         ),
                                         widthBox(8),
                                         // Verification badge integrated here
                                         _buildCompactVerificationBadge(controller, themeController),
                                       ],
                                     ),
                                   ],
                                 ),
                               ),
                             ],
                           ),
                          heightBox(20),
                          // --------------------
                          // View/Edit Toggle Buttons
                          // --------------------
                          Obx(
                            () => Container(
                              height: 50.h,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Colors.pink.withValues(alpha: 0.15),
                                    Colors.purple.withValues(alpha: 0.2),
                                    themeController.blackColor.withValues(alpha: 0.85),
                                  ],
                                  stops: const [0.0, 0.3, 1.0],
                                ),
                                borderRadius: BorderRadius.circular(25.r),
                                border: Border.all(
                                  color: discoverController.currentMode.value == 'bff'
                                      ? themeController.bffPrimaryColor.withValues(alpha: 0.35)
                                      : themeController.lightPinkColor.withValues(alpha: 0.35),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: discoverController.currentMode.value == 'bff'
                                        ? themeController.bffPrimaryColor.withValues(alpha: 0.15)
                                        : themeController.lightPinkColor.withValues(alpha: 0.15),
                                    blurRadius: 20,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  // View Button
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () {
                  if (controller.isEditMode.value) {
                    controller.cancelChanges();
                  }
                },
                                      behavior: HitTestBehavior.opaque,
                                      child: Container(
                                        height: 50.h,
                                        decoration: BoxDecoration(
                                          gradient: !controller.isEditMode.value
                                              ? LinearGradient(
                                                  colors: _getGradientColors(),
                                                )
                                              : null,
                                          borderRadius: BorderRadius.circular(25.r),
                                        ),
                                        child: Center(
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.visibility,
                                                color: !controller.isEditMode.value
                                                    ? Colors.white
                                                    : themeController.whiteColor.withValues(alpha: 0.7),
                                                size: 18.sp,
                                              ),
                                              widthBox(6),
                                              TextConstant(
                                                title: 'View',
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: !controller.isEditMode.value
                                                    ? Colors.white
                                                    : themeController.whiteColor.withValues(alpha: 0.7),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  // Edit Button
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () {
                  if (!controller.isEditMode.value) {
                    controller.toggleEditMode();
                  }
                },
                                      behavior: HitTestBehavior.opaque,
                                      child: Container(
                                        height: 50.h,
                                        decoration: BoxDecoration(
                                          gradient: controller.isEditMode.value
                                              ? LinearGradient(
                                                  colors: _getGradientColors(),
                                                )
                                              : null,
                                          borderRadius: BorderRadius.circular(25.r),
                                        ),
                                        child: Center(
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.edit,
                                                color: controller.isEditMode.value
                                                    ? Colors.white
                                                    : themeController.whiteColor.withValues(alpha: 0.7),
                                                size: 18.sp,
                                              ),
                                              widthBox(6),
                                              TextConstant(
                                                title: 'Edit',
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: controller.isEditMode.value
                                                    ? Colors.white
                                                    : themeController.whiteColor.withValues(alpha: 0.7),
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
                           heightBox(20),
                           // --------------------
                           // Profile Content (View/Edit Mode)
                           // --------------------
                           Obx(() => controller.isEditMode.value
                               ? _buildEditModeContent(controller, themeController)
                               : _buildProfileCardView(controller, themeController)),
                          heightBox(20),
                          // --------------------
                          // Save/Cancel buttons (only visible in edit mode)
                          // --------------------
                          Obx(() => controller.isEditMode.value
                              ? Column(
                                  children: [
                                    heightBox(16),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Container(
                                            height: 50.h,
                                            decoration: BoxDecoration(
                                              color: Colors.transparent,
                                              borderRadius: BorderRadius.circular(25.r),
                                              border: Border.all(
                                                color: themeController.whiteColor.withValues(alpha: 0.3),
                                                width: 1.w,
                                              ),
                                            ),
                                            child: Material(
                                              color: Colors.transparent,
                                              child: InkWell(
                                                onTap: () => controller.cancelChanges(),
                                                borderRadius: BorderRadius.circular(25.r),
                                                child: Center(
                                                  child: TextConstant(
                                                    title: 'Cancel',
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w600,
                                                    color: themeController.whiteColor.withValues(alpha: 0.8),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        widthBox(12),
                                        Expanded(
                                          child: Container(
                                            height: 50.h,
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: _getGradientColors(),
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                              ),
                                              borderRadius: BorderRadius.circular(25.r),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: _getShadowColor(),
                                                  blurRadius: 8,
                                                  offset: const Offset(0, 4),
                                                ),
                                              ],
                                            ),
                                            child: Material(
                                              color: Colors.transparent,
                                              child: InkWell(
                                                onTap: () => controller.saveChanges(),
                                                borderRadius: BorderRadius.circular(25.r),
                                                child: Center(
                                                  child: TextConstant(
                                                    title: 'Save Changes',
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w600,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                )
                              : const SizedBox.shrink()),
                          heightBox(16),
                          // --------------------
                          // Settings Button
                          // --------------------
                          Container(
                            width: double.infinity,
                            height: 50.h,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: _getGradientColors(),
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(25.r),
                              boxShadow: [
                                BoxShadow(
                                  color: _getShadowColor(),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  Get.to(() => AccountSettingsScreen());
                                },
                                borderRadius: BorderRadius.circular(25.r),
                                child: Center(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.settings, color: Colors.white, size: 20.sp),
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
                          // --------------------
                          // Logout Button
                          // --------------------
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
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () async {
                                  Get.dialog(
                                    Dialog(
                                      backgroundColor: Colors.transparent,
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(22.r),
                                        child: BackdropFilter(
                                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                          child: Container(
                                            padding: EdgeInsets.all(24.w),
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                                colors: discoverController.currentMode.value == 'bff'
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
                                              borderRadius: BorderRadius.circular(22.r),
                                              border: Border.all(
                                                color: discoverController.currentMode.value == 'bff'
                                                    ? themeController.bffPrimaryColor.withValues(alpha: 0.35)
                                                    : themeController.lightPinkColor.withValues(alpha: 0.35),
                                                width: 1.5,
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: discoverController.currentMode.value == 'bff'
                                                      ? themeController.bffPrimaryColor.withValues(alpha: 0.15)
                                                      : themeController.lightPinkColor.withValues(alpha: 0.15),
                                                  blurRadius: 20,
                                                  spreadRadius: 2,
                                                ),
                                              ],
                                            ),
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  'Logout',
                                                  style: TextStyle(
                                                    color: themeController.whiteColor,
                                                    fontSize: 22.sp,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                heightBox(16),
                                                Text(
                                                  'Are you sure you want to logout?',
                                                  style: TextStyle(
                                                    color: themeController.whiteColor.withValues(alpha: 0.8),
                                                    fontSize: 15.sp,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                                heightBox(24),
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
                                                    widthBox(12),
                                                    Expanded(
                                                      child: GestureDetector(
                                                        onTap: () async {
                                                          try {
                                                            Get.back();
                                                            
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
                                                                        color: Colors.red,
                                                                      ),
                                                                      SizedBox(height: 10),
                                                                      Text(
                                                                        'Signing out...',
                                                                        style: TextStyle(
                                                                          color: Colors.white,
                                                                          fontSize: 14,
                                                                        ),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                ),
                                                              ),
                                                              barrierDismissible: false,
                                                            );
                                                            
                                                            await SupabaseService.signOut();
                                                            
                                                            // Close loading dialog
                                                            Get.back();
                                                            
                                                            // Force navigation to welcome screen after logout
                                                            Get.offAll(() => WelcomeScreen());
                                                          } catch (e) {
                                                            print('❌ Error during logout: $e');
                                                            // Close loading dialog if it's still open
                                                            if (Get.isDialogOpen == true) {
                                                              Get.back();
                                                            }
                                                            // Even if signOut fails, navigate to welcome screen
                                                            Get.offAll(() => WelcomeScreen());
                                                          }
                                                        },
                                                        child: Container(
                                                          padding: EdgeInsets.symmetric(vertical: 12.h),
                                                          decoration: BoxDecoration(
                                                            gradient: LinearGradient(
                                                              colors: [Colors.red.shade600, Colors.red.shade800],
                                                            ),
                                                            borderRadius: BorderRadius.circular(20.r),
                                                            border: Border.all(
                                                              color: Colors.red.withValues(alpha: 0.5),
                                                              width: 1.5,
                                                            ),
                                                          ),
                                                          child: const Text(
                                                            'Logout',
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
                                  );
                                },
                                borderRadius: BorderRadius.circular(25.r),
                                child: Center(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.logout, color: Colors.white, size: 20.sp),
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
              ),

            ],
          ),
        );
      }),
    );
  }

  // Build Profile Card View (how others see your profile)
  Widget _buildProfileCardView(ProfileController controller, ThemeController themeController) {
    return Container(
      height: Get.height * 0.6,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: discoverController.currentMode.value == 'bff'
              ? themeController.bffPrimaryColor.withValues(alpha: 0.3)
              : themeController.lightPinkColor.withValues(alpha: 0.3),
          width: 1.w,
        ),
        boxShadow: [
          BoxShadow(
            color: discoverController.currentMode.value == 'bff'
                ? themeController.bffPrimaryColor.withValues(alpha: 0.1)
                : themeController.lightPinkColor.withValues(alpha: 0.1),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20.r),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background image (first photo or default)
            controller.myPhotos.isNotEmpty
                ? Image.network(
                    controller.myPhotos.first,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: discoverController.currentMode.value == 'bff'
                                ? [
                                    themeController.bffPrimaryColor.withValues(alpha: 0.3),
                                    themeController.bffSecondaryColor.withValues(alpha: 0.3),
                                  ]
                                : [
                                    themeController.lightPinkColor.withValues(alpha: 0.3),
                                    themeController.purpleColor.withValues(alpha: 0.3),
                                  ],
                          ),
                        ),
                      );
                    },
                  )
                : Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: discoverController.currentMode.value == 'bff'
                            ? [
                                themeController.bffPrimaryColor.withValues(alpha: 0.3),
                                themeController.bffSecondaryColor.withValues(alpha: 0.3),
                              ]
                            : [
                                themeController.lightPinkColor.withValues(alpha: 0.3),
                                themeController.purpleColor.withValues(alpha: 0.3),
                              ],
                      ),
                    ),
                  ),
            // Bottom overlay with profile info
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: Get.height * 0.25,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(20.r),
                    bottomRight: Radius.circular(20.r),
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0.0, 0.3, 0.7, 1.0],
                    colors: [
                      Colors.transparent,
                      Colors.white.withValues(alpha: 0.5),
                      Colors.white.withValues(alpha: 0.8),
                      Colors.white.withValues(alpha: 0.95),
                    ],
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.all(16.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Name and Age
                      Row(
                        children: [
                          Flexible(
                            child: TextConstant(
                              title: controller.userProfile['name']?.toString() ?? 'User',
                              fontSize: 24.sp,
                              fontWeight: FontWeight.bold,
                              color: themeController.blackColor,
                            ),
                          ),
                          TextConstant(
                            title: ', ${controller.userProfile['age']?.toString() ?? '25'}',
                            fontSize: 24.sp,
                            fontWeight: FontWeight.bold,
                            color: discoverController.currentMode.value == 'bff'
                                ? themeController.bffPrimaryColor
                                : themeController.lightPinkColor,
                          ),
                          SizedBox(width: 8.w),
                          // Compact verification badge in profile card
                          _buildCompactVerificationBadge(controller, themeController),
                        ],
                      ),
                      heightBox(8),
                      // Location
                      Row(
                        children: [
                          Icon(Icons.location_on,
                              color: themeController.blackColor, size: 14.sp),
                          SizedBox(width: 4.w),
                          TextConstant(
                            title: controller.userProfile['location']?.toString() ?? 'New York',
                            fontSize: 13.sp,
                            color: themeController.blackColor,
                          ),
                        ],
                      ),
                      heightBox(10),
                      // Bio/Description
                      Flexible(
                        child: Container(
                          padding: EdgeInsets.all(10.w),
                          decoration: BoxDecoration(
                            color: (discoverController.currentMode.value == 'bff'
                                ? themeController.bffPrimaryColor
                                : themeController.lightPinkColor).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10.r),
                            border: Border.all(
                              color: (discoverController.currentMode.value == 'bff'
                                  ? themeController.bffPrimaryColor
                                  : themeController.lightPinkColor).withValues(alpha: 0.2),
                              width: 0.5.w,
                            ),
                          ),
                          child: TextConstant(
                            title: controller.userProfile['bio']?.toString() ??
                                controller.userProfile['description']?.toString() ??
                                'Tell us about yourself',
                            fontSize: 12.sp,
                            height: 1.3,
                            fontWeight: FontWeight.w400,
                            softWrap: true,
                            color: themeController.blackColor,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      heightBox(10),
                      // Interests/Hobbies
                      Wrap(
                        spacing: 6.w,
                        runSpacing: 6.h,
                        children: (controller.myInterestList.isNotEmpty
                                ? controller.myInterestList.take(3)
                                : ['Music', 'Sports', 'Travel'])
                            .map((interest) {
                          return Container(
                            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: discoverController.currentMode.value == 'bff'
                                    ? [
                                        themeController.bffPrimaryColor.withValues(alpha: 0.4),
                                        themeController.bffPrimaryColor.withValues(alpha: 0.2),
                                      ]
                                    : [
                                        themeController.lightPinkColor.withValues(alpha: 0.4),
                                        themeController.lightPinkColor.withValues(alpha: 0.2),
                                      ],
                              ),
                              borderRadius: BorderRadius.circular(15.r),
                              border: Border.all(
                                color: discoverController.currentMode.value == 'bff'
                                    ? themeController.bffPrimaryColor.withValues(alpha: 0.5)
                                    : themeController.lightPinkColor.withValues(alpha: 0.5),
                                width: 0.5.w,
                              ),
                            ),
                            child: TextConstant(
                              title: interest,
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w500,
                              color: themeController.blackColor,
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Build Edit Mode Content (current editable interface)
  Widget _buildEditModeContent(ProfileController controller, ThemeController themeController) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --------------------
        // My Photos
        // --------------------
        TextConstant(
          title: 'My Photos',
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: themeController.whiteColor,
        ),
        Padding(
          padding: EdgeInsets.only(top: 15.h),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.0,
              crossAxisSpacing: 8.w,
              mainAxisSpacing: 8.h,
            ),
            itemCount: controller.myPhotos.length + 1,
            itemBuilder: (context, index) {
              if (index == controller.myPhotos.length) {
                return GestureDetector(
                  onTap: () {
                    controller.pickImageFromCamera(ImageSource.gallery);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: discoverController.currentMode.value == 'bff'
                            ? [
                                themeController.bffPrimaryColor.withValues(alpha: 0.1),
                                themeController.bffSecondaryColor.withValues(alpha: 0.05),
                              ]
                            : [
                                themeController.lightPinkColor.withValues(alpha: 0.1),
                                themeController.purpleColor.withValues(alpha: 0.05),
                              ],
                      ),
                      border: Border.all(
                        color: discoverController.currentMode.value == 'bff'
                            ? themeController.bffPrimaryColor.withValues(alpha: 0.3)
                            : themeController.lightPinkColor.withValues(alpha: 0.3),
                        width: 1.w,
                      ),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add,
                          color: discoverController.currentMode.value == 'bff'
                              ? themeController.bffPrimaryColor
                              : themeController.lightPinkColor,
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
        // --------------------
        // About Me
        // --------------------
        TextConstant(
          title: 'About Me',
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: themeController.whiteColor,
        ),
        heightBox(8),
        TextField(
          controller: controller.aboutController,
          maxLines: 4,
          style: TextStyle(
            color: themeController.whiteColor,
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: 'Tell us about yourself...',
            hintStyle: TextStyle(
              color: themeController.whiteColor.withValues(alpha: 0.5),
              fontSize: 14.sp,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(
                color: discoverController.currentMode.value == 'bff'
                    ? themeController.bffSecondaryColor.withValues(alpha: 0.3)
                    : themeController.purpleColor.withValues(alpha: 0.3),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(
                color: discoverController.currentMode.value == 'bff'
                    ? themeController.bffSecondaryColor.withValues(alpha: 0.3)
                    : themeController.purpleColor.withValues(alpha: 0.3),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(
                color: discoverController.currentMode.value == 'bff'
                    ? themeController.bffSecondaryColor
                    : themeController.purpleColor,
              ),
            ),
            filled: true,
            fillColor: discoverController.currentMode.value == 'bff'
                ? themeController.bffSecondaryColor.withValues(alpha: 0.1)
                : themeController.purpleColor.withValues(alpha: 0.1),
            contentPadding: EdgeInsets.all(16.w),
          ),
        ),
        heightBox(16),
        // --------------------
        // My Interests
        // --------------------
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
                  : ['Sports', 'Travel', 'Food', 'Music', 'Movies'])
              .map((interest) => Container(
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: discoverController.currentMode.value == 'bff'
                            ? [
                                themeController.bffPrimaryColor.withValues(alpha: 0.1),
                                themeController.bffSecondaryColor.withValues(alpha: 0.05),
                              ]
                            : [
                                themeController.lightPinkColor.withValues(alpha: 0.1),
                                themeController.purpleColor.withValues(alpha: 0.05),
                              ],
                      ),
                      border: Border.all(
                        color: discoverController.currentMode.value == 'bff'
                            ? themeController.bffPrimaryColor.withValues(alpha: 0.3)
                            : themeController.lightPinkColor.withValues(alpha: 0.3),
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
                  ))
              .toList(),
        ),
      ],
    );
  }

  // Build Compact Verification Badge (for user info section)
  Widget _buildCompactVerificationBadge(ProfileController controller, ThemeController themeController) {
    return Obx(() {
      final verificationStatus = controller.userProfile['verification_status'] ?? 'unverified';
      
      Color badgeColor;
      String badgeText;
      IconData badgeIcon;
      bool isClickable = false;

      switch (verificationStatus) {
        case 'verified':
          badgeColor = Colors.green;
          badgeText = 'Verified';
          badgeIcon = Icons.verified;
          break;
        case 'pending':
          badgeColor = Colors.orange;
          badgeText = 'Pending';
          badgeIcon = Icons.hourglass_empty;
          break;
        case 'rejected':
          badgeColor = Colors.red;
          badgeText = 'Retry';
          badgeIcon = Icons.refresh;
          isClickable = true;
          break;
        default:
          badgeColor = Colors.grey;
          badgeText = 'Verify';
          badgeIcon = Icons.verified_user;
          isClickable = true;
      }

      return GestureDetector(
        onTap: isClickable ? () => Get.to(() => const VerificationScreen()) : null,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
          decoration: BoxDecoration(
            color: badgeColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: badgeColor.withOpacity(0.4),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                badgeIcon,
                color: badgeColor,
                size: 12.sp,
              ),
              SizedBox(width: 4.w),
              TextConstant(
                title: badgeText,
                fontSize: 10.sp,
                fontWeight: FontWeight.w600,
                color: badgeColor,
              ),
            ],
          ),
        ),
      );
    });
  }
}
