import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../services/supabase_service.dart';
import '../services/in_app_purchase_service.dart';
import '../widgets/super_like_purchase_button.dart';
import '../Screens/SubscriptionPage/ui_subscription_screen.dart';

class UpgradePromptWidget extends StatelessWidget {
  final String title;
  final String message;
  final String action;
  final String? limitType; // 'swipe', 'super_like', 'message'
  final VoidCallback? onUpgrade;
  final VoidCallback? onDismiss;

  const UpgradePromptWidget({
    Key? key,
    required this.title,
    required this.message,
    required this.action,
    this.limitType,
    this.onUpgrade,
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
            Colors.pink.withOpacity(0.1),
            Colors.purple.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: Colors.pink.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: Colors.pink.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getIcon(),
              size: 24.w,
              color: Colors.pink,
            ),
          ),
          
          SizedBox(height: 16.h),
          
          // Title
          Text(
            title,
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
            message,
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
              
              if (onDismiss != null) SizedBox(width: 12.w),
              
              // Upgrade button
              Expanded(
                flex: onDismiss != null ? 2 : 1,
                child: ElevatedButton(
                  onPressed: () {
                    if (onUpgrade != null) {
                      onUpgrade!();
                    } else {
                      Get.to(() => SubscriptionScreen());
                    }
                  },
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
                    action,
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

  IconData _getIcon() {
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
