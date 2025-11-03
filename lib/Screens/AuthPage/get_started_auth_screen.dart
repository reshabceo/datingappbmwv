import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lovebug/ThemeController/theme_controller.dart';
import 'package:lovebug/Common/widget_constant.dart';
import 'package:lovebug/Common/text_constant.dart';
import 'package:lovebug/Common/textfield_constant.dart';
import 'auth_controller.dart';
import 'package:lovebug/services/supabase_service.dart';
import 'package:lovebug/Screens/BottomBarPage/bottombar_screen.dart';
import 'package:lovebug/Language/language_model.dart';

class GetStartedAuthScreen extends StatelessWidget {
  GetStartedAuthScreen({super.key});

  final ThemeController theme = Get.find<ThemeController>();
  final TextEditingController emailController = TextEditingController();
  final AuthController authController = Get.put(AuthController());

  @override
  Widget build(BuildContext context) {
    // Failsafe: if a session already exists, don't show this screen
    final session = SupabaseService.client.auth.currentSession;
    if (session != null) {
      print('🔍 DEBUG: Auth screen detected active session; forcing navigation to main app');
      // Use immediate navigation instead of post-frame callback
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
      // Return a loading screen while navigating
      return Scaffold(
        backgroundColor: Color(theme.blackColor.value),
        body: Center(
          child: CircularProgressIndicator(color: theme.primaryColor.value),
        ),
      );
    }
    return Scaffold(
      backgroundColor: theme.blackColor,
      body: Container(
        width: Get.width,
        height: Get.height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [theme.blackColor, theme.bgGradient1, theme.blackColor],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                heightBox(40),
                // App logo with language button aligned to the right
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Logo
                    Image.asset(
                      'assets/images/lovebug_logo.png',
                      height: 48,
                    ),
                    SizedBox(width: 16.w),
                    // Language selection button aligned to the right of logo
                    Obx(
                      () => PopupMenuButton<String>(
                        onSelected: (String languageName) {
                          authController.selectedLanguage.value = languageName;
                          final languageCode = authController.languagesMap[languageName];
                          if (languageCode != null) {
                            setLocale(languageCode, authController.selectedLanguage.value);
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
                                title: authController.selectedLanguage.value,
                                color: theme.whiteColor,
                                fontSize: 14,
                              ),
                              SizedBox(width: 6.w),
                              Icon(
                                Icons.arrow_drop_down,
                                color: theme.whiteColor,
                                size: 18.sp,
                              ),
                            ],
                          ),
                        ),
                        itemBuilder: (BuildContext context) {
                          return authController.languagesMap.keys.map((String language) {
                            return PopupMenuItem<String>(
                              value: language,
                              child: TextConstant(
                                title: language,
                                color: theme.blackColor,
                              ),
                            );
                          }).toList();
                        },
                      ),
                    ),
                  ],
                ),
                heightBox(32),
                TextConstant(
                  title: 'log_in_or_sign_up',
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: theme.whiteColor,
                ),
                heightBox(32),

                // Email field (styled with existing component)
                TextFieldConstant(
                  height: 50.h,
                  hintFontSize: 14,
                  hintText: 'email_address',
                  hintFontWeight: FontWeight.bold,
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  borderColor: theme.whiteColor,
                  textColor: theme.whiteColor,
                ),

                heightBox(16),

                // Continue button (uses existing gradient button)
                SizedBox(
                  width: double.infinity,
                  height: 56.h,
                  child: elevatedButton(
                    title: 'continue',
                    textColor: theme.whiteColor,
                    borderRadius: 28,
                    onPressed: () async {
                      print('Continue button pressed');
                      final email = emailController.text.trim();
                      print('Email entered: $email');
                      if (email.isEmpty) {
                        Get.snackbar('Error', 'Please enter your email');
                        return;
                      }
                      
                      print('Starting email check...');
                      // Email check happens here directly
                      authController.emailController.text = email;
                      await authController.continueWithEmail();
                      print('Email check completed');
                    },
                  ),
                ),

                heightBox(24),

                Row(
                  children: [
                    Expanded(child: Divider(color: theme.whiteColor.withValues(alpha: 0.2))),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      child: TextConstant(
                        title: 'or',
                        color: theme.whiteColor.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    Expanded(child: Divider(color: theme.whiteColor.withValues(alpha: 0.2))),
                  ],
                ),

                heightBox(24),

                // Social login buttons with chat bubble gradient style
                Container(
                  width: double.infinity,
                  height: 56.h,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        theme.lightPinkColor.withValues(alpha: 0.15),
                        theme.purpleColor.withValues(alpha: 0.1),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(
                      color: theme.lightPinkColor.withValues(alpha: 0.3),
                      width: 1.w,
                    ),
                    borderRadius: BorderRadius.circular(28.r),
                    boxShadow: [
                      BoxShadow(
                        color: theme.lightPinkColor.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        authController.continueWithGoogle();
                      },
                      borderRadius: BorderRadius.circular(28.r),
                      child: Center(
                        child: TextConstant(
                          title: 'continue_google',
                          color: theme.whiteColor.withValues(alpha: 0.9),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
                heightBox(12),
                Container(
                  width: double.infinity,
                  height: 56.h,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        theme.lightPinkColor.withValues(alpha: 0.15),
                        theme.purpleColor.withValues(alpha: 0.1),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(
                      color: theme.lightPinkColor.withValues(alpha: 0.3),
                      width: 1.w,
                    ),
                    borderRadius: BorderRadius.circular(28.r),
                    boxShadow: [
                      BoxShadow(
                        color: theme.lightPinkColor.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        authController.continueWithApple();
                      },
                      borderRadius: BorderRadius.circular(28.r),
                      child: Center(
                        child: TextConstant(
                          title: 'continue_apple',
                          color: theme.whiteColor.withValues(alpha: 0.9),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),

                heightBox(40),

                Center(
                  child: Wrap(
                    spacing: 12.w,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      TextConstant(
                        title: 'terms_of_use',
                        color: theme.whiteColor.withValues(alpha: 0.7),
                      ),
                      TextConstant(
                        title: '|',
                        color: theme.whiteColor.withValues(alpha: 0.3),
                      ),
                      TextConstant(
                        title: 'privacy_policy',
                        color: theme.whiteColor.withValues(alpha: 0.7),
                      ),
                    ],
                  ),
                ),
                heightBox(12),
              ],
            ),
            ),
          ),
        ),
      ),
    );
  }

  // No custom provider button; reuse glassyButton to match app UI
}


