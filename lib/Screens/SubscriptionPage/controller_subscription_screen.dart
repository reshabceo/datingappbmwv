import 'package:get/get.dart';
import '../../services/payment_service.dart';
import '../../services/supabase_service.dart';
import '../../services/in_app_purchase_service.dart';
import 'package:lovebug/Common/widget_constant.dart';

class SubscriptionController extends GetxController {
  RxBool isLoading = false.obs;
  RxBool hasActiveSubscription = false.obs;
  RxMap<String, dynamic> subscriptionDetails = <String, dynamic>{}.obs;

  @override
  void onInit() {
    super.onInit();
    checkSubscriptionStatus();
  }

  Future<void> checkSubscriptionStatus() async {
    try {
      isLoading.value = true;
      
      // Check if user has active subscription from payment records/RPC
      bool hasSubscription = false;
      try {
        hasSubscription = await PaymentService.hasActiveSubscription();
      } catch (e) {
        print('⚠️ RPC subscription check failed (might not exist): $e');
        // RPC may not exist yet — fall through to profile check
      }
      
      // Also check profile is_premium flag as a secondary source (synced with Profile Tag)
      final isProfilePremium = await SupabaseService.isPremiumUser();
      
      print('🔍 Subscription check: RPC=$hasSubscription, Profile=$isProfilePremium');
      
      hasActiveSubscription.value = hasSubscription || isProfilePremium;
      
      if (hasSubscription || isProfilePremium) {
        // Get subscription details for dates and plan type
        Map<String, dynamic>? details;
        try {
          details = await PaymentService.getSubscriptionDetails();
        } catch (e) {
          print('⚠️ getSubscriptionDetails failed: $e');
        }
        
        if (details != null) {
          subscriptionDetails.value = details;
        } else if (isProfilePremium) {
          // Fallback details if we know user is premium but RPC has no record
          subscriptionDetails.value = {
            'plan_type': 'premium', // Generic premium if specific plan unknown
            'status': 'active',
            'start_date': DateTime.now().toIso8601String(),
            'end_date': DateTime.now().add(const Duration(days: 365)).toIso8601String(),
          };
        }
      }
    } catch (e) {
      print('Error checking subscription status: $e');
    } finally {
      isLoading.value = false;
      update(); // CRITICAL: notify GetBuilder listeners
    }
  }

  Future<void> initiatePayment(String planType) async {
    try {
      isLoading.value = true;
      
      final user = SupabaseService.currentUser;
      if (user == null) {
        showCustomSnackBar(title: 'error'.tr, message: 'please_login_first'.tr, isError: true);
        return;
      }

      await InAppPurchaseService.purchasePremium(planType);
    } catch (e) {
      print('Error initiating payment: $e');
      showCustomSnackBar(title: 'error'.tr, message: 'failed_to_initiate_payment'.tr, isError: true);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> cancelSubscription() async {
    try {
      isLoading.value = true;
      
      await PaymentService.cancelSubscription();
      
      // Refresh subscription status
      await checkSubscriptionStatus();
    } catch (e) {
      print('Error cancelling subscription: $e');
      showCustomSnackBar(title: 'error'.tr, message: 'failed_to_cancel_subscription'.tr, isError: true);
    } finally {
      isLoading.value = false;
    }
  }

  String getSubscriptionStatusText() {
    if (hasActiveSubscription.value) {
      if (subscriptionDetails.isNotEmpty && subscriptionDetails.containsKey('end_date')) {
        try {
          final endDateStr = subscriptionDetails['end_date']?.toString();
          if (endDateStr != null) {
            final endDate = DateTime.parse(endDateStr);
            final daysRemaining = endDate.difference(DateTime.now()).inDays;
            
            if (daysRemaining < 0) {
              return 'Premium expired';
            }
          }
        } catch (e) {
          print('Error parsing subscription date: $e');
        }
      }
      // If we know user is premium (hasActiveSubscription is true) 
      // but details or end_date is missing/invalid, still show Premium Active.
      return 'Premium active';
    }
    return 'Free Plan';
  }

  String getPlanTypeText() {
    if (subscriptionDetails.isNotEmpty) {
      final planType = subscriptionDetails['plan_type']?.toString();
      switch (planType) {
        case 'premium_1_month':
          return 'Premium - 1 Month';
        case 'premium_3_month':
          return 'Premium - 3 Months';
        case 'premium_6_months':
          return 'Premium - 6 Months';
        default:
          return 'Premium';
      }
    }
    return 'Free';
  }

  bool get isPremiumActive {
    return hasActiveSubscription.value;
  }

  int get daysRemaining {
    if (isPremiumActive) {
      final endDateStr = subscriptionDetails['end_date']?.toString();
      if (endDateStr != null) {
        try {
          final endDate = DateTime.parse(endDateStr);
          return endDate.difference(DateTime.now()).inDays;
        } catch (e) {
          return 0;
        }
      }
    }
    return 0;
  }
}



