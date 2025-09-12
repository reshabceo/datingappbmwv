import 'package:boliler_plate/Common/text_constant.dart';
import 'package:boliler_plate/Common/widget_constant.dart';
import 'package:boliler_plate/Screens/ChatPage/controller_message_screen.dart';
import 'package:boliler_plate/ThemeController/theme_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class ChatBubble extends StatelessWidget {
  final Message message;
  final String userImage;
  final String userName;

  ChatBubble({super.key, required this.message, required this.userImage, required this.userName});

  final ThemeController themeController = Get.find<ThemeController>();

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
                Stack(
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
                    child: TextConstant(
                      title: message.text,
                      color: themeController.whiteColor.withValues(alpha: 0.9),
                      softWrap: true, 
                      fontSize: 14, 
                      height: 1.3,
                    ),
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
                    child: TextConstant(
                      title: message.text,
                      softWrap: true,
                      fontSize: 14,
                      height: 1.3,
                      color: themeController.whiteColor.withValues(alpha: 0.9),
                    ),
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
    String period = dateTime.hour >= 12 ? 'PM' : 'AM';
    int hour = dateTime.hour > 12 ? dateTime.hour - 12 : dateTime.hour;
    if (hour == 0) hour = 12;
    final minute = dateTime.minute.toString().padLeft(2, '0');
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
