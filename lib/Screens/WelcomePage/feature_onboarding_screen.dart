import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:lovebug/ThemeController/theme_controller.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lovebug/Screens/BottomBarPage/bottombar_screen.dart';

/// Feature Onboarding Screen - Shows unique features on first app launch
/// This helps App Store reviewers understand what makes the app unique
class FeatureOnboardingScreen extends StatefulWidget {
  const FeatureOnboardingScreen({Key? key}) : super(key: key);

  @override
  State<FeatureOnboardingScreen> createState() => _FeatureOnboardingScreenState();
}

class _FeatureOnboardingScreenState extends State<FeatureOnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final ThemeController themeController = Get.find<ThemeController>();

  final List<OnboardingPage> pages = [
    OnboardingPage(
      title: 'Welcome to LoveBug',
      subtitle: 'More Than Just Dating',
      description: 'A revolutionary app that combines dating, friendship, and cosmic connections.',
      icon: Icons.favorite,
      gradient: [Color(0xFFE91E63), Color(0xFF9C27B0)],
      emoji: '💖',
      animation: 'lottie/welcome.json',
    ),
    OnboardingPage(
      title: 'BFF Mode',
      subtitle: 'Find Your Tribe',
      description: 'Switch between dating and friendship modes. Find your soulmate OR your best friend forever!',
      icon: Icons.people,
      gradient: [Color(0xFF4CAF50), Color(0xFF8BC34A)],
      emoji: '👯',
      animation: 'lottie/friends.json',
    ),
    OnboardingPage(
      title: 'Astrology Matching',
      subtitle: 'Written in the Stars',
      description: 'AI-powered zodiac compatibility analysis. See your cosmic connection score with every match!',
      icon: Icons.auto_awesome,
      gradient: [Color(0xFF9C27B0), Color(0xFF673AB7)],
      emoji: '✨',
      animation: 'lottie/astrology.json',
    ),
    OnboardingPage(
      title: 'Flame Chat',
      subtitle: '5 Minutes of Magic',
      description: 'Timed conversations that create urgency and authenticity. Real connections, real fast!',
      icon: Icons.local_fire_department,
      gradient: [Color(0xFFFF5722), Color(0xFFFF9800)],
      emoji: '🔥',
      animation: 'lottie/flame.json',
    ),
    OnboardingPage(
      title: 'AI-Powered Features',
      subtitle: 'Smart Matching',
      description: 'Personalized ice breakers, conversation starters, and compatibility insights powered by AI.',
      icon: Icons.smart_toy,
      gradient: [Color(0xFF2196F3), Color(0xFF00BCD4)],
      emoji: '🤖',
      animation: 'lottie/ai.json',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: Get.width,
        height: Get.height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              themeController.blackColor,
              themeController.bgGradient1,
              themeController.blackColor,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Skip Button
              Align(
                alignment: Alignment.topRight,
                child: TextButton(
                  onPressed: _skipOnboarding,
                  child: Text(
                    'Skip',
                    style: TextStyle(
                      color: themeController.whiteColor.withValues(alpha: 0.7),
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              
              // Page View
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  itemCount: pages.length,
                  itemBuilder: (context, index) {
                    return _buildPage(pages[index]);
                  },
                ),
              ),
              
              // Page Indicators
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  pages.length,
                  (index) => AnimatedContainer(
                    duration: Duration(milliseconds: 300),
                    margin: EdgeInsets.symmetric(horizontal: 4.w),
                    width: _currentPage == index ? 32.w : 8.w,
                    height: 8.h,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4.r),
                      gradient: _currentPage == index
                          ? LinearGradient(
                              colors: pages[index].gradient,
                            )
                          : null,
                      color: _currentPage == index
                          ? null
                          : themeController.whiteColor.withValues(alpha: 0.3),
                    ),
                  ),
                ),
              ),
              
              SizedBox(height: 32.h),
              
              // Next/Get Started Button
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 32.w),
                child: GestureDetector(
                  onTap: _currentPage == pages.length - 1 ? _finishOnboarding : _nextPage,
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: pages[_currentPage].gradient,
                      ),
                      borderRadius: BorderRadius.circular(30.r),
                      boxShadow: [
                        BoxShadow(
                          color: pages[_currentPage].gradient[0].withValues(alpha: 0.4),
                          blurRadius: 20,
                          offset: Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Text(
                      _currentPage == pages.length - 1 ? 'Get Started' : 'Next',
                      style: GoogleFonts.poppins(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
              
              SizedBox(height: 32.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPage(OnboardingPage page) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 32.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon with gradient background
          Container(
            width: 120.w,
            height: 120.w,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: page.gradient,
              ),
              borderRadius: BorderRadius.circular(30.r),
              boxShadow: [
                BoxShadow(
                  color: page.gradient[0].withValues(alpha: 0.4),
                  blurRadius: 30,
                  offset: Offset(0, 15),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  page.icon,
                  size: 60.sp,
                  color: Colors.white,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Text(
                    page.emoji,
                    style: TextStyle(fontSize: 40.sp),
                  ),
                ),
              ],
            ),
          ),
          
          SizedBox(height: 40.h),
          
          // Title
          Text(
            page.title,
            style: GoogleFonts.dancingScript(
              fontSize: 42.sp,
              fontWeight: FontWeight.w700,
              color: themeController.whiteColor,
              shadows: [
                Shadow(
                  color: page.gradient[0].withValues(alpha: 0.6),
                  blurRadius: 20,
                ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
          
          SizedBox(height: 12.h),
          
          // Subtitle
          Text(
            page.subtitle,
            style: GoogleFonts.poppins(
              fontSize: 20.sp,
              fontWeight: FontWeight.w600,
              color: themeController.whiteColor.withValues(alpha: 0.9),
            ),
            textAlign: TextAlign.center,
          ),
          
          SizedBox(height: 24.h),
          
          // Description
          Text(
            page.description,
            style: GoogleFonts.poppins(
              fontSize: 16.sp,
              height: 1.6,
              color: themeController.whiteColor.withValues(alpha: 0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _nextPage() {
    _pageController.nextPage(
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _skipOnboarding() {
    Get.offAll(() => BottombarScreen());
  }

  void _finishOnboarding() {
    // Mark onboarding as completed
    // You can save this to SharedPreferences
    Get.offAll(() => BottombarScreen());
  }
}

class OnboardingPage {
  final String title;
  final String subtitle;
  final String description;
  final IconData icon;
  final List<Color> gradient;
  final String emoji;
  final String animation;

  OnboardingPage({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.icon,
    required this.gradient,
    required this.emoji,
    required this.animation,
  });
}
