import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'supabase_service.dart';
import 'payment_service.dart';
import '../widgets/upgrade_prompt_widget.dart';
import '../Screens/SubscriptionPage/ui_subscription_screen.dart';
import 'package:lovebug/Common/widget_constant.dart';


class InAppPurchaseService {
  static final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  static final Stream<List<PurchaseDetails>> _purchaseStream = _inAppPurchase.purchaseStream;
  
  // Product IDs for different purchases
  // These must match exactly with your Google Play Console and App Store Connect
  // IMPORTANT: Use the product IDs from IAP_PRODUCT_DETAILS.md
  // See IAP_PRODUCT_DETAILS.md for complete setup instructions, descriptions, and review notes
  static const Map<String, String> productIds = {
    // Super Like Packages
    'super_like_5': 'super_like_5',
    'super_like_10': 'super_like_10',
    'super_like_20': 'super_like_20',
    
    // Premium Subscriptions
    'premium_1_month': '1_month',
    'premium_3_months': '3_month',
    'premium_6_months': '6_month',
  };


  // Pricing for different products
  static const Map<String, Map<String, dynamic>> productPricing = {
    'super_like_5': {
      'price': 99.0,
      'currency': 'INR',
      'title': '5 Super Loves',
      'description': 'You’re 3x more likely to match!',
    },
    'super_like_10': {
      'price': 179.0,
      'currency': 'INR', 
      'title': '10 Super Loves Pack',
      'description': 'Get 10 Super Loves • Popular Choice',
    },
    'super_like_20': {
      'price': 299.0,
      'currency': 'INR',
      'title': '20 Super Loves Pack', 
      'description': 'Get 20 Super Loves • Best Value',
    },

    'premium_1_month': {
      'price': 1500.0,
      'currency': 'INR',
      'title': 'Premium - 1 Month',
      'description': 'Unlimited swipes, calls, media, and more!',
    },
    'premium_3_months': {
      'price': 2250.0,
      'currency': 'INR',
      'title': 'Premium - 3 Months',
      'description': '3 months of full premium access',
    },
    'premium_6_months': {
      'price': 3600.0,
      'currency': 'INR',
      'title': 'Premium - 6 Months',
      'description': '6 months of full premium access',
    },
  };

  static bool _isInitialized = false;

  // Initialize in-app purchases
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      final bool isAvailable = await _inAppPurchase.isAvailable();
      if (!isAvailable) {
        print('In-app purchases not available');
        return;
      }

      // Listen to purchase stream
      _purchaseStream.listen((List<PurchaseDetails> purchaseDetailsList) {
        _handlePurchases(purchaseDetailsList);
      });

      _isInitialized = true;
      print('In-app purchases initialized successfully');
    } catch (e) {
      print('Error initializing in-app purchases: $e');
    }
  }

  // Handle purchase updates
  static void _handlePurchases(List<PurchaseDetails> purchaseDetailsList) {
    for (final PurchaseDetails purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        _showPendingUI();
      } else {
        if (purchaseDetails.status == PurchaseStatus.error) {
          _handleError(purchaseDetails.error!);
        } else if (purchaseDetails.status == PurchaseStatus.purchased ||
                   purchaseDetails.status == PurchaseStatus.restored) {
          _handleSuccessfulPurchase(purchaseDetails);
        }
        
        if (purchaseDetails.pendingCompletePurchase) {
          _inAppPurchase.completePurchase(purchaseDetails);
        }
      }
    }
  }

  // Show pending purchase UI
  static void _showPendingUI() {
    showCustomSnackBar(
      title: 'processing_purchase'.tr,
      message: 'purchase_processing_message'.tr,
    );
  }

  // Handle purchase errors
  static void _handleError(IAPError error) {
    showCustomSnackBar(
      title: 'purchase_failed'.tr,
      message: error.message,
      isError: true,
    );
  }

  // Handle successful purchase
  static Future<void> _handleSuccessfulPurchase(PurchaseDetails purchaseDetails) async {
    try {
      final productId = purchaseDetails.productID;
      final transactionId = purchaseDetails.purchaseID;
      
      // Record purchase in database
      await _recordPurchase(productId, transactionId ?? '');
      
      // Handle different purchase types
      if (productId.contains('super_like')) {
        await _handleSuperLikePurchase(productId);
      } else if (productId.contains('premium')) {
        await _handlePremiumPurchase(productId);
      }
      
      showCustomSnackBar(
        title: 'purchase_successful'.tr,
        message: 'purchase_processed_message'.tr,
      );
    } catch (e) {
      print('Error handling successful purchase: $e');
      showCustomSnackBar(
        title: 'purchase_error'.tr,
        message: '${'failed_to_process_purchase'.tr}: $e',
        isError: true,
      );
    }
  }

  // Record purchase in database
  static Future<void> _recordPurchase(String productId, String transactionId) async {
    try {
      // Detect platform
      String platform = 'unknown';
      try {
        if (Platform.isAndroid) {
          platform = 'google_play';
        } else if (Platform.isIOS) {
          platform = 'apple_pay';
        }
      } catch (e) {
        platform = 'google_play'; // Default fallback
      }
      
      await SupabaseService.client.from('in_app_purchases').insert({
        'user_id': SupabaseService.currentUser?.id,
        'purchase_type': productId,
        'amount': productPricing[productId]?['price'] ?? 0.0,
        'currency': productPricing[productId]?['currency'] ?? 'INR',
        'platform': platform,
        'transaction_id': transactionId,
        'status': 'completed',
      });
    } catch (e) {
      print('Error recording purchase: $e');
    }
  }

  // Handle super like purchase
  static Future<void> _handleSuperLikePurchase(String productId) async {
    try {
      int superLikesToAdd = 0;
      // Support multiple product ID formats for backward compatibility
      switch (productId) {
        // New product IDs (current)
        case 'super_like_3_pack_new':
          superLikesToAdd = 3;
          break;
        case 'super_like_15_pack_new':
          superLikesToAdd = 15;
          break;
        case 'super_like_30_pack_new':
          superLikesToAdd = 30;
          break;
        // Old product IDs (backward compatibility)
        case 'super_like_3_pack':
        case 'lovebug_super_like_3':
        case 'lovebug_spark_connection_pack':
          superLikesToAdd = 3;
          break;
        case 'super_like_15_pack':
        case 'lovebug_super_like_15':
        case 'lovebug_premium_spark_bundle':
          superLikesToAdd = 15;
          break;
        case 'super_like_30_pack':
        case 'lovebug_super_like_30':
        case 'lovebug_ultimate_spark_collection':
          superLikesToAdd = 30;
          break;
      }
      
      // Add super likes to user's account
      await SupabaseService.client.rpc('add_super_likes', params: {
        'user_id': SupabaseService.currentUser?.id,
        'super_likes_to_add': superLikesToAdd,
      });
      
      showCustomSnackBar(
        title: 'super_loves_added'.tr,
        message: 'you_received_super_loves'.tr.replaceAll('\$count', superLikesToAdd.toString()),
      );
    } catch (e) {
      print('Error handling super like purchase: $e');
    }
  }

  // Handle premium subscription purchase
  static Future<void> _handlePremiumPurchase(String productId) async {
    try {
      int durationMonths = 0;
      switch (productId) {
        case 'premium_monthly':
          durationMonths = 1;
          break;
        case 'premium_quarterly':
          durationMonths = 3;
          break;
        case 'premium_semiannual':
          durationMonths = 6;
          break;
      }
      
      // Activate premium subscription
      await SupabaseService.client.rpc('activate_premium_subscription', params: {
        'user_id': SupabaseService.currentUser?.id,
        'duration_months': durationMonths,
        'payment_method': 'in_app_purchase',
      });
      
      showCustomSnackBar(
        title: 'premium_activated'.tr,
        message: 'premium_activated_message'.tr,
      );
    } catch (e) {
      print('Error handling premium purchase: $e');
    }
  }

  // Purchase super likes
  static Future<void> purchaseSuperLikes(String packageType) async {
    try {
      final user = SupabaseService.currentUser;
      if (user == null) {
        showCustomSnackBar(title: 'error'.tr, message: 'please_login_first'.tr, isError: true);
        return;
      }

      final planKey = productIds[packageType] ?? packageType;
      
      print('🚀 Routing SuperLike purchase to Cashfree: $planKey');
      
      await PaymentService.initiatePayment(
        planType: planKey,
        userEmail: user.email ?? '',
        userName: user.userMetadata?['name'] ?? user.email?.split('@')[0] ?? 'User',
      );
    } catch (e) {
      print('Error purchasing super likes: $e');
      showCustomSnackBar(title: 'error'.tr, message: '${'failed_to_initiate_purchase'.tr}: $e', isError: true);
    }
  }


  // Purchase premium subscription
  static Future<void> purchasePremium(String planType) async {
    try {
      final user = SupabaseService.currentUser;
      if (user == null) {
        showCustomSnackBar(title: 'error'.tr, message: 'please_login_first'.tr, isError: true);
        return;
      }

      final planKey = productIds[planType] ?? planType;
      
      print('🚀 Routing Premium purchase to Cashfree: $planKey');

      await PaymentService.initiatePayment(
        planType: planKey,
        userEmail: user.email ?? '',
        userName: user.userMetadata?['name'] ?? user.email?.split('@')[0] ?? 'User',
      );
    } catch (e) {
      print('Error purchasing premium: $e');
      showCustomSnackBar(title: 'error'.tr, message: '${'failed_to_initiate_purchase'.tr}: $e', isError: true);
    }
  }


  // Get product details
  static Future<ProductDetails?> _getProductDetails(String productId) async {
    try {
      final ProductDetailsResponse response = await _inAppPurchase.queryProductDetails({productId});
      if (response.notFoundIDs.isNotEmpty) {
        print('Product not found: $productId');
        return null;
      }
      return response.productDetails.first;
    } catch (e) {
      print('Error getting product details: $e');
      return null;
    }
  }

  // Show super like purchase dialog
  static void showSuperLikePurchaseDialog() {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Container(
          padding: EdgeInsets.all(20.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Title
              Text(
                'Buy Super Loves',
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              
              SizedBox(height: 16.h),
              
              // Super like packages
              ...productPricing.entries
                  .where((entry) => entry.key.contains('super_like'))
                  .map((entry) => _buildSuperLikePackage(entry.key, entry.value))
                  .toList(),
              
              SizedBox(height: 16.h),
              
              // Cancel button
              OutlinedButton(
                onPressed: () => Get.back(),
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
                child: Text('Cancel'),
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: true,
    );
  }

  // Build super like package widget
  static Widget _buildSuperLikePackage(String packageId, Map<String, dynamic> pricing) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      child: InkWell(
        onTap: () {
          Get.back();
          purchaseSuperLikes(packageId);
        },
        child: Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.amber.shade300),
            borderRadius: BorderRadius.circular(12.r),
            color: Colors.amber.shade50,
          ),
          child: Row(
            children: [
              Icon(Icons.star, color: Colors.amber.shade700, size: 24.sp),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pricing['title'],
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      pricing['description'],
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '₹${pricing['price'].toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber.shade700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
