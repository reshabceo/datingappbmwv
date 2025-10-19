import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lovebug/services/supabase_service.dart';
import 'package:lovebug/services/disappearing_photo_service.dart';
import 'package:lovebug/Screens/ChatPage/disappearing_photo_screen.dart';
import 'package:lovebug/Common/text_constant.dart';
import 'package:lovebug/Common/widget_constant.dart';
import 'package:lovebug/ThemeController/theme_controller.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class EnhancedChatBubble extends StatelessWidget {
  final dynamic message;
  final String userName;
  final bool isBffMatch;
  final String? userImage;
  final String? otherUserImage;

  const EnhancedChatBubble({
    super.key,
    required this.message,
    required this.userName,
    this.isBffMatch = false,
    this.userImage,
    this.otherUserImage,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeController themeController = Get.find<ThemeController>();
    final isMe = message.isUser;
    
    return Container(
      margin: EdgeInsets.symmetric(vertical: 4.h, horizontal: 16.w),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMe) ...[
            _buildProfilePicture(
              imageUrl: otherUserImage,
              isBffMatch: isBffMatch,
              themeController: themeController,
            ),
            SizedBox(width: 8.w),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: Get.width * 0.75, // Limit max width to 75% of screen
                minWidth: 0, // Allow shrinking
              ),
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.1), // Add subtle background
                gradient: isMe 
                    ? (isBffMatch 
                        ? LinearGradient(
                            colors: [
                              themeController.bffPrimaryColor.withValues(alpha: 0.7),
                              themeController.bffSecondaryColor.withValues(alpha: 0.5),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : LinearGradient(
                            colors: [
                              themeController.getAccentColor().withValues(alpha: 0.7),
                              themeController.getSecondaryColor().withValues(alpha: 0.5),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ))
                    : LinearGradient(
                        colors: [
                          themeController.greyColor.withValues(alpha: 0.5),
                          themeController.greyColor.withValues(alpha: 0.3),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
              child: IntrinsicWidth(
                child: _buildMessageContent(themeController, isMe),
              ),
            ),
          ),
          if (isMe) ...[
            SizedBox(width: 8.w),
            _buildProfilePicture(
              imageUrl: userImage,
              isBffMatch: isBffMatch,
              themeController: themeController,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProfilePicture({
    required String? imageUrl,
    required bool isBffMatch,
    required ThemeController themeController,
  }) {
    print('🔄 DEBUG: Building profile picture with imageUrl: $imageUrl');
    print('🔄 DEBUG: isBffMatch: $isBffMatch');
    return CircleAvatar(
      radius: 16.r,
      backgroundColor: isBffMatch ? themeController.bffPrimaryColor : themeController.lightPinkColor,
      child: imageUrl != null && imageUrl.isNotEmpty && imageUrl.startsWith('http')
          ? ClipOval(
              child: Image.network(
                imageUrl,
                width: 32.w,
                height: 32.h,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  print('❌ DEBUG: Error loading profile image: $error');
                  return Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 16.sp,
                  );
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) {
                    print('✅ DEBUG: Profile image loaded successfully');
                    return child;
                  }
                  print('🔄 DEBUG: Loading profile image...');
                  return Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 16.sp,
                  );
                },
              ),
            )
          : Icon(
              Icons.person,
              color: Colors.white,
              size: 16.sp,
            ),
    );
  }

  Widget _buildMessageContent(ThemeController themeController, bool isMe) {
    // Check if it's a disappearing photo
    if (message.isDisappearingPhoto == true && message.disappearingPhotoId != null) {
      return _buildDisappearingPhotoContent(themeController, isMe);
    }
    
    // Check if it's a regular photo
    if (message.text.toString().startsWith('📸 Photo: ')) {
      return _buildRegularPhotoContent(themeController);
    }
    
    // Regular text message
    return Container(
      width: double.infinity,
      child: TextConstant(
        title: message.text ?? '',
        color: themeController.whiteColor,
        fontSize: 16,
        fontWeight: FontWeight.w400,
        maxLines: null,
        overflow: TextOverflow.visible,
        softWrap: true,
        textAlign: TextAlign.start,
      ),
    );
  }

  Widget _buildDisappearingPhotoContent(ThemeController themeController, bool isMe) {
    final disappearingPhotoId = message.disappearingPhotoId.toString();
    
    // If it's the sender, show a placeholder message
    if (isMe) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.visibility_off,
            color: themeController.whiteColor.withValues(alpha: 0.7),
            size: 16.sp,
          ),
          SizedBox(width: 8.w),
          TextConstant(
            title: 'Disappearing photo sent',
            color: themeController.whiteColor.withValues(alpha: 0.7),
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
        ],
      );
    }
    
    // If it's the receiver, show the disappearing photo option
    return GestureDetector(
      onTap: () => _viewDisappearingPhoto(disappearingPhotoId),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: themeController.purpleColor.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: themeController.purpleColor.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.visibility_off,
              color: themeController.purpleColor,
              size: 20.sp,
            ),
            SizedBox(width: 8.w),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                TextConstant(
                  title: 'Disappearing Photo',
                  color: themeController.whiteColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                TextConstant(
                  title: 'Tap to view',
                  color: themeController.whiteColor.withValues(alpha: 0.7),
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRegularPhotoContent(ThemeController themeController) {
    // Get photo URL from either the message.photoUrl property or extract from text
    final photoUrl = message.photoUrl ?? 
        (message.text.toString().startsWith('📸 Photo: ') 
            ? message.text.toString().substring(10) 
            : message.text.toString());
    final isUploading = message.isUploading ?? false;
    final photoBytes = message.photoBytes;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        TextConstant(
          title: '📸 Photo',
          color: themeController.whiteColor.withValues(alpha: 0.9),
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        SizedBox(height: 8.h),
        Container(
          constraints: BoxConstraints(
            maxWidth: 200.w,
            maxHeight: 200.h,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(
              color: isBffMatch ? themeController.bffPrimaryColor : themeController.getAccentColor().withValues(alpha: 0.3),
              width: 1.w,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8.r),
            child: Stack(
              children: [
                // Show instant preview if available, otherwise network image
                if (photoBytes != null && isUploading)
                  Image.memory(
                    photoBytes,
                    fit: BoxFit.cover,
                    width: 200.w,
                    height: 200.h,
                  )
                else if (photoUrl.isNotEmpty && photoUrl.startsWith('http'))
                  Image.network(
                    photoUrl,
                    fit: BoxFit.cover,
                    width: 200.w,
                    height: 200.h,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        width: 200.w,
                        height: 200.h,
                        color: themeController.greyColor.withValues(alpha: 0.3),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: isBffMatch ? themeController.bffPrimaryColor : themeController.getAccentColor(),
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 200.w,
                        height: 200.h,
                        color: themeController.greyColor.withValues(alpha: 0.3),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: themeController.whiteColor.withValues(alpha: 0.7),
                              size: 24.sp,
                            ),
                            SizedBox(height: 4.h),
                            TextConstant(
                              title: 'Failed to load',
                              color: themeController.whiteColor.withValues(alpha: 0.7),
                              fontSize: 12,
                            ),
                          ],
                        ),
                      );
                    },
                  )
                else
                  Container(
                    width: 200.w,
                    height: 200.h,
                    color: themeController.greyColor.withValues(alpha: 0.3),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.image,
                          color: themeController.whiteColor.withValues(alpha: 0.7),
                          size: 24.sp,
                        ),
                        SizedBox(height: 4.h),
                        TextConstant(
                          title: 'Photo',
                          color: themeController.whiteColor.withValues(alpha: 0.7),
                          fontSize: 12,
                        ),
                      ],
                    ),
                  ),
                // Show loading overlay if uploading
                if (isUploading)
                  Container(
                    width: 200.w,
                    height: 200.h,
                    color: Colors.black.withValues(alpha: 0.3),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.0,
                          ),
                          SizedBox(height: 8.h),
                          TextConstant(
                            title: 'Uploading...',
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _viewDisappearingPhoto(String photoId) async {
    try {
      print('🔄 DEBUG: Viewing disappearing photo: $photoId');
      
      // Get the disappearing photo details
      final photoData = await EnhancedDisappearingPhotoService.getDisappearingPhoto(photoId);
      
      if (photoData == null) {
        Get.snackbar('Error', 'Photo not found or expired');
        return;
      }

      print('✅ DEBUG: Photo data: $photoData');
      
      // Check if photo is expired
      final expiresAt = DateTime.parse(photoData['expires_at']);
      if (DateTime.now().isAfter(expiresAt)) {
        Get.snackbar('Error', 'Photo has expired');
        return;
      }

      // Check if already viewed by current user
      final currentUserId = SupabaseService.currentUser?.id;
      if (photoData['viewed_by'] != null && photoData['viewed_by'] == currentUserId) {
        Get.snackbar('Error', 'You have already viewed this photo');
        return;
      }

      // Mark as viewed in database BEFORE opening
      await EnhancedDisappearingPhotoService.markPhotoAsViewed(photoId);

      // Navigate to disappearing photo viewer
      Get.to(() => DisappearingPhotoScreen(
        photoUrl: photoData['photo_url'],
        senderName: userName,
        sentAt: DateTime.parse(photoData['created_at']),
        viewDuration: photoData['view_duration'],
      ));
      
    } catch (e) {
      print('❌ DEBUG: Error viewing disappearing photo: $e');
      Get.snackbar('Error', 'Failed to load photo: $e');
    }
  }
}
