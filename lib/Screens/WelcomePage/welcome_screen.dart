import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../Common/widget_constant.dart';
import '../../Common/text_constant.dart';
import '../../ThemeController/theme_controller.dart';
import '../AuthPage/auth_ui_screen.dart';
import '../AuthPage/get_started_auth_screen.dart';
import '../AuthPage/auth_controller.dart';
import 'package:lovebug/services/supabase_service.dart';
import 'package:lovebug/Screens/BottomBarPage/bottombar_screen.dart';
import 'package:lovebug/Language/language_model.dart';
import 'package:lovebug/Language/all_languages.dart';
import 'package:lovebug/global_data.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    print('🔍 DEBUG: WelcomeScreen build() called');
    // Failsafe: if a session exists, force navigation to main app
    final session = SupabaseService.client.auth.currentSession;
    if (session != null) {
      print('🔍 DEBUG: WelcomeScreen detected active session; forcing immediate navigation to main app');
      // Use immediate navigation and return loading screen
      Future.microtask(() {
        // Primary: GetX
        try { Get.offAll(() => BottombarScreen()); } catch (_) {}
        // Fallback: root Navigator
        try {
          Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => BottombarScreen()),
            (route) => false,
          );
        } catch (_) {}
      });
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }
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
                  // Language selection button at top right
                  Align(
                    alignment: Alignment.topRight,
                    child: Builder(
                      builder: (context) {
                        final controller = Get.put(AuthController());
                        return Obx(
                          () => PopupMenuButton<String>(
                            onSelected: (String languageName) {
                              controller.selectedLanguage.value = languageName;
                              final languageCode = controller.languagesMap[languageName];
                              if (languageCode != null) {
                                setLocale(languageCode, controller.selectedLanguage.value);
                              }
                            },
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20.r),
                              border: Border.all(color: Colors.white.withOpacity(0.2)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                TextConstant(
                                  title: controller.selectedLanguage.value,
                                  color: themeController.whiteColor,
                                  fontSize: 14,
                                ),
                                SizedBox(width: 6.w),
                                Icon(
                                  Icons.arrow_drop_down,
                                  color: themeController.whiteColor,
                                  size: 18.sp,
                                ),
                              ],
                            ),
                          ),
                          itemBuilder: (BuildContext context) {
                            return controller.languagesMap.keys.map((String language) {
                              return PopupMenuItem<String>(
                                value: language,
                                child: TextConstant(
                                  title: language,
                                  color: themeController.blackColor,
                                ),
                              );
                            }).toList();
                          },
                          ),
                        );
                      },
                    ),
                  ),
                  
                  // Top spacing for better balance
                  SizedBox(height: 40.h),
                
                  // App Logo
                  Image.asset(
                    'assets/images/lovebug_logo.png',
                    width: 280.w,
                    height: 120.w,
                    fit: BoxFit.contain,
                  ),
                  
                  SizedBox(height: 40.h),
                  
                  // Tagline with better typography
                  Obx(() {
                    final _ = lanCode.value; // Observe locale changes
                    return Text(
                      'find_your'.tr,
                      style: TextStyle(
                        fontSize: 32.sp,
                        fontWeight: FontWeight.w700,
                        color: themeController.whiteColor,
                        letterSpacing: 0.5,
                        height: 1.2,
                      ),
                      textAlign: TextAlign.center,
                    );
                  }),
                  
                  SizedBox(height: 20.h),
                  
                  // Description with better spacing
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    child: Obx(() {
                      final _ = lanCode.value; // Observe locale changes
                      return Text(
                        'connect_amazing_people'.tr,
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w400,
                          color: themeController.whiteColor.withOpacity(0.9),
                          height: 1.6,
                          letterSpacing: 0.3,
                        ),
                        textAlign: TextAlign.center,
                      );
                    }),
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
                          child: Obx(() {
                            final _ = lanCode.value; // Observe locale changes
                            return Text(
                              'get_started'.tr,
                              style: TextStyle(
                                fontSize: 20.sp,
                                fontWeight: FontWeight.w700,
                                color: themeController.whiteColor,
                                letterSpacing: 0.5,
                              ),
                            );
                          }),
                        ),
                      ),
                    ),
                  ),
                  
                  SizedBox(height: 30.h),
                  
                  // Sign In with better styling
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Obx(() {
                        final _ = lanCode.value; // Observe locale changes
                        return Text(
                          'already_have_account'.tr + ' ',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w400,
                            color: themeController.whiteColor.withOpacity(0.8),
                          ),
                        );
                      }),
                      GestureDetector(
                        onTap: () {
                          Get.to(() => GetStartedAuthScreen());
                        },
                        child: Obx(() {
                          final _ = lanCode.value; // Observe locale changes
                          return Text(
                            'sign_in'.tr,
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                              color: themeController.lightPinkColor,
                              decoration: TextDecoration.underline,
                              decorationColor: themeController.lightPinkColor,
                            ),
                          );
                        }),
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