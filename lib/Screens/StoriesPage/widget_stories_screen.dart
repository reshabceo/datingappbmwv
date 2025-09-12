import 'package:boliler_plate/Common/text_constant.dart';
import 'package:boliler_plate/Common/widget_constant.dart';
import 'package:boliler_plate/Screens/StoriesPage/controller_stories_screen.dart';
import 'package:boliler_plate/Screens/StoriesPage/ui_show_story_screen.dart';
import 'package:boliler_plate/ThemeController/theme_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

class WidgetStories {
  ThemeController themeController = Get.find<ThemeController>();

  Widget storyGroupCard({required StoryGroup storyGroup, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        child: Row(
          children: [
            // Profile Avatar with Story Ring
            Stack(
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
            
            widthBox(12),
            
            // User Info
            Expanded(
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
            
            // Time and Arrow
            Column(
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
          ],
        ),
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
