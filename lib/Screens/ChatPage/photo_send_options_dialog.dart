import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lovebug/Common/text_constant.dart';
import 'package:lovebug/Common/widget_constant.dart';
import 'package:lovebug/ThemeController/theme_controller.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class PhotoSendOptionsDialog extends StatelessWidget {
  final String imagePath;
  final VoidCallback onSendNormal;
  final VoidCallback onSendDisappearing;

  const PhotoSendOptionsDialog({
    super.key,
    required this.imagePath,
    required this.onSendNormal,
    required this.onSendDisappearing,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeController themeController = Get.find<ThemeController>();
    
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: Get.width * 0.9,
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
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: themeController.getAccentColor().withValues(alpha: 0.3),
            width: 1.w,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(20.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                children: [
                  Icon(
                    Icons.photo_camera,
                    color: themeController.getAccentColor(),
                    size: 24.sp,
                  ),
                  SizedBox(width: 12.w),
                  TextConstant(
                    title: 'Send Photo',
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: themeController.whiteColor,
                  ),
                ],
              ),
              heightBox(20.h.toInt()),
              
              // Photo Preview
              Container(
                height: 200.h,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: themeController.getAccentColor().withValues(alpha: 0.3),
                    width: 1.w,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12.r),
                  child: Image.network(
                    imagePath,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: themeController.greyColor.withValues(alpha: 0.3),
                        child: Icon(
                          Icons.image,
                          color: themeController.whiteColor.withValues(alpha: 0.5),
                          size: 50.sp,
                        ),
                      );
                    },
                  ),
                ),
              ),
              heightBox(20.h.toInt()),
              
              // Send Options
              TextConstant(
                title: 'How would you like to send this photo?',
                fontSize: 16,
                color: themeController.whiteColor.withValues(alpha: 0.8),
                textAlign: TextAlign.center,
              ),
              heightBox(20.h.toInt()),
              
              // Normal Photo Option
              _buildSendOption(
                themeController: themeController,
                icon: Icons.photo,
                title: 'Send as Regular Photo',
                subtitle: 'Photo will remain in chat',
                onTap: onSendNormal,
              ),
              heightBox(12.h.toInt()),
              
              // Disappearing Photo Option
              _buildSendOption(
                themeController: themeController,
                icon: Icons.visibility_off,
                title: 'Send as Disappearing Photo',
                subtitle: 'Photo will disappear after viewing',
                onTap: onSendDisappearing,
              ),
              heightBox(20.h.toInt()),
              
              // Cancel Button
              GestureDetector(
                onTap: () => Get.back(),
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                  decoration: BoxDecoration(
                    color: themeController.greyColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: themeController.greyColor.withValues(alpha: 0.3),
                      width: 1.w,
                    ),
                  ),
                  child: TextConstant(
                    title: 'Cancel',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: themeController.whiteColor,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSendOption({
    required ThemeController themeController,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              themeController.getAccentColor().withValues(alpha: 0.1),
              themeController.getSecondaryColor().withValues(alpha: 0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: themeController.getAccentColor().withValues(alpha: 0.3),
            width: 1.w,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: themeController.getAccentColor().withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Icon(
                icon,
                color: themeController.getAccentColor(),
                size: 24.sp,
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextConstant(
                    title: title,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: themeController.whiteColor,
                  ),
                  SizedBox(height: 4.h),
                  TextConstant(
                    title: subtitle,
                    fontSize: 14,
                    color: themeController.whiteColor.withValues(alpha: 0.7),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: themeController.whiteColor.withValues(alpha: 0.5),
              size: 16.sp,
            ),
          ],
        ),
      ),
    );
  }
}
