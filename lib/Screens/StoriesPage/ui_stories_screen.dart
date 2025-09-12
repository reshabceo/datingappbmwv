import 'package:boliler_plate/Common/text_constant.dart';
import 'package:boliler_plate/Common/widget_constant.dart';
import 'package:boliler_plate/Screens/StoriesPage/controller_stories_screen.dart';
import 'package:boliler_plate/Screens/StoriesPage/widget_stories_screen.dart';
import 'package:boliler_plate/Screens/StoriesPage/ui_instagram_story_viewer.dart';
import 'package:boliler_plate/ThemeController/theme_controller.dart';
import 'package:boliler_plate/services/supabase_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

class StoriesScreen extends StatelessWidget {
  StoriesScreen({super.key});

  final StoriesController controller = Get.put(StoriesController());
  final ThemeController themeController = Get.find<ThemeController>();

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
        child: screenPadding(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              heightBox(10),
              TextConstant(
                fontSize: 24,
                title: 'snap_stories'.tr,
                fontWeight: FontWeight.bold,
                color: themeController.whiteColor,
              ),
              heightBox(10),
              heightBox(10),
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
                    return SizedBox(
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
                    );
                  }
                  
                  return Stack(
                    children: [
                      GridView.builder(
                        padding: EdgeInsets.fromLTRB(0.w, 8.h, 0.w, 80.h), // Align with text start
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
                      
                      // Floating Add Story Button
                      Positioned(
                        bottom: 20.h,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: GestureDetector(
                            onTap: _addStory,
                            child: Container(
                              width: 56.w,
                              height: 56.w,
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
                                    blurRadius: 16,
                                    offset: Offset(0, 6),
                                  ),
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.2),
                                    blurRadius: 8,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.add,
                                color: Colors.white,
                                size: 24,
                              ),
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
    // For testing, let's add a sample story
    final testImageUrl = 'https://picsum.photos/400/600?random=${DateTime.now().millisecondsSinceEpoch}';
    await controller.addStory(testImageUrl);
    
    final theme = themeController;
    try {
      final picker = ImagePicker();
      final img = await picker.pickImage(source: ImageSource.gallery);
      if (img == null) return;
      final uid = SupabaseService.currentUser?.id;
      if (uid == null) {
        Get.snackbar('Login required', 'Please sign in to add a story');
        return;
      }
      final bytes = await img.readAsBytes();
      final path = uid + '/story_' + DateTime.now().millisecondsSinceEpoch.toString() + '.jpg';
      final url = await SupabaseService.uploadFile(bucket: 'story-media', path: path, fileBytes: bytes);
      await controller.addStory(url);
      Get.snackbar('Story added', 'Your story is live for 24 hours');
    } catch (e) {
      Get.snackbar('Error', e.toString(), backgroundColor: theme.blackColor);
    }
  }
}
