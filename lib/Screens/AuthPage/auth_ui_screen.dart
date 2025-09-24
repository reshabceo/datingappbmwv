import 'package:get/get.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:boliler_plate/Common/glass_butto.dart';
import 'package:boliler_plate/Constant/app_assets.dart';
import 'package:boliler_plate/Common/text_constant.dart';
import 'package:boliler_plate/Common/widget_constant.dart';
import 'package:boliler_plate/Language/language_model.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:boliler_plate/Common/textfield_constant.dart';
import 'package:boliler_plate/Screens/AuthPage/auth_controller.dart';
import 'package:boliler_plate/ThemeController/theme_controller.dart';
import 'package:boliler_plate/Screens/BottomBarPage/bottombar_screen.dart';

class AuthScreen extends StatelessWidget {
  final String? startMode; // 'email' or 'phone'
  final String? prefillEmail;
  final bool isPasswordMode; // Show password field for existing users
  final bool isSignupMode; // Show signup fields for new users
  AuthScreen({super.key, this.startMode, this.prefillEmail, this.isPasswordMode = false, this.isSignupMode = false});

  final AuthController controller = Get.put(AuthController());

  final ThemeController themeController = Get.find<ThemeController>();

  @override
  Widget build(BuildContext context) {
    // Initialize selected mode and prefill when arriving from GetStarted
    if (startMode != null && (startMode == 'email' || startMode == 'phone')) {
      controller.authMode.value = startMode!;
    }
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
    }
    final bool hideProviders = startMode != null; // hide 3rd-party rows when user picked a mode
    final bool lockMode = startMode != null; // hide the phone/email toggle when user picked a mode
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
                          itemBuilder: (BuildContext context) {
                            return controller.languagesMap.keys.map((String languageName) {
                              return PopupMenuItem<String>(
                                value: languageName,
                                child: Container(
                                  alignment: Alignment.center,
                                  padding: EdgeInsets.symmetric(vertical: 4.h),
                                  child: TextConstant(
                                    title: languageName,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              );
                            }).toList();
                          },
                          child: Container(
                            width: 70.w,
                            height: 30.h,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              border: Border.all(
                                width: 0.8,
                                color: themeController.greyColor.withValues(
                                  alpha: 0.5,
                                ),
                              ),
                              borderRadius: BorderRadius.circular(20.r),
                              color: themeController.whiteColor.withValues(
                                alpha: 0.1,
                              ),
                            ),
                            child: TextConstant(
                              title: controller.selectedLanguage.value,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  Padding(
                    padding: EdgeInsetsGeometry.only(top: 90.h),
                    child: Obx(() {
                      return Image.asset(
                        themeController.isDarkMode.value ? AppAssets.logolight :  AppAssets.logodark,
                        width: 160.w,
                        fit: BoxFit.fitWidth,
                      );
                    }),
                  ),
                  Padding(
                    padding: EdgeInsetsGeometry.only(top: 20.h),
                    child: TextConstant(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      title: 'find_your'.tr,

                    ),
                  ),
                  screenPadding(
                    customPadding: EdgeInsets.only(top: 50.h),
                    child: TextConstant(
                      fontSize: 14,
                      title: 'join_day'.tr,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  // Auth Mode Toggle (hidden when a startMode is provided)
                  if (!lockMode)
                    screenPadding(
                      customPadding: EdgeInsets.only(top: 30.h),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(25.r),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                          ),
                        ),
                        child: Obx(() => Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () => controller.authMode.value = 'phone',
                                child: Container(
                                  padding: EdgeInsets.symmetric(vertical: 12.h),
                                  decoration: BoxDecoration(
                                    color: controller.authMode.value == 'phone' 
                                      ? themeController.lightPinkColor 
                                      : Colors.transparent,
                                    borderRadius: BorderRadius.circular(25.r),
                                  ),
                                  child: Text(
                                    'Phone',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: controller.authMode.value == 'phone' 
                                        ? Colors.white 
                                        : Colors.white.withOpacity(0.7),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14.sp,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => controller.authMode.value = 'email',
                                child: Container(
                                  padding: EdgeInsets.symmetric(vertical: 12.h),
                                  decoration: BoxDecoration(
                                    color: controller.authMode.value == 'email' 
                                      ? themeController.lightPinkColor 
                                      : Colors.transparent,
                                    borderRadius: BorderRadius.circular(25.r),
                                  ),
                                  child: Text(
                                    'Email',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: controller.authMode.value == 'email' 
                                        ? Colors.white 
                                        : Colors.white.withOpacity(0.7),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14.sp,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )),
                      ),
                    ),

                  // Input Fields based on auth mode
                  Obx(() => controller.authMode.value == 'phone' 
                    ? screenPadding(
                        child: Row(
                          children: [
                            // Country Code Dropdown
                            Container(
                              height: 44.h,
                              padding: EdgeInsets.symmetric(horizontal: 12.w),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8.r),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                ),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: controller.selectedCountryCode.value,
                                  isExpanded: false,
                                  icon: Icon(
                                    Icons.arrow_drop_down,
                                    color: Colors.white,
                                  ),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14.sp,
                                  ),
                                  items: [
                                    DropdownMenuItem(value: '+1', child: Text('🇺🇸 +1')),
                                    DropdownMenuItem(value: '+44', child: Text('🇬🇧 +44')),
                                    DropdownMenuItem(value: '+91', child: Text('🇮🇳 +91')),
                                    DropdownMenuItem(value: '+86', child: Text('🇨🇳 +86')),
                                    DropdownMenuItem(value: '+81', child: Text('🇯🇵 +81')),
                                    DropdownMenuItem(value: '+49', child: Text('🇩🇪 +49')),
                                    DropdownMenuItem(value: '+33', child: Text('🇫🇷 +33')),
                                    DropdownMenuItem(value: '+39', child: Text('🇮🇹 +39')),
                                    DropdownMenuItem(value: '+34', child: Text('🇪🇸 +34')),
                                    DropdownMenuItem(value: '+61', child: Text('🇦🇺 +61')),
                                  ],
                                  onChanged: (value) {
                                    controller.selectedCountryCode.value = value!;
                                  },
                                ),
                              ),
                            ),
                            SizedBox(width: 12.w),
                            // Phone Number Input
                            Expanded(
                              child: TextFieldConstant(
                                height: 44.h,
                                hintFontSize: 14,
                                hintText: 'phone_number'.tr,
                                hintFontWeight: FontWeight.bold,
                                keyboardType: TextInputType.number,
                                controller: controller.phoneController,
                                inputFormatters: [
                                  LengthLimitingTextInputFormatter(10),
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                              ),
                            ),
                          ],
                        ),
                        customPadding: EdgeInsets.only(top: 20.h),
                      )
                    : screenPadding(
                        child: Column(
                          children: [
                            TextFieldConstant(
                              height: 44.h,
                              hintFontSize: 14,
                              hintText: 'Email Address',
                              hintFontWeight: FontWeight.bold,
                              keyboardType: TextInputType.emailAddress,
                              controller: controller.emailController,
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
                                    ),
                                    heightBox(12),
                                    TextFieldConstant(
                                      height: 44.h,
                                      hintFontSize: 14,
                                      hintText: 'Confirm password',
                                      hintFontWeight: FontWeight.bold,
                                      obscureText: true,
                                      controller: controller.confirmPasswordController,
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
                            // No magic link (simplify)
                          ],
                        ),
                        customPadding: EdgeInsets.only(top: 20.h),
                      ),
                  ),
                  heightBox(20),
                  Obx(() {
                    if (controller.authMode.value == 'phone') {
                      // Phone authentication flow
                      return controller.isOTPSent.value
                        ? Column(
                            children: [
                              // Demo OTP Display
                              Container(
                                padding: EdgeInsets.all(12.w),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8.r),
                                  border: Border.all(color: Colors.orange),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.info, color: Colors.orange, size: 16.sp),
                                    SizedBox(width: 8.w),
                                    Expanded(
                                      child: Text(
                                        'Demo OTP: ${controller.currentOTP.value}',
                                        style: TextStyle(
                                          color: Colors.orange,
                                          fontSize: 12.sp,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              heightBox(16),
                              TextFieldConstant(
                                height: 44.h,
                                hintFontSize: 14,
                                hintText: 'Enter OTP',
                                hintFontWeight: FontWeight.bold,
                                keyboardType: TextInputType.number,
                                controller: controller.otpController,
                                inputFormatters: [
                                  LengthLimitingTextInputFormatter(6),
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                              ),
                              heightBox(20),
                              elevatedButton(
                                title: controller.isLoading.value ? 'Verifying...' : 'Verify OTP',
                                textColor: themeController.whiteColor,
                                onPressed: controller.isLoading.value ? null : () {
                                  controller.verifyOTP();
                                },
                                colorsGradient: [
                                  themeController.lightPinkColor,
                                  themeController.purpleColor,
                                ],
                              ),
                              heightBox(10),
                              Obx(() => Text(
                                controller.resendSeconds.value > 0
                                    ? 'Resend in \\${controller.resendSeconds.value}s'
                                    : '',
                                style: TextStyle(color: Colors.white70, fontSize: 12),
                              )),
                              heightBox(16),
                              // Skip Profile Button for Demo
                              TextButton(
                                onPressed: () {
                                  Get.offAll(() => BottombarScreen());
                                },
                                child: Text(
                                  'Skip Profile Creation (Demo)',
                                  style: TextStyle(
                                    color: themeController.whiteColor.withOpacity(0.7),
                                    fontSize: 12.sp,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ],
                          )
                        : Column(
                            children: [
                              elevatedButton(
                                title: controller.isLoading.value ? 'Sending...' : 'Send OTP',
                                textColor: themeController.whiteColor,
                                onPressed: controller.isLoading.value ? null : () {
                                  controller.sendOTP();
                                },
                                colorsGradient: [
                                  themeController.lightPinkColor,
                                  themeController.purpleColor,
                                ],
                              ),
                            ],
                          );
                    } else {
                      // Email authentication flow
                      return Column(
                        children: [
                          Obx(() => elevatedButton(
                                title: controller.isSignupMode.value
                                    ? 'Sign up'
                                    : controller.isExistingEmail.value
                                        ? 'Sign in'
                                        : 'Continue',
                                textColor: themeController.whiteColor,
                                onPressed: controller.isLoading.value
                                    ? null
                                    : () {
                                        if (controller.isSignupMode.value) {
                                          controller.signUpWithEmail();
                                        } else if (controller.isExistingEmail.value) {
                                          controller.signInWithPassword();
                                        } else {
                                          controller.continueWithEmail();
                                        }
                                      },
                                colorsGradient: [
                                  themeController.lightPinkColor,
                                  themeController.purpleColor,
                                ],
                              )),
                          heightBox(16),
                          // Skip Profile Button for Demo
                          TextButton(
                            onPressed: () {
                              Get.offAll(() => BottombarScreen());
                            },
                            child: Text(
                              'Skip Profile Creation (Demo)',
                              style: TextStyle(
                                color: themeController.whiteColor.withOpacity(0.7),
                                fontSize: 12.sp,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      );
                    }
                  }),
                  if (!hideProviders) screenPadding(
                    customPadding: EdgeInsets.symmetric(vertical: 50.h),
                    child: Row(
                      children: [
                        Expanded(
                          child: Divider(
                            endIndent: 15,
                            thickness: 0.2,
                          ),
                        ),
                        TextConstant(
                          title: 'or'.tr,
                          color: themeController.greyColor,
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
                  if (!hideProviders) glassyButton(title: 'continue_google'.tr, onTap: () { controller.continueWithGoogle(); }),
                  if (!hideProviders) heightBox(20),
                  if (!hideProviders)
                    glassyButton(
                      onTap: () { controller.continueWithApple(); },
                      title: 'continue_apple'.tr,
                      imagePath: AppAssets.appleLogo,
                    ),
                  heightBox(40),
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w400,
                        color: Theme
                            .of(Get.context!)
                            .colorScheme
                            .onSurface,
                      ),
                      children: [
                        TextSpan(text: 'by_continuing'.tr),
                        TextSpan(
                          text: 'terms'.tr,
                          style: TextStyle(
                            color: themeController.lightPinkColor,
                            decoration: TextDecoration.underline,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              print('Terms tapped');
                            },
                        ),
                        TextSpan(
                          text: ' and '.tr,
                          style: TextStyle(
                            color: Theme
                                .of(Get.context!)
                                .colorScheme
                                .onSurface,
                          ),
                        ),
                        TextSpan(
                          text: 'privacy_policy'.tr,
                          style: TextStyle(
                            color: themeController.lightPinkColor,
                            decoration: TextDecoration.underline,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {},
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
  }
}
