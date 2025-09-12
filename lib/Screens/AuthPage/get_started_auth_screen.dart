import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:boliler_plate/ThemeController/theme_controller.dart';
import 'package:boliler_plate/Common/widget_constant.dart';
import 'package:boliler_plate/Common/text_constant.dart';
import 'package:boliler_plate/Common/textfield_constant.dart';
import 'package:boliler_plate/Common/glass_butto.dart';
import 'package:boliler_plate/Constant/app_assets.dart';
import 'auth_ui_screen.dart';
import 'auth_controller.dart';

class GetStartedAuthScreen extends StatelessWidget {
  GetStartedAuthScreen({super.key});

  final ThemeController theme = Get.find<ThemeController>();
  final TextEditingController emailController = TextEditingController();
  final AuthController authController = Get.put(AuthController());

  @override
  Widget build(BuildContext context) {
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
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                heightBox(12),
                TextConstant(
                  title: 'Log in or sign up',
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: theme.whiteColor,
                ),
                heightBox(12),
                TextConstant(
                  title: "You'll get smarter responses and can upload files, images, and more.",
                  fontSize: 14,
                  color: theme.whiteColor.withValues(alpha: 0.7),
                  height: 1.4,
                ),
                heightBox(24),

                // Email field (styled with existing component)
                TextFieldConstant(
                  height: 50.h,
                  hintFontSize: 14,
                  hintText: 'Email address',
                  hintFontWeight: FontWeight.bold,
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                ),

                heightBox(16),

                // Continue button (uses existing gradient button)
                SizedBox(
                  width: double.infinity,
                  height: 56.h,
                  child: elevatedButton(
                    title: 'Continue',
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

                heightBox(16),

                Row(
                  children: [
                    Expanded(child: Divider(color: theme.whiteColor.withValues(alpha: 0.2))),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12.w),
                      child: TextConstant(
                        title: 'OR',
                        color: theme.whiteColor.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Expanded(child: Divider(color: theme.whiteColor.withValues(alpha: 0.2))),
                  ],
                ),

                heightBox(16),

                glassyButton(title: 'Continue with Google', onTap: () {}),
                heightBox(12),
                glassyButton(title: 'Continue with Microsoft Account', onTap: () {}),
                heightBox(12),
                glassyButton(
                  title: 'Continue with Apple',
                  imagePath: AppAssets.appleLogo,
                  onTap: () {},
                ),
                heightBox(12),
                glassyButton(
                  title: 'Continue with phone',
                  onTap: () {
                    Get.to(() => AuthScreen(startMode: 'phone'));
                  },
                ),

                const Spacer(),

                Center(
                  child: Wrap(
                    spacing: 12.w,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      TextConstant(
                        title: 'Terms of Use',
                        color: theme.whiteColor.withValues(alpha: 0.7),
                      ),
                      TextConstant(
                        title: '|',
                        color: theme.whiteColor.withValues(alpha: 0.3),
                      ),
                      TextConstant(
                        title: 'Privacy Policy',
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
    );
  }

  // No custom provider button; reuse glassyButton to match app UI
}


