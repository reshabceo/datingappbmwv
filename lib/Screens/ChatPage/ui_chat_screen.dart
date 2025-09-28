import 'package:lovebug/Common/text_constant.dart';
import 'package:lovebug/Common/widget_constant.dart';
import 'package:lovebug/Constant/app_assets.dart';
import 'package:lovebug/Screens/ChatPage/controller_chat_screen.dart';
import 'package:lovebug/Screens/ChatPage/chat_integration_helper.dart';
import 'package:lovebug/ThemeController/theme_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

class ChatScreen extends StatelessWidget {
  ChatScreen({super.key});

  final ChatController chatController = Get.put(ChatController());
  final ThemeController themeController = Get.find<ThemeController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: Get.width,
        height: Get.height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [themeController.blackColor, themeController.bgGradient1, themeController.blackColor],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: screenPadding(customPadding: EdgeInsets.fromLTRB(15.w, 56.h, 15.w, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              heightBox(8),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // New Matches Section - MOVED TO TOP
                      TextConstant(
                        fontSize: 24,
                        title: 'new_matches'.tr,
                        fontWeight: FontWeight.bold,
                        color: themeController.whiteColor,
                      ),
                      heightBox(10),
                      GetX<ChatController>(builder: (c) => SizedBox(
                        height: 80.h,
                        child: ListView.separated(
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          scrollDirection: Axis.horizontal,
                          itemCount: c.chatList.length == 0 ? 1 : c.chatList.length,
                          separatorBuilder: (context, index) => widthBox(15),
                          itemBuilder: (context, index) {
                            if (c.chatList.isEmpty) {
                              return Center(
                                child: TextConstant(title: 'No matches yet', color: themeController.whiteColor.withValues(alpha: 0.8)),
                              );
                            }
                            final chat = c.chatList[index];
                              return InkWell(
                                onTap: () {
                                  ChatIntegrationHelper.navigateToChat(
                                    userName: chat.name,
                                    userImage: chat.avatarUrl,
                                    matchId: chat.matchId,
                                  );
                                },
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Stack(
                                      alignment: Alignment.bottomRight,
                                      children: [
                                        ProfileAvatar(
                                          imageUrl: chat.avatarUrl,
                                          size: 60,
                                          borderWidth: 2.w,
                                        ),
                                        Container(
                                          width: 20.w,
                                          height: 20.w,
                                          decoration: BoxDecoration(
                                            color: themeController.lightPinkColor,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: themeController.whiteColor,
                                              width: 2.w,
                                            ),
                                          ),
                                          child: Icon(
                                            Icons.chat_bubble,
                                            color: themeController.whiteColor,
                                            size: 12.sp,
                                          ),
                                        ),
                                      ],
                                    ),
                                    heightBox(6),
                                    TextConstant(
                                      title: chat.name,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: themeController.whiteColor,
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        )),
                        heightBox(18),
                        // Section: Flame Chat (conversations)
                        TextConstant(
                          fontSize: 24,
                          title: 'flame_chat'.tr,
                          fontWeight: FontWeight.bold,
                          color: themeController.whiteColor,
                        ),
                        heightBox(8),
                        GetX<ChatController>(builder: (c) => (c.chatList.isEmpty)
                            ? Center(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(vertical: 40.h),
                                  child: TextConstant(title: 'No conversations yet', color: themeController.whiteColor.withValues(alpha: 0.8)),
                                ),
                              )
                            : ListView.separated(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          padding: EdgeInsets.zero,
                          itemCount: c.chatList.length,
                          separatorBuilder: (context, index) => heightBox(12),
                          itemBuilder: (context, index) {
                            final chat = c.chatList[index];
                            return InkWell(
                              onTap: () {
                                ChatIntegrationHelper.navigateToChat(
                                  userName: chat.name,
                                  userImage: chat.avatarUrl,
                                  matchId: chat.matchId,
                                );
                              },
                              child: Container(
                                width: Get.width,
                                padding: EdgeInsets.all(16.w),
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
                                  borderRadius: BorderRadius.circular(20.r),
                                  boxShadow: [
                                    BoxShadow(
                                      color: themeController.lightPinkColor.withValues(alpha: 0.1),
                                      blurRadius: 15,
                                      offset: Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Stack(
                                      alignment: Alignment.bottomRight,
                                      children: [
                                        ProfileAvatar(
                                          imageUrl: chat.avatarUrl,
                                          size: 50,
                                          borderWidth: 2.w,
                                        ),
                                        Container(
                                          height: 14.h,
                                          width: 14.h,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: themeController.lightPinkColor,
                                            border: Border.all(
                                              color: themeController.whiteColor,
                                              width: 2.w,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    widthBox(15),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              TextConstant(
                                                title: chat.name,
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: themeController.whiteColor,
                                              ),
                                              if (chat.time.isNotEmpty)
                                                Container(
                                                  padding: EdgeInsets.symmetric(
                                                    horizontal: 10.w,
                                                    vertical: 4.h,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: themeController.lightPinkColor,
                                                    borderRadius: BorderRadius.circular(15.r),
                                                  ),
                                                  child: TextConstant(
                                                    title: chat.time,
                                                    fontSize: 11,
                                                    color: themeController.whiteColor,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                            ],
                                          ),
                                          heightBox(6),
                                          TextConstant(
                                            title: chat.message.isEmpty ? 'Say hi!' : chat.message,
                                            fontSize: 14,
                                            overflow: TextOverflow.ellipsis,
                                            color: themeController.whiteColor.withValues(alpha: 0.8),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        )),
                        heightBox(20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
    );
  }
}
