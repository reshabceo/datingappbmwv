import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:lovebug/ThemeController/theme_controller.dart';
import 'package:lovebug/Screens/DiscoverPage/controller_discover_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';

/// Mode Switcher Banner - Prominently displays and allows switching between Dating and BFF modes
/// This is a key differentiator that sets LoveBug apart from other dating apps
class ModeSwitcherBanner extends StatelessWidget {
  const ModeSwitcherBanner({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ThemeController themeController = Get.find<ThemeController>();
    final DiscoverController discoverController = Get.find<DiscoverController>();

    return Obx(() {
      final currentMode = discoverController.currentMode.value;
      final isDating = currentMode == 'dating';

      return Container(
        margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20.r),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDating
                      ? [
                          themeController.lightPinkColor.withValues(alpha: 0.15),
                          themeController.purpleColor.withValues(alpha: 0.15),
                        ]
                      : [
                          themeController.bffPrimaryColor.withValues(alpha: 0.15),
                          themeController.bffSecondaryColor.withValues(alpha: 0.15),
                        ],
                ),
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(
                  color: isDating
                      ? themeController.lightPinkColor.withValues(alpha: 0.4)
                      : themeController.bffPrimaryColor.withValues(alpha: 0.4),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isDating
                        ? themeController.lightPinkColor.withValues(alpha: 0.2)
                        : themeController.bffPrimaryColor.withValues(alpha: 0.2),
                    blurRadius: 20,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.all(4.w),
                child: Row(
                  children: [
                    // Dating Mode Button
                    Expanded(
                      child: _ModeButton(
                        icon: Icons.favorite,
                        label: 'Dating',
                        emoji: '💖',
                        isActive: isDating,
                        gradient: [themeController.lightPinkColor, themeController.purpleColor],
                        onTap: () => discoverController.setMode('dating'),
                      ),
                    ),
                    SizedBox(width: 4.w),
                    // BFF Mode Button
                    Expanded(
                      child: _ModeButton(
                        icon: Icons.people,
                        label: 'BFF Mode',
                        emoji: '👯',
                        isActive: !isDating,
                        gradient: [themeController.bffPrimaryColor, themeController.bffSecondaryColor],
                        onTap: () => discoverController.setMode('bff'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    });
  }
}

class _ModeButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String emoji;
  final bool isActive;
  final List<Color> gradient;
  final VoidCallback onTap;

  const _ModeButton({
    required this.icon,
    required this.label,
    required this.emoji,
    required this.isActive,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeController themeController = Get.find<ThemeController>();

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 12.w),
        decoration: BoxDecoration(
          gradient: isActive
              ? LinearGradient(
                  colors: gradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isActive ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: gradient[0].withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon
            Icon(
              icon,
              color: isActive
                  ? Colors.white
                  : themeController.whiteColor.withValues(alpha: 0.6),
              size: 20.sp,
            ),
            SizedBox(width: 6.w),
            // Emoji
            Text(
              emoji,
              style: TextStyle(fontSize: 18.sp),
            ),
            SizedBox(width: 6.w),
            // Label
            Flexible(
              child: Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 14.sp,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  color: isActive
                      ? Colors.white
                      : themeController.whiteColor.withValues(alpha: 0.6),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
