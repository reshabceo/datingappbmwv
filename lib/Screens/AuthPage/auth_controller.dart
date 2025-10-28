import 'package:lovebug/global_data.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../ProfileFormPage/multi_step_profile_form.dart';
import '../BottomBarPage/bottombar_screen.dart';
import '../../services/supabase_service.dart';
import '../../services/analytics_service.dart';
import 'email_code_verify_screen.dart';
import 'auth_ui_screen.dart';
import '../WelcomePage/welcome_screen.dart';

class AuthController extends GetxController {
  TextEditingController passwordController = TextEditingController();
  TextEditingController confirmPasswordController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController emailOtpController = TextEditingController();
  RxInt resendSeconds = 0.obs;
  String _emailAction = 'auto'; // 'signin' or 'signup'

  RxString selectedLanguage = 'English'.obs;
  RxBool isLoading = false.obs;
  RxBool isExistingEmail = false.obs;
  RxBool isSignupMode = false.obs;
  RxBool didProbeEmail = false.obs;
  RxBool isOTPSent = false.obs;
  RxString authMode = 'email'.obs; // Always email mode

  final Map<String, String> languagesMap = {
    'English': 'en',
    'Hindi': 'hi',
    'Arabic': 'ar',
    'German': 'de',
  };

  @override
  void onInit() {
    selectedLanguage.value = lanName.value;
    super.onInit();
  }




  Future<void> signUpWithEmail() async {
    if (emailController.text.isEmpty || passwordController.text.isEmpty || confirmPasswordController.text.isEmpty) {
      Get.snackbar('Error', 'Please fill all fields');
      return;
    }
    if (passwordController.text.length < 6) {
      Get.snackbar('Error', 'Password must be at least 6 characters');
      return;
    }
    if (passwordController.text != confirmPasswordController.text) {
      Get.snackbar('Error', 'Passwords do not match');
      return;
    }
    try {
      isLoading.value = true;
      print('Signing up user with email and sending OTP...');
      
      // Use signUp which will create user and send verification email automatically
      final response = await SupabaseService.signUpWithEmail(
        email: emailController.text,
        password: passwordController.text
      );
      
      print('User signed up successfully: ${response.user?.id}');
      
      isOTPSent.value = true;
      _startResendTimer();
      
      print('Navigating to email verification screen');
      Get.to(() => EmailCodeVerifyScreen(
        isSignupFlow: true, 
        email: emailController.text, 
        password: passwordController.text
      ));
      
      Get.snackbar('Check your email', 'We sent a verification code to ${emailController.text}');
    } on AuthApiException catch (e) {
      print('Auth error in signUpWithEmail: $e');
      if (e.code == 'over_email_send_rate_limit') {
        Get.snackbar('Rate Limited', 'Please wait ${e.message.split('after ')[1].split(' seconds')[0]} seconds before trying again');
      } else {
        Get.snackbar('Error', 'Failed to create account: ${e.message}');
      }
    } catch (e) {
      print('Error in signUpWithEmail: $e');
      Get.snackbar('Error', 'Failed to create account: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }


  Future<void> signInWithEmail() async {
    if (emailController.text.isEmpty) {
      Get.snackbar('Error', 'Enter email');
      return;
    }
    try {
      isLoading.value = true;
      await SupabaseService.sendEmailOtp(emailController.text);
      Get.snackbar('Verification needed', 'We sent a 6-digit code to your email.');
      isOTPSent.value = true;
    } catch (e) {
      Get.snackbar('Error', 'Failed to send code');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> verifyEmailCodeAndSetPassword() async {
    if (emailOtpController.text.isEmpty) {
      Get.snackbar('Error', 'Enter the 6-digit code');
      return;
    }
    try {
      isLoading.value = true;
      print('Verifying email OTP: ${emailOtpController.text}');
      
      final res = await SupabaseService.verifyEmailOtp(
        email: emailController.text,
        token: emailOtpController.text,
      );
      
      print('Email verification result: ${res.user?.id}');
      
      if (res.user != null) {
        print('Email verified successfully, navigating...');
        // Track login for UAC
        await AnalyticsService.trackLoginEnhanced('email_otp');
        await _checkUserProfileAndNavigate();
      } else {
        Get.snackbar('Error', 'Invalid code');
      }
    } catch (e) {
      print('Error verifying email: $e');
      Get.snackbar('Error', 'Verification failed: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> continueWithEmail() async {
    final email = emailController.text.trim();
    if (email.isEmpty) {
      Get.snackbar('Error', 'Enter email');
      return;
    }
    
    print('Checking email: $email');
    try {
      // Skip the admin-only provider check and go directly to password mode
      // This avoids the "User not allowed" error
      print('Email exists, showing password option');
      isExistingEmail.value = true;
      isSignupMode.value = false;
      didProbeEmail.value = true;
      Get.to(() => AuthScreen(prefillEmail: email, isPasswordMode: true));
    } on AuthApiException catch (e) {
      final code = (e.code ?? '').toLowerCase();
      final msg = (e.message).toLowerCase();
      print('AuthApiException caught - Code: $code, Message: $msg');
      
      // Supabase returns user-not-found variants for non-existing users
      if (code.contains('user_not_found') || msg.contains('user not found') || msg.contains('no user') || code.contains('invalid_user')) {
        print('User not found, navigating to signup');
        isExistingEmail.value = false;
        isSignupMode.value = true;
        didProbeEmail.value = true;
        Get.to(() => AuthScreen(prefillEmail: email, isSignupMode: true));
      } else if (code.contains('over_email_send_rate_limit') || msg.contains('rate limit')) {
        // Rate limited while sending OTP → email exists. Route to sign in and show message.
        print('Rate limited, treating as existing user');
        isExistingEmail.value = true;
        isSignupMode.value = false;
        didProbeEmail.value = true;
        Get.to(() => AuthScreen(prefillEmail: email, isPasswordMode: true));
        Get.snackbar('Please wait', 'Too many attempts. Try again shortly.');
      } else {
        // Any other error: conservatively treat as non-existing
        print('Other error, defaulting to signup - Code: $code, Message: $msg');
        isExistingEmail.value = false;
        isSignupMode.value = true;
        didProbeEmail.value = true;
        Get.to(() => AuthScreen(prefillEmail: email, isSignupMode: true));
      }
    } catch (e) {
      // Network/unknown → default to signup to avoid blocking
      print('General exception caught, defaulting to signup: $e');
      isExistingEmail.value = false;
      isSignupMode.value = true;
      didProbeEmail.value = true;
      Get.to(() => AuthScreen(prefillEmail: email, isSignupMode: true));
    }
  }

  Future<void> resendEmailCode() async {
    if (resendSeconds.value > 0) return;
    final email = emailController.text.trim();
    if (email.isEmpty) return;
    try {
      await SupabaseService.sendEmailOtp(email);
      _startResendTimer();
      Get.snackbar('Sent', 'We resent the code to $email');
    } catch (_) {}
  }

  Future<void> signInWithPassword() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    if (email.isEmpty || password.isEmpty) {
      Get.snackbar('Error', 'Enter email and password');
      return;
    }
    try {
      isLoading.value = true;
      print('🔄 DEBUG: Attempting email/password sign in for: $email');
      await SupabaseService.signInWithEmail(email: email, password: password);
      print('✅ DEBUG: Email/password sign in successful');
      // Track login for UAC
      await AnalyticsService.trackLoginEnhanced('email_password');
      await _checkUserProfileAndNavigate();
    } on AuthApiException catch (e) {
      print('❌ DEBUG: Auth error in signInWithPassword: ${e.code} - ${e.message}');
      final code = (e.code ?? '').toLowerCase();
      final msg = e.message.toLowerCase();
      
      if (code.contains('invalid_credentials') || 
          code.contains('invalid_login') || 
          msg.contains('invalid') || 
          msg.contains('wrong password') ||
          msg.contains('incorrect password')) {
        Get.snackbar('Sign in failed', 'Invalid email or password');
      } else if (code.contains('email_not_confirmed') || msg.contains('email not confirmed')) {
        Get.snackbar('Email not verified', 'Please check your email and click the verification link');
      } else if (code.contains('too_many_requests') || msg.contains('rate limit')) {
        Get.snackbar('Too many attempts', 'Please wait a moment before trying again');
      } else {
        Get.snackbar('Sign in failed', e.message);
      }
    } catch (e) {
      print('❌ DEBUG: General error in signInWithPassword: $e');
      Get.snackbar('Sign in failed', 'An error occurred. Please try again.');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      isLoading.value = true;
      print('🔄 DEBUG: Starting Google Sign-In...');
      await SupabaseService.signInWithProvider(OAuthProvider.google);
      print('✅ DEBUG: Google Sign-In initiated, waiting for redirect...');
      
      // Track login for UAC
      await AnalyticsService.trackLoginEnhanced('google');
      
      // 🔧 CRITICAL FIX: Check profile and navigate after Google Sign-In
      // This ensures existing users with completed profiles go directly to the app
      await _checkUserProfileAndNavigate();
      
    } catch (e) {
      print('❌ DEBUG: Google Sign-In failed: $e');
      Get.snackbar('Google sign in failed', e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> startEmailOtp() async {
    final email = emailController.text.trim();
    if (email.isEmpty) {
      Get.snackbar('Error', 'Enter email');
      return;
    }
    try {
      await SupabaseService.sendEmailOtp(email);
      isOTPSent.value = true;
      isExistingEmail.value = true;
      _startResendTimer();
      Get.to(() => EmailCodeVerifyScreen(isSignupFlow: false));
    } catch (e) {
      Get.snackbar('Error', 'Could not send code');
    }
  }

  Future<void> sendMagicLink() async {
    final email = emailController.text.trim();
    if (email.isEmpty) {
      Get.snackbar('Error', 'Enter email');
      return;
    }
    try {
      await SupabaseService.client.auth.signInWithOtp(
        email: email, 
        shouldCreateUser: false,
        emailRedirectTo: 'https://dkcitxzvojvecuvacwsp.supabase.co/auth/v1/callback',
      );
      Get.snackbar('Check your email', 'We sent you a sign-in link. Click it to continue in the app.');
    } catch (e) {
      print('Magic link error: $e');
      Get.snackbar('Error', 'Could not send link: $e');
    }
  }

  void _startResendTimer() {
    resendSeconds.value = 30;
    Future.doWhile(() async {
      await Future.delayed(Duration(seconds: 1));
      resendSeconds.value--;
      return resendSeconds.value > 0;
    });
  }


  Future<void> continueWithGoogle() async {
    try {
      isLoading.value = true;
      await SupabaseService.signInWithProvider(OAuthProvider.google);
      // Track login for UAC
      await AnalyticsService.trackLoginEnhanced('google');
      await _checkUserProfileAndNavigate();
    } catch (e) {
      Get.snackbar('Google sign-in failed', e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> continueWithApple() async {
    try {
      isLoading.value = true;
      await SupabaseService.signInWithProvider(OAuthProvider.apple);
      // Track login for UAC
      await AnalyticsService.trackLoginEnhanced('apple');
      await _checkUserProfileAndNavigate();
    } catch (e) {
      Get.snackbar('Apple sign-in failed', e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  void _showAccountDeactivatedDialog(String userId) {
    Get.dialog(
      AlertDialog(
        title: Text('Account Deactivated'),
        content: Text('Your account has been deactivated. All your data is preserved and will be restored when you reactivate your account.'),
        actions: [
          TextButton(
            onPressed: () {
              Get.back();
              // Navigate to welcome screen
              Get.offAll(() => WelcomeScreen());
            },
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Get.back();
              await _reactivateAccount(userId);
            },
            child: Text('Reactivate Account'),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  Future<void> _reactivateAccount(String userId) async {
    try {
      // Show loading
      Get.dialog(
        Center(
          child: Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: Colors.pink),
                SizedBox(height: 10),
                Text(
                  'Reactivating account...',
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
              ],
            ),
          ),
        ),
        barrierDismissible: false,
      );

      // Reactivate the user's account using the stored user ID
      print('🔄 Reactivating account for user: $userId');
      final response = await SupabaseService.client
          .from('profiles')
          .update({'is_active': true})
          .eq('id', userId);
      print('✅ Account reactivated successfully. Response: $response');
      
      // Wait a moment for the database to commit the change
      await Future.delayed(Duration(milliseconds: 500));

      // Close loading dialog
      Get.back();

      // Show success message
      Get.snackbar(
        'Account Reactivated',
        'Your account has been reactivated successfully! Please log in again.',
        backgroundColor: Colors.black,
        colorText: Colors.white,
        duration: Duration(seconds: 3),
      );

      // Navigate to welcome screen - the user needs to log in again
      // This will trigger the normal login flow which should load their real data
      Get.offAll(() => WelcomeScreen());
    } catch (e) {
      print('❌ Error reactivating account: $e');
      Get.back(); // Close loading dialog
      Get.snackbar(
        'Error',
        'Failed to reactivate account: $e',
        backgroundColor: Colors.black,
        colorText: Colors.white,
        duration: Duration(seconds: 3),
      );
    }
  }

  Future<void> _checkUserProfileAndNavigate() async {
    print('🔍 DEBUG: _checkUserProfileAndNavigate called after successful login');
    
    // Wait a moment for the auth state to propagate
    await Future.delayed(Duration(milliseconds: 500));
    
    // Check if user has a session
    final session = SupabaseService.client.auth.currentSession;
    print('🔍 DEBUG: Session check - session exists: ${session != null}');
    print('🔍 DEBUG: User ID: ${session?.user?.id}');
    print('🔍 DEBUG: User email: ${session?.user?.email}');
    
    if (session != null) {
      print('✅ DEBUG: Session found, navigating to main app');
      
      // Force navigation to main app
      Get.offAll(() => BottombarScreen());
    } else {
      print('❌ DEBUG: No session found after login, trying again...');
      
      // Try again after a longer delay
      await Future.delayed(Duration(milliseconds: 1000));
      final retrySession = SupabaseService.client.auth.currentSession;
      if (retrySession != null) {
        print('✅ DEBUG: Session found on retry, navigating to main app');
        Get.offAll(() => BottombarScreen());
      } else {
        print('❌ DEBUG: Still no session after retry');
      }
    }
  }
}
