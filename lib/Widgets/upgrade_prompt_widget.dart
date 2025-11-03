import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../services/supabase_service.dart';
import '../services/in_app_purchase_service.dart';
import '../widgets/super_like_purchase_button.dart';
import '../Widgets/super_like_purchase_dialog.dart';
import '../Screens/SubscriptionPage/ui_subscription_screen.dart';
import '../ThemeController/theme_controller.dart';
import '../Screens/DiscoverPage/controller_discover_screen.dart';

class UpgradePromptWidget extends StatelessWidget {
  final String title;
  final String message;
  final String action;
  final String? limitType; // 'swipe', 'super_like', 'message'
  final VoidCallback? onUpgrade;
  final VoidCallback? onDismiss;
  final IconData? icon;
  final List<Color>? gradientColors;
  final String? dismissLabel;
  final Color? accentColor;

  const UpgradePromptWidget({
    Key? key,
    required this.title,
    required this.message,
    required this.action,
    this.limitType,
    this.onUpgrade,
    this.onDismiss,
    this.icon,
    this.gradientColors,
    this.dismissLabel,
    this.accentColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();
    
    // Detect current mode (dating/bff) - EXACT copy from rewind dialog
    bool isBffMode = false;
    if (Get.isRegistered<DiscoverController>()) {
      try {
        final d = Get.find<DiscoverController>();
        isBffMode = (d.currentMode.value == 'bff');
      } catch (_) {}
    }

    // Pick gradient colors based on mode - EXACT copy from rewind dialog
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
    final Color iconColor = isBffMode
        ? themeController.bffPrimaryColor
        : themeController.getAccentColor();
    final List<Color> ctaColors = isBffMode
        ? [themeController.bffPrimaryColor, themeController.bffSecondaryColor]
        : [themeController.getAccentColor(), themeController.getSecondaryColor()];

    return Dialog(
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
                  // Icon container - matching rewind dialog
                  Container(
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon ?? _getIcon(),
                      size: 32.sp,
                      color: iconColor,
                    ),
                  ),
                  
                  SizedBox(height: 16.h),
                  
                  // Title
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: themeController.whiteColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  SizedBox(height: 8.h),
                  
                  // Message
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: themeController.whiteColor.withValues(alpha: 0.8),
                      height: 1.4,
                    ),
                  ),
                  
                  SizedBox(height: 20.h),
                  
                  // Action buttons - matching rewind dialog
                  Row(
                    children: [
                      if (onDismiss != null) ...[
                        Expanded(
                          child: GestureDetector(
                            onTap: onDismiss,
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
                                dismissLabel ?? 'Maybe Later',
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
                      ],
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            if (onUpgrade != null) {
                              onUpgrade!();
                            } else {
                              Get.to(() => SubscriptionScreen());
                            }
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
                              action,
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
    );
  }

  IconData _getIcon() {
    if (icon != null) return icon!;
    switch (limitType) {
      case 'swipe':
        return Icons.swipe;
      case 'super_like':
        return Icons.star;
      case 'message':
        return Icons.message;
      default:
        return Icons.lock;
    }
  }
}

// Specialized widgets for different limit types
class SwipeLimitWidget extends StatelessWidget {
  final VoidCallback? onUpgrade;
  final VoidCallback? onDismiss;

  const SwipeLimitWidget({
    Key? key,
    this.onUpgrade,
    this.onDismiss,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return UpgradePromptWidget(
      title: 'Daily Swipe Limit Reached',
      message: 'You\'ve used all 20 free swipes today. Upgrade for unlimited swipes and see who liked you!',
      action: 'Upgrade Now',
      limitType: 'swipe',
      onUpgrade: onUpgrade,
      onDismiss: onDismiss,
    );
  }
}

class SuperLikeLimitWidget extends StatelessWidget {
  final VoidCallback? onUpgrade;
  final VoidCallback? onBuyMore;
  final VoidCallback? onDismiss;

  const SuperLikeLimitWidget({
    Key? key,
    this.onUpgrade,
    this.onBuyMore,
    this.onDismiss,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Use UpgradePromptWidget but change action to "Buy More" and navigate to SuperLikePurchaseDialog
    return UpgradePromptWidget(
      title: 'Daily Super Like Limit Reached',
      message: 'You\'ve used your free super like today. Buy more super likes or upgrade for unlimited super likes!',
      action: 'Buy More',
      limitType: 'super_like',
      onUpgrade: () {
        Get.back(); // Close current dialog
        Get.dialog(SuperLikePurchaseDialog(), barrierDismissible: true);
      },
      onDismiss: onDismiss,
    );
  }
}

class MessageLimitWidget extends StatelessWidget {
  final VoidCallback? onUpgrade;
  final VoidCallback? onDismiss;

  const MessageLimitWidget({
    Key? key,
    this.onUpgrade,
    this.onDismiss,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return UpgradePromptWidget(
      title: 'Daily Message Limit Reached',
      message: 'You\'ve sent your free message today. Upgrade for unlimited messaging and send photos!',
      action: 'Upgrade Now',
      limitType: 'message',
      onUpgrade: onUpgrade,
      onDismiss: onDismiss,
    );
  }
}
