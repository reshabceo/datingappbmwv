class RazorpayConfig {
  // Replace these with your actual Razorpay credentials
  static const String razorpayKeyId = 'rzp_test_1DP5mmOlF5G5ag';
  static const String razorpayKeySecret = 'your_secret_key_here';
  
  // Webhook URL for payment verification (optional)
  static const String webhookUrl = 'https://your-domain.com/webhook/razorpay';
  
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



