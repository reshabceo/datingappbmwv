import 'package:get/get.dart';
import '../../services/payment_service.dart';
import '../../services/supabase_service.dart';

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
      
      // Check if user has active subscription
      final hasSubscription = await PaymentService.hasActiveSubscription();
      hasActiveSubscription.value = hasSubscription;
      
      if (hasSubscription) {
        // Get subscription details
        final details = await PaymentService.getSubscriptionDetails();
        if (details != null) {
          subscriptionDetails.value = details;
        }
      }
    } catch (e) {
      print('Error checking subscription status: $e');
      Get.snackbar('Error', 'Failed to check subscription status');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> initiatePayment(String planType) async {
    try {
      isLoading.value = true;
      
      // Get current user details
      final user = SupabaseService.currentUser;
      if (user == null) {
        Get.snackbar('Error', 'Please login first');
        return;
      }

      // Get user profile for name and email
      final profile = await SupabaseService.getProfile(user.id);
      final userName = profile?['name'] ?? 'User';
      final userEmail = user.email ?? '';

      // Initialize payment
      await PaymentService.initiatePayment(
        planType: planType,
        userEmail: userEmail,
        userName: userName,
      );
    } catch (e) {
      print('Error initiating payment: $e');
      Get.snackbar('Error', 'Failed to initiate payment');
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
      Get.snackbar('Error', 'Failed to cancel subscription');
    } finally {
      isLoading.value = false;
    }
  }

  String getSubscriptionStatusText() {
    if (hasActiveSubscription.value && subscriptionDetails.isNotEmpty) {
      final endDate = DateTime.parse(subscriptionDetails['end_date']);
      final daysRemaining = endDate.difference(DateTime.now()).inDays;
      
      if (daysRemaining > 0) {
        return 'Premium active - $daysRemaining days remaining';
      } else {
        return 'Premium expired';
      }
    }
    return 'Free Plan';
  }

  String getPlanTypeText() {
    if (subscriptionDetails.isNotEmpty) {
      final planType = subscriptionDetails['plan_type'] as String;
      switch (planType) {
        case '1_month':
          return 'Premium - 1 Month';
        case '3_month':
          return 'Premium - 3 Months';
        case '6_month':
          return 'Premium - 6 Months';
        default:
          return 'Premium';
      }
    }
    return 'Free';
  }

  bool get isPremiumActive {
    return hasActiveSubscription.value && subscriptionDetails.isNotEmpty;
  }

  int get daysRemaining {
    if (isPremiumActive) {
      final endDate = DateTime.parse(subscriptionDetails['end_date']);
      return endDate.difference(DateTime.now()).inDays;
    }
    return 0;
  }
}



