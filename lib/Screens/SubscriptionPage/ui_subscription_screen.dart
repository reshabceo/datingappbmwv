import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../services/in_app_purchase_service.dart';
import '../../ThemeController/theme_controller.dart';
import 'dart:ui';

class SubscriptionScreen extends StatelessWidget {
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    InAppPurchaseService.initialize();
    final themeController = Get.find<ThemeController>();
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black,
              themeController.bgGradient1,
              Colors.black,
            ],
          ),
        ),
        child: Stack(
          children: [
            // Blurred backdrop like the upgrade prompt
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(color: Colors.black.withOpacity(0.25)),
            ),
            SafeArea(
              child: Padding(
                padding: EdgeInsets.all(20.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  // Top bar with back + title (styled like prompt)
                  Row(
                    children: [
                      GestureDetector(
                        onTap: Get.back,
                        child: Container(
                          width: 36.w,
                          height: 36.w,
                          decoration: BoxDecoration(
                            color: themeController.whiteColor.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: themeController.whiteColor.withValues(alpha: 0.3),
                              width: 1.5,
                            ),
                          ),
                          child: const Icon(Icons.arrow_back, color: Colors.white),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Text(
                        'Go Premium',
                        style: TextStyle(
                          color: themeController.whiteColor,
                          fontSize: 20.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20.h),
                  // Card styled like UpgradePromptWidget
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            themeController.getAccentColor().withValues(alpha: 0.15),
                            themeController.getSecondaryColor().withValues(alpha: 0.15),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(22.r),
                        border: Border.all(
                          color: themeController.getAccentColor().withValues(alpha: 0.35),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: themeController.getAccentColor().withValues(alpha: 0.15),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(20.w),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Unlock everything',
                              style: TextStyle(
                                color: themeController.whiteColor,
                                fontSize: 22.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 8.h),
                            Text(
                              'Unlimited swipes, super likes, calls, media and more',
                              style: TextStyle(
                                color: themeController.whiteColor.withValues(alpha: 0.8),
                                fontSize: 14.sp,
                              ),
                            ),
                            SizedBox(height: 16.h),
                            _buildBenefit(icon: Icons.swipe, text: 'Unlimited swipes', themeController: themeController),
                            _buildBenefit(icon: Icons.star, text: 'Unlimited super likes', themeController: themeController),
                            _buildBenefit(icon: Icons.lock_open, text: 'Send images and audio notes', themeController: themeController),
                            _buildBenefit(icon: Icons.videocam, text: 'Audio and video calls', themeController: themeController),
                            _buildBenefit(icon: Icons.visibility, text: 'See who liked you', themeController: themeController),
                            SizedBox(height: 20.h),
                            _buildPlan(
                              title: '1 Month',
                              price: '₹2000',
                              subtitle: 'Billed monthly',
                              onTap: () => InAppPurchaseService.purchasePremium('premium_1_month'),
                              themeController: themeController,
                            ),
                            _buildPlan(
                              title: '3 Months',
                              price: '₹3000',
                              subtitle: 'Billed every 3 months',
                              onTap: () => InAppPurchaseService.purchasePremium('premium_3_months'),
                              themeController: themeController,
                            ),
                            _buildPlan(
                              title: '6 Months',
                              price: '₹5000',
                              subtitle: 'Billed every 6 months',
                              onTap: () => InAppPurchaseService.purchasePremium('premium_6_months'),
                              themeController: themeController,
                            ),
                            const Spacer(),
                            Text(
                              'Payments are processed securely via App Store / Google Play.',
                              style: TextStyle(color: themeController.whiteColor.withValues(alpha: 0.6), fontSize: 12.sp),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBenefit({required IconData icon, required String text, required ThemeController themeController}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        children: [
          Icon(icon, color: themeController.getSecondaryColor()),
          SizedBox(width: 8.w),
          Expanded(child: Text(text, style: TextStyle(fontSize: 14.sp, color: themeController.whiteColor))),
        ],
      ),
    );
  }

  Widget _buildPlan({
    required String title,
    required String price,
    required String subtitle,
    required VoidCallback onTap,
    required ThemeController themeController,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            border: Border.all(color: themeController.getAccentColor().withValues(alpha: 0.5)),
            borderRadius: BorderRadius.circular(12.r),
            color: themeController.whiteColor.withValues(alpha: 0.06),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: themeController.whiteColor)),
                    SizedBox(height: 4.h),
                    Text(subtitle, style: TextStyle(color: themeController.whiteColor.withValues(alpha: 0.7), fontSize: 12.sp)),
                  ],
                ),
              ),
              Text(
                price,
                style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: themeController.getAccentColor()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
