import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:lovebug/Common/text_constant.dart';
import 'package:lovebug/Common/widget_constant.dart';
import 'package:lovebug/ThemeController/theme_controller.dart';
import 'package:lovebug/Screens/ChatPage/controller_message_screen.dart';
import 'package:lovebug/services/disappearing_photo_service.dart';

class PhotoPreviewScreen extends StatefulWidget {
  final File imageFile;
  final String matchId;
  
  const PhotoPreviewScreen({
    super.key, 
    required this.imageFile, 
    required this.matchId,
  });

  @override
  State<PhotoPreviewScreen> createState() => _PhotoPreviewScreenState();
}

class _PhotoPreviewScreenState extends State<PhotoPreviewScreen> {
  final ThemeController themeController = Get.find<ThemeController>();
  bool _isDisappearing = false;
  bool _isSending = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: themeController.blackColor,
      body: SafeArea(
        child: Stack(
          children: [
            // Full screen image
            Positioned.fill(
              child: Image.file(
                widget.imageFile,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: themeController.blackColor,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.broken_image,
                            size: 60.sp,
                            color: themeController.whiteColor.withValues(alpha: 0.3),
                          ),
                          heightBox(16),
                          TextConstant(
                            title: 'Failed to load image',
                            fontSize: 16,
                            color: themeController.whiteColor.withValues(alpha: 0.7),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            
            // Top bar with close button
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      themeController.blackColor.withValues(alpha: 0.7),
                      themeController.blackColor.withValues(alpha: 0.3),
                      Colors.transparent,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () => Get.back(),
                      child: Container(
                        padding: EdgeInsets.all(8.w),
                        decoration: BoxDecoration(
                          color: themeController.blackColor.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(20.r),
                        ),
                        child: Icon(
                          Icons.close,
                          color: themeController.whiteColor,
                          size: 20.sp,
                        ),
                      ),
                    ),
                    TextConstant(
                      title: 'Preview',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: themeController.whiteColor,
                    ),
                    SizedBox(width: 40.w), // Balance the close button
                  ],
                ),
              ),
            ),
            
            // Bottom controls
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.all(20.w),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      themeController.blackColor.withValues(alpha: 0.3),
                      themeController.blackColor.withValues(alpha: 0.8),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Disappearing toggle
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Disappearing toggle (left) - Simplified
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _isDisappearing = !_isDisappearing;
                            });
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                            decoration: BoxDecoration(
                              color: _isDisappearing 
                                  ? themeController.getAccentColor().withValues(alpha: 0.2)
                                  : themeController.whiteColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(25.r),
                              border: Border.all(
                                color: _isDisappearing 
                                    ? themeController.getAccentColor()
                                    : themeController.whiteColor.withValues(alpha: 0.3),
                                width: 1.w,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.visibility_off,
                                  color: _isDisappearing 
                                      ? themeController.getAccentColor()
                                      : themeController.whiteColor.withValues(alpha: 0.7),
                                  size: 18.sp,
                                ),
                                widthBox(8),
                                TextConstant(
                                  title: _isDisappearing ? 'Disappearing' : 'Normal',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: _isDisappearing 
                                      ? themeController.getAccentColor()
                                      : themeController.whiteColor.withValues(alpha: 0.7),
                                ),
                              ],
                            ),
                          ),
                        ),
                        
                        // Send button (right)
                        GestureDetector(
                          onTap: _isSending ? null : _sendPhoto,
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  themeController.getAccentColor(),
                                  themeController.getSecondaryColor(),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(25.r),
                              boxShadow: [
                                BoxShadow(
                                  color: themeController.getAccentColor().withValues(alpha: 0.3),
                                  blurRadius: 10,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: _isSending
                                ? SizedBox(
                                    width: 20.w,
                                    height: 20.w,
                                    child: CircularProgressIndicator(
                                      color: themeController.whiteColor,
                                      strokeWidth: 2.0,
                                    ),
                                  )
                                : Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.visibility_off,
                                        color: themeController.whiteColor,
                                        size: 18.sp,
                                      ),
                                      widthBox(8),
                                      TextConstant(
                                        title: 'Send',
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: themeController.whiteColor,
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ],
                    ),
                    
                    heightBox(16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendPhoto() async {
    if (_isSending) return;
    
    setState(() {
      _isSending = true;
    });

    try {
      String? photoUrl;
      
      if (_isDisappearing) {
        // Send as disappearing photo
        final bytes = await widget.imageFile.readAsBytes();
        photoUrl = await EnhancedDisappearingPhotoService.sendDisappearingPhoto(
          matchId: widget.matchId,
          photoBytes: bytes,
          fileName: widget.imageFile.path.split('/').last,
        );
      } else {
        // Send as regular photo
        final bytes = await widget.imageFile.readAsBytes();
        photoUrl = await EnhancedDisappearingPhotoService.sendRegularPhoto(
          matchId: widget.matchId,
          photoBytes: bytes,
          fileName: widget.imageFile.path.split('/').last,
        );
      }
      
      if (photoUrl != null) {
        Get.back(); // Close preview
        Get.back(); // Close camera/gallery
        Get.snackbar('Success', 'Photo sent successfully');
      } else {
        Get.snackbar('Error', 'Failed to send photo');
      }
    } catch (e) {
      print('Error sending photo: $e');
      Get.snackbar('Error', 'Failed to send photo');
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }
}
