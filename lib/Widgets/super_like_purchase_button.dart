import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../services/in_app_purchase_service.dart';

class SuperLikePurchaseButton extends StatelessWidget {
  final VoidCallback? onPurchaseSuccess;
  final VoidCallback? onPurchaseError;

  const SuperLikePurchaseButton({
    Key? key,
    this.onPurchaseSuccess,
    this.onPurchaseError,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: ElevatedButton(
        onPressed: () {
          InAppPurchaseService.showSuperLikePurchaseDialog();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.amber.shade600,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25.r),
          ),
          elevation: 4,
          shadowColor: Colors.amber.withOpacity(0.3),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.star, size: 18.sp),
            SizedBox(width: 8.w),
            Text(
              'Buy More Super Likes',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Quick purchase buttons for different packages
class QuickSuperLikePurchaseButtons extends StatelessWidget {
  const QuickSuperLikePurchaseButtons({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      child: Column(
        children: [
          Text(
            'Buy Super Likes',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          
          SizedBox(height: 16.h),
          
          // 5 Super Likes
          _buildQuickPurchaseButton(
            title: '5 Super Likes',
            price: '₹99',
            onTap: () => InAppPurchaseService.purchaseSuperLikes('super_like_5'),
          ),
          
          SizedBox(height: 8.h),
          
          // 10 Super Likes (Best Value)
          _buildQuickPurchaseButton(
            title: '10 Super Likes',
            price: '₹179',
            subtitle: 'Best Value',
            isRecommended: true,
            onTap: () => InAppPurchaseService.purchaseSuperLikes('super_like_10'),
          ),
          
          SizedBox(height: 8.h),
          
          // 20 Super Likes
          _buildQuickPurchaseButton(
            title: '20 Super Likes',
            price: '₹299',
            subtitle: 'Maximum Impact',
            onTap: () => InAppPurchaseService.purchaseSuperLikes('super_like_20'),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickPurchaseButton({
    required String title,
    required String price,
    String? subtitle,
    bool isRecommended = false,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: isRecommended ? Colors.amber.shade600 : Colors.grey.shade300,
          width: isRecommended ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(12.r),
        color: isRecommended ? Colors.amber.shade50 : Colors.white,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.r),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Row(
            children: [
              // Star icon
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: Colors.amber.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.star,
                  color: Colors.amber.shade700,
                  size: 20.sp,
                ),
              ),
              
              SizedBox(width: 12.w),
              
              // Title and subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    if (subtitle != null) ...[
                      SizedBox(height: 2.h),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              
              // Price
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    price,
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.amber.shade700,
                    ),
                  ),
                  if (isRecommended) ...[
                    SizedBox(height: 2.h),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade600,
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Text(
                        'RECOMMENDED',
                        style: TextStyle(
                          fontSize: 8.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
