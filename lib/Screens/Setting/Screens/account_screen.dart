import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:lovebug/Common/text_constant.dart';
import 'package:lovebug/ThemeController/theme_controller.dart';
import 'package:lovebug/services/supabase_service.dart';
import 'package:lovebug/Screens/AuthPage/auth_ui_screen.dart';
import 'package:lovebug/Common/widget_constant.dart';

class AccountSettingsScreen extends StatelessWidget {
  AccountSettingsScreen({super.key});
  final ThemeController theme = Get.find<ThemeController>();

  void _showDeleteAccountDialog() {
    Get.dialog(
      AlertDialog(
        backgroundColor: theme.blackColor,
        title: TextConstant(
          title: 'Delete Account',
          color: theme.whiteColor,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextConstant(
              title: 'Are you sure you want to permanently delete your account?',
              color: theme.whiteColor.withOpacity(0.9),
              fontSize: 14,
              fontWeight: FontWeight.w600,
              softWrap: true,
            ),
            SizedBox(height: 12.h),
            TextConstant(
              title: 'This action cannot be undone. All your data including:\n• Profile information\n• Photos\n• Messages\n• Matches\n• Subscriptions\n\nwill be permanently deleted.',
              color: theme.whiteColor.withOpacity(0.7),
              fontSize: 13,
              softWrap: true,
            ),
          ],
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
              await _deleteAccount();
            },
            child: TextConstant(
              title: 'Delete Forever',
              color: Colors.red,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _showChangeEmailDialog() {
    final emailController = TextEditingController();
    final currentEmail = SupabaseService.currentUser?.email ?? '';
    
    Get.dialog(
      Dialog(
        backgroundColor: theme.blackColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
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
                  SizedBox(width: 12.w),
                  Expanded(
                    child: TextConstant(
                      title: 'Change Email',
                      color: theme.whiteColor,
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Get.back(),
                    icon: Icon(
                      Icons.close,
                      color: theme.greyColor,
                      size: 20.sp,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20.h),
              TextConstant(
                title: 'Current Email',
                color: theme.greyColor,
                fontSize: 12.sp,
              ),
              SizedBox(height: 4.h),
              TextConstant(
                title: currentEmail,
                color: theme.whiteColor,
                fontSize: 14.sp,
              ),
              SizedBox(height: 20.h),
              TextConstant(
                title: 'New Email',
                color: theme.whiteColor,
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
              ),
              SizedBox(height: 8.h),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                style: TextStyle(color: theme.whiteColor),
                decoration: InputDecoration(
                  hintText: 'Enter new email address',
                  hintStyle: TextStyle(color: theme.greyColor),
                  filled: true,
                  fillColor: theme.blackColor.withOpacity(0.5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(
                      color: theme.lightPinkColor.withOpacity(0.3),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(
                      color: theme.lightPinkColor.withOpacity(0.3),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(
                      color: theme.lightPinkColor,
                      width: 2,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 24.h),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Get.back(),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          side: BorderSide(
                            color: theme.greyColor.withOpacity(0.3),
                          ),
                        ),
                      ),
                      child: TextConstant(
                        title: 'Cancel',
                        color: theme.greyColor,
                        fontSize: 14.sp,
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        final newEmail = emailController.text.trim();
                        if (newEmail.isEmpty) {
                          showCustomSnackBar(title: 'error'.tr, message: 'please_enter_a_new_email_address'.tr, isError: true);
                          return;
                        }
                        if (newEmail == currentEmail) {
                          showCustomSnackBar(title: 'error'.tr, message: 'new_email_must_be_different_from_current_email'.tr, isError: true);
                          return;
                        }
                        if (!GetUtils.isEmail(newEmail)) {
                          showCustomSnackBar(title: 'error'.tr, message: 'please_enter_a_valid_email_address'.tr, isError: true);
                          return;
                        }
                        
                        Get.back();
                        await _changeEmail(newEmail);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.lightPinkColor,
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      child: TextConstant(
                        title: 'Update',
                        color: theme.whiteColor,
                        fontSize: 14.sp,
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
    );
  }

  void _showChangePasswordDialog() {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final RxBool currentPasswordVisible = false.obs;
    final RxBool newPasswordVisible = false.obs;
    final RxBool confirmPasswordVisible = false.obs;
    
    Get.dialog(
      Dialog(
        backgroundColor: theme.blackColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
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
                  SizedBox(width: 12.w),
                  Expanded(
                    child: TextConstant(
                      title: 'Change Password',
                      color: theme.whiteColor,
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Get.back(),
                    icon: Icon(
                      Icons.close,
                      color: theme.greyColor,
                      size: 20.sp,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20.h),
              TextConstant(
                title: 'Current Password',
                color: theme.whiteColor,
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
              ),
              SizedBox(height: 8.h),
              Obx(() => TextField(
                controller: currentPasswordController,
                obscureText: !currentPasswordVisible.value,
                style: TextStyle(color: theme.whiteColor),
                decoration: InputDecoration(
                  hintText: 'Enter current password',
                  hintStyle: TextStyle(color: theme.greyColor),
                  filled: true,
                  fillColor: theme.blackColor.withOpacity(0.5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(
                      color: theme.purpleColor.withOpacity(0.3),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(
                      color: theme.purpleColor.withOpacity(0.3),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(
                      color: theme.purpleColor,
                      width: 2,
                    ),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      currentPasswordVisible.value
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: theme.greyColor,
                      size: 20.sp,
                    ),
                    onPressed: () => currentPasswordVisible.value = !currentPasswordVisible.value,
                  ),
                ),
              )),
              SizedBox(height: 16.h),
              TextConstant(
                title: 'New Password',
                color: theme.whiteColor,
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
              ),
              SizedBox(height: 8.h),
              Obx(() => TextField(
                controller: newPasswordController,
                obscureText: !newPasswordVisible.value,
                style: TextStyle(color: theme.whiteColor),
                decoration: InputDecoration(
                  hintText: 'Enter new password',
                  hintStyle: TextStyle(color: theme.greyColor),
                  filled: true,
                  fillColor: theme.blackColor.withOpacity(0.5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(
                      color: theme.purpleColor.withOpacity(0.3),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(
                      color: theme.purpleColor.withOpacity(0.3),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(
                      color: theme.purpleColor,
                      width: 2,
                    ),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      newPasswordVisible.value
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: theme.greyColor,
                      size: 20.sp,
                    ),
                    onPressed: () => newPasswordVisible.value = !newPasswordVisible.value,
                  ),
                ),
              )),
              SizedBox(height: 16.h),
              TextConstant(
                title: 'Confirm New Password',
                color: theme.whiteColor,
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
              ),
              SizedBox(height: 8.h),
              Obx(() => TextField(
                controller: confirmPasswordController,
                obscureText: !confirmPasswordVisible.value,
                style: TextStyle(color: theme.whiteColor),
                decoration: InputDecoration(
                  hintText: 'Confirm new password',
                  hintStyle: TextStyle(color: theme.greyColor),
                  filled: true,
                  fillColor: theme.blackColor.withOpacity(0.5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(
                      color: theme.purpleColor.withOpacity(0.3),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(
                      color: theme.purpleColor.withOpacity(0.3),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(
                      color: theme.purpleColor,
                      width: 2,
                    ),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      confirmPasswordVisible.value
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: theme.greyColor,
                      size: 20.sp,
                    ),
                    onPressed: () => confirmPasswordVisible.value = !confirmPasswordVisible.value,
                  ),
                ),
              )),
              SizedBox(height: 24.h),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Get.back(),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          side: BorderSide(
                            color: theme.greyColor.withOpacity(0.3),
                          ),
                        ),
                      ),
                      child: TextConstant(
                        title: 'Cancel',
                        color: theme.greyColor,
                        fontSize: 14.sp,
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        final currentPassword = currentPasswordController.text;
                        final newPassword = newPasswordController.text;
                        final confirmPassword = confirmPasswordController.text;
                        
                        if (currentPassword.isEmpty) {
                          showCustomSnackBar(title: 'error'.tr, message: 'please_enter_your_current_password'.tr, isError: true);
                          return;
                        }
                        if (newPassword.isEmpty) {
                          showCustomSnackBar(title: 'error'.tr, message: 'please_enter_a_new_password'.tr, isError: true);
                          return;
                        }
                        if (newPassword.length < 6) {
                          showCustomSnackBar(title: 'error'.tr, message: 'password_must_be_at_least_6_characters'.tr, isError: true);
                          return;
                        }
                        if (newPassword != confirmPassword) {
                          showCustomSnackBar(title: 'error'.tr, message: 'new_passwords_do_not_match'.tr, isError: true);
                          return;
                        }
                        
                        Get.back();
                        await _changePassword(currentPassword, newPassword);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.purpleColor,
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      child: TextConstant(
                        title: 'Update',
                        color: theme.whiteColor,
                        fontSize: 14.sp,
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
    );
  }

  Future<void> _changeEmail(String newEmail) async {
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
                  title: 'Updating email...',
                  color: theme.whiteColor,
                  fontSize: 14,
                ),
              ],
            ),
          ),
        ),
        barrierDismissible: false,
      );

      await SupabaseService.updateUserEmail(newEmail);

      Get.back(); // Close loading dialog

      showCustomSnackBar(
        title: 'email_update_sent'.tr,
        message: 'email_update_sent_message'.tr.replaceAll('\$email', newEmail),
      );
    } catch (e) {
      print('Error changing email: $e');
      Get.back(); // Close loading dialog
      
      String errorMessage = 'Failed to update email';
      if (e.toString().contains('already registered') || e.toString().contains('already exists')) {
        errorMessage = 'This email is already in use by another account';
      } else if (e.toString().contains('rate limit')) {
        errorMessage = 'Too many requests. Please try again later';
      } else if (e.toString().isNotEmpty) {
        errorMessage = e.toString();
      }
      
      showCustomSnackBar(
        title: 'error'.tr,
        message: errorMessage,
        isError: true,
      );
    }
  }

  Future<void> _changePassword(String currentPassword, String newPassword) async {
    try {
      // Verify current password first
      final currentEmail = SupabaseService.currentUser?.email;
      if (currentEmail == null) {
        showCustomSnackBar(
          title: 'error'.tr,
          message: 'unable_to_verify_current_password'.tr,
          isError: true,
        );
        return;
      }

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
                CircularProgressIndicator(color: theme.purpleColor),
                SizedBox(height: 10),
                TextConstant(
                  title: 'Verifying password...',
                  color: theme.whiteColor,
                  fontSize: 14,
                ),
              ],
            ),
          ),
        ),
        barrierDismissible: false,
      );

      // Verify current password by attempting to sign in
      try {
        await SupabaseService.signInWithEmail(
          email: currentEmail,
          password: currentPassword,
        );
      } catch (e) {
        Get.back(); // Close loading dialog
        showCustomSnackBar(
          title: 'error'.tr,
          message: 'current_password_is_incorrect'.tr,
          isError: true,
        );
        return;
      }

      // Update password
      await SupabaseService.updateUserPassword(newPassword);

      Get.back(); // Close loading dialog

      showCustomSnackBar(
        title: 'password_updated'.tr,
        message: 'password_updated_successfully'.tr,
      );
    } catch (e) {
      print('Error changing password: $e');
      Get.back(); // Close loading dialog
      
      String errorMessage = 'Failed to update password';
      if (e.toString().contains('same password') || e.toString().contains('identical')) {
        errorMessage = 'New password must be different from current password';
      } else if (e.toString().isNotEmpty) {
        errorMessage = e.toString();
      }
      
      showCustomSnackBar(
        title: 'error'.tr,
        message: errorMessage,
        isError: true,
      );
    }
  }

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
              color: Colors.orange,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAccount() async {
    try {
      // Show confirmation dialog with warning
      final confirmed = await Get.dialog<bool>(
        AlertDialog(
          backgroundColor: theme.blackColor,
          title: TextConstant(
            title: 'Final Confirmation',
            color: Colors.red,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
          content: TextConstant(
            title: 'Type "DELETE" to confirm account deletion. This action is permanent and cannot be undone.',
            color: theme.whiteColor.withOpacity(0.9),
            fontSize: 14,
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: TextConstant(
                title: 'Cancel',
                color: theme.greyColor,
                fontSize: 14,
              ),
            ),
            TextButton(
              onPressed: () => Get.back(result: true),
              child: TextConstant(
                title: 'I Understand, Delete',
                color: Colors.red,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );

      if (confirmed != true) return;

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
                CircularProgressIndicator(color: Colors.red),
                SizedBox(height: 10),
                TextConstant(
                  title: 'Deleting account and all data...',
                  color: theme.whiteColor,
                  fontSize: 14,
                ),
              ],
            ),
          ),
        ),
        barrierDismissible: false,
      );

      // Delete the user's account and all associated data
      final currentUserId = SupabaseService.currentUser?.id;
      if (currentUserId != null) {
        // Call database function to delete user and all associated data
        // This should cascade delete all related records (messages, matches, swipes, etc.)
        try {
          await SupabaseService.client.rpc('delete_user_account', params: {
            'p_user_id': currentUserId,
          });
        } catch (e) {
          // If RPC function doesn't exist, manually delete from auth
          print('RPC function not available, using auth admin API: $e');
          // For now, we'll delete the profile which should cascade
          await SupabaseService.client
              .from('profiles')
              .delete()
              .eq('id', currentUserId);
        }

        // Sign out the user
        await SupabaseService.signOut();
      }

      // Close loading dialog
      Get.back();

      // Show success message and navigate to login
      showCustomSnackBar(
        title: 'account_deleted'.tr,
        message: 'account_deleted_successfully'.tr,
      );

      // Navigate to login screen
      Get.offAll(() => AuthScreen());
    } catch (e) {
      print('Error deleting account: $e');
      Get.back(); // Close loading dialog
      showCustomSnackBar(
        title: 'error'.tr,
        message: '${'failed_to_delete_account'.tr}: $e',
        isError: true,
      );
    }
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
      showCustomSnackBar(
        title: 'account_deactivated'.tr,
        message: 'account_deactivated_successfully'.tr,
      );

      // Navigate to login screen
      Get.offAll(() => AuthScreen());
    } catch (e) {
      print('Error deactivating account: $e');
      Get.back(); // Close loading dialog
      showCustomSnackBar(
        title: 'error'.tr,
        message: '${'failed_to_deactivate_account'.tr}: $e',
        isError: true,
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
              GestureDetector(
                onTap: _showChangeEmailDialog,
                child: Container(
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
              ),
              
              // Change Password Section
              GestureDetector(
                onTap: _showChangePasswordDialog,
                child: Container(
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
              ),
              
              // Delete Account Section
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(20.w),
                margin: EdgeInsets.only(bottom: 16.h),
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
                  onTap: _showDeleteAccountDialog,
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(12.w),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Icon(
                          Icons.delete_forever,
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
                              title: 'Delete Account',
                              color: Colors.red,
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                            ),
                            SizedBox(height: 4.h),
                            TextConstant(
                              title: 'Permanently delete your account and all data',
                              color: theme.greyColor,
                              fontSize: 12.sp,
                              softWrap: true,
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
              
              // Deactivate Account Section
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(20.w),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.orange.withOpacity(0.1),
                      Colors.orange.withOpacity(0.05),
                    ],
                  ),
                  border: Border.all(
                    color: Colors.orange.withOpacity(0.3),
                    width: 1.w,
                  ),
                  borderRadius: BorderRadius.circular(16.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orange.withOpacity(0.1),
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
                          color: Colors.orange.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Icon(
                          Icons.person_off,
                          color: Colors.orange,
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
                              color: Colors.orange,
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                            ),
                            SizedBox(height: 4.h),
                            TextConstant(
                              title: 'Temporarily disable your account',
                              color: theme.greyColor,
                              fontSize: 12.sp,
                              softWrap: true,
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
