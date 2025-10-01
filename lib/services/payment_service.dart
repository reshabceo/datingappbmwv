import 'dart:convert';
import 'dart:async';
// import 'package:razorpay_flutter/razorpay_flutter.dart'; // COMMENTED OUT - SWITCHED TO CASHFREE
import 'package:uuid/uuid.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import '../config/supabase_config.dart';
import '../config/cashfree_config.dart';

class PaymentService {
  // static Razorpay? _razorpay; // COMMENTED OUT - SWITCHED TO CASHFREE
  static const String _cashfreeAppId = CashfreeConfig.cashfreeAppId;
  static const String _cashfreeSecretKey = CashfreeConfig.cashfreeSecretKey;
  static const String _environment = CashfreeConfig.environment;
  
  // Subscription plans with pricing
  static const Map<String, Map<String, dynamic>> subscriptionPlans = {
    '1_month': {
      'name': 'Premium - 1 Month',
      'price': 1, // ₹1 (TESTING)
      'duration_months': 1,
      'description': 'Premium features for 1 month'
    },
    '3_month': {
      'name': 'Premium - 3 Months',
      'price': 1, // ₹1 (TESTING)
      'duration_months': 3,
      'description': 'Premium features for 3 months'
    },
    '6_month': {
      'name': 'Premium - 6 Months',
      'price': 1, // ₹1 (TESTING)
      'duration_months': 6,
      'description': 'Premium features for 6 months'
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
  }) async {
    final plan = subscriptionPlans[planType];
    if (plan == null) {
      Get.snackbar('Error', 'Invalid subscription plan');
      return;
    }

    final orderId = const Uuid().v4();
    final amount = (plan['price'] as int) * 100; // Convert rupees to paise for Cashfree (₹1,500 = 150,000 paise)
    final description = plan['description'] as String;

    try {
      // Create order in Supabase first
      await _createOrderRecord(orderId, planType, amount, userEmail);

      // Create Cashfree payment session
      await _createCashfreePaymentSession(
        orderId: orderId,
        amount: amount,
        userEmail: userEmail,
        userName: userName,
        description: description,
      );
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
        'amount': amount,
        'status': 'pending',
        'user_email': userEmail,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error creating order record: $e');
    }
  }

  // CASHFREE PAYMENT SESSION CREATION
  static Future<void> _createCashfreePaymentSession({
    required String orderId,
    required int amount,
    required String userEmail,
    required String userName,
    required String description,
  }) async {
    try {
      final baseUrl = _environment == 'sandbox' 
          ? 'https://sandbox.cashfree.com/pg' 
          : 'https://api.cashfree.com/pg';
      
      final requestBody = {
        'order_id': orderId,
        'order_amount': amount.round(), // Amount is already in paise
        'order_currency': 'INR',
        'customer_details': {
          'customer_id': userEmail,
          'customer_name': userName,
          'customer_email': userEmail,
        },
        'order_meta': {
          'return_url': 'https://your-domain.com/payment/success',
          // 'notify_url': CashfreeConfig.webhookUrl, // Disabled - using direct verification
        },
        'order_note': description,
      };

      final response = await http.post(
        Uri.parse('$baseUrl/orders'),
        headers: {
          'Content-Type': 'application/json',
          'x-api-version': '2023-08-01',
          'x-client-id': _cashfreeAppId,
          'x-client-secret': _cashfreeSecretKey,
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final paymentUrl = responseData['payment_link'];
        
        // Open payment URL in browser or webview
        await _openPaymentUrl(paymentUrl);
      } else {
        throw Exception('Failed to create payment session: ${response.body}');
      }
    } catch (e) {
      print('Error creating Cashfree payment session: $e');
      rethrow;
    }
  }

  static Future<void> _openPaymentUrl(String paymentUrl) async {
    // This would typically open a webview or browser
    print('Payment URL: $paymentUrl');
    Get.snackbar('Payment', 'Redirecting to payment page...');
    
    // In a real implementation, you would:
    // 1. Open a webview with the payment URL
    // 2. Handle the return URL to verify payment
    // 3. Update order status based on payment result
    
    // For now, start polling for payment status
    _startPaymentPolling(paymentUrl);
  }

  static void _startPaymentPolling(String paymentUrl) {
    // Start polling for payment status
    Timer.periodic(const Duration(seconds: 10), (timer) async {
      try {
        // Get the order ID from the payment URL or store it somewhere
        // This is a simplified approach - in production you'd store the order ID
        print('Polling payment status...');
        
        // You would implement payment verification here
        // For now, we'll just show a message
        Get.snackbar('Payment', 'Please complete payment in the browser and return to the app');
        
        // Stop polling after 5 minutes
        if (timer.tick >= 30) {
          timer.cancel();
          Get.snackbar('Payment', 'Payment timeout - please try again');
        }
      } catch (e) {
        print('Error polling payment: $e');
      }
    });
  }

  // CASHFREE PAYMENT VERIFICATION
  static Future<bool> _verifyCashfreePayment(String orderId) async {
    try {
      final baseUrl = _environment == 'sandbox' 
          ? 'https://sandbox.cashfree.com/pg' 
          : 'https://api.cashfree.com/pg';
      
      final response = await http.get(
        Uri.parse('$baseUrl/orders/$orderId'),
        headers: {
          'x-api-version': '2023-08-01',
          'x-client-id': _cashfreeAppId,
          'x-client-secret': _cashfreeSecretKey,
        },
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return responseData['order_status'] == 'PAID';
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
