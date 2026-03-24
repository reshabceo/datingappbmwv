import 'package:lovebug/Common/text_constant.dart';
import 'package:lovebug/Screens/DiscoverPage/controller_discover_screen.dart';
import 'package:lovebug/Screens/DiscoverPage/profile_detail_screen.dart';
import 'package:lovebug/Screens/DiscoverPage/Widget/image_gallery_widget.dart';
import 'package:lovebug/ThemeController/theme_controller.dart';
import 'package:lovebug/services/supabase_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'dart:ui';
import 'package:google_fonts/google_fonts.dart';

class ProfileCard extends StatefulWidget {
  final Profile profile;
  final ThemeController themeController;

  const ProfileCard({
    super.key,
    required this.profile,
    required this.themeController,
  });

  @override
  State<ProfileCard> createState() => _ProfileCardState();
}

class _ProfileCardState extends State<ProfileCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _glowAnim;
  bool _isCurrentUserPremium = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000), // Slower, more breathing-like
    );

    _glowAnim = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _startAnimationIfNeeded();
    _checkPremiumStatus();
  }

  Future<void> _checkPremiumStatus() async {
    try {
      final isPremium = await SupabaseService.isPremiumUser();
      if (mounted) {
        setState(() {
          _isCurrentUserPremium = isPremium;
        });
      }
    } catch (e) {
      print('Error checking premium status: $e');
    }
  }

  void _startAnimationIfNeeded() {
    if (widget.profile.isSuperLiked) {
      print('🌟 Starting super like animation for ${widget.profile.name}');
      _controller.repeat(reverse: true); // Continuous pulsating
    }
  }

  @override
  void didUpdateWidget(ProfileCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.profile.isSuperLiked != oldWidget.profile.isSuperLiked) {
      if (widget.profile.isSuperLiked) {
        print('🌟 Starting super like animation for ${widget.profile.name}');
        _controller.repeat(reverse: true); // Start pulsating
      } else {
        print('🌟 Stopping super like animation for ${widget.profile.name}');
        _controller.stop(); // Stop pulsating
        _controller.reset(); // Reset to initial state
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Only log once per profile to reduce noise
    if (widget.profile.photos.isNotEmpty) {
      print('🎴 ProfileCard building for: ${widget.profile.name} (ID: ${widget.profile.id})');
      print('🎴 Photos count: ${widget.profile.photos.length}');
    }
    
    return GestureDetector(
      onTap: () => Get.to(() => ProfileDetailScreen(profile: widget.profile)),
       child: AnimatedBuilder(
         animation: _glowAnim,
         builder: (context, child) {
           if (widget.profile.isSuperLiked) {
             print('🎬 Glow animation value: ${_glowAnim.value}');
           }
           return Container(
            height: Get.height - 320.h,
            width: double.infinity,
             decoration: BoxDecoration(
               borderRadius: BorderRadius.circular(20.r),
               border: widget.profile.isSuperLiked
                   ? Border.all(
                       color: Colors.blueAccent.withOpacity(0.8 + (0.2 * _glowAnim.value)),
                       width: 2.0 + (1.5 * _glowAnim.value),
                     )
                   : null,
               boxShadow: widget.profile.isSuperLiked
                   ? [
                       BoxShadow(
                         color: Colors.blueAccent
                             .withOpacity(0.4 + (0.4 * _glowAnim.value)),
                         blurRadius: 20 + (15 * _glowAnim.value),
                         spreadRadius: 2 + (3 * _glowAnim.value),
                       ),
                       BoxShadow(
                         color: Colors.cyan
                             .withOpacity(0.2 + (0.3 * _glowAnim.value)),
                         blurRadius: 30 + (20 * _glowAnim.value),
                         spreadRadius: 3 + (4 * _glowAnim.value),
                       ),
                     ]
                   : [],
             ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20.r),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.grey.shade800,
                      Colors.grey.shade900,
                    ],
                  ),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // 🔧 FIX: Ensure ImageGalleryWidget always has valid images
                    if (widget.profile.photos.isNotEmpty)
                      ImageGalleryWidget(
                        key: ValueKey('gallery_${widget.profile.id}'),
                        images: widget.profile.photos,
                        themeController: widget.themeController,
                      )
                    else
                      // 🔧 FIX: Show proper placeholder when no photos
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.grey.shade800,
                              Colors.grey.shade900,
                            ],
                          ),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.person,
                                color: Colors.white.withValues(alpha: 0.8),
                                size: 80.sp,
                              ),
                              SizedBox(height: 16.h),
                              Text(
                                'No Photos Available',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  if (widget.profile.isLocked)
                    _buildLockOverlay(),
                  
                  // Bottom section (info) always on top for visibility
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Spacer(),
                      _buildBottomSection(),
                    ],
                  ),
                ],
              ),
            ),
          ),
          );
        },
      ),
    );
  }

  Widget _buildLockOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.12), // Reduced opacity for clearer background
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12), // Increased blur for better visibility
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(20.w),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5),
                ),
                child: Icon(
                  Icons.lock_rounded,
                  color: Colors.white,
                  size: 40.sp,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                margin: EdgeInsets.only(top: 15.h),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                ),
                child: Text(
                  'Start chat to unlock',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuperLikeBadge() {
    return Positioned(
      top: 20.h,
      right: 20.w,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade600, Colors.cyan.shade400],
          ),
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.5),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.star, color: Colors.white, size: 16.sp),
            SizedBox(width: 4.w),
            Text(
              'SUPER LOVE',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomSection() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(16.w, 40.h, 16.w, 16.h), // Top padding for gradient transition
      decoration: BoxDecoration(
        // Smooth gradient for readability but keeping it minimalist
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(0.0),
            Colors.black.withOpacity(0.2),
            Colors.black.withOpacity(0.5),
            Colors.black.withOpacity(0.8),
          ],
          stops: const [0.0, 0.3, 0.6, 1.0],
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min, // Use minimum size to prevent taking up all space and overflowing
          children: [
            // Pink Name & Age at the top of bottom section
              Text(
                '${widget.profile.name}, ${widget.profile.age}',
                style: GoogleFonts.dancingScript(
                  fontSize: 32.sp,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFFC850C0), // Bold Pink
                  shadows: [
                    Shadow(color: Colors.black.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 1)),
                  ],
                ),
              ),
              SizedBox(height: 8.h),
              Row(
                children: [
                  Icon(Icons.location_on, color: Colors.white, size: 14.sp),
                  SizedBox(width: 4.w),
                  Text(
                    widget.profile.location,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    ' • ',
                    style: TextStyle(color: Colors.white70, fontSize: 13.sp),
                  ),
                  Text(
                    widget.profile.distance,
                    style: TextStyle(
                      color: widget.themeController.lightPinkColor,
                      fontSize: 13.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8.h),
              Row(
                children: [
                  if (widget.profile.isVerified)
                    _buildStatusBadge(
                      icon: Icons.check_circle_rounded,
                      text: 'Verified',
                      color: Colors.blue.shade300,
                      isSmall: true,
                    ),
                  if (widget.profile.isVerified) SizedBox(width: 8.w),
                  if (widget.profile.isActiveNow)
                    _buildStatusBadge(
                      icon: LucideIcons.flame,
                      text: 'Active Now',
                      color: Colors.orange.shade300,
                      isSmall: true,
                    ),
                  if (widget.profile.intent != null && widget.profile.intent!.isNotEmpty) ...[
                    SizedBox(width: 8.w),
                    _buildStatusBadge(
                      icon: LucideIcons.tag,
                      text: widget.profile.intent!,
                      color: const Color(0xFFC850C0).withOpacity(0.8),
                      isSmall: true,
                    ),
                  ],
                ],
              ),
              SizedBox(height: 12.h),
              if (widget.profile.description.isNotEmpty)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: Text(
                    widget.profile.description,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 12.sp,
                      height: 1.4,
                      fontWeight: FontWeight.w400,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            SizedBox(height: 12.h),

          ],
        ),
      ),
    );
  }


  Widget _buildStatusBadge({
    required IconData icon,
    required String text,
    required Color color,
    bool isSmall = false,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmall ? 8.w : 12.w,
        vertical: isSmall ? 4.h : 6.h,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(isSmall ? 15.r : 20.r),
        border: Border.all(color: color, width: isSmall ? 0.5.w : 1.w),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: isSmall ? 12.sp : 16.sp),
          SizedBox(width: isSmall ? 3.w : 4.w),
          TextConstant(
            title: text,
            fontSize: isSmall ? 9.sp : 11.sp,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ],
      ),
    );
  }
}
