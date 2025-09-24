import 'dart:convert';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../config/razorpay_config.dart';

class PaymentService {
  static Razorpay? _razorpay;
  static const String _razorpayKeyId = RazorpayConfig.razorpayKeyId;
  static const String _razorpayKeySecret = RazorpayConfig.razorpayKeySecret;
  
  // Subscription plans with pricing
  static const Map<String, Map<String, dynamic>> subscriptionPlans = {
    '1_month': {
      'name': 'Premium - 1 Month',
      'price': 1500, // ₹15.00 (in paise)
      'duration_months': 1,
      'description': 'Premium features for 1 month'
    },
    '3_month': {
      'name': 'Premium - 3 Months',
      'price': 2250, // ₹22.50 (in paise)
      'duration_months': 3,
      'description': 'Premium features for 3 months'
    },
    '6_month': {
      'name': 'Premium - 6 Months',
      'name': 'Premium - 6 Months',
      'price': 3600, // ₹36.00 (in paise)
      'duration_months': 6,
      'description': 'Premium features for 6 months'
    }
  };

  static Future<void> initialize() async {
    _razorpay = Razorpay();
    _razorpay!.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay!.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay!.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  static Future<void> dispose() async {
    _razorpay?.clear();
  }

  static Future<void> initiatePayment({
    required String planType,
    required String userEmail,
    required String userName,
  }) async {
    if (_razorpay == null) {
      await initialize();
    }

    final plan = subscriptionPlans[planType];
    if (plan == null) {
      Get.snackbar('Error', 'Invalid subscription plan');
      return;
    }

    final orderId = const Uuid().v4();
    final amount = plan['price'] as int;
    final description = plan['description'] as String;

    try {
      // Create order in Supabase first
      await _createOrderRecord(orderId, planType, amount, userEmail);

      final options = {
        'key': _razorpayKeyId,
        'amount': amount,
        'name': 'FlameChat Premium',
        'description': description,
        'order_id': orderId,
        'prefill': {
          'contact': userEmail,
          'email': userEmail,
          'name': userName,
        },
        'external': {
          'wallets': ['paytm']
        }
      };

      _razorpay!.open(options);
    } catch (e) {
      Get.snackbar('Error', 'Failed to initiate payment: $e');
    }
  }

  static Future<void> _createOrderRecord(
    String orderId,
    String planType,
    int amount,
    String userEmail,
  ) async {
    try {
      await Supabase.instance.client.from('payment_orders').insert({
        'order_id': orderId,
        'user_id': Supabase.instance.client.auth.currentUser?.id,
        'plan_type': planType,
        'amount': amount,
        'status': 'pending',
        'user_email': userEmail,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error creating order record: $e');
    }
  }

  static Future<void> _handlePaymentSuccess(PaymentSuccessResponse response) async {
    try {
      print('Payment Success: ${response.paymentId}');
      
      // Verify payment with Razorpay (this also creates the subscription)
      final isVerified = await _verifyPayment(response.paymentId!);
      
      if (isVerified) {
        Get.snackbar('Success', 'Payment successful! Premium features activated.');
        
        // Track analytics
        await _trackPaymentSuccess(response.orderId!);
      } else {
        Get.snackbar('Error', 'Payment verification failed');
      }
    } catch (e) {
      print('Error handling payment success: $e');
      Get.snackbar('Error', 'Payment processing failed');
    }
  }

  static Future<void> _handlePaymentError(PaymentFailureResponse response) async {
    print('Payment Error: ${response.code} - ${response.message}');
    Get.snackbar('Payment Failed', 'Payment was cancelled or failed');
    
    // Update order status
    if (response.orderId != null) {
      await _updateOrderStatus(response.orderId!, 'failed', null);
    }
  }

  static Future<void> _handleExternalWallet(ExternalWalletResponse response) async {
    print('External Wallet: ${response.walletName}');
  }

  static Future<bool> _verifyPayment(String paymentId) async {
    try {
      // Get order ID from the current payment context
      // We need to pass both payment_id and order_id to the Edge Function
      final orderId = await _getCurrentOrderId();
      if (orderId == null) {
        print('No order ID found for payment verification');
        return false;
      }

      // Call Supabase Edge Function to verify payment
      final response = await Supabase.instance.client.functions.invoke(
        'verify-payment',
        body: {
          'payment_id': paymentId,
          'order_id': orderId,
        },
      );
      
      if (response.status == 200) {
        final data = response.data as Map<String, dynamic>;
        return data['verified'] == true;
      }
      
      return false;
    } catch (e) {
      print('Payment verification error: $e');
      return false;
    }
  }

  static Future<String?> _getCurrentOrderId() async {
    try {
      // Get the most recent pending order for the current user
      final response = await Supabase.instance.client
          .from('payment_orders')
          .select('order_id')
          .eq('user_id', Supabase.instance.client.auth.currentUser?.id)
          .eq('status', 'pending')
          .order('created_at', ascending: false)
          .limit(1)
          .single();
      
      return response['order_id'] as String?;
    } catch (e) {
      print('Error getting order ID: $e');
      return null;
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


  static Future<void> _trackPaymentSuccess(String orderId) async {
    try {
      // Track payment success in analytics
      await Supabase.instance.client.from('user_events').insert({
        'event_type': 'payment_success',
        'event_data': {
          'order_id': orderId,
          'timestamp': DateTime.now().toIso8601String(),
        },
        'user_id': Supabase.instance.client.auth.currentUser?.id,
      });
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
        Get.snackbar('Success', 'Subscription cancelled successfully');
      } else {
        Get.snackbar('Error', 'No active subscription found to cancel');
      }
    } catch (e) {
      print('Error cancelling subscription: $e');
      Get.snackbar('Error', 'Failed to cancel subscription');
    }
  }
}
