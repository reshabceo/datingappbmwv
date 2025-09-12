import 'package:boliler_plate/Common/text_constant.dart';
import 'package:boliler_plate/Common/widget_constant.dart';
import 'package:boliler_plate/Screens/DiscoverPage/controller_discover_screen.dart';
import 'package:boliler_plate/Screens/DiscoverPage/profile_detail_screen.dart';
import 'package:boliler_plate/ThemeController/theme_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:gradient_borders/gradient_borders.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class ProfileCard extends StatelessWidget {
  final Profile profile;
  final ThemeController themeController;

  const ProfileCard({
    super.key,
    required this.profile,
    required this.themeController,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Get.to(() => ProfileDetailScreen(profile: profile));
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20.r),
        child: AspectRatio(
          aspectRatio: 3 / 4,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                profile.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stack) {
                  return Container(
                    color: themeController.blackColor,
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.image_not_supported_outlined,
                      color: themeController.whiteColor.withValues(alpha: 0.6),
                      size: 36.sp,
                    ),
                  );
                },
              ),
              // Foreground content
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTopSection(),
                  Spacer(),
                  _buildBottomSection(),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopSection() {
    return Padding(
      padding: EdgeInsets.all(15.w),
      child: Row(
        children: [
          ProfileAvatar(
            size: 50,
            imageUrl: profile.imageUrl,
            borderWidth: 2,
          ),
          Spacer(),
          _buildPhotoCountIndicator(),
        ],
      ),
    );
  }

  Widget _buildPhotoCountIndicator() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: themeController.blackColor.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: themeController.lightPinkColor.withValues(alpha: 0.5),
          width: 1.w,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.photo_library,
            color: themeController.whiteColor,
            size: 16.sp,
          ),
          SizedBox(width: 4.w),
          TextConstant(
            title: profile.photos.length.toString(),
            fontSize: 12.sp,
            color: themeController.whiteColor,
            fontWeight: FontWeight.bold,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSection() {
    return Container(
      height: Get.height * 0.25, // Exactly 1/4 of screen height
      decoration: BoxDecoration(
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20.r),
          bottomRight: Radius.circular(20.r),
        ),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: [0.0, 0.3, 0.7, 1.0], // White blur gradient
          colors: [
            Colors.transparent,
            Colors.white.withValues(alpha: 0.5), // Strong white blur
            Colors.white.withValues(alpha: 0.8), // Stronger white blur
            Colors.white.withValues(alpha: 0.95), // Very strong white blur
          ],
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            // Location and Distance - Smaller text
            Row(
              children: [
                Icon(
                  Icons.location_on,
                  color: themeController.blackColor,
                  size: 14.sp,
                ),
                SizedBox(width: 4.w),
                TextConstant(
                  title: profile.location,
                  fontSize: 13.sp,
                  color: themeController.blackColor,
                ),
                TextConstant(
                  title: ' • ',
                  fontSize: 13.sp,
                  color: themeController.blackColor,
                ),
                TextConstant(
                  title: profile.distance,
                  fontSize: 13.sp,
                  color: themeController.lightPinkColor,
                ),
              ],
            ),
            
            SizedBox(height: 8.h),
            
            // Status Badges - Smaller badges
            Row(
              children: [
                if (profile.isVerified)
                  _buildStatusBadge(
                    icon: Icons.check_circle_rounded,
                    text: 'Verified',
                    color: themeController.lightPinkColor,
                    isSmall: true,
                  ),
                if (profile.isVerified) SizedBox(width: 8.w),
                if (profile.isActiveNow)
                  _buildStatusBadge(
                    icon: LucideIcons.flame,
                    text: 'Active Now',
                    color: themeController.lightPinkColor,
                    isSmall: true,
                  ),
              ],
            ),
            
            SizedBox(height: 10.h),
            
            // Bio Section - Compact design with proper overflow handling
            Flexible(
              child: Container(
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  color: themeController.lightPinkColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(
                    color: themeController.lightPinkColor.withValues(alpha: 0.2),
                    width: 0.5.w,
                  ),
                ),
                child: TextConstant(
                  title: profile.description,
                  fontSize: 12.sp,
                  height: 1.3,
                  fontWeight: FontWeight.w400,
                  softWrap: true,
                  color: themeController.blackColor,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            
            SizedBox(height: 10.h),
            
            // Interests - Smaller tags
            Wrap(
              spacing: 6.w,
              runSpacing: 6.h,
              children: profile.hobbies.take(3).map((hobby) {
                return Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        themeController.lightPinkColor.withValues(alpha: 0.4),
                        themeController.lightPinkColor.withValues(alpha: 0.2),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(15.r),
                    border: Border.all(
                      color: themeController.lightPinkColor.withValues(alpha: 0.5),
                      width: 0.5.w,
                    ),
                  ),
                  child: TextConstant(
                    title: hobby,
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w600,
                    color: themeController.blackColor,
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