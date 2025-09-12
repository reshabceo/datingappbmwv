import 'package:boliler_plate/Common/setting_tile_widget.dart';
import 'package:boliler_plate/Common/text_constant.dart';
import 'package:boliler_plate/Common/widget_constant.dart';
import 'package:boliler_plate/Screens/AuthPage/auth_ui_screen.dart';
import 'package:boliler_plate/services/supabase_service.dart';
import 'package:boliler_plate/Screens/Setting/Controller/setting_controller.dart';
import 'package:boliler_plate/ThemeController/theme_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:glass/glass.dart';
import 'account_screen.dart';
import 'privacy_screen.dart';
import 'appearance_screen.dart';
import 'notifications_screen.dart';
import 'blocked_users_screen.dart';

void showCustomMenuDialog(BuildContext context) {
  final controller = Get.find<SettingsController>();
  final themecontroller = Get.find<ThemeController>();

  showDialog(
    context: context,
    barrierColor: themecontroller.transparentColor,
    builder: (context) {
      return Obx(() {
        return Align(
          alignment: Alignment.topRight,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.only(topLeft: Radius.circular(10.r), bottomLeft: Radius.circular(10.r)),
              color: themecontroller.isDarkMode.value ? null : themecontroller.lightTheme.scaffoldBackgroundColor,
              gradient: themecontroller.isDarkMode.value
                  ? LinearGradient(
                      colors: [themecontroller.blackColor, themecontroller.bgGradient1, themecontroller.blackColor],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    )
                  : null,
            ),
            width: 380.w,
            margin: EdgeInsets.only(left: 50.w),
            child: Material(
              color: themecontroller.transparentColor,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: EdgeInsets.only(bottom: 10.h),
                    child: Container(
                      height: 50.h,
                      width: 380.w,
                      decoration: BoxDecoration(
                        color: themecontroller.isDarkMode.value ? null : themecontroller.lightTheme.scaffoldBackgroundColor,
                        gradient: themecontroller.isDarkMode.value
                            ? LinearGradient(
                                colors: [
                                  themecontroller.dialogBGColor1,
                                  themecontroller.dialogBGColor2,
                                  themecontroller.dialogBGColor1,
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              )
                            : null,
                      ),
                      child: Row(
                        children: [
                          widthBox(10),
                          TextConstant(fontSize: 17.sp, title: 'Settings', fontWeight: FontWeight.w700),
                          Spacer(),
                          IconButton(onPressed: () => Get.back(), icon: Icon(Icons.cancel)),
                          widthBox(2),
                        ],
                      ),
                    ),
                  ).asGlass(blurX: 2, blurY: 2, tintColor: themecontroller.transparentColor),

                  Padding(
                    padding: EdgeInsets.only(left: 10.w, bottom: 10.h),
                    child: ListView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: controller.settingsList.length,
                      itemBuilder: (context, index) {
                        final item = controller.settingsList[index];
                        return Padding(
                          padding: EdgeInsets.all(4),
                          child: InkWell(
                            onTap: () async {
                              switch (index) {
                                case 0:
                                  Get.to(() => AccountSettingsScreen());
                                  break;
                                case 1:
                                  Get.to(() => PrivacySettingsScreen());
                                  break;
                                case 2:
                                  Get.to(() => NotificationsSettingsScreen());
                                  break;
                                case 3:
                                  Get.to(() => AppearanceSettingsScreen());
                                  break;
                                case 4:
                                  Get.to(() => BlockedUsersScreen());
                                  break;
                                case 6:
                                  try { await SupabaseService.signOut(); } catch (_) {}
                                  Get.offAll(() => AuthScreen());
                                  break;
                                default:
                                  break;
                              }
                            },
                            child: buildMenuItem(
                              title: item.title,
                              icon: item.icon,
                              index: index,
                            ).asGlass(blurX: 4, blurY: 4, clipBorderRadius: BorderRadius.circular(10.r)),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      });
    },
  );
}
