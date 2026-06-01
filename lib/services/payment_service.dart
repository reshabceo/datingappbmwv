import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
// import 'package:razorpay_flutter/razorpay_flutter.dart'; // COMMENTED OUT - SWITCHED TO CASHFREE
import 'package:uuid/uuid.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import '../config/supabase_config.dart';
import '../config/cashfree_config.dart';
import 'analytics_service.dart';
import 'app_state_service.dart';
import '../Common/widget_constant.dart';
import '../Screens/cashfree_checkout_screen.dart';

class PaymentService {
  static const String _environment = 'production';

  // Subscription plans with pricing
  static const Map<String, Map<String, dynamic>> subscriptionPlans = {
    '1_month': {
      'name': 'Premium - 1 Month',
      'price': 1500, // ₹1,500
      'duration_months': 1,
      'description': 'Premium features for 1 month'
    },
    '3_month': {
      'name': 'Premium - 3 Months',
      'price': 2250, // ₹2,250
      'duration_months': 3,
      'description': 'Premium features for 3 months'
    },
    '6_month': {
      'name': 'Premium - 6 Months',
      'price': 3600, // ₹3,600
      'duration_months': 6,
      'description': 'Premium features for 6 months'
    }

  };

  // Super Like Packages
  // NOTE: Keys must match the DB CHECK constraint (payment_orders_plan_type_check)
  // which allows: super_like_5, super_like_10, super_like_20
  // Display names/counts can differ from the key names
  static const Map<String, Map<String, dynamic>> superLikePackages = {
    'super_like_5': {
      'name': '5 Super Loves',
      'price': 99,
      'count': 5,
      'description': 'Get 5 Super Loves to boost your profile'
    },
    'super_like_10': {
      'name': '15 Super Loves',
      'price': 179,
      'count': 15,
      'description': 'Popular Choice - 15 Super Loves'
    },
    'super_like_20': {
      'name': '30 Super Loves',
      'price': 299,
      'count': 30,
      'description': 'Best Value - 30 Super Loves'
    }
  };


  static Future<void> initialize() async {
    // Cashfree doesn't require initialization like Razorpay
    // The payment flow is handled through API calls
    print('Cashfree Payment Service initialized');
  }

  static Future<void> dispose() async {
    // No cleanup needed for Cashfree
    print('Cashfree Payment Service disposed');
  }

  static Future<void> initiatePayment({
    required String planType,
    required String userEmail,
    required String userName,
    String? userPhone,
  }) async {
    // Ensure we have strings and no nulls from dynamic callers
    final String cleanPlanType = planType.trim();
    final String safeUserName = userName.isEmpty ? 'User' : userName;
    final String safeUserEmail = userEmail.isEmpty ? '' : userEmail;
    
    print('💰 initiatePayment called for planType: "$cleanPlanType"');
    
    final plan = (subscriptionPlans[cleanPlanType] ?? superLikePackages[cleanPlanType]) as Map<String, dynamic>?;
    
    if (plan == null) {
      print('❌ Invalid planType: "$cleanPlanType". Available keys: ${[...subscriptionPlans.keys, ...superLikePackages.keys]}');
      showCustomSnackBar(title: 'error'.tr, message: 'invalid_package_or_plan_selected'.tr, isError: true);
      return;
    }

    // Use a plain UUID to support databases that expect UUID types and avoid "Invalid Session"
    // Using a new UUID for every attempt ensures uniqueness
    // Use a simpler order ID format as recommended for sandbox
    final String orderId = "order_${DateTime.now().millisecondsSinceEpoch}";
    final double amount = (plan['price'] as num?)?.toDouble() ?? 0.0;
    final String description = plan['description']?.toString() ?? 'Purchase of $cleanPlanType';


    try {
      // Get current user ID
      final user = Supabase.instance.client.auth.currentUser;
      final String userId = user?.id ?? 'guest_${const Uuid().v4().substring(0, 8)}';

      // Create order in Supabase first
      await _createOrderRecord(orderId, planType, amount, userEmail);

      // Check if phone number is available
      String? rawPhone = userPhone ?? user?.phone;
      
      // If phone is missing, try to fetch from profile
      if (rawPhone == null || rawPhone.isEmpty || rawPhone == '0000000000' || rawPhone == '9999999999') {
        try {
          final profile = await Supabase.instance.client
              .from('profiles')
              .select('phone')
              .eq('id', user?.id ?? '')
              .single();
          rawPhone = profile['phone']?.toString();
        } catch (e) {
          print('Could not fetch phone from profile: $e');
        }
      }

      // Fallback to a valid-looking dummy number if phone is missing or clearly invalid (000/999)
      // This ensures payments are never blocked by missing profile info.
      if (rawPhone == null || rawPhone.isEmpty || rawPhone == '0000000000' || rawPhone == '9999999999') {
        print('⚠️ Phone missing or dummy, using fallback: 9876543210');
        rawPhone = '9876543210';
      }

      // Sanitize phone number to contain only digits (Cashfree requirement)
      String sanitizedPhone = rawPhone.replaceAll(RegExp(r'\D'), '');
      
      // If still invalid after sanitization, use fallback
      if (sanitizedPhone.length < 10) {
        print('⚠️ Sanitized phone too short (${sanitizedPhone.length}), using fallback: 9876543210');
        sanitizedPhone = '9876543210';
      }
      
      // Ensure it has exactly 10 digits
      final String finalPhone = sanitizedPhone.length >= 10 
          ? sanitizedPhone.substring(sanitizedPhone.length - 10) 
          : sanitizedPhone;

      // Create Cashfree payment session
      await _createCashfreePaymentSession(
        orderId: orderId,
        amount: amount,
        userId: userId,
        userEmail: safeUserEmail,
        userName: safeUserName,
        userPhone: finalPhone,
        description: description,
      );
    } catch (e) {
      print('❌ Error in initiatePayment: $e');
      showCustomSnackBar(title: 'error'.tr, message: '${'failed_to_initiate_payment'.tr}: ${e.toString()}', isError: true);
    }
  }

  static Future<void> _createOrderRecord(
    String orderId,
    String planType,
    double amount,
    String userEmail,
  ) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      String? userId = user?.id;
      
      // Check if user has a profile, if not create one
      if (user != null && user.id != null) {
        try {
          // Check if profile exists
          await Supabase.instance.client
              .from('profiles')
              .select('id')
              .eq('id', user.id!)
              .single();
        } catch (e) {
          // Profile doesn't exist, create one
          print('Creating profile for user: ${user.id}');
          try {
            await Supabase.instance.client.from('profiles').insert({
              'id': user.id,
              'email': user.email,
              'name': user.userMetadata?['name'] ?? user.email?.split('@')[0] ?? 'User',
              'age': 18, // Default age
              'is_active': false, // Profile not active until completed
              'created_at': DateTime.now().toIso8601String(),
              'updated_at': DateTime.now().toIso8601String(),
            });
            print('Profile created successfully');
          } catch (createError) {
            print('Error creating profile: $createError');
            // Continue anyway, we'll use null user_id
            userId = null;
          }
        }
      }
      
      await Supabase.instance.client.from('payment_orders').insert({
        'order_id': orderId,
        'user_id': userId,
        'plan_type': planType,
        'amount': amount.toInt(),
        'status': 'pending',
        'user_email': userEmail,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error creating order record: $e');
      // CRITICAL: rethrow so the caller knows the DB insert failed
      rethrow;
    }
  }

  // CASHFREE PAYMENT SESSION CREATION
  static Future<void> _createCashfreePaymentSession({
    required String orderId,
    required double amount,
    required String userId,
    required String userEmail,
    required String userName,
    required String userPhone,
    required String description,
  }) async {
    try {
      print('🚀 Calling Cashfree Edge Function for orderId: $orderId');
      
      final response = await Supabase.instance.client.functions.invoke(
        'cashfree-payment',
        body: {
          'type': 'createOrder',
          'orderId': orderId,
          'amount': amount,
          'userEmail': userEmail,
          'userName': userName,
          'description': description,
          'userId': userId,
          'environment': _environment,
          'userPhone': userPhone,
        },
      );

      final responseData = response.data;
      if (response.status == 200 && responseData != null && responseData['success'] == true) {
        print('✅ Edge Function Order Created! Response: $responseData');
        
        final rawSessionId = responseData['payment_session_id']?.toString();
        print('🔍 Received raw session_id: $rawSessionId');

        String? paymentUrl;
        // Only use direct payment_link if returned by Edge Function (do NOT use payments.url as it is a backend API endpoint)
        if (responseData['debug_response'] != null) {
          final debugResponse = responseData['debug_response'] as Map<dynamic, dynamic>;
          if (debugResponse['payment_link'] != null) {
            paymentUrl = debugResponse['payment_link']?.toString();
          }
        }

        if (rawSessionId != null) {
          // Store the raw session ID to avoid 'Client session invalid'
          await _updateOrderSessionId(orderId, rawSessionId);
          print('💾 Stored payment_session_id in DB: $rawSessionId');
          
          // Open the in-app Webview modal
          Get.to(() => CashfreeCheckoutScreen(
            paymentSessionId: rawSessionId,
            orderId: orderId,
            onPaymentResult: (success, completedOrderId) {
              print('Checkout screen closed. Result: success=$success, orderId=$completedOrderId');
              // Start polling only after checkout completes or is closed
              _startPaymentPolling(completedOrderId);
            },
          ));
        } else if (paymentUrl != null) {
          await _openPaymentUrl(paymentUrl, orderId);
        } else {
          print('❌ Could not find or construct payment URL from response: $responseData');
          throw Exception('Payment URL not found in Cashfree response');
        }
      } else {
        print('❌ Edge Function Error: ${response.status} - $responseData');
        throw Exception(responseData?['error'] ?? 'Failed to invoke Edge Function');
      }
    } catch (e) {
      print('Error creating Cashfree payment session: $e');
      rethrow;
    }
  }

  // Track the current active payment polling timer so we can cancel it
  static Timer? _paymentPollingTimer;
  static String? _currentPaymentOrderId;
  static String? _currentPaymentPlanType;

  static Future<void> _openPaymentUrl(String? paymentUrl, String orderId) async {
    if (paymentUrl == null || paymentUrl.isEmpty) {
      print('❌ Cannot open null or empty payment URL');
      showCustomSnackBar(title: 'error'.tr, message: 'invalid_payment_url_received'.tr, isError: true);
      return;
    }
    
    print('Opening Payment URL: $paymentUrl');
    showCustomSnackBar(title: 'payment'.tr, message: 'opening_payment_page'.tr);
    
    try {
      final Uri url = Uri.parse(paymentUrl);
      if (await canLaunchUrl(url)) {
        // CRITICAL: Use external application (system browser) for Cashfree checkout
        // In-app browsers often fail session validation
        await launchUrl(
          url,
          mode: LaunchMode.externalApplication,
        );
      } else {
        print('❌ Could not launch URL: $paymentUrl');
        throw Exception('Could not launch payment URL');
      }
    } catch (e) {
      print('Error launching payment URL: $e');
      showCustomSnackBar(title: 'error'.tr, message: 'failed_to_open_payment_page'.tr, isError: true);
    }
    
    // Start polling for payment status with the actual orderId
    _startPaymentPolling(orderId);
  }

  static void _startPaymentPolling(String orderId) {
    // Cancel any previous polling timer
    _paymentPollingTimer?.cancel();
    _currentPaymentOrderId = orderId;
    
    // Look up the plan type from the pending order
    _getCurrentPlanType(orderId);
    
    print('💰 Starting payment verification polling for order: $orderId');
    
    // Poll every 5 seconds for payment status
    _paymentPollingTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      try {
        // Skip verification queries while the app is in the background (i.e. user is on the checkout page)
        // This is CRITICAL because Cashfree's verify API (GET /orders/{id}) rotates/invalidates 
        // the active payment_session_id. Doing GET requests while the user is checking out
        // causes their browser checkout session to become "Invalid".
        // We only poll when the user is back inside the app.
        if (!AppStateService.isAppInForeground) {
          print('⏳ Skipping polling verification tick ${timer.tick} because app is in background/inactive');
          return;
        }

        print('🔄 Polling payment status for order: $orderId (tick ${timer.tick})...');
        
        // Verify payment with Cashfree API
        final isPaid = await _verifyCashfreePayment(orderId);
        
        if (isPaid) {
          // ✅ Payment confirmed!
          timer.cancel();
          _paymentPollingTimer = null;
          print('✅ Payment CONFIRMED for order: $orderId');
          
          // Update order status in database - changed 'paid' to 'success' to match CHECK constraint
          await _updateOrderStatus(orderId, 'success', orderId);
          
          // Activate the subscription/package
          await _activateSubscription(orderId);
          
          // Track payment success
          final planType = _currentPaymentPlanType ?? 'unknown';
          await _trackPaymentSuccess(orderId, planType);
          
          // Show success message
          showCustomSnackBar(
            title: 'payment_successful'.tr,
            message: 'premium_features_active_message'.tr,
          );
          return;
        }
        
        // Check if payment failed by querying full order status
        final orderStatus = await _getOrderStatus(orderId);
        if (orderStatus == 'EXPIRED' || orderStatus == 'TERMINATED') {
          timer.cancel();
          _paymentPollingTimer = null;
          print('❌ Payment FAILED/EXPIRED for order: $orderId (status: $orderStatus)');
          await _updateOrderStatus(orderId, 'failed', null);
          showCustomSnackBar(
            title: 'payment_failed'.tr,
            message: 'payment_session_expired_message'.tr,
            isError: true,
          );
          return;
        }
        
        // Stop polling after 5 minutes (60 ticks × 5 seconds)
        if (timer.tick >= 60) {
          timer.cancel();
          _paymentPollingTimer = null;
          print('⏰ Payment polling TIMEOUT for order: $orderId');
          // Changed 'timeout' to 'failed' to match database CHECK constraint
          await _updateOrderStatus(orderId, 'failed', null);
          showCustomSnackBar(
            title: 'payment_timeout'.tr,
            message: 'payment_verification_timeout_message'.tr,
            isError: true,
          );
        }
      } catch (e) {
        print('Error polling payment status: $e');
      }
    });
  }

  /// Get the full order status string from Cashfree
  static Future<String?> _getOrderStatus(String orderId) async {
    try {
      print('🚀 Calling Cashfree Edge Function for status of orderId: $orderId');
      
      final response = await Supabase.instance.client.functions.invoke(
        'cashfree-payment',
        body: {
          'type': 'verifyOrder',
          'orderId': orderId,
          'environment': _environment,
        },
      );

      final responseData = response.data;
      if (response.status == 200 && responseData != null && responseData['success'] == true) {
        return responseData['order_status'] as String?;
      }
      return null;
    } catch (e) {
      print('Error getting order status: $e');
      return null;
    }
  }

  /// Look up the plan type for the given order from DB
  static Future<void> _getCurrentPlanType(String orderId) async {
    try {
      final row = await Supabase.instance.client
          .from('payment_orders')
          .select('plan_type')
          .eq('order_id', orderId)
          .maybeSingle();
      _currentPaymentPlanType = row?['plan_type'] as String?;
    } catch (e) {
      print('Error getting plan type: $e');
    }
  }

  /// Activate subscription after confirmed payment
  static Future<void> _activateSubscription(String orderId) async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      // Get the order details
      final orderRow = await Supabase.instance.client
          .from('payment_orders')
          .select('plan_type, amount')
          .eq('order_id', orderId)
          .maybeSingle();

      if (orderRow == null) {
        print('❌ Order not found for activation: $orderId');
        return;
      }

      final planType = orderRow['plan_type'] as String? ?? '';
      
      // Check if this is a super like package
      if (superLikePackages.containsKey(planType)) {
        final package = superLikePackages[planType]!;
        final count = package['count'] as int? ?? 0;
        
        // Add super likes to user
        try {
          await Supabase.instance.client.rpc('add_super_likes', params: {
            'p_user_id': userId,
            'p_count': count,
          });
          print('✅ Added $count super likes for user: $userId');
        } catch (e) {
          print('⚠️ Error adding super likes via RPC: $e');
          // Fallback: update directly
          try {
            final profile = await Supabase.instance.client
                .from('profiles')
                .select('super_likes_count')
                .eq('id', userId)
                .maybeSingle();
            final currentCount = (profile?['super_likes_count'] as int?) ?? 0;
            await Supabase.instance.client
                .from('profiles')
                .update({'super_likes_count': currentCount + count})
                .eq('id', userId);
            print('✅ Fallback: Added $count super likes for user: $userId');
          } catch (fallbackError) {
            print('❌ Fallback super likes update failed: $fallbackError');
          }
        }
        return;
      }

      // This is a subscription plan
      final plan = subscriptionPlans[planType];
      if (plan == null) {
        print('❌ Unknown plan type: $planType');
        return;
      }

      final durationMonths = plan['duration_months'] as int? ?? 1;
      final now = DateTime.now();
      final endDate = DateTime(now.year, now.month + durationMonths, now.day);

      // Insert/update subscription record
      try {
        await Supabase.instance.client.from('user_subscriptions').upsert({
          'user_id': userId,
          'plan_type': planType,
          'start_date': now.toIso8601String(),
          'end_date': endDate.toIso8601String(),
          'status': 'active',
          'order_id': orderId, // Changed from payment_order_id to order_id to match DB schema
          'updated_at': now.toIso8601String(),
        }, onConflict: 'user_id');
        print('✅ Subscription activated: $planType until ${endDate.toIso8601String()}');
      } catch (e) {
        print('⚠️ Error upserting subscription: $e');
      }

      // Update profile is_premium flag
      try {
        await Supabase.instance.client
            .from('profiles')
            .update({'is_premium': true})
            .eq('id', userId);
        print('✅ Profile is_premium set to true');
      } catch (e) {
        print('⚠️ Error updating is_premium: $e');
      }
    } catch (e) {
      print('❌ Error activating subscription: $e');
    }
  }

  // CASHFREE PAYMENT VERIFICATION
  static Future<bool> _verifyCashfreePayment(String orderId) async {
    try {
      print('🚀 Calling Cashfree Edge Function for verification of orderId: $orderId');
      
      final response = await Supabase.instance.client.functions.invoke(
        'cashfree-payment',
        body: {
          'type': 'verifyOrder',
          'orderId': orderId,
          'environment': _environment,
        },
      );

      final responseData = response.data;
      if (response.status == 200 && responseData != null && responseData['success'] == true) {
        print('✅ Edge Function verification response: $responseData');
        final orderStatus = responseData['order_status'];
        final paymentStatus = responseData['payment_status'];
        // Removed 'ACTIVE' orderStatus check because ACTIVE means order created but not paid.
        final isPaid = orderStatus == 'PAID' || paymentStatus == 'SUCCESS' || paymentStatus == 'PAID';
        return isPaid;
      }
      return false;
    } catch (e) {
      print('Error verifying Cashfree payment: $e');
      return false;
    }
  }

  static Future<bool> _verifyPayment(String orderId) async {
    try {
      // Verify payment with Cashfree
      return await _verifyCashfreePayment(orderId);
    } catch (e) {
      print('Payment verification error: $e');
      return false;
    }
  }

  static Future<String?> _getCurrentOrderId() async {
    try {
      // Get the most recent pending order for the current user
      final row = await Supabase.instance.client
          .from('payment_orders')
          .select('order_id')
          .eq('user_id', Supabase.instance.client.auth.currentUser?.id ?? '')
          .eq('status', 'pending')
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      return row?['order_id'] as String?;
    } catch (e) {
      print('Error getting order ID: $e');
      return null;
    }
  }

  static Future<void> _updateOrderSessionId(
    String orderId,
    String sessionId,
  ) async {
    try {
      await Supabase.instance.client.from('payment_orders').update({
        'payment_session_id': sessionId,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('order_id', orderId);
    } catch (e) {
      print('Error updating order session ID: $e');
      // This might fail if the column doesn't exist yet, we'll log it but not crash
    }
  }

  static Future<void> _updateOrderStatus(
    String orderId,
    String status,
    String? paymentId,
  ) async {
    try {
      await Supabase.instance.client.from('payment_orders').update({
        'status': status,
        'payment_id': paymentId,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('order_id', orderId);
    } catch (e) {
      print('Error updating order status: $e');
    }
  }


  static Future<void> _trackPaymentSuccess(String orderId, String planId) async {
    try {
      // Get plan details from either subscriptions or super likes
      final plan = subscriptionPlans[planId] ?? superLikePackages[planId];
      if (plan == null) return;
      
      final String planName = plan['name']?.toString() ?? 'Package';
      final double amount = (plan['price'] as num?)?.toDouble() ?? 0.0;
      await Supabase.instance.client.from('user_events').insert({
        'event_type': 'payment_success',
        'event_data': {
          'order_id': orderId,
          'timestamp': DateTime.now().toIso8601String(),
        },
        'user_id': Supabase.instance.client.auth.currentUser?.id,
      });
      
      // Track subscription/package purchase for UAC
      await AnalyticsService.trackSubscriptionPurchased(
        subscriptionId: orderId,
        planName: planName,
        price: amount,
        currency: 'INR',
        paymentMethod: 'cashfree',
      );
    } catch (e) {
      print('Error tracking payment success: $e');
    }
  }

  // Check if user has active premium subscription
  static Future<bool> hasActiveSubscription() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return false;

      // Use database function for better performance
      final response = await Supabase.instance.client.rpc('get_user_subscription_status', params: {
        'user_uuid': userId,
      });
      
      if (response is List && response.isNotEmpty) {
        final subscription = response.first as Map<String, dynamic>;
        return subscription['is_premium'] == true;
      }
      
      return false;
    } catch (e) {
      print('Error checking subscription: $e');
      return false;
    }
  }

  // Get subscription details
  static Future<Map<String, dynamic>?> getSubscriptionDetails() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return null;

      // Use database function for better performance
      final response = await Supabase.instance.client.rpc('get_user_subscription_status', params: {
        'user_uuid': userId,
      });
      
      if (response is List && response.isNotEmpty) {
        final subscription = response.first as Map<String, dynamic>;
        if (subscription['is_premium'] == true) {
          return {
            'plan_type': subscription['plan_type'],
            'start_date': subscription['start_date'],
            'end_date': subscription['end_date'],
            'status': 'active',
            'days_remaining': subscription['days_remaining'],
            'subscription_id': subscription['subscription_id'],
          };
        }
      }
      
      return null;
    } catch (e) {
      print('Error getting subscription details: $e');
      return null;
    }
  }

  // Cancel subscription
  static Future<void> cancelSubscription() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      // Use database function for cancellation
      final response = await Supabase.instance.client.rpc('cancel_user_subscription', params: {
        'user_uuid': userId,
      });
      
      if (response == true) {
        showCustomSnackBar(title: 'success'.tr, message: 'subscription_cancelled_successfully'.tr);
      } else {
        showCustomSnackBar(title: 'error'.tr, message: 'no_active_subscription_found_to_cancel'.tr, isError: true);
      }
    } catch (e) {
      print('Error cancelling subscription: $e');
      showCustomSnackBar(title: 'error'.tr, message: 'failed_to_cancel_subscription'.tr, isError: true);
    }
  }
}
