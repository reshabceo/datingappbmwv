import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../services/payment_service.dart';
import '../../services/supabase_service.dart';
import 'controller_subscription_screen.dart';

class SubscriptionPlansScreen extends StatelessWidget {
  const SubscriptionPlansScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<SubscriptionController>(
      init: SubscriptionController(),
      builder: (controller) {
        return Scaffold(
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF1A1A2E),
                  Color(0xFF16213E),
                  Color(0xFF0F3460),
                ],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // Header
                  Padding(
                    padding: EdgeInsets.all(20.w),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => Get.back(),
                          child: Container(
                            padding: EdgeInsets.all(8.w),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            child: Icon(
                              Icons.arrow_back_ios,
                              color: Colors.white,
                              size: 20.w,
                            ),
                          ),
                        ),
                        SizedBox(width: 16.w),
                        Text(
                          'Choose Your Plan',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Pre-launch banner
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: 20.w),
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF6B35), Color(0xFFFF8E53)],
                      ),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.local_fire_department,
                          color: Colors.white,
                          size: 24.w,
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Pre-Launch Offer',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'All plans include 25% pre-launch discount',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 12.sp,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  SizedBox(height: 24.h),
                  
                  // Subscription Plans
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.symmetric(horizontal: 20.w),
                      child: Column(
                        children: [
                          // Free Plan
                          _buildPlanCard(
                            context: context,
                            title: 'Free',
                            subtitle: 'Forever',
                            icon: Icons.flash_on,
                            features: [
                              'Browse public profiles',
                              'View limited stories',
                              'Basic search filters',
                              'Create your profile',
                              'Limited matches',
                            ],
                            isFree: true,
                            onTap: () {
                              Get.back();
                            },
                          ),
                          
                          SizedBox(height: 20.h),
                          
                          // Premium Plans
                          Text(
                            'Premium Plans',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          
                          SizedBox(height: 16.h),
                          
                          // 1 Month Plan
                          _buildPremiumPlanCard(
                            context: context,
                            planType: '1_month',
                            title: 'Premium - 1 Month',
                            price: '₹15.00',
                            originalPrice: '₹20.00',
                            discount: '25%',
                            features: [
                              'Everything in Free',
                              'See who liked you',
                              'Priority visibility',
                              'Advanced filters',
                              'Read receipts',
                              'Unlimited matches',
                              'Super loves',
                              'Profile boost',
                            ],
                            onTap: () => controller.initiatePayment('1_month'),
                          ),
                          
                          SizedBox(height: 16.h),
                          
                          // 3 Month Plan
                          _buildPremiumPlanCard(
                            context: context,
                            planType: '3_month',
                            title: 'Premium - 3 Months',
                            price: '₹22.50',
                            originalPrice: '₹45.00',
                            discount: '50%',
                            features: [
                              'Everything in Free',
                              'See who liked you',
                              'Priority visibility',
                              'Advanced filters',
                              'Read receipts',
                              'Unlimited matches',
                              'Super loves',
                              'Profile boost',
                            ],
                            onTap: () => controller.initiatePayment('3_month'),
                          ),
                          
                          SizedBox(height: 16.h),
                          
                          // 6 Month Plan (Most Popular)
                          _buildPremiumPlanCard(
                            context: context,
                            planType: '6_month',
                            title: 'Premium - 6 Months',
                            price: '₹36.00',
                            originalPrice: '₹90.00',
                            discount: '60%',
                            features: [
                              'Everything in Free',
                              'See who liked you',
                              'Priority visibility',
                              'Advanced filters',
                              'Read receipts',
                              'Unlimited matches',
                              'Super loves',
                              'Profile boost',
                            ],
                            isPopular: true,
                            onTap: () => controller.initiatePayment('6_month'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPlanCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required List<String> features,
    required bool isFree,
    required VoidCallback onTap,
  }) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: isFree ? Colors.yellow : Colors.purple,
                size: 24.w,
              ),
              SizedBox(width: 12.w),
              Text(
                title,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 14.sp,
                ),
              ),
            ],
          ),
          
          SizedBox(height: 16.h),
          
          ...features.map((feature) => Padding(
            padding: EdgeInsets.only(bottom: 8.h),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 16.w,
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    feature,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14.sp,
                    ),
                  ),
                ),
              ],
            ),
          )),
          
          SizedBox(height: 20.h),
          
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: isFree ? Colors.grey : const Color(0xFFE91E63),
                padding: EdgeInsets.symmetric(vertical: 12.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              child: Text(
                isFree ? 'Start Free' : 'Upgrade to Premium',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumPlanCard({
    required BuildContext context,
    required String planType,
    required String title,
    required String price,
    required String originalPrice,
    required String discount,
    required List<String> features,
    required VoidCallback onTap,
    bool isPopular = false,
  }) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.1),
            Colors.white.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isPopular ? const Color(0xFFE91E63) : Colors.white.withOpacity(0.2),
          width: isPopular ? 2 : 1,
        ),
      ),
      child: Stack(
        children: [
          if (isPopular)
            Positioned(
              top: -1,
              right: 20.w,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: const Color(0xFFE91E63),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Text(
                  '★ Most Popular',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.star,
                    color: const Color(0xFFE91E63),
                    size: 24.w,
                  ),
                  SizedBox(width: 12.w),
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: 12.h),
              
              Row(
                children: [
                  Text(
                    price,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    originalPrice,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 16.sp,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Text(
                      '$discount OFF',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: 16.h),
              
              ...features.map((feature) => Padding(
                padding: EdgeInsets.only(bottom: 8.h),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 16.w,
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        feature,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 14.sp,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
              
              SizedBox(height: 20.h),
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onTap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE91E63),
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  child: Text(
                    'Upgrade to Premium',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16.sp,
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



