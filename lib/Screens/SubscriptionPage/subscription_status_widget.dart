import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'controller_subscription_screen.dart';
import 'subscription_plans_screen.dart';

class SubscriptionStatusWidget extends StatelessWidget {
  const SubscriptionStatusWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<SubscriptionController>(
      init: SubscriptionController(),
      builder: (controller) {
        return Container(
          margin: EdgeInsets.all(16.w),
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: controller.isPremiumActive
                  ? [const Color(0xFFE91E63), const Color(0xFF9C27B0)]
                  : [Colors.grey.withOpacity(0.3), Colors.grey.withOpacity(0.1)],
            ),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: controller.isPremiumActive
                  ? const Color(0xFFE91E63)
                  : Colors.grey.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    controller.isPremiumActive ? Icons.star : Icons.person,
                    color: controller.isPremiumActive
                        ? Colors.yellow
                        : Colors.grey,
                    size: 20.w,
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    controller.isPremiumActive ? 'Premium Active' : 'Free Plan',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  if (controller.isPremiumActive)
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Text(
                        '${controller.daysRemaining} days left',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              
              SizedBox(height: 8.h),
              
              Text(
                controller.getSubscriptionStatusText(),
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 12.sp,
                ),
              ),
              
              SizedBox(height: 12.h),
              
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Get.to(() => const SubscriptionPlansScreen());
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: controller.isPremiumActive
                            ? Colors.white.withOpacity(0.2)
                            : const Color(0xFFE91E63),
                        padding: EdgeInsets.symmetric(vertical: 8.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                      ),
                      child: Text(
                        controller.isPremiumActive ? 'Manage' : 'Upgrade',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  
                  if (controller.isPremiumActive) ...[
                    SizedBox(width: 8.w),
                    ElevatedButton(
                      onPressed: () {
                        _showCancelDialog(context, controller);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.withOpacity(0.2),
                        padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 12.w),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showCancelDialog(BuildContext context, SubscriptionController controller) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A2E),
          title: Text(
            'Cancel Subscription',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'Are you sure you want to cancel your premium subscription? You will lose access to premium features immediately.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 14.sp,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Keep Subscription',
                style: TextStyle(
                  color: Colors.green,
                  fontSize: 14.sp,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                controller.cancelSubscription();
              },
              child: Text(
                'Cancel Subscription',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 14.sp,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}



