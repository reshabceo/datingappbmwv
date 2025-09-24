import 'package:boliler_plate/Language/all_languages.dart';
import 'package:boliler_plate/Screens/WelcomePage/welcome_screen.dart';
import 'package:boliler_plate/global_data.dart';
import 'package:boliler_plate/shared_prefrence_helper.dart';
import 'package:boliler_plate/services/supabase_service.dart';
import 'package:boliler_plate/services/analytics_service.dart';
import 'package:boliler_plate/services/payment_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import 'ThemeController/theme_controller.dart';
// Firebase Analytics
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'Screens/BottomBarPage/bottombar_screen.dart';
import 'Screens/ProfileFormPage/multi_step_profile_form.dart';
import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Supabase
  await SupabaseService.initialize();
  
  // Initialize Payment Service
  await PaymentService.initialize();
  
  // Initialize Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await AnalyticsService.initialize();
    print('✅ Firebase Analytics initialized');
  } catch (e) {
    print('❌ Firebase initialization failed: $e');
  }
  
  // Initialize SharedPreferences
  await SharedPreferenceHelper.init();
  lanCode.value = SharedPreferenceHelper.getString(SharedPreferenceHelper.languageCode, defaultValue: 'en');
  lanName.value = SharedPreferenceHelper.getString(SharedPreferenceHelper.languageName, defaultValue: 'English');
  // Ensure ThemeController is registered before any widget requests it
  if (!Get.isRegistered<ThemeController>()) {
    Get.put(ThemeController(), permanent: true);
  }
  
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp({super.key});

  final ThemeController themeController = Get.find<ThemeController>();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: ScreenUtilInit(
        minTextAdapt: true,
        splitScreenMode: true,
        designSize: const Size(375, 812),
        builder: (_, child) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
              child: GetMaterialApp(
                title: 'Dating App',
                debugShowCheckedModeBanner: false,
                locale: Locale(lanCode.value),
                translations: AppTranslations(),
                theme: themeController.lightTheme,
                darkTheme: themeController.darkTheme,
                themeMode: themeController.isDarkMode.value ? ThemeMode.dark : ThemeMode.light,
                home: _AuthGate(),
                // home: BottombarScreen(),
              ),
            );
        },
      ),
    );
  }
}

class _AuthGate extends StatefulWidget {
  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  bool _ready = false;
  bool _hasSession = false;
  bool _hasProfile = false;
  bool _checkingProfile = true;
  StreamSubscription<AuthState>? _authSub;

  @override
  void initState() {
    super.initState();
    _checkSessionAndProfile();
    // React to login/logout in real time
    _authSub = SupabaseService.authStateChanges.listen((_) {
      _checkSessionAndProfile();
    });
  }

  Future<void> _checkSessionAndProfile() async {
    // Give Supabase a beat to hydrate session
    await Future.delayed(const Duration(milliseconds: 150));
    final session = SupabaseService.client.auth.currentSession;
    
    if (session != null) {
      // User is authenticated, check if they have a complete profile
      try {
        final user = SupabaseService.currentUser;
        if (user != null) {
          final profile = await SupabaseService.getProfile(user.id);
          setState(() {
            _ready = true;
            _hasSession = true;
            _hasProfile = profile != null && profile.isNotEmpty && profile['name'] != null;
            _checkingProfile = false;
          });
          
          // Start analytics session for authenticated user
          await AnalyticsService.startSession();
        } else {
          setState(() {
            _ready = true;
            _hasSession = false;
            _hasProfile = false;
            _checkingProfile = false;
          });
        }
      } catch (e) {
        print('Error checking profile: $e');
        setState(() {
          _ready = true;
          _hasSession = true;
          _hasProfile = false;
          _checkingProfile = false;
        });
        
        // Start analytics session even if profile check fails
        await AnalyticsService.startSession();
      }
    } else {
      setState(() {
        _ready = true;
        _hasSession = false;
        _hasProfile = false;
        _checkingProfile = false;
      });
    }
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready || _checkingProfile) {
      return Center(child: CircularProgressIndicator());
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        Widget child;
        if (!_hasSession) {
          child = WelcomeScreen();
        } else if (!_hasProfile) {
          child = MultiStepProfileForm();
        } else {
          child = BottombarScreen();
        }
        
        if (constraints.maxWidth > 600) {
          return Center(
            child: Container(
              constraints: BoxConstraints(maxWidth: 400, maxHeight: constraints.maxHeight),
              child: child,
            ),
          );
        }
        return child;
      },
    );
  }
}

// Push init & handlers
// Future<void> _initPush() async {}
