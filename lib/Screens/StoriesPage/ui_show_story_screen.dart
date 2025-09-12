import 'package:boliler_plate/Common/text_constant.dart';
import 'package:boliler_plate/Common/widget_constant.dart';
import 'package:boliler_plate/Constant/app_assets.dart';
import 'package:boliler_plate/Screens/ChatPage/controller_message_screen.dart';
import 'package:boliler_plate/Screens/ChatPage/ui_message_screen.dart';
import 'package:boliler_plate/Screens/StoriesPage/controller_show_story_screen.dart';
import 'package:boliler_plate/Screens/StoriesPage/controller_stories_screen.dart';
import 'package:boliler_plate/ThemeController/theme_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

class ShowStoryScreen extends StatelessWidget {
  final ShowStoryController controller = Get.put(ShowStoryController());
  final ThemeController themeController = Get.find<ThemeController>();

  final StoryItem story;

  ShowStoryScreen({super.key, required this.story});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Image
          SizedBox(
            height: Get.height,
            width: Get.width,
            child: Image.network(story.mediaUrl.isNotEmpty ? story.mediaUrl : story.avatarUrl, fit: BoxFit.cover),
          ),

          // Top Profile Info
          Positioned(
            top: 45.h,
            left: 15.w,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                backButton(),
                widthBox(8),
                ProfileAvatar(imageUrl: story.avatarUrl, borderWidth: 1.5, size: 40),
                widthBox(8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextConstant(title: story.userName, fontSize: 16, fontWeight: FontWeight.bold),
                    TextConstant(title: story.timeLabel, fontSize: 12),
                  ],
                ),
              ],
            ),
          ),

          // Bottom Message Box
          Positioned(
            bottom: 20.h,
            left: 15.w,
            right: 15.w,
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 40.h,
                    child: TextField(
                      onSubmitted: (v) {
                        if (v.isNotEmpty) {
                          Get.to(() => MessageScreen(userImage: story.avatarUrl, userName: story.userName, matchId: ''))?.then((value) {
                            MessageController controller = Get.find<MessageController>();
                            controller.sendMessage('', v);
                            controller.messages.refresh();
                          });
                        }
                      },
                      controller: controller.textController,
                      style: TextStyle(fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        hintText: "Send message...",
                        filled: true,
                        fillColor: themeController.whiteColor.withValues(alpha: 0.3),
                        contentPadding: EdgeInsets.symmetric(horizontal: 13.w),
                        border: InputBorder.none,
                        enabledBorder: OutlineInputBorder(borderSide: BorderSide.none, borderRadius: BorderRadius.circular(50.r)),
                        focusedBorder: OutlineInputBorder(borderSide: BorderSide.none, borderRadius: BorderRadius.circular(50.r)),
                      ),
                    ),
                  ),
                ),
                widthBox(8),
                SvgPicture.asset(AppAssets.storylike, height: 40.h, width: 40.h),
                widthBox(8),
                SvgPicture.asset(
                  AppAssets.storysend,
                  colorFilter: ColorFilter.mode(Theme.of(context).iconTheme.color!, BlendMode.srcIn),
                  height: 40.h,
                  width: 40.h,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
