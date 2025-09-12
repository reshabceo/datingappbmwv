import 'package:boliler_plate/Common/text_constant.dart';
import 'package:boliler_plate/Common/widget_constant.dart';
import 'package:boliler_plate/Screens/DiscoverPage/controller_discover_screen.dart';
import 'package:boliler_plate/ThemeController/theme_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:gradient_borders/gradient_borders.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';

class ProfileDetailScreen extends StatefulWidget {
  final Profile profile;

  const ProfileDetailScreen({
    super.key,
    required this.profile,
  });

  @override
  State<ProfileDetailScreen> createState() => _ProfileDetailScreenState();
}

class _ProfileDetailScreenState extends State<ProfileDetailScreen> {
  late PageController _pageController;
  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeController themeController = Get.find<ThemeController>();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.black,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: themeController.blackColor,
        extendBodyBehindAppBar: true,
        body: Container(
          width: Get.width,
          height: Get.height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                themeController.blackColor,
                themeController.bgGradient1,
                themeController.blackColor,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Stack(
            children: [
              // Main Content
              Column(
                children: [
                  // Custom App Bar
                  _buildCustomAppBar(themeController),
                  
                  // Scrollable Content
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20.r),
                      child: _buildStaggeredBody(themeController),
                    ),
                  ),
                ],
              ),
              
              // Fixed Action Buttons Overlay
              _buildActionButtons(themeController),
            ],
          ),
        ),
      ),
    );
  }

  // Staggered appearance for sections
  Widget _buildStaggeredBody(ThemeController themeController) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOut,
      builder: (context, t, child) {
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, (1 - t) * 20),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildImageGallery(themeController),
                  _delayed(t, 0.1, _buildProfileInfo(themeController)),
                  _delayed(t, 0.2, _buildBioSection(themeController)),
                  _delayed(t, 0.3, _buildInterestsSection(themeController)),
                  SizedBox(height: 100.h),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _delayed(double t, double start, Widget child) {
    final localT = t.clamp(start, 1);
    final p = (localT - start) / (1 - start);
    return Opacity(
      opacity: p,
      child: Transform.translate(
        offset: Offset(0, (1 - p) * 16),
        child: child,
      ),
    );
  }

  Widget _buildCustomAppBar(ThemeController themeController) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 10.h,
        left: 20.w,
        right: 20.w,
        bottom: 10.h,
      ),
      child: Row(
        children: [
          // Back Button
          GestureDetector(
            onTap: () => Get.back(),
            child: Container(
              width: 40.w,
              height: 40.w,
              decoration: BoxDecoration(
                color: themeController.blackColor.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(
                  color: themeController.lightPinkColor.withValues(alpha: 0.3),
                  width: 1.w,
                ),
              ),
              child: Icon(
                Icons.arrow_back_ios_new,
                color: themeController.whiteColor,
                size: 20.sp,
              ),
            ),
          ),
          
          Spacer(),
          
          // Image Counter
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: themeController.blackColor.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(
                color: themeController.lightPinkColor.withValues(alpha: 0.3),
                width: 1.w,
              ),
            ),
            child: TextConstant(
              title: '${_currentImageIndex + 1}/${_getImageCount()}',
              fontSize: 12.sp,
              color: themeController.whiteColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          
          SizedBox(width: 10.w),
          
          // More Options Button
          GestureDetector(
            onTap: () {
              // TODO: Add more options menu
            },
            child: Container(
              width: 40.w,
              height: 40.w,
              decoration: BoxDecoration(
                color: themeController.blackColor.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(
                  color: themeController.lightPinkColor.withValues(alpha: 0.3),
                  width: 1.w,
                ),
              ),
              child: Icon(
                Icons.more_vert,
                color: themeController.whiteColor,
                size: 20.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageGallery(ThemeController themeController) {
    final images = _getImages();
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: AspectRatio(
        aspectRatio: 3 / 4,
        child: Stack(
          children: [
          // Image PageView
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentImageIndex = index;
              });
            },
            itemCount: images.length,
            itemBuilder: (context, index) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(20.r),
                child: Image.network(images[index], fit: BoxFit.cover),
              );
            },
          ),
          
          // Image Dots Indicator
          Positioned(
            bottom: 20.h,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(images.length, (index) {
                return Container(
                  margin: EdgeInsets.symmetric(horizontal: 4.w),
                  width: _currentImageIndex == index ? 20.w : 8.w,
                  height: 8.h,
                  decoration: BoxDecoration(
                    color: _currentImageIndex == index
                        ? themeController.lightPinkColor
                        : themeController.whiteColor.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                );
              }),
            ),
          ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileInfo(ThemeController themeController) {
    return Container(
      margin: EdgeInsets.all(20.w),
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: themeController.blackColor.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: themeController.lightPinkColor.withValues(alpha: 0.3),
          width: 1.w,
        ),
        boxShadow: [
          BoxShadow(
            color: themeController.lightPinkColor.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name and Age
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                widget.profile.name,
                style: GoogleFonts.dancingScript(
                  fontSize: 34.sp,
                  fontWeight: FontWeight.w700,
                  color: themeController.whiteColor,
                  shadows: [
                    Shadow(color: themeController.lightPinkColor.withValues(alpha: 0.6), blurRadius: 20.r),
                    Shadow(color: themeController.lightPinkColor.withValues(alpha: 0.3), blurRadius: 40.r),
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              Text(
                '${widget.profile.age}',
                style: GoogleFonts.dancingScript(
                  fontSize: 34.sp,
                  fontWeight: FontWeight.w700,
                  color: themeController.lightPinkColor,
                  shadows: [
                    Shadow(color: themeController.lightPinkColor.withValues(alpha: 0.6), blurRadius: 20.r),
                    Shadow(color: themeController.lightPinkColor.withValues(alpha: 0.3), blurRadius: 40.r),
                  ],
                ),
              ),
            ],
          ),
          
          SizedBox(height: 10.h),
          
          // Location and Distance
          Row(
            children: [
              Icon(
                Icons.location_on,
                color: themeController.lightPinkColor,
                size: 18.sp,
              ),
              SizedBox(width: 5.w),
              TextConstant(
                title: widget.profile.location,
                fontSize: 16.sp,
                color: themeController.whiteColor,
              ),
              TextConstant(
                title: ' • ',
                fontSize: 16.sp,
                color: themeController.whiteColor,
              ),
              TextConstant(
                title: widget.profile.distance,
                fontSize: 16.sp,
                color: themeController.lightPinkColor,
              ),
            ],
          ),
          
          SizedBox(height: 15.h),
          
          // Status Badges
          Row(
            children: [
              if (widget.profile.isVerified)
                _buildStatusBadge(
                  themeController,
                  icon: Icons.check_circle_rounded,
                  text: 'Verified',
                  color: themeController.lightPinkColor,
                ),
              if (widget.profile.isVerified) SizedBox(width: 10.w),
              if (widget.profile.isActiveNow)
                _buildStatusBadge(
                  themeController,
                  icon: LucideIcons.flame,
                  text: 'Active Now',
                  color: themeController.lightPinkColor,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(
    ThemeController themeController, {
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: color, width: 1.w),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16.sp),
          SizedBox(width: 4.w),
          TextConstant(
            title: text,
            fontSize: 12.sp,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ],
      ),
    );
  }

  Widget _buildBioSection(ThemeController themeController) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w),
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: themeController.lightPinkColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: themeController.lightPinkColor.withValues(alpha: 0.3),
          width: 1.w,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextConstant(
            title: 'About Me',
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: themeController.whiteColor,
          ),
          SizedBox(height: 10.h),
          TextConstant(
            title: widget.profile.description,
            fontSize: 16.sp,
            color: themeController.whiteColor.withValues(alpha: 0.9),
            height: 1.5,
          ),
        ],
      ),
    );
  }

  Widget _buildInterestsSection(ThemeController themeController) {
    return Container(
      margin: EdgeInsets.all(20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextConstant(
            title: 'Interests',
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: themeController.whiteColor,
          ),
          SizedBox(height: 15.h),
          Wrap(
            spacing: 10.w,
            runSpacing: 10.h,
            children: widget.profile.hobbies.map((hobby) {
              return Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      themeController.lightPinkColor.withValues(alpha: 0.3),
                      themeController.lightPinkColor.withValues(alpha: 0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(25.r),
                  border: Border.all(
                    color: themeController.lightPinkColor.withValues(alpha: 0.5),
                    width: 1.w,
                  ),
                ),
                child: TextConstant(
                  title: hobby,
                  fontSize: 14.sp,
                  color: themeController.whiteColor,
                  fontWeight: FontWeight.w600,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(ThemeController themeController) {
    return Positioned(
      bottom: 30.h,
      left: 0,
      right: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Pass Button
          _buildActionButton(
            themeController,
            icon: Icons.close,
            color: Colors.red,
            onTap: () {
              Get.back();
              // TODO: Implement pass functionality
            },
          ),
          
          // Super Like Button
          _buildActionButton(
            themeController,
            icon: Icons.star,
            color: Colors.blue,
            onTap: () {
              // TODO: Implement super like functionality
            },
          ),
          
          // Like Button
          _buildActionButton(
            themeController,
            icon: Icons.favorite,
            color: themeController.lightPinkColor,
            onTap: () {
              Get.back();
              // TODO: Implement like functionality
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    ThemeController themeController, {
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80.w,
        height: 80.w,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.9),
          shape: BoxShape.circle,
          border: Border.all(color: color, width: 3.w),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.6),
              blurRadius: 25,
              offset: Offset(0, 10),
            ),
            BoxShadow(
              color: themeController.blackColor.withValues(alpha: 0.8),
              blurRadius: 20,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: themeController.whiteColor,
          size: 36.sp,
        ),
      ),
    );
  }

  List<String> _getImages() {
    if (widget.profile.photos.isNotEmpty) return widget.profile.photos;
    return [widget.profile.imageUrl];
  }

  int _getImageCount() {
    return _getImages().length;
  }
}
