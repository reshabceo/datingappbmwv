import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lovebug/Common/widget_constant.dart';
import 'package:lovebug/Common/text_constant.dart';
import 'package:lovebug/Common/textfield_constant.dart';
import 'package:lovebug/ThemeController/theme_controller.dart';
import 'auth_controller.dart';

class EmailCodeVerifyScreen extends StatelessWidget {
  final bool isSignupFlow;
  final String? email;
  final String? password;
  EmailCodeVerifyScreen({super.key, required this.isSignupFlow, this.email, this.password});

  final AuthController controller = Get.find<AuthController>();
  final ThemeController theme = Get.find<ThemeController>();

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
                  title: isSignupFlow ? 'Verify your email' : 'Enter code',
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
                heightBox(6),
                TextConstant(
                  title: 'Code sent to ${email ?? controller.emailController.text}',
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
                  controller: controller.emailOtpController,
                ),
                heightBox(12),
                Obx(() => TextConstant(
                      title: controller.resendSeconds.value > 0
                          ? 'Resend in ${controller.resendSeconds.value}s'
                          : 'Didn\'t get it? Tap Resend',
                      color: theme.whiteColor.withValues(alpha: 0.6),
                      fontSize: 12,
                    )),
                heightBox(12),
                Row(
                  children: [
                    Expanded(
                      child: elevatedButton(
                        title: 'Verify Code',
                        textColor: theme.whiteColor,
                        onPressed: controller.isLoading.value
                            ? null
                            : () {
                                controller.verifyEmailCodeAndSetPassword();
                              },
                        colorsGradient: [theme.lightPinkColor, theme.purpleColor],
                      ),
                    ),
                  ],
                ),
                heightBox(10),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      controller.resendEmailCode();
                    },
                    child: const Text('Resend'),
                  ),
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


