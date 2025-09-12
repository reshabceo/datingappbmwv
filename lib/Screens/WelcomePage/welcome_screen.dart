import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../Common/widget_constant.dart';
import '../../ThemeController/theme_controller.dart';
import '../AuthPage/auth_ui_screen.dart';
import '../AuthPage/get_started_auth_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeController themeController = Get.find<ThemeController>();

    return AnnotatedRegion<SystemUiOverlayStyle>(
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
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.all(24.w),
              child: Column(
                children: [
                  // Top spacing
                  SizedBox(height: 60.h),
                
                  // App Logo
                  Container(
                    width: 120.w,
                    height: 120.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          themeController.lightPinkColor,
                          themeController.purpleColor,
                        ],
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '💕',
                        style: TextStyle(fontSize: 50.sp),
                      ),
                    ),
                  ),
                  
                  SizedBox(height: 40.h),
                  
                  // App Name
                  Text(
                    'Love Bug 💕',
                    style: TextStyle(
                      fontSize: 36.sp,
                      fontWeight: FontWeight.bold,
                      color: themeController.whiteColor,
                    ),
                  ),
                  
                  SizedBox(height: 16.h),
                  
                  // Tagline
                  Text(
                    'Find Your Perfect Match',
                    style: TextStyle(
                      fontSize: 24.sp,
                      fontWeight: FontWeight.w600,
                      color: themeController.whiteColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  SizedBox(height: 16.h),
                  
                  // Description
                  Text(
                    'Join millions of people finding love every day. Connect with amazing people and start your journey to find true love.',
                    style: TextStyle(
                      fontSize: 16.sp,
                      color: themeController.whiteColor.withOpacity(0.8),
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  SizedBox(height: 80.h),
                  
                  // Get Started Button
                  SizedBox(
                    width: double.infinity,
                    height: 56.h,
                    child: elevatedButton(
                      title: 'Get Started',
                      textColor: themeController.whiteColor,
                      borderRadius: 28,
                      onPressed: () {
                        Get.to(() => GetStartedAuthScreen());
                      },
                    ),
                  ),
                  
                  SizedBox(height: 24.h),
                  
                  // Already have account
                  Wrap(
                    alignment: WrapAlignment.center,
                    children: [
                      Text(
                        'Already have an account? ',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: themeController.whiteColor.withOpacity(0.7),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Get.to(() => GetStartedAuthScreen());
                        },
                        child: Text(
                          'Sign In',
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: themeController.lightPinkColor,
                            fontWeight: FontWeight.w600,
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
  }
}