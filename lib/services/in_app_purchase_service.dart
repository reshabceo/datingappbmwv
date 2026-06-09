import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:lovebug/Common/widget_constant.dart';

import '../Screens/SubscriptionPage/ui_subscription_screen.dart';
import 'supabase_service.dart';

class InAppPurchaseService {
  static final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  static StreamSubscription<List<PurchaseDetails>>? _subscription;

  /// Google Play Console product IDs (must match Play Console exactly).
  static const Set<String> _storeProductIds = {
    'super_like_5',
    'super_like_15',
    'super_like_30',
    'premium_1_month',
    'premium_3_month',
    'premium_6_months',
  };

  static const Map<String, int> _superLikeCounts = {
    'super_like_5': 5,
    'super_like_15': 15,
    'super_like_30': 30,
  };

  static const Map<String, int> _premiumDurationMonths = {
    'premium_1_month': 1,
    'premium_3_month': 3,
    'premium_6_months': 6,
  };

  // Local fallback pricing for DB records and UI when store prices are unavailable.
  static const Map<String, Map<String, dynamic>> productPricing = {
    'super_like_5': {
      'price': 99.0,
      'currency': 'INR',
      'title': '5 Super Loves',
      'description': 'You\'re 3x more likely to match!',
    },
    'super_like_15': {
      'price': 179.0,
      'currency': 'INR',
      'title': '15 Super Loves Pack',
      'description': 'Get 15 Super Loves • Popular Choice',
    },
    'super_like_30': {
      'price': 299.0,
      'currency': 'INR',
      'title': '30 Super Loves Pack',
      'description': 'Get 30 Super Loves • Best Value',
    },
    'premium_1_month': {
      'price': 1500.0,
      'currency': 'INR',
      'title': 'Premium 1 month Membership',
      'description': 'Full premium access for 1 month',
    },
    'premium_3_month': {
      'price': 2250.0,
      'currency': 'INR',
      'title': '3 months Premium Membership',
      'description': 'Full premium access for 3 months',
    },
    'premium_6_months': {
      'price': 3600.0,
      'currency': 'INR',
      'title': '6 months premium plan',
      'description': 'Full premium access for 6 months',
    },
  };

  static bool _isInitialized = false;
  static List<ProductDetails> _products = [];

  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      final bool isAvailable = await _inAppPurchase.isAvailable();
      if (!isAvailable) {
        print('❌ In-app purchases not available on this device');
        return;
      }

      _subscription?.cancel();
      _subscription = _inAppPurchase.purchaseStream.listen(
        _handlePurchases,
        onDone: () => _subscription?.cancel(),
        onError: (error) => print('❌ In-App Purchase Stream Error: $error'),
      );

      await _loadProducts();

      _isInitialized = true;
      print('✅ In-app purchases initialized. Loaded ${_products.length} products.');
    } catch (e) {
      print('❌ Error initializing in-app purchases: $e');
    }
  }

  static Future<void> _loadProducts() async {
    try {
      final ProductDetailsResponse response =
          await _inAppPurchase.queryProductDetails(_storeProductIds);

      if (response.error != null) {
        print('❌ Error querying products: ${response.error?.message}');
        return;
      }

      _products = response.productDetails;
      if (response.notFoundIDs.isNotEmpty) {
        print('⚠️ Products not found in Play Console: ${response.notFoundIDs}');
      }
      for (final prod in _products) {
        print('📦 Loaded Product: ${prod.id} - ${prod.title} (${prod.price})');
      }
    } catch (e) {
      print('❌ Error loading products: $e');
    }
  }

  static void dispose() {
    _subscription?.cancel();
    _subscription = null;
    _isInitialized = false;
  }

  static Future<void> restorePurchases() async {
    if (!_isInitialized) await initialize();
    await _inAppPurchase.restorePurchases();
  }

  static void _handlePurchases(List<PurchaseDetails> purchaseDetailsList) async {
    for (final PurchaseDetails purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        _showPendingUI();
      } else {
        if (purchaseDetails.status == PurchaseStatus.error) {
          _handleError(purchaseDetails.error!);
        } else if (purchaseDetails.status == PurchaseStatus.purchased ||
            purchaseDetails.status == PurchaseStatus.restored) {
          await _handleSuccessfulPurchase(purchaseDetails);
        }

        if (purchaseDetails.pendingCompletePurchase) {
          await _inAppPurchase.completePurchase(purchaseDetails);
          print('✅ Completed purchase for ID: ${purchaseDetails.purchaseID}');
        }
      }
    }
  }

  static void _showPendingUI() {
    showCustomSnackBar(
      title: 'processing_purchase'.tr,
      message: 'purchase_processing_message'.tr,
    );
  }

  static void _handleError(IAPError error) {
    print('❌ Purchase flow error: ${error.code} - ${error.message}');
    showCustomSnackBar(
      title: 'purchase_failed'.tr,
      message: error.message,
      isError: true,
    );
  }

  static Future<void> _handleSuccessfulPurchase(PurchaseDetails purchaseDetails) async {
    try {
      final productId = purchaseDetails.productID;
      final transactionId = purchaseDetails.purchaseID ??
          purchaseDetails.verificationData.serverVerificationData;

      print('🎉 Processing purchase of $productId (Transaction: $transactionId)');

      await _recordPurchase(productId, transactionId);

      if (Platform.isAndroid && _superLikeCounts.containsKey(productId)) {
        final androidAddition =
            _inAppPurchase.getPlatformAddition<InAppPurchaseAndroidPlatformAddition>();
        await androidAddition.consumePurchase(purchaseDetails);
        print('✅ Consumed super like pack $productId');
      }

      if (_superLikeCounts.containsKey(productId)) {
        await _handleSuperLikePurchase(productId);
      } else if (_premiumDurationMonths.containsKey(productId)) {
        await _handlePremiumPurchase(productId, transactionId);
      } else {
        print('⚠️ Unknown product ID: $productId');
        showCustomSnackBar(
          title: 'purchase_successful'.tr,
          message: 'purchase_processed_message'.tr,
        );
      }
    } catch (e) {
      print('❌ Error handling successful purchase: $e');
      showCustomSnackBar(
        title: 'purchase_error'.tr,
        message: '${'failed_to_process_purchase'.tr}: $e',
        isError: true,
      );
    }
  }

  static Future<void> _recordPurchase(String productId, String transactionId) async {
    try {
      final platform =
          Platform.isAndroid ? 'google_play' : (Platform.isIOS ? 'apple_pay' : 'unknown');

      await SupabaseService.client.from('in_app_purchases').insert({
        'user_id': SupabaseService.currentUser?.id,
        'purchase_type': productId,
        'amount': productPricing[productId]?['price'] ?? 0.0,
        'currency': productPricing[productId]?['currency'] ?? 'INR',
        'platform': platform,
        'transaction_id': transactionId,
        'status': 'completed',
        'created_at': DateTime.now().toIso8601String(),
      });
      print('💾 Logged purchase in in_app_purchases table.');
    } catch (e) {
      print('⚠️ Error recording purchase transaction: $e');
    }
  }

  static Future<void> _handleSuperLikePurchase(String productId) async {
    try {
      final userId = SupabaseService.currentUser?.id;
      if (userId == null) return;

      final superLikesToAdd = _superLikeCounts[productId] ?? 5;
      print('⭐️ Adding $superLikesToAdd Super Likes to user $userId');

      try {
        await SupabaseService.client.rpc('add_super_likes', params: {
          'p_user_id': userId,
          'p_super_likes_to_add': superLikesToAdd,
        });
      } catch (e) {
        print('⚠️ RPC add_super_likes failed: $e, trying fallback...');
        try {
          await SupabaseService.client.rpc('add_super_likes', params: {
            'p_user_id': userId,
            'p_count': superLikesToAdd,
          });
        } catch (e2) {
          final profile = await SupabaseService.client
              .from('profiles')
              .select('super_likes_count')
              .eq('id', userId)
              .maybeSingle();
          final currentCount = (profile?['super_likes_count'] as int?) ?? 0;
          await SupabaseService.client
              .from('profiles')
              .update({'super_likes_count': currentCount + superLikesToAdd})
              .eq('id', userId);
        }
      }

      showCustomSnackBar(
        title: 'super_loves_added'.tr,
        message: 'you_received_super_loves'.tr.replaceAll('\$count', superLikesToAdd.toString()),
      );
    } catch (e) {
      print('❌ Error handling super like database update: $e');
    }
  }

  static Future<void> _handlePremiumPurchase(String productId, String transactionId) async {
    try {
      final userId = SupabaseService.currentUser?.id;
      if (userId == null) return;

      final durationMonths = _premiumDurationMonths[productId] ?? 1;
      final normalizedPlan = productId;

      print('👑 Activating premium ($durationMonths months) for user $userId');

      final now = DateTime.now();
      final endDate = DateTime(now.year, now.month + durationMonths, now.day);

      try {
        await SupabaseService.client.rpc('activate_premium_subscription', params: {
          'p_user_id': userId,
          'p_duration_months': durationMonths,
          'p_payment_method': 'google_play',
        });
      } catch (e) {
        print('⚠️ RPC activate_premium_subscription failed: $e');
      }

      try {
        await SupabaseService.client.from('user_subscriptions').upsert({
          'user_id': userId,
          'plan_type': normalizedPlan,
          'start_date': now.toIso8601String(),
          'end_date': endDate.toIso8601String(),
          'status': 'active',
          'order_id': transactionId,
          'updated_at': now.toIso8601String(),
        }, onConflict: 'user_id');
      } catch (e) {
        print('⚠️ Error inserting into user_subscriptions: $e');
      }

      try {
        await SupabaseService.client
            .from('profiles')
            .update({'is_premium': true})
            .eq('id', userId);
      } catch (e) {
        print('⚠️ Error updating profile premium flag: $e');
      }

      try {
        if (Get.isRegistered<SubscriptionScreen>()) {
          Get.find<SubscriptionScreen>();
        }
      } catch (_) {}

      showCustomSnackBar(
        title: 'premium_activated'.tr,
        message: 'premium_activated_message'.tr,
      );
    } catch (e) {
      print('❌ Error handling premium database update: $e');
    }
  }

  static Future<ProductDetails?> _resolveProduct(String productId) async {
    if (!_isInitialized) await initialize();

    ProductDetails? product =
        _products.firstWhereOrNull((prod) => prod.id == productId);

    if (product == null) {
      print('⚠️ Product $productId not loaded. Re-querying store...');
      await _loadProducts();
      product = _products.firstWhereOrNull((prod) => prod.id == productId);
    }

    return product;
  }

  static Future<void> purchaseSuperLikes(String packageType) async {
    try {
      if (SupabaseService.currentUser == null) {
        showCustomSnackBar(title: 'error'.tr, message: 'please_login_first'.tr, isError: true);
        return;
      }

      if (!_storeProductIds.contains(packageType) || !_superLikeCounts.containsKey(packageType)) {
        showCustomSnackBar(
          title: 'error'.tr,
          message: 'Invalid super like package.',
          isError: true,
        );
        return;
      }

      print('🚀 Initiating super like purchase: $packageType');
      final product = await _resolveProduct(packageType);
      if (product == null) {
        showCustomSnackBar(
          title: 'error'.tr,
          message: 'Product not available. Ensure it is active in Google Play Console.',
          isError: true,
        );
        return;
      }

      await _inAppPurchase.buyConsumable(
        purchaseParam: PurchaseParam(productDetails: product),
        autoConsume: true,
      );
    } catch (e) {
      print('❌ Error purchasing super likes: $e');
      showCustomSnackBar(
        title: 'error'.tr,
        message: '${'failed_to_initiate_purchase'.tr}: $e',
        isError: true,
      );
    }
  }

  static Future<void> purchasePremium(String planType) async {
    try {
      if (SupabaseService.currentUser == null) {
        showCustomSnackBar(title: 'error'.tr, message: 'please_login_first'.tr, isError: true);
        return;
      }

      if (!_storeProductIds.contains(planType) || !_premiumDurationMonths.containsKey(planType)) {
        showCustomSnackBar(
          title: 'error'.tr,
          message: 'Invalid subscription plan.',
          isError: true,
        );
        return;
      }

      print('🚀 Initiating premium subscription purchase: $planType');
      final product = await _resolveProduct(planType);
      if (product == null) {
        showCustomSnackBar(
          title: 'error'.tr,
          message: 'Subscription not available. Ensure base plans are active in Google Play Console.',
          isError: true,
        );
        return;
      }

      // Google Play subscriptions are purchased via buyNonConsumable in the Flutter IAP plugin.
      await _inAppPurchase.buyNonConsumable(
        purchaseParam: PurchaseParam(productDetails: product),
      );
    } catch (e) {
      print('❌ Error purchasing premium: $e');
      showCustomSnackBar(
        title: 'error'.tr,
        message: '${'failed_to_initiate_purchase'.tr}: $e',
        isError: true,
      );
    }
  }

  static Future<ProductDetails?> getProductDetails(String productId) async {
    try {
      return await _resolveProduct(productId);
    } catch (e) {
      print('Error getting product details: $e');
      return null;
    }
  }

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
              Text(
                'Buy Super Loves',
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 16.h),
              ..._superLikeCounts.keys.map(
                (id) => _buildSuperLikePackage(id, productPricing[id]!),
              ),
              SizedBox(height: 16.h),
              OutlinedButton(
                onPressed: () => Get.back(),
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
                child: const Text('Cancel'),
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: true,
    );
  }

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
