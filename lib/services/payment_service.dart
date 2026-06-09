import 'dart:async';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'analytics_service.dart';
import '../Common/widget_constant.dart';

class PaymentService {
  static Future<void> initialize() async {
    print('Payment Service (IAP Mode) initialized');
  }

  static Future<void> dispose() async {
    print('Payment Service (IAP Mode) disposed');
  }

  // Check if user has active premium subscription
  static Future<bool> hasActiveSubscription() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return false;

      // Use database function for checking premium status
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

      // Use database function for fetching details
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

