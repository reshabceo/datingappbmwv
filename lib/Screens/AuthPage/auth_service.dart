import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/supabase_service.dart';

class AuthService {
  static Future<AuthResponse?> signUpWithPhone({
    required String phone,
    required String password,
  }) async {
    try {
      // For now, we'll use email-based auth with phone as email
      // In production, you'd implement proper SMS OTP
      final email = '$phone@temp.com';
      
      final response = await SupabaseService.signUpWithEmail(
        email: email,
        password: password,
        data: {'phone': phone},
      );
      
      return response;
    } catch (e) {
      print('Error signing up: $e');
      return null;
    }
  }

  static Future<AuthResponse?> signInWithPhone({
    required String phone,
    required String password,
  }) async {
    try {
      final email = '$phone@temp.com';
      
      final response = await SupabaseService.signInWithEmail(
        email: email,
        password: password,
      );
      
      return response;
    } catch (e) {
      print('Error signing in: $e');
      return null;
    }
  }

  static Future<bool> verifyOTP({
    required String phone,
    required String otp,
  }) async {
    // For demo purposes, accept any 6-digit OTP
    // In production, integrate with SMS service
    return otp.length == 6;
  }

  static Future<void> sendOTP(String phone) async {
    // For demo purposes, generate a random 6-digit OTP
    // In production, send real SMS
    final otp = (100000 + (DateTime.now().millisecondsSinceEpoch % 900000)).toString();
    print('🔐 OTP for $phone: $otp');
    print('📱 This is a demo OTP - use this number to verify');
  }

  static Future<void> signOut() async {
    await SupabaseService.signOut();
  }

  static User? get currentUser => SupabaseService.currentUser;
}
