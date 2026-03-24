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
  // Environment (sandbox or production)
  static const String environment = 'sandbox'; // Set to 'sandbox' for testing
  
  // Production credentials
  static const String prodAppId = '108566980dabe16ff7dcf1c424e9665801';
  static const String prodSecretKey = 'cfsk_ma_prod_2696a352b7f5c5519d02aa8750eccfd5_5b5f2bd0';
  
  // Sandbox credentials
  static const String sandboxAppId = 'TEST108148726e3fe406cfaf95fc00af27841801';
  static const String sandboxSecretKey = 'cfsk_ma_test_66de59f49e4468e95026fe4777c738dc_c66ff734';
  
  // Dynamic credentials based on environment
  static String get cashfreeAppId => environment == 'sandbox' ? sandboxAppId : prodAppId;
  static String get cashfreeSecretKey => environment == 'sandbox' ? sandboxSecretKey : prodSecretKey;
  
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



