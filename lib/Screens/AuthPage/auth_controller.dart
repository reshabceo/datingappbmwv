import 'package:lovebug/global_data.dart';
import 'package:lovebug/shared_prefrence_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import '../ProfileFormPage/multi_step_profile_form.dart';
import '../BottomBarPage/bottombar_screen.dart';
import '../../services/supabase_service.dart';
import '../../services/analytics_service.dart';
import '../../services/notification_service.dart';
import '../../utils/email_validation.dart';
import 'email_code_verify_screen.dart';
import 'reset_password_verify_screen.dart';
import 'auth_ui_screen.dart';
import 'package:lovebug/Common/widget_constant.dart';
import '../WelcomePage/welcome_screen.dart';

class AuthController extends GetxController {
  TextEditingController passwordController = TextEditingController();
  TextEditingController confirmPasswordController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController emailOtpController = TextEditingController();
  RxInt resendSeconds = 0.obs;
  String _emailAction = 'auto'; // 'signin' or 'signup'
  bool _isSignupFlow = false; // Track if current OTP verification is for signup

  RxString selectedLanguage = 'English'.obs;
  RxBool isLoading = false.obs;
  RxBool isExistingEmail = false.obs;
  RxBool isSignupMode = false.obs;
  RxBool didProbeEmail = false.obs;
  RxBool isOTPSent = false.obs;
  RxString authMode = 'email'.obs; // Always email mode

  // Method to set signup flow flag from EmailCodeVerifyScreen
  void setSignupFlow(bool isSignup) {
    _isSignupFlow = isSignup;
    print('🔍 DEBUG: Signup flow flag set to: $_isSignupFlow');
  }

  final Map<String, String> languagesMap = {
    'English': 'en',
    'Hindi': 'hi',
    'Arabic': 'ar',
    'German': 'de',
  };

  @override
  void onInit() {
    super.onInit();
    // Load saved language preference
    final savedLanguageName = SharedPreferenceHelper.getString(
      SharedPreferenceHelper.languageName,
      defaultValue: 'English',
    );
    selectedLanguage.value = savedLanguageName.isNotEmpty ? savedLanguageName : 'English';
    print('🌍 DEBUG: AuthController initialized with language: ${selectedLanguage.value}');
  }




  Future<void> signUpWithEmail() async {
    if (emailController.text.isEmpty || passwordController.text.isEmpty || confirmPasswordController.text.isEmpty) {
      showCustomSnackBar(title: 'error'.tr, message: 'please_fill_all_fields'.tr, isError: true);
      return;
    }
    
    // Validate email format and prevent invalid emails
    final emailValidation = EmailValidation.validateEmail(emailController.text.trim());
    if (!emailValidation.valid) {
      showCustomSnackBar(title: 'invalid_email'.tr, message: (emailValidation.error ?? 'please_enter_a_valid_email_address'.tr), isError: true);
      return;
    }
    
    if (passwordController.text.length < 6) {
      showCustomSnackBar(title: 'error'.tr, message: 'password_must_be_at_least_6_characters'.tr, isError: true);
      return;
    }
    if (passwordController.text != confirmPasswordController.text) {
      showCustomSnackBar(title: 'error'.tr, message: 'passwords_do_not_match'.tr, isError: true);
      return;
    }
    try {
      isLoading.value = true;
      print('Signing up user with email and sending OTP...');
      
      // Use signUp to create user account
      final response = await SupabaseService.signUpWithEmail(
        email: emailController.text,
        password: passwordController.text
      );
      
      print('User signed up successfully: ${response.user?.id}');
      
      // CRITICAL FIX: After signup, send OTP code explicitly
      // signUp() sends a magic link by default; we want a 6-digit code instead
      try {
        await SupabaseService.sendEmailOtp(emailController.text);
        print('✅ OTP code sent to ${emailController.text}');
      } catch (otpError) {
        print('⚠️ OTP send after signup error (may be rate limited): $otpError');
        // Continue anyway - the user was created
      }
      
      isOTPSent.value = true;
      _startResendTimer();
      
      print('Navigating to email verification screen');
      _isSignupFlow = true; // Mark this as signup flow
      Get.to(() => EmailCodeVerifyScreen(
        isSignupFlow: true, 
        email: emailController.text, 
        password: passwordController.text
      ));
      
      showCustomSnackBar(title: 'check_your_email'.tr, message: '${'we_sent_a_6_digit_verification_code_to'.tr} ${emailController.text}');
    } on AuthApiException catch (e) {
      print('Auth error in signUpWithEmail: $e');
      if (e.code == 'over_email_send_rate_limit') {
        // Safely extract wait time from error message
        String waitMessage = 'a few minutes';
        try {
          final messageParts = e.message.split('after ');
          if (messageParts.length > 1) {
            final timeParts = messageParts[1].split(' seconds');
            if (timeParts.isNotEmpty) {
              final seconds = int.tryParse(timeParts[0]);
              if (seconds != null) {
                if (seconds < 60) {
                  waitMessage = '$seconds seconds';
                } else {
                  final minutes = (seconds / 60).ceil();
                  waitMessage = '$minutes minute${minutes > 1 ? 's' : ''}';
                }
              }
            }
          }
        } catch (_) {
          // If parsing fails, use default message
        }
        showCustomSnackBar(title: 'rate_limited'.tr, message: '${'too_many_requests_please_wait'.tr} $waitMessage ${'before_trying_again'.tr}', isError: true);
      } else {
        showCustomSnackBar(title: 'error'.tr, message: '${'failed_to_create_account'.tr}: ${e.message}', isError: true);
      }
    } catch (e) {
      print('Error in signUpWithEmail: $e');
      showCustomSnackBar(title: 'error'.tr, message: '${'failed_to_create_account'.tr}: ${e.toString()}', isError: true);
    } finally {
      isLoading.value = false;
    }
  }


  Future<void> signInWithEmail() async {
    if (emailController.text.isEmpty) {
      showCustomSnackBar(title: 'error'.tr, message: 'enter_email'.tr, isError: true);
      return;
    }
    try {
      isLoading.value = true;
      await SupabaseService.sendEmailOtp(emailController.text);
      showCustomSnackBar(title: 'verification_needed'.tr, message: 'we_sent_a_6_digit_code_to_your_email'.tr);
      isOTPSent.value = true;
    } catch (e) {
      showCustomSnackBar(title: 'error'.tr, message: 'failed_to_send_code'.tr, isError: true);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> verifyEmailCodeAndSetPassword() async {
    if (emailOtpController.text.isEmpty) {
      showCustomSnackBar(title: 'error'.tr, message: 'enter_the_6_digit_code'.tr, isError: true);
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
        // Pass isSignupFlow flag to check profile and navigate appropriately
        await _checkUserProfileAndNavigate(isSignupFlow: _isSignupFlow);
        _isSignupFlow = false; // Reset after use
      } else {
        showCustomSnackBar(title: 'error'.tr, message: 'invalid_code'.tr, isError: true);
      }
    } catch (e) {
      print('Error verifying email: $e');
      showCustomSnackBar(title: 'error'.tr, message: '${'verification_failed'.tr}: ${e.toString()}', isError: true);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> continueWithEmail() async {
    final email = emailController.text.trim();
    if (email.isEmpty) {
      showCustomSnackBar(title: 'error'.tr, message: 'enter_email'.tr, isError: true);
      return;
    }
    
    print('Checking email: $email');
    try {
      // Primary probe: check profiles table for email (most reliable and fast)
      final row = await SupabaseService.client
          .from('profiles')
          .select('id')
          .eq('email', email)
          .maybeSingle();
      if (row != null) {
        print('Email found in profiles, showing password option');
        isExistingEmail.value = true;
        isSignupMode.value = false;
        didProbeEmail.value = true;
        Get.to(() => AuthScreen(prefillEmail: email, isPasswordMode: true));
        return;
      }
      
      // Fallback probe: request sign-in OTP without creating a user
      // Some environments may not allow selecting profiles by email due to RLS
      try {
        await SupabaseService.client.auth.signInWithOtp(
          email: email,
          shouldCreateUser: false,
        );
        print('OTP request succeeded → treat as existing user');
        isExistingEmail.value = true;
        isSignupMode.value = false;
        didProbeEmail.value = true;
        Get.to(() => AuthScreen(prefillEmail: email, isPasswordMode: true));
      } on AuthApiException catch (e) {
        final code = (e.code ?? '').toLowerCase();
        final msg = (e.message).toLowerCase();
        print('OTP probe exception - Code: $code, Message: $msg');
        if (code.contains('user_not_found') || msg.contains('user not found') || msg.contains('no user') || code.contains('invalid_user')) {
          print('Email not found → go to signup');
          isExistingEmail.value = false;
          isSignupMode.value = true;
          didProbeEmail.value = true;
          Get.to(() => AuthScreen(prefillEmail: email, isSignupMode: true));
        } else if (code.contains('over_email_send_rate_limit') || msg.contains('rate limit')) {
          print('Rate limited → treat as existing');
          isExistingEmail.value = true;
          isSignupMode.value = false;
          didProbeEmail.value = true;
          Get.to(() => AuthScreen(prefillEmail: email, isPasswordMode: true));
          showCustomSnackBar(title: 'please_wait'.tr, message: 'too_many_attempts_try_again_shortly'.tr, isError: true);
        } else {
          print('Unknown OTP probe error → default to signup');
          isExistingEmail.value = false;
          isSignupMode.value = true;
          didProbeEmail.value = true;
          Get.to(() => AuthScreen(prefillEmail: email, isSignupMode: true));
        }
      }
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
        showCustomSnackBar(title: 'please_wait'.tr, message: 'too_many_attempts_try_again_shortly'.tr, isError: true);
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
    
    // Validate email before resending
    final emailValidation = EmailValidation.validateEmail(email);
    if (!emailValidation.valid) {
      showCustomSnackBar(title: 'invalid_email'.tr, message: (emailValidation.error ?? 'please_enter_a_valid_email_address'.tr), isError: true);
      return;
    }
    try {
      await SupabaseService.sendEmailOtp(email);
      _startResendTimer();
      showCustomSnackBar(title: 'sent'.tr, message: '${'we_resent_the_code_to'.tr} $email');
    } catch (_) {}
  }

  Future<void> signInWithPassword() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    if (email.isEmpty || password.isEmpty) {
      showCustomSnackBar(title: 'error'.tr, message: 'enter_email_and_password'.tr, isError: true);
      return;
    }
    
    // Validate email format
    final emailValidation = EmailValidation.validateEmail(email);
    if (!emailValidation.valid) {
      showCustomSnackBar(title: 'invalid_email'.tr, message: (emailValidation.error ?? 'please_enter_a_valid_email_address'.tr), isError: true);
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
        showCustomSnackBar(title: 'sign_in_failed'.tr, message: 'invalid_email_or_password'.tr, isError: true);
      } else if (code.contains('email_not_confirmed') || msg.contains('email not confirmed')) {
        showCustomSnackBar(title: 'email_not_verified'.tr, message: 'please_check_your_email_and_click_the_verification_link'.tr, isError: true);
      } else if (code.contains('too_many_requests') || msg.contains('rate limit')) {
        showCustomSnackBar(title: 'too_many_attempts'.tr, message: 'please_wait_a_moment_before_trying_again'.tr, isError: true);
      } else {
        showCustomSnackBar(title: 'sign_in_failed'.tr, message: e.message, isError: true);
      }
    } catch (e) {
      print('❌ DEBUG: General error in signInWithPassword: $e');
      showCustomSnackBar(title: 'sign_in_failed'.tr, message: 'an_error_occurred_please_try_again'.tr, isError: true);
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
      showCustomSnackBar(title: 'google_sign_in_failed'.tr, message: e.toString(), isError: true);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> startEmailOtp() async {
    final email = emailController.text.trim();
    if (email.isEmpty) {
      showCustomSnackBar(title: 'error'.tr, message: 'enter_email'.tr, isError: true);
      return;
    }
    try {
      await SupabaseService.sendEmailOtp(email);
      isOTPSent.value = true;
      isExistingEmail.value = true;
      _isSignupFlow = false; // This is sign-in, not signup
      _startResendTimer();
      Get.to(() => EmailCodeVerifyScreen(isSignupFlow: false));
    } catch (e) {
      showCustomSnackBar(title: 'error'.tr, message: 'could_not_send_code'.tr, isError: true);
    }
  }

  Future<bool> verifyPasswordResetOtp(String email, String otp, String newPassword) async {
    try {
      isLoading.value = true;
      print('🔄 DEBUG: Verifying recovery OTP for: $email');
      
      final res = await SupabaseService.client.auth.verifyOTP(
        email: email,
        token: otp,
        type: OtpType.recovery,
      );
      
      if (res.user != null) {
        print('✅ DEBUG: OTP verified, updating password for user: ${res.user?.id}');
        await SupabaseService.client.auth.updateUser(
          UserAttributes(password: newPassword),
        );
        
        print('✅ DEBUG: Password updated, checking profile and navigating...');
        // Track for UAC
        await AnalyticsService.trackLoginEnhanced('password_reset_otp');
        await _checkUserProfileAndNavigate();
        return true;
      }
      return false;
    } on AuthApiException catch (e) {
      print('❌ DEBUG: Auth error in verifyPasswordResetOtp: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      print('❌ DEBUG: General error in verifyPasswordResetOtp: $e');
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> forgotPassword() async {
    final email = emailController.text.trim();
    if (email.isEmpty) {
      showCustomSnackBar(title: 'error'.tr, message: 'enter_email'.tr, isError: true);
      return;
    }
    
    // Validate email format
    final emailValidation = EmailValidation.validateEmail(email);
    if (!emailValidation.valid) {
      showCustomSnackBar(title: 'invalid_email'.tr, message: (emailValidation.error ?? 'please_enter_a_valid_email_address'.tr), isError: true);
      return;
    }

    try {
      isLoading.value = true;
      print('🔄 DEBUG: Requesting password reset OTP for: $email');
      await SupabaseService.client.auth.resetPasswordForEmail(email);
      
      _startResendTimer();
      isOTPSent.value = true;
      
      showCustomSnackBar(title: 'code_sent'.tr, message: '${'we_sent_a_6_digit_password_reset_code_to'.tr} $email');
      
      // Navigate if not already on the verify screen
      if (Get.currentRoute != '/ResetPasswordVerifyScreen') {
        Get.to(() => ResetPasswordVerifyScreen(email: email));
      }
    } on AuthApiException catch (e) {
      print('❌ DEBUG: Auth error in forgotPassword: ${e.code} - ${e.message}');
      if (e.code == 'over_email_send_rate_limit') {
        showCustomSnackBar(title: 'please_wait'.tr, message: 'too_many_requests_please_try_again_in_a_few_minutes'.tr, isError: true);
      } else {
        showCustomSnackBar(title: 'error'.tr, message: '${'failed_to_send_reset_code'.tr}: ${e.message}', isError: true);
      }
    } catch (e) {
      print('❌ DEBUG: General error in forgotPassword: $e');
      showCustomSnackBar(title: 'error'.tr, message: 'could_not_send_reset_code_please_try_again'.tr, isError: true);
    } finally {
      isLoading.value = false;
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
      // NOTE: Don't call _checkUserProfileAndNavigate() here!
      // signInWithOAuth only opens the browser — OAuth hasn't completed yet.
      // The _AuthGate auth state listener will handle navigation when the
      // OAuth deep link callback fires and Supabase completes the PKCE exchange.
      print('✅ Google OAuth browser opened — waiting for callback via deep link');
    } catch (e) {
      showCustomSnackBar(title: 'google_sign_in_failed'.tr, message: e.toString(), isError: true);
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
      // NOTE: Don't call _checkUserProfileAndNavigate() here!
      // signInWithOAuth only opens the browser — OAuth hasn't completed yet.
      // The _AuthGate auth state listener handles navigation on deep link callback.
      print('✅ Apple OAuth browser opened — waiting for callback via deep link');
    } catch (e) {
      showCustomSnackBar(title: 'apple_sign_in_failed'.tr, message: e.toString(), isError: true);
    } finally {
      isLoading.value = false;
    }
  }

  void _showAccountDeactivatedDialog(String userId) {
    Get.dialog(
      AlertDialog(
        title: Text('account_deactivated'.tr),
        content: Text('account_deactivated_message'.tr),
        actions: [
          TextButton(
            onPressed: () {
              Get.back();
              // Navigate to welcome screen
              Get.offAll(() => WelcomeScreen());
            },
            child: Text('cancel'.tr),
          ),
          TextButton(
            onPressed: () async {
              Get.back();
              await _reactivateAccount(userId);
            },
            child: Text('reactivate_account'.tr),
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
      showCustomSnackBar(
        title: 'account_reactivated'.tr,
        message: 'account_reactivated_success_message'.tr,
      );

      // Navigate to welcome screen - the user needs to log in again
      // This will trigger the normal login flow which should load their real data
      Get.offAll(() => WelcomeScreen());
    } catch (e) {
      print('❌ Error reactivating account: $e');
      Get.back(); // Close loading dialog
      showCustomSnackBar(
        title: 'error'.tr,
        message: '${'failed_to_reactivate_account'.tr}: $e',
        isError: true,
      );
    }
  }

  Future<void> _checkUserProfileAndNavigate({bool isSignupFlow = false}) async {
    print('🔍 DEBUG: _checkUserProfileAndNavigate called after successful login');
    print('🔍 DEBUG: isSignupFlow: $isSignupFlow');
    
    // Wait a moment for the auth state to propagate
    await Future.delayed(Duration(milliseconds: 500));
    
    // Check if user has a session
    final session = SupabaseService.client.auth.currentSession;
    print('🔍 DEBUG: Session check - session exists: ${session != null}');
    print('🔍 DEBUG: User ID: ${session?.user?.id}');
    print('🔍 DEBUG: User email: ${session?.user?.email}');
    
    if (session != null) {
      final userId = session.user!.id;
      
      // 🔔 CRITICAL FIX: Register FCM token after successful authentication
      try {
        await NotificationService.registerFCMToken();
        print('✅ DEBUG: FCM token registration attempted after login');
        
        // iOS-specific: Retry FCM registration after a delay if it failed
        if (Platform.isIOS) {
          Future.delayed(Duration(seconds: 3), () async {
            try {
              print('🍎 DEBUG: Retrying FCM token registration for iOS...');
              await NotificationService.registerFCMToken();
              print('✅ DEBUG: iOS FCM token retry completed');
            } catch (e) {
              print('❌ DEBUG: iOS FCM token retry failed: $e');
            }
          });
        }
      } catch (e) {
        print('❌ DEBUG: FCM token registration failed: $e');
      }
      
      // Check if profile exists and is complete
      try {
        final profile = await SupabaseService.getProfile(userId);
        
        print('🔍 DEBUG: Profile check - exists: ${profile != null}');
        
        if (profile != null) {
          // Check if profile is complete (has all required fields)
          final hasName = profile['name'] != null && profile['name'].toString().trim().isNotEmpty;
          final hasAge = profile['age'] != null && profile['age'] != 0;
          final hasDescription = profile['description'] != null && profile['description'].toString().trim().isNotEmpty;
          final hasHobbies = profile['hobbies'] != null && (profile['hobbies'] as List).isNotEmpty;
          final hasPhotos = profile['image_urls'] != null && (profile['image_urls'] as List).isNotEmpty;
          
          final isProfileComplete = hasName && hasAge && hasDescription && hasHobbies && hasPhotos;
          
          print('🔍 DEBUG: Profile completeness:');
          print('  - Name: $hasName');
          print('  - Age: $hasAge');
          print('  - Description: $hasDescription');
          print('  - Hobbies: $hasHobbies');
          print('  - Photos: $hasPhotos');
          print('  - Complete: $isProfileComplete');
          
          // If this is a signup flow OR profile is incomplete, go to profile form
          if (isSignupFlow || !isProfileComplete) {
            print('📝 DEBUG: Navigating to profile form (signup: $isSignupFlow, incomplete: ${!isProfileComplete})');
            Get.offAll(() => MultiStepProfileForm());
            return;
          } else {
            print('✅ DEBUG: Profile is complete, navigating to main app');
            Get.offAll(() => BottombarScreen());
            return;
          }
        } else {
          // No profile exists - must be a new signup, go to profile form
          print('📝 DEBUG: No profile found, navigating to profile form');
          Get.offAll(() => MultiStepProfileForm());
          return;
        }
      } catch (e) {
        print('❌ DEBUG: Error checking profile: $e');
        // On error, if it's a signup flow, go to profile form
        // Otherwise, try to go to main app
        if (isSignupFlow) {
          print('📝 DEBUG: Error during signup, navigating to profile form');
          Get.offAll(() => MultiStepProfileForm());
        } else {
          print('✅ DEBUG: Error but not signup, navigating to main app');
          Get.offAll(() => BottombarScreen());
        }
        return;
      }
    } else {
      print('❌ DEBUG: No session found after login, trying again...');
      
      // Try again after a longer delay
      await Future.delayed(Duration(milliseconds: 1000));
      final retrySession = SupabaseService.client.auth.currentSession;
      if (retrySession != null) {
        print('✅ DEBUG: Session found on retry, checking profile...');
        // Recursively call with same signup flag
        await _checkUserProfileAndNavigate(isSignupFlow: isSignupFlow);
      } else {
        print('❌ DEBUG: Still no session after retry');
      }
    }
  }
}
