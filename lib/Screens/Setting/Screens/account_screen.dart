import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:lovebug/Common/text_constant.dart';
import 'package:lovebug/ThemeController/theme_controller.dart';
import 'package:lovebug/services/supabase_service.dart';
import 'package:lovebug/Screens/AuthPage/auth_ui_screen.dart';

class AccountSettingsScreen extends StatelessWidget {
  AccountSettingsScreen({super.key});
  final ThemeController theme = Get.find<ThemeController>();

  void _showDeactivateAccountDialog() {
    Get.dialog(
      AlertDialog(
        backgroundColor: theme.blackColor,
        title: TextConstant(
          title: 'Deactivate Account',
          color: theme.whiteColor,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        content: TextConstant(
          title: 'Are you sure you want to deactivate your account? This will log you out and you won\'t be able to access your account until an administrator reactivates it.',
          color: theme.whiteColor.withOpacity(0.8),
          fontSize: 14,
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: TextConstant(
              title: 'Cancel',
              color: theme.greyColor,
              fontSize: 14,
            ),
          ),
          TextButton(
            onPressed: () async {
              Get.back();
              await _deactivateAccount();
            },
            child: TextConstant(
              title: 'Deactivate',
              color: Colors.red,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deactivateAccount() async {
    try {
      // Show loading
      Get.dialog(
        Center(
          child: Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.blackColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: theme.lightPinkColor),
                SizedBox(height: 10),
                TextConstant(
                  title: 'Deactivating account...',
                  color: theme.whiteColor,
                  fontSize: 14,
                ),
              ],
            ),
          ),
        ),
        barrierDismissible: false,
      );

      // Deactivate the user's account
      final currentUserId = SupabaseService.currentUser?.id;
      if (currentUserId != null) {
        await SupabaseService.client
            .from('profiles')
            .update({'is_active': false})
            .eq('id', currentUserId);
      }

      // Close loading dialog
      Get.back();

      // Sign out the user
      await SupabaseService.signOut();

      // Show success message and navigate to login
      Get.snackbar(
        'Account Deactivated',
        'Your account has been deactivated successfully',
        backgroundColor: theme.blackColor,
        colorText: theme.whiteColor,
        duration: Duration(seconds: 3),
      );

      // Navigate to login screen
      Get.offAll(() => AuthScreen());
    } catch (e) {
      print('Error deactivating account: $e');
      Get.back(); // Close loading dialog
      Get.snackbar(
        'Error',
        'Failed to deactivate account: $e',
        backgroundColor: theme.blackColor,
        colorText: theme.whiteColor,
        duration: Duration(seconds: 3),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextConstant(title: 'Account', color: theme.whiteColor), 
        backgroundColor: theme.blackColor,
        iconTheme: IconThemeData(color: theme.whiteColor),
      ),
      backgroundColor: theme.blackColor,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.blackColor,
              theme.bgGradient1,
              theme.blackColor,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            children: [
              SizedBox(height: 20.h),
              
              // Change Email Section
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(20.w),
                margin: EdgeInsets.only(bottom: 16.h),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.lightPinkColor.withOpacity(0.1),
                      theme.purpleColor.withOpacity(0.05),
                    ],
                  ),
                  border: Border.all(
                    color: theme.lightPinkColor.withOpacity(0.3),
                    width: 1.w,
                  ),
                  borderRadius: BorderRadius.circular(16.r),
                  boxShadow: [
                    BoxShadow(
                      color: theme.lightPinkColor.withOpacity(0.1),
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        color: theme.lightPinkColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Icon(
                        Icons.email_outlined,
                        color: theme.lightPinkColor,
                        size: 24.sp,
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextConstant(
                            title: 'Change Email',
                            color: theme.whiteColor,
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                          ),
                          SizedBox(height: 4.h),
                          TextConstant(
                            title: 'Update your email address',
                            color: theme.greyColor,
                            fontSize: 12.sp,
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      color: theme.greyColor,
                      size: 16.sp,
                    ),
                  ],
                ),
              ),
              
              // Change Password Section
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(20.w),
                margin: EdgeInsets.only(bottom: 16.h),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.lightPinkColor.withOpacity(0.1),
                      theme.purpleColor.withOpacity(0.05),
                    ],
                  ),
                  border: Border.all(
                    color: theme.lightPinkColor.withOpacity(0.3),
                    width: 1.w,
                  ),
                  borderRadius: BorderRadius.circular(16.r),
                  boxShadow: [
                    BoxShadow(
                      color: theme.lightPinkColor.withOpacity(0.1),
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        color: theme.purpleColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Icon(
                        Icons.lock_outline,
                        color: theme.purpleColor,
                        size: 24.sp,
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextConstant(
                            title: 'Change Password',
                            color: theme.whiteColor,
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                          ),
                          SizedBox(height: 4.h),
                          TextConstant(
                            title: 'Update your password',
                            color: theme.greyColor,
                            fontSize: 12.sp,
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      color: theme.greyColor,
                      size: 16.sp,
                    ),
                  ],
                ),
              ),
              
              // Deactivate Account Section
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(20.w),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.red.withOpacity(0.1),
                      Colors.red.withOpacity(0.05),
                    ],
                  ),
                  border: Border.all(
                    color: Colors.red.withOpacity(0.3),
                    width: 1.w,
                  ),
                  borderRadius: BorderRadius.circular(16.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withOpacity(0.1),
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: GestureDetector(
                  onTap: _showDeactivateAccountDialog,
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(12.w),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Icon(
                          Icons.person_off,
                          color: Colors.red,
                          size: 24.sp,
                        ),
                      ),
                      SizedBox(width: 16.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextConstant(
                              title: 'Deactivate Account',
                              color: Colors.red,
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                            ),
                            SizedBox(height: 4.h),
                            TextConstant(
                              title: 'Temporarily disable your account',
                              color: theme.greyColor,
                              fontSize: 12.sp,
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        color: theme.greyColor,
                        size: 16.sp,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
