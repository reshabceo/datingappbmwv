import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:lovebug/Common/glass_butto.dart';
import 'package:lovebug/Common/text_constant.dart';
import 'package:lovebug/Common/widget_constant.dart';
import 'package:lovebug/Language/language_model.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lovebug/Common/textfield_constant.dart';
import 'package:lovebug/Screens/AuthPage/auth_controller.dart';
import 'package:lovebug/ThemeController/theme_controller.dart';
import 'package:lovebug/services/supabase_service.dart';
import 'package:lovebug/Screens/BottomBarPage/bottombar_screen.dart';

class AuthScreen extends StatelessWidget {
  final String? prefillEmail;
  final bool isPasswordMode; // Show password field for existing users
  final bool isSignupMode; // Show signup fields for new users
  final bool isOAuthMode; // Show OAuth options for users who signed up with OAuth
  final String? oauthProvider; // Which OAuth provider (google, apple)
  AuthScreen({super.key, this.prefillEmail, this.isPasswordMode = false, this.isSignupMode = false, this.isOAuthMode = false, this.oauthProvider});

  final AuthController controller = Get.put(AuthController());
  final ThemeController themeController = Get.find<ThemeController>();

  @override
  Widget build(BuildContext context) {
    // Failsafe: if a session already exists, don't show this screen
    final session = SupabaseService.client.auth.currentSession;
    if (session != null) {
      print('🔍 DEBUG: AuthScreen detected active session; forcing immediate navigation to main app');
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
    
    // Initialize email mode and prefill when arriving from GetStarted
    controller.authMode.value = 'email';
    if ((prefillEmail ?? '').isNotEmpty) {
      controller.emailController.text = prefillEmail!;
    }
    
    // Set the correct state based on the mode parameters
    if (isPasswordMode) {
      controller.isExistingEmail.value = true;
      controller.isSignupMode.value = false;
      controller.didProbeEmail.value = true;
    } else if (isSignupMode) {
      controller.isExistingEmail.value = false;
      controller.isSignupMode.value = true;
      controller.didProbeEmail.value = true;
    } else if (isOAuthMode) {
      controller.isExistingEmail.value = true;
      controller.isSignupMode.value = false;
      controller.didProbeEmail.value = true;
    }
    final bool hideProviders = false; // Always show OAuth providers
    
    return Scaffold(
      body: Container(
        width: Get.width,
        height: Get.height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [themeController.blackColor, themeController.bgGradient1, themeController.blackColor],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: screenPadding(
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: Column(
              children: [
                screenPadding(
                  customPadding: EdgeInsets.only(top: 30.h),
                  child: Align(
                    alignment: Alignment.topRight,
                    child: Obx(
                      () => PopupMenuButton<String>(
                        onSelected: (String languageName) {
                          controller.selectedLanguage.value = languageName;
                          final languageCode = controller.languagesMap[languageName];
                          if (languageCode != null) {
                            setLocale(languageCode, controller.selectedLanguage.value);
                          }
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
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
                                fontSize: 12,
                              ),
                              Icon(
                                Icons.arrow_drop_down,
                                color: themeController.whiteColor,
                                size: 16.sp,
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
                    ),
                  ),
                ),
                heightBox(40),
                screenPadding(
                  child: Column(
                    children: [
                      // App logo
                      Image.asset(
                        'assets/images/lovebug_logo.png',
                        height: 48,
                      ),
                      heightBox(16),
                      TextConstant(
                        title: 'Welcome Back',
                        color: themeController.whiteColor,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                      heightBox(8),
                      TextConstant(
                        title: 'Find your perfect match with LoveBug',
                        color: themeController.greyColor,
                        fontSize: 16,
                      ),
                    ],
                  ),
                ),
                heightBox(40),
                
                // Email Input Field
                screenPadding(
                  child: Column(
                    children: [
                      TextFieldConstant(
                        height: 44,
                        hintFontSize: 14,
                        hintText: 'Email Address',
                        hintFontWeight: FontWeight.bold,
                        keyboardType: TextInputType.emailAddress,
                        controller: controller.emailController,
                        borderColor: themeController.whiteColor,
                        textColor: themeController.whiteColor,
                      ),
                      heightBox(16),
                      Obx(() {
                        if (controller.isSignupMode.value) {
                          return Column(
                            children: [
                              TextFieldConstant(
                                height: 44.h,
                                hintFontSize: 14,
                                hintText: 'Set password',
                                hintFontWeight: FontWeight.bold,
                                obscureText: true,
                                controller: controller.passwordController,
                                borderColor: themeController.whiteColor,
                                textColor: themeController.whiteColor,
                              ),
                              heightBox(12),
                              TextFieldConstant(
                                height: 44.h,
                                hintFontSize: 14,
                                hintText: 'Confirm password',
                                hintFontWeight: FontWeight.bold,
                                obscureText: true,
                                controller: controller.confirmPasswordController,
                                borderColor: themeController.whiteColor,
                                textColor: themeController.whiteColor,
                              ),
                            ],
                          );
                        } else if (controller.isExistingEmail.value) {
                          return TextFieldConstant(
                            height: 44.h,
                            hintFontSize: 14,
                            hintText: 'Password',
                            hintFontWeight: FontWeight.bold,
                            obscureText: true,
                            controller: controller.passwordController,
                            borderColor: themeController.whiteColor,
                            textColor: themeController.whiteColor,
                          );
                        }
                        return SizedBox.shrink();
                      }),
                      // Add "Use verification code" and "Send magic link" for existing users
                      Obx(() {
                        if (controller.isExistingEmail.value) {
                          return Column(
                            children: [
                              heightBox(12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  TextButton(
                                    onPressed: () {
                                      controller.startEmailOtp();
                                    },
                                    child: Text(
                                      'Use verification code',
                                      style: TextStyle(
                                        color: themeController.lightPinkColor,
                                        fontSize: 12.sp,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      controller.sendMagicLink();
                                    },
                                    child: Text(
                                      'Send magic link',
                                      style: TextStyle(
                                        color: themeController.lightPinkColor,
                                        fontSize: 12.sp,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          );
                        }
                        return SizedBox.shrink();
                      }),
                    ],
                  ),
                  customPadding: EdgeInsets.only(top: 20.h),
                ),
                heightBox(20),
                
                // Email authentication flow
                Column(
                  children: [
                    Obx(() => elevatedButton(
                          height: 56.h,
                          borderRadius: 28,
                          title: controller.isSignupMode.value
                              ? 'Sign up'
                              : controller.isExistingEmail.value
                                  ? (isOAuthMode ? 'Continue with ${oauthProvider?.toUpperCase() ?? 'OAuth'}' : 'Sign in')
                                  : 'Continue',
                          textColor: themeController.whiteColor,
                          onPressed: controller.isLoading.value
                              ? null
                              : () {
                                  if (controller.isSignupMode.value) {
                                    controller.signUpWithEmail();
                                  } else if (controller.isExistingEmail.value) {
                                    if (isOAuthMode) {
                                      if (oauthProvider == 'google') {
                                        controller.signInWithGoogle();
                                      } else if (oauthProvider == 'apple') {
                                        controller.continueWithApple();
                                      }
                                    } else {
                                      controller.signInWithPassword();
                                    }
                                  } else {
                                    controller.continueWithEmail();
                                  }
                                },
                          colorsGradient: [
                            themeController.lightPinkColor,
                            themeController.purpleColor,
                          ],
                        )),
                    heightBox(24),
                    // OR divider directly under the button (match Get Started)
                    screenPadding(
                      customPadding: EdgeInsets.symmetric(vertical: 0.h),
                      child: Row(
                        children: [
                          Expanded(
                            child: Divider(
                              endIndent: 15,
                              thickness: 0.2,
                            ),
                          ),
                          TextConstant(
                            title: 'OR',
                            color: themeController.greyColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                          Expanded(
                            child: Divider(
                              indent: 15,
                              thickness: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    heightBox(24),
                  ],
                ),
                
                if (!hideProviders) ...[
                  // Google button (copied styling from GetStarted screen)
                  Container(
                    width: double.infinity,
                    height: 56.h,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          themeController.lightPinkColor.withValues(alpha: 0.15),
                          themeController.purpleColor.withValues(alpha: 0.1),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      border: Border.all(
                        color: themeController.lightPinkColor.withValues(alpha: 0.3),
                        width: 1.w,
                      ),
                      borderRadius: BorderRadius.circular(28.r),
                      boxShadow: [
                        BoxShadow(
                          color: themeController.lightPinkColor.withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () { controller.continueWithGoogle(); },
                        borderRadius: BorderRadius.circular(28.r),
                        child: Center(
                          child: TextConstant(
                            title: 'Continue with Google',
                            color: themeController.whiteColor.withValues(alpha: 0.9),
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                  heightBox(12),
                  // Apple button (copied styling from GetStarted screen)
                  Container(
                    width: double.infinity,
                    height: 56.h,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          themeController.lightPinkColor.withValues(alpha: 0.15),
                          themeController.purpleColor.withValues(alpha: 0.1),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      border: Border.all(
                        color: themeController.lightPinkColor.withValues(alpha: 0.3),
                        width: 1.w,
                      ),
                      borderRadius: BorderRadius.circular(28.r),
                      boxShadow: [
                        BoxShadow(
                          color: themeController.lightPinkColor.withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () { controller.continueWithApple(); },
                        borderRadius: BorderRadius.circular(28.r),
                        child: Center(
                          child: TextConstant(
                            title: 'Continue with Apple',
                            color: themeController.whiteColor.withValues(alpha: 0.9),
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}