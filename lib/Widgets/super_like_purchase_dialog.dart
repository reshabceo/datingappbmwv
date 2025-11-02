import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../services/in_app_purchase_service.dart';

class SuperLikePurchaseDialog extends StatelessWidget {
  const SuperLikePurchaseDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.r),
          color: const Color(0xFF101214),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Stand out with Super Like. You’re 3x more likely to get a match!',
              style: TextStyle(color: Colors.white, fontSize: 16.sp, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 12.h),
            _buildPack(
              title: '3 Super Likes',
              trailing: '₹299.67/ea',
              onTap: () => _buy('super_like_3'),
            ),
            SizedBox(height: 10.h),
            _buildLabeledPack(
              label: 'Popular',
              title: '15 Super Likes',
              trailing: '₹226.60/ea',
              onTap: () => _buy('super_like_15'),
            ),
            SizedBox(height: 10.h),
            _buildLabeledPack(
              label: 'Best Value',
              title: '30 Super Likes',
              trailing: '₹173.33/ea',
              onTap: () => _buy('super_like_30'),
            ),
            SizedBox(height: 12.h),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Get.back(),
                child: const Text('Close'),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildPack({required String title, required String trailing, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: const Color(0xFF161A1D),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(title, style: TextStyle(color: Colors.white, fontSize: 16.sp, fontWeight: FontWeight.w600)),
            ),
            Text(trailing, style: TextStyle(color: Colors.white70, fontSize: 14.sp)),
          ],
        ),
      ),
    );
  }

  Widget _buildLabeledPack({
    required String label,
    required String title,
    required String trailing,
    required VoidCallback onTap,
  }) {
    return Stack(
      children: [
        _buildPack(title: title, trailing: trailing, onTap: onTap),
        Positioned(
          top: 6.h,
          right: 10.w,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Text(label, style: TextStyle(color: Colors.white, fontSize: 10.sp, fontWeight: FontWeight.w700)),
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




