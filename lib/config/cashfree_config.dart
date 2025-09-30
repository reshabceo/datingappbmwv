// COMMENTED OUT - SWITCHED TO CASHFREE
// class RazorpayConfig {
//   // Replace these with your actual Razorpay credentials
//   static const String razorpayKeyId = 'rzp_test_1DP5mmOlF5G5ag';
//   static const String razorpayKeySecret = 'your_secret_key_here';
//   
//   // Webhook URL for payment verification (optional)
//   static const String webhookUrl = 'https://your-domain.com/webhook/razorpay';
//   
//   // Currency code
//   static const String currency = 'INR';
//   
//   // Company details
//   static const String companyName = 'FlameChat';
//   static const String companyDescription = 'Premium Dating Features';
//   
//   // Payment methods to enable
//   static const List<String> paymentMethods = [
//     'card',
//     'netbanking',
//     'wallet',
//     'upi',
//     'paytm'
//   ];
// }

// CASHFREE CONFIGURATION
class CashfreeConfig {
  // Cashfree credentials
  static const String cashfreeAppId = 'TEST108148726e3fe406cfaf95fc00af27841801';
  static const String cashfreeSecretKey = 'cfsk_ma_test_66de59f49e4468e95026fe4777c738dc_c66ff734';
  
  // Environment (sandbox or production)
  static const String environment = 'sandbox'; // Change to 'production' for live
  
  // Webhook URL for payment verification
  static const String webhookUrl = 'https://dkcitxzvojvecuvacwsp.supabase.co/functions/v1/cashfree-webhook';
  
  // Currency code
  static const String currency = 'INR';
  
  // Company details
  static const String companyName = 'FlameChat';
  static const String companyDescription = 'Premium Dating Features';
  
  // Payment methods to enable
  static const List<String> paymentMethods = [
    'card',
    'netbanking',
    'wallet',
    'upi',
    'paytm'
  ];
}



