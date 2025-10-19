import 'package:lovebug/global_data.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_service.dart';
import '../ProfileFormPage/multi_step_profile_form.dart';
import '../BottomBarPage/bottombar_screen.dart';
import '../../services/supabase_service.dart';
import '../../services/analytics_service.dart';
import 'email_code_verify_screen.dart';
import 'auth_ui_screen.dart';
import '../WelcomePage/welcome_screen.dart';

class AuthController extends GetxController {
  TextEditingController phoneController = TextEditingController();
  TextEditingController otpController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController confirmPasswordController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController emailOtpController = TextEditingController();
  RxInt resendSeconds = 0.obs;
  String _emailAction = 'auto'; // 'signin' or 'signup'

  RxString selectedLanguage = 'English'.obs;
  RxString selectedCountryCode = '+1'.obs;
  RxBool isLoading = false.obs;
  RxBool isOTPSent = false.obs;
  RxBool isExistingEmail = false.obs;
  RxBool isSignupMode = false.obs;
  RxBool didProbeEmail = false.obs;
  RxString currentPhone = ''.obs;
  RxString currentOTP = ''.obs;
  RxString authMode = 'phone'.obs; // 'phone' or 'email'

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

  Future<void> sendOTP() async {
    if (phoneController.text.isEmpty) {
      Get.snackbar('Error', 'Please enter phone number');
      return;
    }

    try {
      isLoading.value = true;
      await SupabaseService.sendPhoneOtp(phoneController.text);
      currentPhone.value = phoneController.text;
      isOTPSent.value = true;
      _startResendTimer();
      Get.snackbar('Success', 'OTP sent to ${phoneController.text}');
    } catch (e) {
      Get.snackbar('Error', 'Failed to send OTP');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> verifyOTP() async {
    if (otpController.text.isEmpty) {
      Get.snackbar('Error', 'Please enter OTP');
      return;
    }

    try {
      isLoading.value = true;
      
      final res = await SupabaseService.verifyPhoneOtp(
        phone: currentPhone.value,
        token: otpController.text,
      );
      if (res.user != null) {
        Get.snackbar('Success', 'Verified!');
        // Track login for UAC
        await AnalyticsService.trackLoginEnhanced('phone_otp');
        await _checkUserProfileAndNavigate();
      } else {
        Get.snackbar('Error', 'Invalid code.');
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to verify OTP');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _createDemoUser() async {
    try {
      // Create a demo user with phone number as email
      final email = '${currentPhone.value}@demo.com';
      final password = 'demo123456';
      
      // Sign up the user
      final response = await SupabaseService.client.auth.signUp(
        email: email,
        password: password,
      );
      
      if (response.user != null) {
        print('Demo user created: ${response.user!.id}');
        // Update the user metadata with phone number
        await SupabaseService.client.auth.updateUser(
          UserAttributes(
            data: {'phone': currentPhone.value}
          )
        );
      }
    } catch (e) {
      print('Error creating demo user: $e');
      // If user already exists, try to sign in
      try {
        final email = '${currentPhone.value}@demo.com';
        final password = 'demo123456';
        await SupabaseService.client.auth.signInWithPassword(
          email: email,
          password: password,
        );
        print('Demo user signed in: ${SupabaseService.currentUser?.id}');
      } catch (signInError) {
        print('Error signing in demo user: $signInError');
      }
    }
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

  Future<void> signUp() async {
    if (phoneController.text.isEmpty || passwordController.text.isEmpty) {
      Get.snackbar('Error', 'Please fill all fields');
      return;
    }

    try {
      isLoading.value = true;
      final response = await AuthService.signUpWithPhone(
        phone: phoneController.text,
        password: passwordController.text,
      );

      if (response?.user != null) {
        Get.snackbar('Success', 'Account created successfully!');
        // Track sign up for UAC
        await AnalyticsService.trackSignUp('phone');
        Get.to(() => MultiStepProfileForm());
      } else {
        Get.snackbar('Error', 'Failed to create account');
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to create account');
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
      // Probe existence WITHOUT creating a user.
      await SupabaseService.client.auth.signInWithOtp(
        email: email,
        shouldCreateUser: false,
      );
      // If OTP send succeeds, the email exists → go to sign in
      isExistingEmail.value = true;
      isSignupMode.value = false;
      didProbeEmail.value = true;
      Get.to(() => AuthScreen(startMode: 'email', prefillEmail: email, isPasswordMode: true));
    } on AuthApiException catch (e) {
      final code = (e.code ?? '').toLowerCase();
      final msg = (e.message).toLowerCase();
      // Supabase returns user-not-found variants for non-existing users
      if (code.contains('user_not_found') || msg.contains('user not found') || msg.contains('no user') || code.contains('invalid_user')) {
        isExistingEmail.value = false;
        isSignupMode.value = true;
        didProbeEmail.value = true;
        Get.to(() => AuthScreen(startMode: 'email', prefillEmail: email, isSignupMode: true));
      } else if (code.contains('over_email_send_rate_limit') || msg.contains('rate limit')) {
        // Rate limited while sending OTP → email exists. Route to sign in and show message.
        isExistingEmail.value = true;
        isSignupMode.value = false;
        didProbeEmail.value = true;
        Get.to(() => AuthScreen(startMode: 'email', prefillEmail: email, isPasswordMode: true));
        Get.snackbar('Please wait', 'Too many attempts. Try again shortly.');
      } else {
        // Any other error: conservatively treat as non-existing
        isExistingEmail.value = false;
        isSignupMode.value = true;
        didProbeEmail.value = true;
        Get.to(() => AuthScreen(startMode: 'email', prefillEmail: email, isSignupMode: true));
      }
    } catch (e) {
      // Network/unknown → default to signup to avoid blocking
      isExistingEmail.value = false;
      isSignupMode.value = true;
      didProbeEmail.value = true;
      Get.to(() => AuthScreen(startMode: 'email', prefillEmail: email, isSignupMode: true));
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
      await SupabaseService.signInWithEmail(email: email, password: password);
      // Track login for UAC
      await AnalyticsService.trackLoginEnhanced('email_password');
      await _checkUserProfileAndNavigate();
    } on AuthApiException catch (e) {
      Get.snackbar('Sign in failed', e.message);
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
      await SupabaseService.client.auth.signInWithOtp(email: email, shouldCreateUser: false);
      Get.snackbar('Check your email', 'We sent you a sign-in link');
    } catch (_) {
      Get.snackbar('Error', 'Could not send link');
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

  Future<void> signIn() async {
    if (phoneController.text.isEmpty || passwordController.text.isEmpty) {
      Get.snackbar('Error', 'Please fill all fields');
      return;
    }

    try {
      isLoading.value = true;
      final response = await AuthService.signInWithPhone(
        phone: phoneController.text,
        password: passwordController.text,
      );

      if (response?.user != null) {
        Get.snackbar('Success', 'Signed in successfully!');
        Get.offAll(() => BottombarScreen());
      } else {
        Get.snackbar('Error', 'Failed to sign in');
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to sign in');
    } finally {
      isLoading.value = false;
    }
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
    try {
      // Wait a moment for the session to be established
      await Future.delayed(Duration(milliseconds: 500));
      
      final user = SupabaseService.currentUser;
      print('Current user in _checkUserProfileAndNavigate: ${user?.id}');
      print('User email: ${user?.email}');
      
      if (user != null) {
        // Check if user has a profile
        try {
          print('🔄 DEBUG: Fetching profile for user: ${user.id}');
          final profile = await SupabaseService.getProfile(user.id);
          print('🔄 DEBUG: Profile result: $profile');
          print('🔄 DEBUG: Profile found: ${profile != null}');
          print('🔄 DEBUG: Profile is empty: ${profile?.isEmpty}');
          
          if (profile == null || profile.isEmpty) {
            // New user - go to profile creation
            print('❌ DEBUG: No profile found - navigating to profile creation for new user');
            Get.offAll(() => MultiStepProfileForm());
          } else {
            // Check if user account is deactivated
            if (profile['is_active'] == false) {
              print('🚫 DEBUG: User account is deactivated in auth controller');
              // Store user ID before signing out
              final userId = user.id;
              // Sign out the user and show deactivation message
              await SupabaseService.signOut();
              _showAccountDeactivatedDialog(userId);
              return;
            }
            
            // Returning user - go to main app
            print('Navigating to main app for returning user');
            Get.offAll(() => BottombarScreen());
          }
        } catch (profileError) {
          print('Error checking profile: $profileError');
          // If profile check fails, assume new user
          Get.offAll(() => MultiStepProfileForm());
        }
      } else {
        print('No current user found, navigating to profile creation');
        // No user - go to profile creation
        Get.offAll(() => MultiStepProfileForm());
      }
    } catch (e) {
      print('Error in _checkUserProfileAndNavigate: $e');
      // On error, go to profile creation to be safe
      Get.offAll(() => MultiStepProfileForm());
    }
  }
}
