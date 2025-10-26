import 'package:lovebug/Common/text_constant.dart';
import 'package:lovebug/Screens/DiscoverPage/controller_discover_screen.dart';
import 'package:lovebug/Screens/DiscoverPage/profile_detail_screen.dart';
import 'package:lovebug/Screens/DiscoverPage/Widget/image_gallery_widget.dart';
import 'package:lovebug/ThemeController/theme_controller.dart';
import 'package:lovebug/widgets/premium_message_button.dart';
import 'package:lovebug/widgets/premium_indicator.dart';
import 'package:lovebug/services/supabase_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Spacer(),
                      _buildBottomSection(),
                    ],
                  ),
                  if (widget.profile.isSuperLiked)
                    Positioned(
                      top: 20.h,
                      right: 20.w,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 12.w, vertical: 6.h),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.blue.shade600,
                              Colors.cyan.shade400
                            ],
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
                            Icon(Icons.star,
                                color: Colors.white, size: 16.sp),
                            SizedBox(width: 4.w),
                            Text(
                              'SUPER LIKE',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  
                  // Premium message button
                  ProfilePremiumMessageButton(
                    recipientId: widget.profile.id,
                    recipientName: widget.profile.name,
                    recipientPhoto: widget.profile.photos.isNotEmpty 
                        ? widget.profile.photos.first 
                        : '',
                  ),
                  
                  // Premium indicator for premium users
                  if (widget.profile.isPremium ?? false)
                    Positioned(
                      top: 20.h,
                      left: 20.w,
                      child: PremiumBadge(
                        size: 10.sp,
                        showText: true,
                      ),
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

  Widget _buildBottomSection() {
    return Container(
      height: Get.height * 0.25,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20.r),
          bottomRight: Radius.circular(20.r),
        ),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: const [0.0, 0.3, 0.7, 1.0],
          colors: [
            Colors.transparent,
            Colors.white.withValues(alpha: 0.5),
            Colors.white.withValues(alpha: 0.8),
            Colors.white.withValues(alpha: 0.95),
          ],
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Row(
              children: [
                Icon(Icons.location_on,
                    color: widget.themeController.blackColor, size: 14.sp),
                SizedBox(width: 4.w),
                TextConstant(
                  title: widget.profile.location,
                  fontSize: 13.sp,
                  color: widget.themeController.blackColor,
                ),
                TextConstant(
                  title: ' • ',
                  fontSize: 13.sp,
                  color: widget.themeController.blackColor,
                ),
                TextConstant(
                  title: widget.profile.distance,
                  fontSize: 13.sp,
                  color: widget.themeController.lightPinkColor,
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
                    color: widget.themeController.lightPinkColor,
                    isSmall: true,
                  ),
                if (widget.profile.isVerified) SizedBox(width: 8.w),
                if (widget.profile.isActiveNow)
                  _buildStatusBadge(
                    icon: LucideIcons.flame,
                    text: 'Active Now',
                    color: widget.themeController.lightPinkColor,
                    isSmall: true,
                  ),
              ],
            ),
            SizedBox(height: 10.h),
            Flexible(
              child: Container(
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  color: widget.themeController.lightPinkColor
                      .withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(
                    color: widget.themeController.lightPinkColor
                        .withValues(alpha: 0.2),
                    width: 0.5.w,
                  ),
                ),
                child: TextConstant(
                  title: widget.profile.description,
                  fontSize: 12.sp,
                  height: 1.3,
                  fontWeight: FontWeight.w400,
                  softWrap: true,
                  color: widget.themeController.blackColor,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            SizedBox(height: 10.h),
            Wrap(
              spacing: 6.w,
              runSpacing: 6.h,
              children: widget.profile.hobbies.take(3).map((hobby) {
                return Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        widget.themeController.lightPinkColor
                            .withValues(alpha: 0.4),
                        widget.themeController.lightPinkColor
                            .withValues(alpha: 0.2),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(15.r),
                    border: Border.all(
                      color: widget.themeController.lightPinkColor
                          .withValues(alpha: 0.5),
                      width: 0.5.w,
                    ),
                  ),
                  child: TextConstant(
                    title: hobby,
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w600,
                    color: widget.themeController.blackColor,
                  ),
                );
              }).toList(),
            ),
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
