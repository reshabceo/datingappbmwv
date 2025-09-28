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
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 24.h),
              child: Column(
                children: [
                  // Top spacing for better balance
                  SizedBox(height: 80.h),
                
                  // App Logo
                  Image.asset(
                    'assets/images/lovebug_logo.png',
                    width: 280.w,
                    height: 120.w,
                    fit: BoxFit.contain,
                  ),
                  
                  SizedBox(height: 40.h),
                  
                  // Tagline with better typography
                  Text(
                    'Find Your Perfect Match',
                    style: TextStyle(
                      fontSize: 32.sp,
                      fontWeight: FontWeight.w700,
                      color: themeController.whiteColor,
                      letterSpacing: 0.5,
                      height: 1.2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  SizedBox(height: 20.h),
                  
                  // Description with better spacing
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    child: Text(
                      'Join millions of people finding love every day. Connect with amazing people and start your journey to find true love.',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w400,
                        color: themeController.whiteColor.withOpacity(0.9),
                        height: 1.6,
                        letterSpacing: 0.3,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  
                  SizedBox(height: 60.h),
                  
                  // Get Started Button with enhanced design
                  Container(
                    width: double.infinity,
                    height: 64.h,
                    margin: EdgeInsets.symmetric(horizontal: 20.w),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          themeController.lightPinkColor,
                          themeController.purpleColor,
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(32.r),
                      boxShadow: [
                        BoxShadow(
                          color: themeController.lightPinkColor.withOpacity(0.4),
                          blurRadius: 20.r,
                          offset: Offset(0, 8.h),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          Get.to(() => GetStartedAuthScreen());
                        },
                        borderRadius: BorderRadius.circular(32.r),
                        child: Center(
                          child: Text(
                            'Get Started',
                            style: TextStyle(
                              fontSize: 20.sp,
                              fontWeight: FontWeight.w700,
                              color: themeController.whiteColor,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  SizedBox(height: 30.h),
                  
                  // Sign In with better styling
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Already have an account? ',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w400,
                          color: themeController.whiteColor.withOpacity(0.8),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Get.to(() => GetStartedAuthScreen());
                        },
                        child: Text(
                          'Sign In',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                            color: themeController.lightPinkColor,
                            decoration: TextDecoration.underline,
                            decorationColor: themeController.lightPinkColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  // Bottom spacing for better balance
                  SizedBox(height: 40.h),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}