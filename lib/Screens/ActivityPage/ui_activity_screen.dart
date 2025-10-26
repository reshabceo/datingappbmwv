import 'package:lovebug/Common/text_constant.dart';
import 'package:lovebug/Common/widget_constant.dart';
import 'package:lovebug/Screens/ActivityPage/controller_activity_screen.dart';
import 'package:lovebug/Screens/ActivityPage/models/activity_model.dart';
import 'package:lovebug/ThemeController/theme_controller.dart';
import 'package:lovebug/widgets/blurred_profile_widget.dart';
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
          customPadding: EdgeInsets.fromLTRB(15.w, 20.h, 15.w, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              heightBox(35),
              TextConstant(
                fontSize: 24,
                title: 'activity'.tr,
                fontWeight: FontWeight.bold,
                color: themeController.whiteColor,
              ),
              heightBox(2),
              Expanded(
                child: Obx(() {
                  // Loading
                  if (controller.isLoading.value &&
                      controller.activities.isEmpty) {
                    return Center(
                      child: CircularProgressIndicator(
                        color: themeController.lightPinkColor,
                      ),
                    );
                  }

                  // Error
                  if (controller.hasError.value) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 48.sp,
                            color: themeController.lightPinkColor,
                          ),
                          heightBox(16),
                          TextConstant(
                            title: 'Failed to load activities',
                            fontSize: 14,
                            color: themeController.whiteColor,
                          ),
                          heightBox(16),
                          ElevatedButton(
                            onPressed: () => controller.loadActivities(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  themeController.lightPinkColor,
                            ),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    );
                  }

                  // Empty
                  if (controller.activities.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            LucideIcons.inbox,
                            size: 48.sp,
                            color: themeController.whiteColor
                                .withValues(alpha: 0.5),
                          ),
                          heightBox(16),
                          TextConstant(
                            title: 'No activities yet',
                            fontSize: 16,
                            color: themeController.whiteColor
                                .withValues(alpha: 0.7),
                          ),
                          heightBox(8),
                          TextConstant(
                            title:
                                'Start swiping to see who likes you!',
                            fontSize: 12,
                            color: themeController.whiteColor
                                .withValues(alpha: 0.5),
                          ),
                        ],
                      ),
                    );
                  }

                  // List
                  return RefreshIndicator(
                    onRefresh: controller.refresh,
                    color: themeController.lightPinkColor,
                    child: ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.zero,
                      itemCount: controller.activities.length,
                      separatorBuilder: (context, index) => heightBox(10),
                      itemBuilder: (context, index) {
                        final activity = controller.activities[index];
                        // Use blue gradient for BFF activities, pink/purple for dating activities
                        final isBffActivity = activity.type.toString().contains('bff');
                        final backgroundColor = isBffActivity
                            ? themeController.bffPrimaryColor.withValues(alpha: 0.2)
                            : (index % 2 != 0
                                ? themeController.lightPinkColor.withValues(alpha: 0.2)
                                : themeController.purpleColor.withValues(alpha: 0.2));
                        final iconColor = isBffActivity
                            ? themeController.bffPrimaryColor
                            : (index % 2 != 0
                                ? themeController.lightPinkColor
                                : themeController.purpleColor);

                        // Check if activity should be blurred for free users
                        final shouldBlur = !controller.isPremium.value &&
                            (activity.type == ActivityType.premiumMessage);
                        
                        Widget activityWidget = InkWell(
                          onTap: () => controller.onActivityTap(activity),
                          child: Container(
                                width: Get.width,
                                decoration: BoxDecoration(
                                  gradient: isBffActivity
                                      ? LinearGradient(
                                          colors: [
                                            themeController.bffPrimaryColor.withValues(alpha: 0.15),
                                            themeController.bffSecondaryColor.withValues(alpha: 0.1),
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        )
                                      : null,
                                  color: isBffActivity
                                      ? null
                                      : themeController.lightPinkColor.withValues(alpha: 0.15),
                                  border: Border.all(
                                    color: isBffActivity
                                        ? themeController.bffPrimaryColor.withValues(alpha: 0.3)
                                        : themeController.lightPinkColor.withValues(alpha: 0.3),
                                    width: 1.w,
                                  ),
                                  borderRadius: BorderRadius.circular(16.r),
                                  boxShadow: [
                                    BoxShadow(
                                      color: isBffActivity
                                          ? themeController.bffPrimaryColor.withValues(alpha: 0.2)
                                          : themeController.lightPinkColor.withValues(alpha: 0.2),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                padding: EdgeInsets.all(12.w),
                                child: Row(
                                  children: [
                                    // Profile photo
                                    Container(
                                      width: 40.h,
                                      height: 40.h,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: backgroundColor,
                                        image: activity.otherUserPhoto !=
                                                    null &&
                                                activity.otherUserPhoto!
                                                    .isNotEmpty
                                            ? DecorationImage(
                                                image: NetworkImage(
                                                    activity.otherUserPhoto!),
                                                fit: BoxFit.cover,
                                              )
                                            : null,
                                      ),
                                      child: (activity.otherUserPhoto ==
                                                  null ||
                                              activity.otherUserPhoto!
                                                  .isEmpty)
                                          ? Icon(
                                              Icons.person,
                                              color: iconColor,
                                              size: 20.sp,
                                            )
                                          : null,
                                    ),
                                    widthBox(12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            activity.displayMessage,
                                            style: TextStyle(
                                              color: themeController
                                                  .whiteColor,
                                              fontSize: 13.sp,
                                              fontWeight: FontWeight.w600,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          heightBox(4),
                                          Text(
                                            activity.timeAgo,
                                            style: TextStyle(
                                              color: themeController
                                                  .whiteColor
                                                  .withValues(alpha: 0.6),
                                              fontSize: 11.sp,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    widthBox(8),
                                    Icon(
                                      activity.icon,
                                      color: iconColor,
                                      size: 20.sp,
                                    ),
                                    widthBox(8),
                                    if (activity.isUnread)
                                      Container(
                                        width: 8.h,
                                        height: 8.h,
                                        decoration: BoxDecoration(
                                          color: themeController
                                              .lightPinkColor,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            );
                        
                        // Wrap with blurring for free users
                        if (shouldBlur) {
                          return BlurredActivityWidget(
                            activityType: activity.type.toString(),
                            child: activityWidget,
                            onTap: () => controller.onActivityTap(activity),
                          );
                        }
                        
                        return activityWidget;
                      },
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
