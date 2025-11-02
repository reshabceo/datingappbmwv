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
  final bool isSelected;
  final bool isSelectionMode;
  final bool isSelectable;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const EnhancedChatBubble({
    super.key,
    required this.message,
    required this.userName,
    this.isBffMatch = false,
    this.userImage,
    this.otherUserImage,
    this.isSelected = false,
    this.isSelectionMode = false,
    this.isSelectable = false,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeController themeController = Get.find<ThemeController>();
    final isMe = message.isUser;
    final bool isDeleted = message.isDeletedForEveryone;
    final Color accentColor = isBffMatch
        ? themeController.bffPrimaryColor
        : themeController.getAccentColor();

    final LinearGradient outgoingGradient = isDeleted
        ? LinearGradient(
            colors: [
              themeController.greyColor.withValues(alpha: 0.5),
              themeController.greyColor.withValues(alpha: 0.4),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : (isBffMatch
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
              ));

    final LinearGradient incomingGradient = isDeleted
        ? LinearGradient(
            colors: [
              themeController.greyColor.withValues(alpha: 0.4),
              themeController.greyColor.withValues(alpha: 0.3),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : LinearGradient(
            colors: [
              themeController.greyColor.withValues(alpha: 0.5),
              themeController.greyColor.withValues(alpha: 0.3),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );

    return GestureDetector(
      onTap: onTap,
      onLongPress: isSelectable ? onLongPress : null,
      behavior: HitTestBehavior.translucent,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 4.h, horizontal: 16.w),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Row(
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
                  child: () {
                    final bool showSelection = isSelectionMode && isSelected;
                    
                    final LinearGradient bubbleGradient = showSelection
                        ? LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              accentColor.withValues(alpha: isMe ? 0.82 : 0.6),
                              accentColor.withValues(alpha: isMe ? 0.65 : 0.48),
                            ],
                          )
                        : (isMe ? outgoingGradient : incomingGradient);

                    final Color borderColor = showSelection
                        ? accentColor
                        : themeController.whiteColor.withValues(alpha: 0.12);

                    final List<BoxShadow> bubbleshadow = [
                      BoxShadow(
                        color: showSelection
                            ? accentColor.withValues(alpha: 0.35)
                            : themeController.blackColor.withValues(alpha: 0.15),
                        blurRadius: showSelection ? 18 : 8,
                        offset: Offset(0, showSelection ? 6 : 3),
                      ),
                    ];
                    
                    return Container(
                      constraints: BoxConstraints(
                        maxWidth: Get.width * 0.75,
                        minWidth: 0,
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.06),
                        gradient: bubbleGradient,
                        borderRadius: BorderRadius.circular(20.r),
                        border: Border.all(
                          color: borderColor,
                          width: showSelection ? 2.w : 1.1,
                        ),
                        boxShadow: bubbleshadow,
                      ),
                      child: IntrinsicWidth(
                        child: _buildMessageContent(themeController, isMe),
                      ),
                    );
                  }(),
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
            SizedBox(height: 4.h),
            Padding(
              padding: EdgeInsets.only(
                left: isMe ? 0 : 8.w,
                right: isMe ? 8.w : 0,
              ),
              child: TextConstant(
                title: _formatTimestamp(message.timestamp),
                color: themeController.whiteColor.withValues(alpha: 0.6),
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
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
                cacheWidth: (32.w * 3).round(), // Force reload with cache busting
                cacheHeight: (32.h * 3).round(),
                headers: {'Cache-Control': 'no-cache'}, // Disable caching
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
    if (message.isDeletedForEveryone) {
      return _buildDeletedMessage(themeController);
    }
    
    // Check if it's a disappearing photo
    if (message.isDisappearingPhoto == true && message.disappearingPhotoId != null) {
      return _buildDisappearingPhotoContent(themeController, isMe);
    }
    
    // Check if it's a story reply
    if (message.isStoryReply == true) {
      return _buildStoryReplyContent(themeController, isMe);
    }
    
    // Check if it's a regular photo
    if (message.text.toString().startsWith('📸 Photo: ')) {
      return _buildRegularPhotoContent(themeController);
    }
    
    // Regular text message with timestamp
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        TextConstant(
          title: message.text ?? '',
          color: themeController.whiteColor,
          fontSize: 16,
          fontWeight: FontWeight.w400,
          maxLines: null,
          overflow: TextOverflow.visible,
          softWrap: true,
          textAlign: TextAlign.start,
        ),
      ],
    );
  }

  Widget _buildDeletedMessage(ThemeController themeController) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.block,
          color: themeController.whiteColor.withValues(alpha: 0.6),
          size: 14.sp,
        ),
        SizedBox(width: 8.w),
        TextConstant(
          title: 'This message was deleted',
          color: themeController.whiteColor.withValues(alpha: 0.7),
          fontSize: 14,
          fontWeight: FontWeight.w400,
          fontStyle: FontStyle.italic,
        ),
      ],
    );
  }

  Widget _buildDisappearingPhotoContent(ThemeController themeController, bool isMe) {
    final disappearingPhotoId = message.disappearingPhotoId.toString();
    
    // If it's the sender, show a placeholder message
    if (isMe) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
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
          ),
          SizedBox(height: 4.h),
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
        // Remove container constraints and decoration to show full image
        Stack(
          children: [
                // Show instant preview if available, otherwise network image
                if (photoBytes != null && isUploading)
                  Image.memory(
                    photoBytes,
                    fit: BoxFit.contain, // Show full image without cropping
                  )
                else if (photoUrl.isNotEmpty && photoUrl.startsWith('http'))
                  Image.network(
                    photoUrl,
                    fit: BoxFit.contain, // Show full image without cropping
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
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
      ],
    );
  }

  Widget _buildStoryReplyContent(ThemeController themeController, bool isMe) {
    // Debug logging for story reply data
    print('🔄 DEBUG: Story reply data - ImageUrl: ${message.storyImageUrl}, Content: ${message.storyContent}, Author: ${message.storyAuthorName}');
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Story reply header - Smaller
        Container(
          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 3.h),
          decoration: BoxDecoration(
            color: themeController.whiteColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6.r),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.reply,
                color: themeController.whiteColor.withValues(alpha: 0.8),
                size: 12.sp,
              ),
              SizedBox(width: 3.w),
              TextConstant(
                title: isMe ? "You replied to their story" : "Replied to your story",
                color: themeController.whiteColor.withValues(alpha: 0.8),
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ],
          ),
        ),
        SizedBox(height: 6.h),
        // Story preview - Show full image without constraints
        if (message.storyImageUrl != null && message.storyImageUrl!.isNotEmpty)
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6.r),
              border: Border.all(
                color: themeController.whiteColor.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6.r),
              child: Image.network(
                message.storyImageUrl!,
                fit: BoxFit.cover, // Use cover to fill naturally
                errorBuilder: (context, error, stackTrace) {
                  print('❌ DEBUG: Story image error: $error');
                  return Container(
                    height: 120.h,
                    color: themeController.greyColor.withValues(alpha: 0.3),
                    child: Icon(
                      Icons.image,
                      color: themeController.whiteColor.withValues(alpha: 0.7),
                      size: 20.sp,
                    ),
                  );
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) {
                    print('✅ DEBUG: Story image loaded successfully');
                    return child;
                  }
                  print('🔄 DEBUG: Loading story image...');
                  return Container(
                    height: 120.h,
                    color: themeController.greyColor.withValues(alpha: 0.3),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: themeController.whiteColor,
                        strokeWidth: 2.0,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        SizedBox(height: 6.h),
        // Story content preview - Smaller
        if (message.storyContent != null && message.storyContent!.isNotEmpty)
          Container(
            padding: EdgeInsets.all(6.w),
            decoration: BoxDecoration(
              color: themeController.whiteColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6.r),
            ),
            child: TextConstant(
              title: message.storyContent!,
              color: themeController.whiteColor.withValues(alpha: 0.8),
              fontSize: 10,
              fontWeight: FontWeight.w400,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        SizedBox(height: 6.h),
        // Reply message
        TextConstant(
          title: message.text ?? '',
          color: themeController.whiteColor,
          fontSize: 16,
          fontWeight: FontWeight.w400,
          maxLines: null,
          overflow: TextOverflow.visible,
          softWrap: true,
          textAlign: TextAlign.start,
        ),
        // Note: Timestamp moved outside the bubble in the main build method
      ],
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    // Always display in the user's local timezone
    final ts = timestamp.toLocal();
    // Format as absolute time with AM/PM: HH:MM AM/PM or DD/MM HH:MM AM/PM
    final now = DateTime.now();
    final isToday = ts.year == now.year && 
                   ts.month == now.month && 
                   ts.day == now.day;
    
    // Convert to 12-hour format with AM/PM
    final hour12 = ts.hour == 0 ? 12 : (ts.hour > 12 ? ts.hour - 12 : ts.hour);
    final amPm = ts.hour < 12 ? 'AM' : 'PM';
    final timeString = '${hour12.toString().padLeft(2, '0')}:${ts.minute.toString().padLeft(2, '0')} $amPm';
    
    if (isToday) {
      // Show time only for today: 2:30 PM
      return timeString;
    } else {
      // Show date and time for other days: 19/10 2:30 PM
      return '${ts.day.toString().padLeft(2, '0')}/${ts.month.toString().padLeft(2, '0')} $timeString';
    }
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
