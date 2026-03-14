import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lovebug/Common/widget_constant.dart';
import 'package:lovebug/Common/text_constant.dart';
import 'package:lovebug/Common/textfield_constant.dart';
import 'package:lovebug/ThemeController/theme_controller.dart';
import 'auth_controller.dart';

class ResetPasswordVerifyScreen extends StatelessWidget {
  final String email;
  ResetPasswordVerifyScreen({super.key, required this.email});

  final AuthController controller = Get.find<AuthController>();
  final ThemeController theme = Get.find<ThemeController>();
  final TextEditingController otpController = TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: theme.blackColor,
      body: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Container(
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
            child: screenPadding(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  heightBox(20),
                  TextConstant(
                    title: 'Reset Password',
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                  heightBox(6),
                  TextConstant(
                    title: 'Enter the 6-digit code sent to $email',
                    color: theme.whiteColor.withValues(alpha: 0.7),
                    fontSize: 12,
                  ),
                  heightBox(24),
                  TextFieldConstant(
                    height: 48.h,
                    hintFontSize: 14,
                    hintText: '6-digit code',
                    hintFontWeight: FontWeight.bold,
                    keyboardType: TextInputType.number,
                    controller: otpController,
                  ),
                  heightBox(12),
                  TextFieldConstant(
                    height: 48.h,
                    hintFontSize: 14,
                    hintText: 'New Password',
                    hintFontWeight: FontWeight.bold,
                    obscureText: true,
                    controller: newPasswordController,
                  ),
                  heightBox(12),
                  TextFieldConstant(
                    height: 48.h,
                    hintFontSize: 14,
                    hintText: 'Confirm New Password',
                    hintFontWeight: FontWeight.bold,
                    obscureText: true,
                    controller: confirmPasswordController,
                  ),
                  heightBox(12),
                  Obx(() => TextConstant(
                        title: controller.resendSeconds.value > 0
                            ? 'Resend code in ${controller.resendSeconds.value}s'
                            : 'Didn\'t get it? Tap Resend below',
                        color: theme.whiteColor.withValues(alpha: 0.6),
                        fontSize: 12,
                      )),
                  heightBox(24),
                  Row(
                    children: [
                      Expanded(
                        child: Obx(() => elevatedButton(
                              title: 'Update Password',
                              textColor: theme.whiteColor,
                              onPressed: controller.isLoading.value
                                  ? null
                                  : () async {
                                      if (otpController.text.trim().isEmpty ||
                                          newPasswordController.text.trim().isEmpty) {
                                        Get.snackbar('Error', 'Please fill all fields');
                                        return;
                                      }
                                      if (newPasswordController.text !=
                                          confirmPasswordController.text) {
                                        Get.snackbar('Error', 'Passwords do not match');
                                        return;
                                      }
                                      if (newPasswordController.text.length < 6) {
                                        Get.snackbar('Error',
                                            'Password must be at least 6 characters');
                                        return;
                                      }
                                      
                                      try {
                                        final res = await controller.verifyPasswordResetOtp(
                                            email,
                                            otpController.text.trim(),
                                            newPasswordController.text.trim());
                                        if (res) {
                                          Get.snackbar('Success',
                                              'Password updated successfully!');
                                        } else {
                                          Get.snackbar('Error',
                                              'Invalid code. Please try again.');
                                        }
                                      } catch (e) {
                                        print('❌ DEBUG: Reset password error: $e');
                                        Get.snackbar('Error',
                                            'Verification failed. Make sure the code is correct.');
                                      }
                                    },
                              colorsGradient: [
                                theme.lightPinkColor,
                                theme.purpleColor
                              ],
                            )),
                      ),
                    ],
                  ),
                  heightBox(10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Obx(() => TextButton(
                          onPressed: controller.resendSeconds.value > 0 ||
                                  controller.isLoading.value
                              ? null
                              : () {
                                  controller.forgotPassword();
                                },
                          child: Text(
                            'Resend Code',
                            style: TextStyle(
                              color: controller.resendSeconds.value > 0
                                  ? theme.greyColor
                                  : theme.lightPinkColor,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        )),
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
