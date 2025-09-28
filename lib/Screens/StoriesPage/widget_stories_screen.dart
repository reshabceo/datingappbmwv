import 'package:lovebug/Common/text_constant.dart';
import 'package:lovebug/Common/widget_constant.dart';
import 'package:lovebug/Screens/StoriesPage/controller_stories_screen.dart';
import 'package:lovebug/Screens/StoriesPage/ui_show_story_screen.dart';
import 'package:lovebug/Screens/DiscoverPage/profile_detail_screen.dart';
import 'package:lovebug/Screens/DiscoverPage/controller_discover_screen.dart';
import 'package:lovebug/ThemeController/theme_controller.dart';
import 'package:lovebug/services/supabase_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

class WidgetStories {
  ThemeController themeController = Get.find<ThemeController>();

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

  Future<void> _viewProfile(String userId) async {
    try {
      print('🔍 _viewProfile called for userId: $userId');
      // Get the user's profile
      final profileData = await SupabaseService.getProfile(userId);
      print('🔍 Profile data received: $profileData');
      if (profileData != null) {
        // Convert Map to Profile object
        final profile = _mapToProfile(profileData);
        print('🔍 Profile object created: ${profile.name}');
        // Navigate to profile detail screen with isMatched: true
        Get.to(() => ProfileDetailScreen(profile: profile, isMatched: true));
      } else {
        print('❌ Profile data is null');
        Get.snackbar('Error', 'Profile not found');
      }
    } catch (e) {
      print('❌ Error viewing profile: $e');
      Get.snackbar('Error', 'Failed to load profile');
    }
  }

  Widget storyGroupCard({required StoryGroup storyGroup, required VoidCallback onTap}) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      child: Row(
        children: [
          // Profile Avatar with Story Ring
          GestureDetector(
            onTap: () {
              print('🎯 Profile picture tapped for user: ${storyGroup.userId}');
              print('🎯 StoryGroup details: ${storyGroup.userName}, ${storyGroup.avatarUrl}');
              _viewProfile(storyGroup.userId);
            },
            child: Stack(
                children: [
                  Container(
                    padding: EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: storyGroup.hasUnviewed
                          ? LinearGradient(
                              colors: [
                                themeController.lightPinkColor,
                                themeController.lightPinkColor.withValues(alpha: 0.7),
                              ],
                            )
                          : LinearGradient(
                              colors: [
                                themeController.greyColor,
                                themeController.greyColor,
                              ],
                            ),
                    ),
                    child: ProfileAvatar(
                      imageUrl: storyGroup.avatarUrl,
                      borderWidth: 0,
                      size: 50,
                    ),
                  ),
                if (storyGroup.hasUnviewed)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: themeController.lightPinkColor,
                        border: Border.all(
                          color: themeController.blackColor,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            widthBox(12),
            
            // User Info and Story Tap Area
            Expanded(
              child: GestureDetector(
                onTap: onTap,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextConstant(
                      title: storyGroup.userName,
                      fontWeight: FontWeight.bold,
                      color: themeController.whiteColor,
                      fontSize: 16,
                    ),
                    TextConstant(
                      title: '${storyGroup.stories.length} story${storyGroup.stories.length > 1 ? 'ies' : ''}',
                      color: themeController.whiteColor.withValues(alpha: 0.7),
                      fontSize: 14,
                    ),
                  ],
                ),
              ),
            ),
            
            // Time and Arrow
            GestureDetector(
              onTap: onTap,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  TextConstant(
                    title: storyGroup.stories.first.timeLabel,
                    color: themeController.whiteColor.withValues(alpha: 0.7),
                    fontSize: 12,
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: themeController.whiteColor.withValues(alpha: 0.5),
                    size: 16,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
  }

  Widget storiesCard({required StoryItem story}) {
    return InkWell(
      onTap: () {
        Get.to(() => ShowStoryScreen(story: story));
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.r),
                  boxShadow: [
                    BoxShadow(
                      color: themeController.lightPinkColor.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
          image: DecorationImage(
            fit: BoxFit.cover,
            image: NetworkImage(story.mediaUrl.isNotEmpty ? story.mediaUrl : story.avatarUrl),
          ),
        ),
        child: Stack(
          children: [
            // // Online Dot
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: themeController.lightPinkColor,
                ),
              ),
            ),

            // gradient
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 45.h,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(12.r),
                    bottomRight: Radius.circular(12.r),
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      themeController.blackColor.withValues(alpha: 0.5),
                      themeController.transparentColor,
                    ],
                  ),
                ),
              ),
            ),

            // Bottom content
            Positioned(
              left: 10.w,
              bottom: 8.h,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: themeController.blackColor.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(20.r),
                            border: Border.all(
                              color: themeController.lightPinkColor.withValues(alpha: 0.3),
                              width: 1,
                            ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ProfileAvatar(
                      imageUrl: story.avatarUrl,
                      borderWidth: 1.5,
                    ),
                    widthBox(8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextConstant(
                          title: story.userName,
                          fontWeight: FontWeight.bold,
                          color: themeController.whiteColor,
                          fontSize: 14,
                        ),
                        TextConstant(
                          title: story.timeLabel,
                          color: themeController.whiteColor.withValues(
                            alpha: 0.7,
                          ),
                          fontSize: 12,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
