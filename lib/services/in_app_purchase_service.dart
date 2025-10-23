import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'supabase_service.dart';
import '../widgets/upgrade_prompt_widget.dart';
import '../Screens/SubscriptionPage/ui_subscription_screen.dart';

class InAppPurchaseService {
  static final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  static final Stream<List<PurchaseDetails>> _purchaseStream = _inAppPurchase.purchaseStream;
  
  // Product IDs for different purchases
  // These must match exactly with your Google Play Console and App Store Connect
  static const Map<String, String> productIds = {
    'super_like_5': 'super_like_5_pack',
    'super_like_10': 'super_like_10_pack', 
    'super_like_20': 'super_like_20_pack',
    'premium_1_month': 'premium_monthly',
    'premium_3_months': 'premium_quarterly',
    'premium_6_months': 'premium_semiannual',
  };

  // Pricing for different products
  static const Map<String, Map<String, dynamic>> productPricing = {
    'super_like_5': {
      'price': 99.0,
      'currency': 'INR',
      'title': '5 Super Likes',
      'description': 'Get 5 super likes to stand out!',
    },
    'super_like_10': {
      'price': 179.0,
      'currency': 'INR', 
      'title': '10 Super Likes',
      'description': 'Get 10 super likes - best value!',
    },
    'super_like_20': {
      'price': 299.0,
      'currency': 'INR',
      'title': '20 Super Likes', 
      'description': 'Get 20 super likes - maximum impact!',
    },
    'premium_1_month': {
      'price': 299.0,
      'currency': 'INR',
      'title': 'Premium - 1 Month',
      'description': 'Unlimited swipes, see who liked you, and more!',
    },
    'premium_3_months': {
      'price': 799.0,
      'currency': 'INR',
      'title': 'Premium - 3 Months',
      'description': 'Save ₹98 with 3-month premium!',
    },
    'premium_6_months': {
      'price': 1499.0,
      'currency': 'INR',
      'title': 'Premium - 6 Months',
      'description': 'Save ₹295 with 6-month premium!',
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
    Get.snackbar(
      'Processing Purchase',
      'Your purchase is being processed...',
      backgroundColor: Colors.blue,
      colorText: Colors.white,
      duration: Duration(seconds: 3),
    );
  }

  // Handle purchase errors
  static void _handleError(IAPError error) {
    Get.snackbar(
      'Purchase Failed',
      error.message,
      backgroundColor: Colors.red,
      colorText: Colors.white,
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
      
      Get.snackbar(
        'Purchase Successful! 🎉',
        'Your purchase has been processed',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: Duration(seconds: 3),
      );
    } catch (e) {
      print('Error handling successful purchase: $e');
      Get.snackbar(
        'Purchase Error',
        'Failed to process purchase: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
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
      switch (productId) {
        case 'super_like_5_pack':
          superLikesToAdd = 5;
          break;
        case 'super_like_10_pack':
          superLikesToAdd = 10;
          break;
        case 'super_like_20_pack':
          superLikesToAdd = 20;
          break;
      }
      
      // Add super likes to user's account
      await SupabaseService.client.rpc('add_super_likes', params: {
        'user_id': SupabaseService.currentUser?.id,
        'super_likes_to_add': superLikesToAdd,
      });
      
      Get.snackbar(
        'Super Likes Added! ⭐',
        'You received $superLikesToAdd super likes',
        backgroundColor: Colors.amber,
        colorText: Colors.white,
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
      
      Get.snackbar(
        'Premium Activated! 👑',
        'Welcome to premium! Enjoy unlimited features',
        backgroundColor: Colors.purple,
        colorText: Colors.white,
      );
    } catch (e) {
      print('Error handling premium purchase: $e');
    }
  }

  // Purchase super likes
  static Future<void> purchaseSuperLikes(String packageType) async {
    try {
      final productId = productIds[packageType];
      if (productId == null) {
        Get.snackbar('Error', 'Invalid package type');
        return;
      }

      final ProductDetails? productDetails = await _getProductDetails(productId);
      if (productDetails == null) {
        Get.snackbar('Error', 'Product not available');
        return;
      }

      final PurchaseParam purchaseParam = PurchaseParam(productDetails: productDetails);
      await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
    } catch (e) {
      print('Error purchasing super likes: $e');
      Get.snackbar('Error', 'Failed to purchase super likes: $e');
    }
  }

  // Purchase premium subscription
  static Future<void> purchasePremium(String planType) async {
    try {
      final productId = productIds[planType];
      if (productId == null) {
        Get.snackbar('Error', 'Invalid plan type');
        return;
      }

      final ProductDetails? productDetails = await _getProductDetails(productId);
      if (productDetails == null) {
        Get.snackbar('Error', 'Product not available');
        return;
      }

      final PurchaseParam purchaseParam = PurchaseParam(productDetails: productDetails);
      await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
    } catch (e) {
      print('Error purchasing premium: $e');
      Get.snackbar('Error', 'Failed to purchase premium: $e');
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
                'Buy Super Likes',
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
