import 'package:lovebug/Common/text_constant.dart';
import 'package:lovebug/Common/widget_constant.dart';
import 'package:lovebug/Screens/StoriesPage/controller_stories_screen.dart';
import 'package:lovebug/Screens/StoriesPage/widget_stories_screen.dart';
import 'package:lovebug/Screens/StoriesPage/ui_instagram_story_viewer.dart';
import 'package:lovebug/Screens/StoriesPage/ui_create_story_screen.dart';
import 'package:lovebug/Screens/StoriesPage/ui_story_camera_screen.dart';
import 'package:lovebug/Screens/DiscoverPage/profile_detail_screen.dart';
import 'package:lovebug/Screens/DiscoverPage/controller_discover_screen.dart';
import 'package:lovebug/ThemeController/theme_controller.dart';
import 'package:lovebug/services/supabase_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

class _NoGlowBehavior extends ScrollBehavior {
  const _NoGlowBehavior();

  @override
  Widget buildOverscrollIndicator(BuildContext context, Widget child, ScrollableDetails details) {
    return child;
  }
}

class StoriesScreen extends StatelessWidget {
  StoriesScreen({super.key});

  final StoriesController controller = Get.put(StoriesController());
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

  Future<void> _viewProfile(String userId) async {
    try {
      // Get the user's profile
      final profileData = await SupabaseService.getProfile(userId);
      if (profileData != null) {
        // Convert Map to Profile object
        final profile = _mapToProfile(profileData);
        // Navigate to profile detail screen with isMatched: true
        Get.to(() => ProfileDetailScreen(profile: profile, isMatched: true));
      } else {
        Get.snackbar('Error', 'Profile not found');
      }
    } catch (e) {
      print('Error viewing profile: $e');
      Get.snackbar('Error', 'Failed to load profile');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: themeController.blackColor,
      body: Container(
        width: Get.width,
        height: Get.height,
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
        ),
        child: SafeArea(top: false, bottom: false,
          child: screenPadding(customPadding: EdgeInsets.fromLTRB(15.w, 56.h, 15.w, 0),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  heightBox(0),
                  TextConstant(
                    title: 'Stories',
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: themeController.whiteColor,
                  ),
                  heightBox(8),
                  Expanded(
                    child: Obx(() {
                      if (controller.isLoading.value) {
                        return Center(
                          child: CircularProgressIndicator(
                            color: themeController.lightPinkColor,
                          ),
                        );
                      }
                      
                      if (controller.storyGroups.isEmpty) {
                        return Stack(
                          children: [
                            SizedBox(
                              height: Get.height * 0.5,
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.photo_camera_outlined,
                                      size: 64,
                                      color: themeController.lightPinkColor.withValues(alpha: 0.6),
                                    ),
                                    SizedBox(height: 16),
                                    TextConstant(
                                      title: 'No stories yet',
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: themeController.whiteColor,
                                    ),
                                    SizedBox(height: 8),
                                    TextConstant(
                                      title: 'Get matches to see their stories!',
                                      fontSize: 14,
                                      color: themeController.whiteColor.withValues(alpha: 0.7),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            
                            // FIXED: Always show add story button, even when no stories exist
                            Positioned(
                              bottom: 20.h,
                              left: 0,
                              right: 0,
                              child: Center(
                                child: GestureDetector(
                                  onTap: _addStory,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 64.w,
                                        height: 64.w,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: [
                                              themeController.lightPinkColor,
                                              themeController.lightPinkColor.withValues(alpha: 0.9),
                                              Colors.purple.withValues(alpha: 0.9),
                                            ],
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: themeController.lightPinkColor.withValues(alpha: 0.4),
                                              blurRadius: 20,
                                              offset: Offset(0, 8),
                                            ),
                                            BoxShadow(
                                              color: Colors.black.withValues(alpha: 0.2),
                                              blurRadius: 10,
                                              offset: Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: Icon(
                                          Icons.add,
                                          color: Colors.white,
                                          size: 28,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      }
                      
                      return Stack(
                          children: [
                            ScrollConfiguration(
                              behavior: const _NoGlowBehavior(),
                              child: GridView.builder(
                                physics: const ClampingScrollPhysics(),
                                padding: EdgeInsets.fromLTRB(0.w, 0.h, 0.w, 80.h), // Align with header
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.65, // Slightly shorter cards for better alignment
                              crossAxisSpacing: 12.w, // Increased spacing for better alignment
                              mainAxisSpacing: 12.h,  // Increased spacing
                            ),
                            itemCount: controller.storyGroups.length,
                            itemBuilder: (context, index) {
                              final storyGroup = controller.storyGroups[index];
                              return _buildStoryCard(
                                storyGroup: storyGroup,
                                onTap: () {
                                  Get.to(() => InstagramStoryViewer(
                                    storyGroups: controller.storyGroups,
                                    initialIndex: index,
                                  ));
                                },
                              );
                            },
                            ),
                          ),
                          
                          // Floating Add Story Button (no text label)
                          Positioned(
                            bottom: 20.h,
                            left: 0,
                            right: 0,
                            child: Center(
                              child: GestureDetector(
                                onTap: _addStory,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 64.w,
                                      height: 64.w,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            themeController.lightPinkColor,
                                            themeController.lightPinkColor.withValues(alpha: 0.9),
                                            Colors.purple.withValues(alpha: 0.9),
                                          ],
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: themeController.lightPinkColor.withValues(alpha: 0.4),
                                            blurRadius: 20,
                                            offset: Offset(0, 8),
                                          ),
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.2),
                                            blurRadius: 10,
                                            offset: Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: Icon(
                                        Icons.add,
                                        color: Colors.white,
                                        size: 28,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    }),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
  }

  Widget _buildStoryCard({
    required StoryGroup storyGroup,
    required VoidCallback onTap,
  }) {
    final theme = themeController;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.r),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.lightPinkColor.withValues(alpha: 0.1),
              Colors.purple.withValues(alpha: 0.1),
            ],
          ),
          border: Border.all(
            color: theme.lightPinkColor.withValues(alpha: 0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: theme.lightPinkColor.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16.r),
          child: Stack(
            children: [
              // Background image
              if (storyGroup.stories.isNotEmpty)
                Positioned.fill(
                  child: Image.network(
                    storyGroup.stories.first.mediaUrl.isNotEmpty 
                        ? storyGroup.stories.first.mediaUrl 
                        : storyGroup.avatarUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              theme.lightPinkColor.withValues(alpha: 0.3),
                              Colors.purple.withValues(alpha: 0.3),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              
              // Gradient overlay
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.7),
                      ],
                    ),
                  ),
                ),
              ),
              
              // User DP with story ring
              Positioned(
                top: 6.h,
                left: 6.w,
                child: GestureDetector(
                  onTap: () => _viewProfile(storyGroup.userId),
                  child: Container(
                    width: 28.w,
                    height: 28.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: theme.lightPinkColor,
                        width: 2.5,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 12.r,
                      backgroundImage: storyGroup.avatarUrl.isNotEmpty
                          ? NetworkImage(storyGroup.avatarUrl)
                          : null,
                      child: storyGroup.avatarUrl.isEmpty
                          ? Icon(
                              Icons.person,
                              color: theme.whiteColor,
                              size: 14,
                            )
                          : null,
                    ),
                  ),
                ),
              ),
              
              // Story count indicator
              if (storyGroup.stories.length > 1)
                Positioned(
                  top: 6.h,
                  right: 6.w,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 1.h),
                    decoration: BoxDecoration(
                      color: theme.lightPinkColor,
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Text(
                      '${storyGroup.stories.length}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 9.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              
              // User name at bottom
              Positioned(
                bottom: 6.h,
                left: 6.w,
                right: 6.w,
                child: Text(
                  storyGroup.userName,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              
              // Time indicator
              if (storyGroup.stories.isNotEmpty)
                Positioned(
                  bottom: 6.h,
                  right: 6.w,
                  child: Text(
                    storyGroup.stories.first.timeLabel,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 9.sp,
                    ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _addStory() async {
    final theme = themeController;
    print('🔄 DEBUG: _addStory() called');
    try {
      final uid = SupabaseService.currentUser?.id;
      if (uid == null) {
        print('❌ DEBUG: No user ID found');
        Get.snackbar('Login required', 'Please sign in to add a story');
        return;
      }
      
      // Navigate to story camera screen
      print('🔄 DEBUG: Opening story camera screen...');
      Get.to(() => StoryCameraScreen());
      print('✅ DEBUG: Navigation completed');
      
    } catch (e) {
      print('❌ DEBUG: Error in _addStory: $e');
      Get.snackbar('Error', e.toString(), backgroundColor: theme.blackColor);
    }
  }

  // Show upload progress indicator
  void _showUploadProgress() {
    Get.dialog(
      Center(
        child: Container(
          padding: EdgeInsets.all(20.w),
          decoration: BoxDecoration(
            color: themeController.blackColor.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                color: themeController.getAccentColor(),
                strokeWidth: 3.0,
              ),
              heightBox(16),
              TextConstant(
                title: 'Uploading Story...',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: themeController.whiteColor,
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  // Hide upload progress indicator
  void _hideUploadProgress() {
    if (Get.isDialogOpen == true) {
      Get.back();
    }
  }
}
