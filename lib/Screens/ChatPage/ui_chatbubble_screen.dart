import 'package:lovebug/Common/text_constant.dart';
import 'package:lovebug/Common/widget_constant.dart';
import 'package:lovebug/Screens/ChatPage/controller_message_screen.dart';
import 'package:lovebug/Screens/DiscoverPage/profile_detail_screen.dart';
import 'package:lovebug/Screens/DiscoverPage/controller_discover_screen.dart';
import 'package:lovebug/Screens/ChatPage/disappearing_photo_screen.dart';
import 'package:lovebug/services/disappearing_photo_service.dart';
import 'package:lovebug/ThemeController/theme_controller.dart';
import 'package:lovebug/services/supabase_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class ChatBubble extends StatelessWidget {
  final Message message;
  final String userImage;
  final String userName;
  final String? matchId;

  ChatBubble({super.key, required this.message, required this.userImage, required this.userName, this.matchId});

  final ThemeController themeController = Get.find<ThemeController>();

  Profile _mapToProfile(Map<String, dynamic> profileData) {
    final photos = <String>[];
    if (profileData['photos'] != null) {
      photos.addAll(List<String>.from(profileData['photos']));
    }
    if (profileData['image_urls'] != null) {
      photos.addAll(List<String>.from(profileData['image_urls']));
    }
    
    final hobbies = <String>[];
    if (profileData['hobbies'] != null) {
      hobbies.addAll(List<String>.from(profileData['hobbies']));
    }
    if (profileData['interests'] != null) {
      hobbies.addAll(List<String>.from(profileData['interests']));
    }

    return Profile(
      id: profileData['id']?.toString() ?? '',
      name: profileData['name']?.toString() ?? 'User',
      age: (profileData['age'] ?? 25) as int,
      imageUrl: photos.isNotEmpty ? photos.first : '',
      photos: photos,
      location: profileData['location']?.toString() ?? 'Unknown',
      distance: profileData['distance']?.toString() ?? 'Unknown distance',
      description: profileData['description']?.toString() ?? 
                  profileData['bio']?.toString() ?? 
                  'No description available',
      hobbies: hobbies,
      isVerified: (profileData['is_verified'] ?? false) as bool,
      isActiveNow: (profileData['is_active'] ?? false) as bool,
    );
  }

  Future<void> _viewProfile() async {
    if (matchId == null) return;
    
    try {
      // Get the match details to find the other user's ID
      final match = await SupabaseService.getMatchById(matchId!);
      if (match != null) {
        final currentUserId = SupabaseService.currentUser?.id;
        final userId1 = match['user_id_1']?.toString();
        final userId2 = match['user_id_2']?.toString();
        
        // Find the other user's ID (not the current user)
        String? otherUserId;
        if (userId1 == currentUserId) {
          otherUserId = userId2;
        } else if (userId2 == currentUserId) {
          otherUserId = userId1;
        }
        
        if (otherUserId != null) {
          // Get the other user's profile
          final profileData = await SupabaseService.getProfile(otherUserId);
          if (profileData != null) {
            // Convert Map to Profile object
            final profile = _mapToProfile(profileData);
            // Navigate to profile detail screen (this is a matched profile)
            Get.to(() => ProfileDetailScreen(profile: profile, isMatched: true));
          } else {
            Get.snackbar('Error', 'Profile not found');
          }
        } else {
          Get.snackbar('Error', 'Could not find user profile');
        }
      } else {
        Get.snackbar('Error', 'Match not found');
      }
    } catch (e) {
      print('Error viewing profile: $e');
      Get.snackbar('Error', 'Failed to load profile');
    }
  }

  Future<void> _viewDisappearingPhoto() async {
    if (message.disappearingPhotoId == null) {
      Get.snackbar('Error', 'Disappearing photo ID not found');
      return;
    }

    try {
      print('🔄 DEBUG: Viewing disappearing photo: ${message.disappearingPhotoId}');
      
      // Get the disappearing photo details
      final photoData = await DisappearingPhotoService.getDisappearingPhoto(message.disappearingPhotoId!);
      
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
      await DisappearingPhotoService.markPhotoAsViewed(message.disappearingPhotoId!);

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

  Widget _buildMessageContent() {
    // Check if it's a photo message
    if (message.text.startsWith('📸 Photo: ')) {
      final photoUrl = message.text.substring(10); // Remove "📸 Photo: " prefix
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                color: themeController.lightPinkColor.withValues(alpha: 0.3),
                width: 1.w,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(7.r),
              child: Image.network(
                photoUrl,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    height: 100.h,
                    child: Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                            : null,
                        color: themeController.lightPinkColor,
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 100.h,
                    color: themeController.lightPinkColor.withValues(alpha: 0.2),
                    child: Icon(
                      LucideIcons.image,
                      color: themeController.lightPinkColor,
                      size: 30,
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      );
    }
    
    // Check if it's a disappearing photo
    if (message.isDisappearingPhoto) {
      return GestureDetector(
        onTap: () => _viewDisappearingPhoto(),
        onLongPress: () => _viewDisappearingPhoto(), // Tap and hold also works
        child: Container(
          padding: EdgeInsets.all(8.w),
          decoration: BoxDecoration(
            border: Border.all(
              color: themeController.purpleColor.withValues(alpha: 0.5),
              width: 1.w,
            ),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                LucideIcons.eyeOff,
                color: themeController.purpleColor,
                size: 16,
              ),
              SizedBox(width: 8.w),
              TextConstant(
                title: '📸 Disappearing Photo',
                color: themeController.whiteColor.withValues(alpha: 0.9),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              SizedBox(width: 4.w),
              Icon(
                LucideIcons.play,
                color: themeController.purpleColor,
                size: 12,
              ),
            ],
          ),
        ),
      );
    }
    
    // Regular text message
    return TextConstant(
      title: message.text,
      color: themeController.whiteColor.withValues(alpha: 0.9),
      softWrap: true, 
      fontSize: 14, 
      height: 1.3,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h, horizontal: 4.w),
      child: Column(
        crossAxisAlignment: message.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // Story Reply Header with Full Content (like reference image)
          if (message.isUser && message.isStoryReply) ...[
            Container(
              margin: EdgeInsets.only(bottom: 12.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Story Reply Header
                  TextConstant(
                    title: "You replied to ${message.storyUserName ?? 'their'} story",
                    fontSize: 12,
                    color: themeController.whiteColor.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w500,
                  ),
                  SizedBox(height: 8.h),
                  // Story Image Preview (below the text, same ratio as story cards but smaller)
                  if (message.storyImageUrl != null) ...[
                    Container(
                      width: Get.width * 0.4, // Smaller than story cards but same ratio
                      height: (Get.width * 0.4) * 1.5, // Same aspect ratio as story cards
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                          color: themeController.lightPinkColor.withValues(alpha: 0.5),
                          width: 2.w,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10.r),
                        child: Image.network(
                          message.storyImageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: themeController.lightPinkColor.withValues(alpha: 0.2),
                              child: Icon(
                                LucideIcons.image,
                                color: themeController.lightPinkColor,
                                size: 30,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    SizedBox(height: 8.h),
                  ],
                  // Story Content Display
                  if (message.storyContent != null && message.storyContent!.isNotEmpty) ...[
                    Container(
                      width: Get.width * 0.85,
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        color: themeController.blackColor.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                          color: themeController.lightPinkColor.withValues(alpha: 0.2),
                          width: 1.w,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Story Author Info
                          if (message.storyAuthorName != null) ...[
                            Row(
                              children: [
                                TextConstant(
                                  title: message.storyAuthorName!,
                                  fontSize: 12,
                                  color: themeController.lightPinkColor,
                                  fontWeight: FontWeight.w600,
                                ),
                                if (message.storyCreatedAt != null) ...[
                                  SizedBox(width: 8.w),
                                  TextConstant(
                                    title: _formatStoryTime(message.storyCreatedAt!),
                                    fontSize: 10,
                                    color: themeController.whiteColor.withValues(alpha: 0.5),
                                  ),
                                ],
                              ],
                            ),
                            SizedBox(height: 6.h),
                          ],
                          // Story Content
                          TextConstant(
                            title: message.storyContent!,
                            fontSize: 13,
                            color: themeController.whiteColor.withValues(alpha: 0.9),
                            height: 1.4,
                            softWrap: true,
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
          if (!message.isUser) ...[
            // Other user's message - LEFT SIDE (dynamic width, no name, timestamp below)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile picture
                GestureDetector(
                  onTap: _viewProfile,
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      ProfileAvatar(
                        imageUrl: userImage, 
                        size: 32, 
                        borderWidth: 2.w,
                      ),
                      Container(
                        height: 10.h,
                        width: 10.h,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: themeController.lightPinkColor,
                          border: Border.all(
                            color: themeController.whiteColor,
                            width: 1.5.w,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 8.w),
                // Message bubble (dynamic width)
                Flexible(
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: Get.width * 0.75, // Max width but can be smaller
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          themeController.lightPinkColor.withValues(alpha: 0.15),
                          themeController.purpleColor.withValues(alpha: 0.1),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      border: Border.all(
                        color: themeController.lightPinkColor.withValues(alpha: 0.3),
                        width: 1.w,
                      ),
                      borderRadius: BorderRadius.circular(18.r),
                      boxShadow: [
                        BoxShadow(
                          color: themeController.lightPinkColor.withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: _buildMessageContent(),
                  ),
                ),
              ],
            ),
            // Timestamp below (left aligned)
            Padding(
              padding: EdgeInsets.only(left: 40.w, top: 4.h),
              child: TextConstant(
                title: formatTime(message.timestamp),
                fontSize: 11,
                color: themeController.whiteColor.withValues(alpha: 0.5),
                fontWeight: FontWeight.w400,
              ),
            ),
          ] else ...[
            // My message - RIGHT SIDE (dynamic width, timestamp below)
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Message bubble (dynamic width)
                Flexible(
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: Get.width * 0.75, // Max width but can be smaller
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          themeController.lightPinkColor.withValues(alpha: 0.15),
                          themeController.purpleColor.withValues(alpha: 0.1),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      border: Border.all(
                        color: themeController.lightPinkColor.withValues(alpha: 0.3),
                        width: 1.w,
                      ),
                      borderRadius: BorderRadius.circular(18.r),
                      boxShadow: [
                        BoxShadow(
                          color: themeController.lightPinkColor.withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: _buildMessageContent(),
                  ),
                ),
              ],
            ),
            // Timestamp below (right aligned)
            Padding(
              padding: EdgeInsets.only(right: 0.w, top: 4.h),
              child: Align(
                alignment: Alignment.centerRight,
                child: TextConstant(
                  title: formatTime(message.timestamp),
                  fontSize: 11,
                  color: themeController.whiteColor.withValues(alpha: 0.5),
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String formatTime(DateTime dateTime) {
    // Convert to local timezone
    final localTime = dateTime.toLocal();
    String period = localTime.hour >= 12 ? 'PM' : 'AM';
    int hour = localTime.hour > 12 ? localTime.hour - 12 : localTime.hour;
    if (hour == 0) hour = 12;
    final minute = localTime.minute.toString().padLeft(2, '0');
    
    // Debug logging for disappearing photos
    if (message.isDisappearingPhoto) {
      print('🕐 DEBUG: Disappearing photo timestamp conversion:');
      print('  - Original UTC: $dateTime');
      print('  - Local time: $localTime');
      print('  - Formatted: $hour:$minute $period');
    }
    
    return '$hour:$minute $period';
  }

  String _formatStoryTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'just now';
    }
  }
}
