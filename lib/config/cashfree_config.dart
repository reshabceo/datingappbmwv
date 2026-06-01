// CASHFREE CONFIGURATION — PRODUCTION ONLY
class CashfreeConfig {
  // App ID and Secret Key from Cashfree Production Dashboard
  static const String cashfreeAppId = '108566980dabe16ff7dcf1c424e9665801';
  static const String cashfreeSecretKey = 'cfsk_ma_prod_2696a352b7f5c5519d02aa8750eccfd5_5b5f2bd0';

  // Cashfree Production Hosted Checkout base URL
  // The payment_session_id is appended after '#'
  static const String checkoutBaseUrl = 'https://payments.cashfree.com/order/#';

  // Currency
  static const String currency = 'INR';

  // Company details
  static const String companyName = 'LoveBug';
  static const String companyDescription = 'Premium Dating Features';

  // Payment methods to enable
  static const List<String> paymentMethods = [
    'card',
    'netbanking',
    'wallet',
    'upi',
  ];
}
