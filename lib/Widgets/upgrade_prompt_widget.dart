import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../services/supabase_service.dart';
import '../services/in_app_purchase_service.dart';
import '../widgets/super_like_purchase_button.dart';
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
    final List<Color> ctaColors = isBffMode
        ? [themeController.bffPrimaryColor, themeController.bffSecondaryColor]
        : [themeController.getAccentColor(), themeController.getSecondaryColor()];

    return BackdropFilter(
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
                  title,
                  style: TextStyle(
                    color: themeController.whiteColor,
                    fontSize: 22.sp,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16.h),
                Text(
                  message,
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
                                fontSize: 15,
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
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
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
    return Container(
      margin: EdgeInsets.all(16.w),
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.amber.withOpacity(0.1),
            Colors.orange.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: Colors.amber.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Star icon
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.star,
              size: 24.w,
              color: Colors.amber.shade700,
            ),
          ),
          
          SizedBox(height: 16.h),
          
          // Title
          Text(
            'Daily Super Like Limit Reached',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          
          SizedBox(height: 8.h),
          
          // Message
          Text(
            'You\'ve used your free super like today. Buy more super likes or upgrade for unlimited super likes!',
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.black54,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          
          SizedBox(height: 20.h),
          
          // Action buttons
          Row(
            children: [
              // Dismiss button
              if (onDismiss != null)
                Expanded(
                  child: OutlinedButton(
                    onPressed: onDismiss,
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                    child: Text(
                      'Maybe Later',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                ),
              
              if (onDismiss != null) SizedBox(width: 8.w),
              
              // Buy more button
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    Get.back(); // Close current dialog
                    InAppPurchaseService.showSuperLikePurchaseDialog();
                  },
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    side: BorderSide(color: Colors.amber.shade700),
                  ),
                  child: Text(
                    'Buy More',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Colors.amber.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              
              SizedBox(width: 8.w),
              
              // Upgrade button
              Expanded(
                child: ElevatedButton(
                  onPressed: onUpgrade,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pink,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    elevation: 2,
                  ),
                  child: Text(
                    'Upgrade',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
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
