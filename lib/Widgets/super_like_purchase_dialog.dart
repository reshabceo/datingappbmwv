import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../services/in_app_purchase_service.dart';
import '../ThemeController/theme_controller.dart';
import '../Screens/DiscoverPage/controller_discover_screen.dart';

class SuperLikePurchaseDialog extends StatelessWidget {
  const SuperLikePurchaseDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();

    // Detect current mode (dating/bff)
    bool isBffMode = false;
    if (Get.isRegistered<DiscoverController>()) {
      try {
        final d = Get.find<DiscoverController>();
        isBffMode = (d.currentMode.value == 'bff');
      } catch (_) {}
    }

    // Use solid background color matching premium_message_service theme
    final Color backgroundColor = isBffMode
        ? themeController.bffPrimaryColor.withValues(alpha: 0.15)
        : themeController.getAccentColor().withValues(alpha: 0.15);

    final Color borderColor = isBffMode 
        ? themeController.bffPrimaryColor.withValues(alpha: 0.35)
        : themeController.getAccentColor().withValues(alpha: 0.35);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: 24.w),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(22.r),
            border: Border.all(
              color: borderColor,
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Stand out with Super Like',
                    style: TextStyle(
                      color: themeController.whiteColor, 
                      fontSize: 18.sp, 
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    'You\'re 3x more likely to get a match!',
                    style: TextStyle(
                      color: themeController.whiteColor.withOpacity(0.8), 
                      fontSize: 14.sp,
                      height: 1.4,
                    ),
                  ),
                  SizedBox(height: 20.h),
                  
                  // Super Like Packs
                  _buildPackItem(
                    title: '3 Super Likes',
                    pricePerItem: '₹299.67/ea',
                    totalPrice: '₹899',
                    onTap: () => _buy('super_like_3'),
                    themeController: themeController,
                  ),
                  SizedBox(height: 12.h),
                  
                  _buildPopularPackItem(
                    title: '15 Super Likes',
                    pricePerItem: '₹226.60/ea',
                    totalPrice: '₹3,399',
                    onTap: () => _buy('super_like_15'),
                    themeController: themeController,
                  ),
                  SizedBox(height: 12.h),
                  
                  _buildBestValuePackItem(
                    title: '30 Super Likes',
                    pricePerItem: '₹173.33/ea',
                    totalPrice: '₹5,200',
                    onTap: () => _buy('super_like_30'),
                    themeController: themeController,
                  ),
                  
                  SizedBox(height: 16.h),
                  _buildFooter(themeController),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPackItem({
    required String title,
    required String pricePerItem,
    required String totalPrice,
    required VoidCallback onTap,
    required ThemeController themeController,
    bool isPopular = false,
    bool isBestValue = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: themeController.whiteColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: isPopular 
                ? Colors.amber 
                : isBestValue 
                  ? Colors.green 
                  : themeController.whiteColor.withOpacity(0.3),
            width: isPopular || isBestValue ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isPopular || isBestValue) ...[
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                      decoration: BoxDecoration(
                        color: isPopular ? Colors.amber : Colors.green,
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                      child: Text(
                        isPopular ? 'POPULAR' : 'BEST VALUE',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    SizedBox(height: 8.h),
                  ],
                  Text(
                    title,
                    style: TextStyle(
                      color: themeController.whiteColor, 
                      fontSize: 16.sp, 
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    pricePerItem,
                    style: TextStyle(
                      color: themeController.whiteColor.withOpacity(0.7), 
                      fontSize: 12.sp,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 12.w),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  totalPrice,
                  style: TextStyle(
                    color: themeController.whiteColor,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 2.h),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: themeController.getAccentColor().withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text(
                    'BUY',
                    style: TextStyle(
                      color: themeController.whiteColor,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPopularPackItem({
    required String title,
    required String pricePerItem,
    required String totalPrice,
    required VoidCallback onTap,
    required ThemeController themeController,
  }) {
    return _buildPackItem(
      title: title,
      pricePerItem: pricePerItem,
      totalPrice: totalPrice,
      onTap: onTap,
      themeController: themeController,
      isPopular: true,
    );
  }

  Widget _buildBestValuePackItem({
    required String title,
    required String pricePerItem,
    required String totalPrice,
    required VoidCallback onTap,
    required ThemeController themeController,
  }) {
    return _buildPackItem(
      title: title,
      pricePerItem: pricePerItem,
      totalPrice: totalPrice,
      onTap: onTap,
      themeController: themeController,
      isBestValue: true,
    );
  }

  Widget _buildFooter(ThemeController themeController) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        TextButton(
          onPressed: () => Get.back(),
          style: TextButton.styleFrom(
            foregroundColor: themeController.whiteColor.withOpacity(0.8),
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          ),
          child: Text(
            'Cancel',
            style: TextStyle(fontSize: 14.sp),
          ),
        ),
        Container(
          width: 1.w,
          height: 20.h,
          color: themeController.whiteColor.withOpacity(0.3),
        ),
        TextButton(
          onPressed: () {
            // Add restore purchases functionality
          },
          style: TextButton.styleFrom(
            foregroundColor: themeController.whiteColor.withOpacity(0.8),
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          ),
          child: Text(
            'Restore Purchases',
            style: TextStyle(fontSize: 14.sp),
          ),
        ),
      ],
    );
  }

  void _buy(String packageKey) {
    Get.back();
    InAppPurchaseService.purchaseSuperLikes(packageKey);
  }
}