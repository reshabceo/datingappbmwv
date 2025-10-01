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
  static const String cashfreeAppId = '108566980dabe16ff7dcf1c424e9665801';
  static const String cashfreeSecretKey = 'cfsk_ma_prod_2696a352b7f5c5519d02aa8750eccfd5_5b5f2bd0';
  
  // Environment (sandbox or production)
  static const String environment = 'production'; // Live credentials
  
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



