import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:ui';
import 'supabase_service.dart';
import '../widgets/upgrade_prompt_widget.dart';
import '../Screens/SubscriptionPage/ui_subscription_screen.dart';
import '../ThemeController/theme_controller.dart';
import '../Screens/DiscoverPage/controller_discover_screen.dart';

class PremiumMessageService {
  // Send a premium message before matching
  static Future<Map<String, dynamic>> sendPremiumMessage({
    required String recipientId,
    required String message,
  }) async {
    try {
      // Check if user is premium
      final isPremium = await SupabaseService.isPremiumUser();
      if (!isPremium) {
        return {
          'error': 'Premium subscription required to send messages before matching',
          'requires_premium': true,
        };
      }

      // Send premium message
      final result = await SupabaseService.sendPremiumMessage(
        recipientId: recipientId,
        message: message,
      );

      if (result.containsKey('error')) {
        return result;
      }

      return {
        'success': true,
        'message_id': result['message_id'],
      };
    } catch (e) {
      print('Error sending premium message: $e');
      return {
        'error': 'Failed to send message: $e',
      };
    }
  }

  // Get premium messages for current user
  static Future<List<Map<String, dynamic>>> getPremiumMessages() async {
    try {
      return await SupabaseService.getPremiumMessages();
    } catch (e) {
      print('Error getting premium messages: $e');
      return [];
    }
  }

  // Reveal premium message when user gets premium
  static Future<bool> revealPremiumMessage(String messageId) async {
    try {
      return await SupabaseService.revealPremiumMessage(messageId);
    } catch (e) {
      print('Error revealing premium message: $e');
      return false;
    }
  }

  // Show premium message dialog
  static void showPremiumMessageDialog({
    required String recipientId,
    required String recipientName,
    required String recipientPhoto,
  }) async {
    final isPremium = await SupabaseService.isPremiumUser();
    
    // If not premium, show upgrade dialog immediately
    if (!isPremium) {
      _showUpgradeDialog();
      return;
    }
    
    // If premium, show message input dialog
    final messageController = TextEditingController();

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Container(
          padding: EdgeInsets.all(20.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                children: [
                  // Recipient photo
                  CircleAvatar(
                    radius: 20.r,
                    backgroundImage: recipientPhoto.isNotEmpty
                        ? NetworkImage(recipientPhoto)
                        : null,
                    child: recipientPhoto.isEmpty
                        ? Icon(Icons.person, size: 20.r)
                        : null,
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Send a message to $recipientName',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'They\'ll see this before you match',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: 16.h),
              
              // Message input
              TextField(
                controller: messageController,
                maxLines: 3,
                maxLength: 200,
                decoration: InputDecoration(
                  hintText: 'Type your message...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  counterText: '${messageController.text.length}/200',
                ),
              ),
              
              SizedBox(height: 16.h),
              
              // Premium check
              if (!isPremium)
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(color: Colors.amber.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.lock, color: Colors.amber.shade700, size: 16.sp),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          'Premium feature - Upgrade to send messages before matching',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.amber.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              
              SizedBox(height: 16.h),
              
              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Get.back(),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                      ),
                      child: Text('Cancel'),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: isPremium
                          ? () => _sendMessage(recipientId, messageController.text)
                          : () => _showUpgradeDialog(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isPremium ? Colors.pink : Colors.grey,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                      ),
                      child: Text(isPremium ? 'Send Message' : 'Upgrade'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: true,
    );
  }

  // Send the premium message
  static Future<void> _sendMessage(String recipientId, String message) async {
    if (message.trim().isEmpty) {
      Get.snackbar('Error', 'Please enter a message');
      return;
    }

    try {
      final result = await sendPremiumMessage(
        recipientId: recipientId,
        message: message.trim(),
      );

      if (result.containsKey('error')) {
        Get.snackbar('Error', result['error']);
        return;
      }

      Get.back(); // Close dialog
      Get.snackbar(
        'Message Sent! 💬',
        'Your message was sent and will be revealed when they upgrade',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: Duration(seconds: 3),
      );
    } catch (e) {
      Get.snackbar('Error', 'Failed to send message: $e');
    }
  }

  // Show upgrade dialog with rewind-style design
  static void _showUpgradeDialog() {
    Get.back(); // Close current dialog
    
    final themeController = Get.find<ThemeController>();
    
    // Detect current mode (dating/bff)
    bool isBffMode = false;
    if (Get.isRegistered<DiscoverController>()) {
      try {
        final d = Get.find<DiscoverController>();
        isBffMode = (d.currentMode.value == 'bff');
      } catch (_) {}
    }

    // Pick gradient colors based on mode
    final List<Color> bgColors = isBffMode
        ? [
            themeController.bffPrimaryColor.withValues(alpha: 0.15),
            themeController.bffSecondaryColor.withValues(alpha: 0.15),
          ]
        : [
            themeController.getAccentColor().withValues(alpha: 0.15),
            themeController.getSecondaryColor().withValues(alpha: 0.15),
          ];
    final Color borderColor = isBffMode
        ? themeController.bffPrimaryColor
        : themeController.getAccentColor();
    final List<Color> ctaColors = isBffMode
        ? [themeController.bffPrimaryColor, themeController.bffSecondaryColor]
        : [themeController.getAccentColor(), themeController.getSecondaryColor()];
    
    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.symmetric(horizontal: 24.w),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: bgColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22.r),
              border: Border.all(
                color: borderColor.withValues(alpha: 0.35),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: borderColor.withValues(alpha: 0.15),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.all(20.w),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Premium Feature',
                    style: TextStyle(
                      color: themeController.whiteColor,
                      fontSize: 22.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    'Send messages before matching is a premium feature. Upgrade to unlock this and more!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: themeController.whiteColor.withValues(alpha: 0.8),
                      fontSize: 15.sp,
                      height: 1.4,
                    ),
                  ),
                  SizedBox(height: 24.h),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => Get.back(),
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 12.h),
                            decoration: BoxDecoration(
                              color: themeController.whiteColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20.r),
                              border: Border.all(
                                color: themeController.whiteColor.withValues(alpha: 0.3),
                                width: 1.5,
                              ),
                            ),
                            child: Text(
                              'Maybe Later',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: themeController.whiteColor,
                                fontSize: 15.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            Get.back();
                            Get.to(() => SubscriptionScreen());
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 12.h),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: ctaColors),
                              borderRadius: BorderRadius.circular(20.r),
                              border: Border.all(
                                color: borderColor.withValues(alpha: 0.5),
                                width: 1.5,
                              ),
                            ),
                            child: Text(
                              'Upgrade Now',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      ),
      barrierDismissible: true,
    );
  }
}
