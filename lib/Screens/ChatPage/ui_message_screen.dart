import 'package:boliler_plate/Common/text_constant.dart';
import 'package:boliler_plate/Common/widget_constant.dart';
import 'package:boliler_plate/Constant/app_assets.dart';
import 'package:boliler_plate/Screens/ChatPage/controller_message_screen.dart';
import 'package:boliler_plate/Screens/ChatPage/ui_chatbubble_screen.dart';
import 'package:boliler_plate/ThemeController/theme_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class MessageScreen extends StatelessWidget {
  MessageScreen({
    super.key,
    required this.userImage,
    required this.userName,
    required this.matchId,
  });

  final String? userImage;
  final String? userName;
  final String matchId;

  final ThemeController themeController = Get.find<ThemeController>();

  @override
  Widget build(BuildContext context) {
    final MessageController controller =
        Get.put(MessageController(), tag: 'msg_$matchId')
          ..ensureInitialized(matchId);

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: Container(
          decoration: BoxDecoration(color: themeController.blackColor),
          child: AppBar(
            backgroundColor: themeController.transparentColor,
            elevation: 0,
            iconTheme: IconThemeData(color: themeController.whiteColor),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: Get.back,
            ),
            centerTitle: true,
            title: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextConstant(
                  title: userName ?? '',
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: themeController.whiteColor,
                ),
                TextConstant(
                  title: 'online'.tr,
                  fontWeight: FontWeight.w600,
                  color: themeController.greenColor,
                  fontSize: 11,
                ),
              ],
            ),
            actions: [
              InkWell(
                onTap: () {},
                child: SvgPicture.asset(
                  AppAssets.menu,
                  height: 35.h,
                  width: 35.h,
                  fit: BoxFit.cover,
                ),
              ),
              widthBox(12),
            ],
          ),
        ),
      ),
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
        child: Column(
          children: [
            // Profile header row
            Container(
              width: Get.width,
              alignment: Alignment.center,
              padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 15.w),
              color: themeController.transparentColor,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      ProfileAvatar(
                        imageUrl: userImage ?? '',
                        size: 50,
                        borderWidth: 1.5.w,
                      ),
                      Container(
                        height: 12.h,
                        width: 12.h,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: themeController.greenColor,
                          border: Border.all(
                            color: themeController.primaryColor.value,
                            width: 1.w,
                          ),
                        ),
                      ),
                    ],
                  ),
                  widthBox(11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextConstant(
                          title: userName ?? '',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: themeController.whiteColor,
                        ),
                        heightBox(3),
                        TextConstant(
                          title: 'Last seen today at 10:48 AM',
                          fontSize: 13,
                          // If you do not have withValues, replace with withOpacity
                          color: themeController.whiteColor.withOpacity(0.7),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Divider(
              color: themeController.greyColor.withOpacity(0.2),
              thickness: 1.5.h,
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 15.w),
                child: Obx(() {
                  if (controller.messages.isEmpty) {
                    return Center(
                      child: Container(
                        padding: EdgeInsets.all(20.w),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              themeController.lightPinkColor.withOpacity(0.1),
                              themeController.purpleColor.withOpacity(0.05),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20.r),
                          border: Border.all(
                            color:
                                themeController.lightPinkColor.withOpacity(0.3),
                            width: 1.w,
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextConstant(
                              title: 'Hey 👋',
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: themeController.whiteColor,
                            ),
                            heightBox(10),
                            TextConstant(
                              title: 'Say something to start the conversation!',
                              softWrap: true,
                              fontSize: 14,
                              color: themeController.whiteColor
                                  .withOpacity(0.8),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    controller: controller.scrollController,
                    itemCount: controller.messages.length,
                    itemBuilder: (context, index) {
                      final message = controller.messages[index];
                      return ChatBubble(
                        message: message,
                        userImage: userImage ?? '',
                        userName: userName ?? '',
                      );
                    },
                  );
                }),
              ),
            ),
            // Input field
            _buildChatInputField(controller),
          ],
        ),
      ),
    );
  }

  Widget _buildChatInputField(MessageController controller) {
    final ctx = Get.context!;
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(ctx).viewInsets.bottom,
        left: 15.w,
        right: 15.w,
        top: 10.h,
      ),
      decoration: BoxDecoration(
        color: themeController.blackColor,
        boxShadow: [
          BoxShadow(
            color: themeController.blackColor.withOpacity(0.6),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            ButtonSquare(
              height: 35,
              width: 35,
              onTap: () {},
              iconSize: 16,
              icon: LucideIcons.paperclip,
              iconColor: themeController.whiteColor,
              borderColor: themeController.transparentColor,
              backgroundColor: themeController.lightPinkColor,
            ),
            widthBox(6),
            ButtonSquare(
              width: 35,
              height: 35,
              iconSize: 16,
              onTap: () {},
              icon: Icons.emoji_emotions_rounded,
              iconColor: themeController.whiteColor,
              borderColor: themeController.transparentColor,
              backgroundColor: themeController.lightPinkColor,
            ),
            widthBox(6),
            Expanded(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: 40.h,
                  maxHeight: 200.h,
                ),
                child: SingleChildScrollView(
                  reverse: true,
                  child: TextField(
                    controller: controller.textController,
                    onChanged: (v) {},
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: themeController.whiteColor,
                    ),
                    maxLines: null,
                    minLines: 1,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (v) {
                      if (v.trim().isNotEmpty && !v.contains('\n')) {
                        controller.sendMessage(matchId, v.trim());
                      }
                    },
                    decoration: InputDecoration(
                      filled: true,
                      hintText: 'type_message'.tr,
                      hintStyle: TextStyle(
                        fontWeight: FontWeight.w500,
                        color:
                            themeController.whiteColor.withOpacity(0.6),
                      ),
                      fillColor:
                          themeController.blackColor.withOpacity(0.25),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 15.w,
                        vertical: 12.h,
                      ),
                      border: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: themeController.lightPinkColor
                              .withOpacity(0.3),
                          width: 1.w,
                        ),
                        borderRadius: BorderRadius.circular(50.r),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: themeController.lightPinkColor
                              .withOpacity(0.3),
                          width: 1.w,
                        ),
                        borderRadius: BorderRadius.circular(50.r),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: themeController.lightPinkColor,
                          width: 1.5.w,
                        ),
                        borderRadius: BorderRadius.circular(50.r),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            widthBox(6),
            ButtonSquare(
              onTap: () =>
                  controller.sendMessage(matchId, controller.textController.text.trim()),
              height: 35,
              width: 35,
              icon: LucideIcons.send,
              backgroundColor: themeController.lightPinkColor,
              iconColor: themeController.whiteColor,
              borderColor: themeController.transparentColor,
              iconSize: 16,
            ),
          ],
        ),
      ),
    );
  }
}