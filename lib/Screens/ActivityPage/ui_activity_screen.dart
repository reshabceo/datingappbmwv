import 'package:lovebug/Common/text_constant.dart';
import 'package:lovebug/Common/widget_constant.dart';
import 'package:lovebug/Screens/ActivityPage/controller_activity_screen.dart';
import 'package:lovebug/ThemeController/theme_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class ActivityScreen extends StatelessWidget {
  ActivityScreen({super.key});

  final ActivityController controller = Get.put(ActivityController());
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
            colors: [themeController.blackColor, themeController.bgGradient1, themeController.blackColor],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: screenPadding(customPadding: EdgeInsets.fromLTRB(15.w, 56.h, 15.w, 0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              heightBox(10),
              TextConstant(
                fontSize: 24,
                title: 'activity'.tr,
                fontWeight: FontWeight.bold,
                color: themeController.whiteColor,
              ),
              heightBox(15),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListView.separated(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: controller.activityList.length,
                        separatorBuilder: (context, index) => heightBox(10),
                        itemBuilder: (context, index) {
                          final activity = controller.activityList[index];

                          final isOdd = index % 2 != 0;
                          final backgroundColor = isOdd
                              ? themeController.lightPinkColor.withValues(
                            alpha: 0.2,
                          )
                              : themeController.purpleColor.withValues(
                            alpha: 0.2,
                          );

                          final iconColor = isOdd
                              ? themeController.lightPinkColor
                              : themeController.purpleColor;

                          return InkWell(
                            onTap: () {},
                            child: Container(
                              width: Get.width,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: themeController.lightPinkColor.withValues(
                                  alpha: 0.15,
                                ),
                                border: Border.all(
                                  color: themeController.lightPinkColor.withValues(
                                    alpha: 0.3,
                                  ),
                                  width: 1.w,
                                ),
                                borderRadius: BorderRadius.circular(16.r),
                                boxShadow: [
                                  BoxShadow(
                                    color: themeController.lightPinkColor.withValues(alpha: 0.2),
                                    blurRadius: 8,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                              padding: EdgeInsets.all(12.w),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  ButtonSquare(
                                    icon: activity.icon,
                                    backgroundColor: backgroundColor,
                                    iconColor: iconColor,
                                    width: 35,
                                    height: 35,
                                    iconSize: 15,
                                    borderRadius: 100,
                                  ),
                                  widthBox(11),
                                  Expanded(
                                    child: Column(
                                      spacing: 3.h,
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                      children: [
                                        TextConstant(
                                          title: activity.message,
                                          overflow: TextOverflow.ellipsis,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: themeController.whiteColor,
                                        ),
                                        TextConstant(
                                          title: activity.time,
                                          fontSize: 11,
                                          color: themeController.whiteColor.withValues(alpha: 0.7),
                                        ),
                                      ],
                                    ),
                                  ),
                                  widthBox(10),
                                  Container(
                                    height: 8.h,
                                    width: 8.h,
                                    decoration: BoxDecoration(
                                      color: iconColor,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      heightBox(20),
                        Container(
                          width: Get.width,
                          margin: EdgeInsets.symmetric(vertical: 4),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: themeController.lightPinkColor.withValues(
                              alpha: 0.15,
                            ),
                            border: Border.all(
                              color: themeController.lightPinkColor.withValues(
                                alpha: 0.3,
                              ),
                              width: 1.w,
                            ),
                            borderRadius: BorderRadius.circular(16.r),
                            boxShadow: [
                              BoxShadow(
                                color: themeController.lightPinkColor.withValues(alpha: 0.2),
                                blurRadius: 8,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                        padding: EdgeInsets.all(12.w),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ButtonSquare(
                              icon: LucideIcons.ghost,
                              iconColor: themeController.purpleColor,
                              backgroundColor: themeController.purpleColor
                                  .withValues(alpha: 0.2),
                              width: 35,
                              height: 35,
                              iconSize: 15,
                              borderRadius: 100,
                            ),
                            widthBox(11),
                            Expanded(
                              child: Column(
                                spacing: 3.h,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  TextConstant(
                                    title: 'ghost_mode'.tr,
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    overflow: TextOverflow.ellipsis,
                                    color: themeController.whiteColor,
                                  ),
                                  TextConstant(
                                    fontSize: 11,
                                    title: 'become_hours'.tr,
                                    color: themeController.whiteColor.withValues(alpha: 0.7),
                                  ),
                                ],
                              ),
                            ),
                            widthBox(10),
                            Obx(() {
                              return Switch.adaptive(
                                value: controller.isOn.value,
                                onChanged: (v) {
                                  controller.toggle();
                                },
                                trackOutlineWidth: WidgetStatePropertyAll(0.1),
                                activeTrackColor: themeController.purpleColor
                                    .withValues(alpha: 0.3),
                                inactiveTrackColor: themeController.greyColor
                                    .withValues(alpha: 0.3),
                                thumbColor: controller.isOn.value
                                    ? WidgetStateProperty.all(
                                  themeController.purpleColor,
                                )
                                    : WidgetStateProperty.all(
                                  themeController.whiteColor.withValues(
                                    alpha: 0.7,
                                  ),
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                      heightBox(20),
                      TextConstant(
                        fontSize: 16,
                        title: 'recent_activity'.tr,
                        fontWeight: FontWeight.bold,
                        color: themeController.whiteColor,
                      ),
                      heightBox(15),
                      ListView.separated(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: controller.recentActivity.length,
                        separatorBuilder: (context, index) => heightBox(10),
                        itemBuilder: (context, index) {
                          final recentActivity =
                          controller.recentActivity[index];

                            return Container(
                              width: Get.width,
                              alignment: Alignment.centerLeft,
                              decoration: BoxDecoration(
                                color: themeController.lightPinkColor.withValues(
                                  alpha: 0.15,
                                ),
                                border: Border.all(
                                  color: themeController.lightPinkColor.withValues(
                                    alpha: 0.3,
                                  ),
                                  width: 1.w,
                                ),
                                borderRadius: BorderRadius.circular(16.r),
                                boxShadow: [
                                  BoxShadow(
                                    color: themeController.lightPinkColor.withValues(alpha: 0.2),
                                    blurRadius: 8,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                            padding: EdgeInsets.all(12.w),
                            child: TextConstant(
                              fontSize: 12,
                              title: recentActivity,
                              fontWeight: FontWeight.bold,
                              overflow: TextOverflow.ellipsis,
                              color: themeController.whiteColor,
                            ),
                          );
                        },
                      ),
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