import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:ui';
import 'supabase_service.dart';
import '../Screens/SubscriptionPage/ui_subscription_screen.dart';
import '../ThemeController/theme_controller.dart';
import '../Screens/DiscoverPage/controller_discover_screen.dart';
import 'package:lovebug/Common/widget_constant.dart';

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
                    // Header with gradient icon
                    Container(
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            borderColor.withValues(alpha: 0.1),
                            borderColor.withValues(alpha: 0.05),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(
                          color: borderColor.withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          // Recipient photo with glow effect
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              // Glow effect
                              Container(
                                width: 60.r,
                                height: 60.r,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: borderColor.withValues(alpha: 0.3),
                                      blurRadius: 20,
                                      spreadRadius: 5,
                                    ),
                                  ],
                                ),
                              ),
                              // Photo
                              CircleAvatar(
                                radius: 28.r,
                                backgroundImage: recipientPhoto.isNotEmpty
                                    ? NetworkImage(recipientPhoto)
                                    : null,
                                child: recipientPhoto.isEmpty
                                    ? Icon(Icons.person, size: 28.r, color: themeController.whiteColor)
                                    : null,
                              ),
                            ],
                          ),
                          SizedBox(height: 16.h),
                          // Title with gradient text
                          ShaderMask(
                            shaderCallback: (bounds) => LinearGradient(
                              colors: ctaColors,
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ).createShader(bounds),
                            child: Text(
                              'Personalized Greeting',
                              style: TextStyle(
                                fontSize: 22.sp,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          Text(
                            'for Introduction',
                            style: TextStyle(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.w600,
                              color: themeController.whiteColor.withValues(alpha: 0.9),
                              letterSpacing: 0.3,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 12.h),
                          // Inspiring tagline
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                            decoration: BoxDecoration(
                              color: borderColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            child: Text(
                              '💝 Love at first sight needs no approval',
                              style: TextStyle(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w600,
                                color: themeController.whiteColor,
                                height: 1.3,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          SizedBox(height: 8.h),
                          // Stats line
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.trending_up,
                                color: Colors.greenAccent,
                                size: 16.sp,
                              ),
                              SizedBox(width: 4.w),
                              Text(
                                'Increases your match chances by ',
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  color: themeController.whiteColor.withValues(alpha: 0.8),
                                ),
                              ),
                              Text(
                                '5x',
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.greenAccent,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 12.h),
                          // Recipient info
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                            decoration: BoxDecoration(
                              color: themeController.whiteColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20.r),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'To: ',
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    color: themeController.whiteColor.withValues(alpha: 0.7),
                                  ),
                                ),
                                Text(
                                  recipientName,
                                  style: TextStyle(
                                    fontSize: 13.sp,
                                    fontWeight: FontWeight.w700,
                                    color: themeController.whiteColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    SizedBox(height: 20.h),
                    
                    // Message input section
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.edit_note,
                              color: borderColor,
                              size: 20.sp,
                            ),
                            SizedBox(width: 8.w),
                            Text(
                              'Craft Your Introduction',
                              style: TextStyle(
                                fontSize: 15.sp,
                                fontWeight: FontWeight.w700,
                                color: themeController.whiteColor,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 10.h),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.white.withValues(alpha: 0.95),
                                Colors.white.withValues(alpha: 0.98),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16.r),
                            border: Border.all(
                              color: borderColor.withValues(alpha: 0.4),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: borderColor.withValues(alpha: 0.2),
                                blurRadius: 8,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: messageController,
                            maxLines: 4,
                            maxLength: 200,
                            style: TextStyle(
                              color: Colors.black87,
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w500,
                              height: 1.4,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Write something memorable...\nMake it personal and genuine! 💫',
                              hintStyle: TextStyle(
                                color: Colors.black45,
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w400,
                                height: 1.4,
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.all(16.w),
                              filled: false,
                              counterStyle: TextStyle(
                                color: Colors.black54,
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    SizedBox(height: 24.h),
                    
                    // Action buttons with enhanced styling
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => Get.back(),
                            child: Container(
                              padding: EdgeInsets.symmetric(vertical: 14.h),
                              decoration: BoxDecoration(
                                color: themeController.whiteColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(25.r),
                                border: Border.all(
                                  color: themeController.whiteColor.withValues(alpha: 0.4),
                                  width: 1.5,
                                ),
                              ),
                              child: Text(
                                'Maybe Later',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: themeController.whiteColor,
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          flex: 2,
                          child: GestureDetector(
                            onTap: isPremium
                                ? () => _sendMessage(recipientId, messageController.text)
                                : () {
                                  Get.back();
                                  _showUpgradeDialog();
                                },
                            child: Container(
                              padding: EdgeInsets.symmetric(vertical: 14.h),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: ctaColors,
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(25.r),
                                border: Border.all(
                                  color: borderColor.withValues(alpha: 0.6),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: borderColor.withValues(alpha: 0.4),
                                    blurRadius: 12,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    isPremium ? Icons.send_rounded : Icons.workspace_premium,
                                    size: 18.sp,
                                    color: Colors.white,
                                  ),
                                  SizedBox(width: 8.w),
                                  Text(
                                    isPremium ? 'Send Greeting 💫' : 'Unlock Premium',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 15.sp,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ],
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

  // Send the premium message
  static Future<void> _sendMessage(String recipientId, String message) async {
    if (message.trim().isEmpty) {
      showCustomSnackBar(title: 'error'.tr, message: 'please_enter_a_message'.tr, isError: true);
      return;
    }

    // Premium messages are ONLY for premium users
    // The dialog already checks for premium status, but double-check here
    final isPremium = await SupabaseService.isPremiumUser();
    if (!isPremium) {
      Get.back(); // Close dialog
      _showUpgradeDialog();
      return;
    }

    try {
      final result = await sendPremiumMessage(
        recipientId: recipientId,
        message: message.trim(),
      );

      if (result.containsKey('error')) {
        showCustomSnackBar(title: 'error'.tr, message: result['error'], isError: true);
        return;
      }

      Get.back(); // Close dialog
      
      // Show enhanced success message
      showCustomSnackBar(
        title: 'greeting_sent_successfully'.tr,
        message: 'greeting_sent_successfully_message'.tr,
      );
      
      // Swipe the card right (like) after sending message
      if (Get.isRegistered<DiscoverController>()) {
        try {
          final discoverController = Get.find<DiscoverController>();
          final currentProfile = discoverController.currentProfile;
          
          if (currentProfile != null && currentProfile.id == recipientId) {
            // Trigger programmatic swipe right
            // This will handle the backend swipe and UI animation
            discoverController.triggerSwipeRight();
          }
        } catch (e) {
          print('Error swiping card after message: $e');
        }
      }
    } catch (e) {
      showCustomSnackBar(title: 'error'.tr, message: '${'failed_to_send_message'.tr}: $e', isError: true);
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
                  // Premium icon with gradient
                  Container(
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: ctaColors,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: borderColor.withValues(alpha: 0.3),
                          blurRadius: 15,
                          spreadRadius: 3,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.auto_awesome,
                      size: 32.sp,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  // Title with gradient
                  ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(
                      colors: ctaColors,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ).createShader(bounds),
                    child: Text(
                      '✨ Premium Feature ✨',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24.sp,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  // Subtitle
                  Text(
                    'Personalized Greeting for Introduction',
                    style: TextStyle(
                      color: themeController.whiteColor,
                      fontSize: 17.sp,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 16.h),
                  // Description with icon
                  Container(
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: borderColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14.r),
                      border: Border.all(
                        color: borderColor.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '💝 Love at first sight needs no approval',
                          style: TextStyle(
                            color: themeController.whiteColor,
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w600,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 12.h),
                        Text(
                          'Try sending a personalized greeting for introduction which increases 5 times your chances of a match!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: themeController.whiteColor.withValues(alpha: 0.85),
                            fontSize: 14.sp,
                            height: 1.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 12.h),
                        // Stats badge
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.greenAccent.withValues(alpha: 0.2),
                                Colors.tealAccent.withValues(alpha: 0.2),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20.r),
                            border: Border.all(
                              color: Colors.greenAccent.withValues(alpha: 0.4),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.trending_up,
                                color: Colors.greenAccent,
                                size: 16.sp,
                              ),
                              SizedBox(width: 6.w),
                              Text(
                                '5x Better Match Rate',
                                style: TextStyle(
                                  color: Colors.greenAccent,
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20.h),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => Get.back(),
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 14.h),
                            decoration: BoxDecoration(
                              color: themeController.whiteColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(25.r),
                              border: Border.all(
                                color: themeController.whiteColor.withValues(alpha: 0.4),
                                width: 1.5,
                              ),
                            ),
                            child: Text(
                              'Not Now',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: themeController.whiteColor,
                                fontSize: 15.sp,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        flex: 2,
                        child: GestureDetector(
                          onTap: () {
                            Get.back();
                            Get.to(() => SubscriptionScreen());
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 8.w),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: ctaColors,
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(25.r),
                              border: Border.all(
                                color: borderColor.withValues(alpha: 0.6),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: borderColor.withValues(alpha: 0.4),
                                  blurRadius: 12,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Text(
                              'Get Premium ✨',
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15.sp,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.3,
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
