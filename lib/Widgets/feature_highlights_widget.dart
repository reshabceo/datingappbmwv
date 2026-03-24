import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:lovebug/ThemeController/theme_controller.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';

/// Feature Highlights Widget - Showcases unique features of the app
/// to differentiate from other dating apps
class FeatureHighlightsWidget extends StatefulWidget {
  const FeatureHighlightsWidget({Key? key}) : super(key: key);

  @override
  State<FeatureHighlightsWidget> createState() => _FeatureHighlightsWidgetState();
}

class _FeatureHighlightsWidgetState extends State<FeatureHighlightsWidget> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final ThemeController themeController = Get.find<ThemeController>();

  final List<FeatureCard> features = [
    FeatureCard(
      icon: Icons.people,
      title: 'BFF Mode',
      description: 'Find your next best friend! Switch between dating and friendship modes seamlessly.',
      gradient: [Color(0xFF4CAF50), Color(0xFF8BC34A)],
      emoji: '👯',
    ),
    FeatureCard(
      icon: Icons.auto_awesome,
      title: 'Astrology Matching',
      description: 'Discover cosmic compatibility with AI-powered zodiac insights and personalized match scores.',
      gradient: [Color(0xFF9C27B0), Color(0xFFE91E63)],
      emoji: '✨',
    ),
    FeatureCard(
      icon: Icons.local_fire_department,
      title: 'Flame Chat',
      description: 'Exciting timed chats that create urgency and authentic connections in 5 minutes!',
      gradient: [Color(0xFFFF5722), Color(0xFFFF9800)],
      emoji: '🔥',
    ),
    FeatureCard(
      icon: Icons.chat_bubble_outline,
      title: 'AI Ice Breakers',
      description: 'Never run out of things to say! Get personalized conversation starters based on compatibility.',
      gradient: [Color(0xFF2196F3), Color(0xFF00BCD4)],
      emoji: '💬',
    ),
    FeatureCard(
      icon: Icons.auto_stories_outlined,
      title: 'Life Chronicles',
      description: 'Share your authentic moments and discover connections through engaging chronicles.',
      gradient: [Color(0xFFFF6B6B), Color(0xFFFFE66D)],
      emoji: '📖',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 240.h,
      margin: EdgeInsets.symmetric(vertical: 16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Row(
              children: [
                Text(
                  'What Makes Us Unique',
                  style: GoogleFonts.poppins(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w700,
                    color: themeController.whiteColor,
                  ),
                ),
                SizedBox(width: 8.w),
                Icon(
                  Icons.star,
                  color: Color(0xFFFFD700),
                  size: 24.sp,
                ),
              ],
            ),
          ),
          SizedBox(height: 12.h),
          
          // Feature Cards Carousel
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              itemCount: features.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: _buildFeatureCard(features[index]),
                );
              },
            ),
          ),
          
          // Page Indicators
          SizedBox(height: 12.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              features.length,
              (index) => AnimatedContainer(
                duration: Duration(milliseconds: 300),
                margin: EdgeInsets.symmetric(horizontal: 4.w),
                width: _currentPage == index ? 24.w : 8.w,
                height: 8.h,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4.r),
                  gradient: _currentPage == index
                      ? LinearGradient(
                          colors: features[index].gradient,
                        )
                      : null,
                  color: _currentPage == index
                      ? null
                      : themeController.whiteColor.withValues(alpha: 0.3),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(FeatureCard feature) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            feature.gradient[0].withValues(alpha: 0.2),
            feature.gradient[1].withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: feature.gradient[0].withValues(alpha: 0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: feature.gradient[0].withValues(alpha: 0.2),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon and Emoji
          Row(
            children: [
              Container(
                width: 50.w,
                height: 50.w,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: feature.gradient,
                  ),
                  borderRadius: BorderRadius.circular(12.r),
                  boxShadow: [
                    BoxShadow(
                      color: feature.gradient[0].withValues(alpha: 0.4),
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  feature.icon,
                  color: Colors.white,
                  size: 28.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Text(
                feature.emoji,
                style: TextStyle(fontSize: 32.sp),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          
          // Title
          Text(
            feature.title,
            style: GoogleFonts.poppins(
              fontSize: 22.sp,
              fontWeight: FontWeight.w700,
              color: themeController.whiteColor,
              shadows: [
                Shadow(
                  color: feature.gradient[0].withValues(alpha: 0.5),
                  blurRadius: 10,
                ),
              ],
            ),
          ),
          SizedBox(height: 8.h),
          
          // Description
          Text(
            feature.description,
            style: GoogleFonts.poppins(
              fontSize: 14.sp,
              height: 1.5,
              color: themeController.whiteColor.withValues(alpha: 0.9),
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class FeatureCard {
  final IconData icon;
  final String title;
  final String description;
  final List<Color> gradient;
  final String emoji;

  FeatureCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.gradient,
    required this.emoji,
  });
}
