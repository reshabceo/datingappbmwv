import 'package:lovebug/Common/text_constant.dart';
import 'package:lovebug/Common/widget_constant.dart';
import 'package:lovebug/Screens/ActivityPage/controller_activity_screen.dart';
import 'package:lovebug/Screens/ActivityPage/models/activity_model.dart';
import 'package:lovebug/ThemeController/theme_controller.dart';
import 'package:lovebug/widgets/blurred_profile_widget.dart';
import 'package:lovebug/Widgets/upgrade_prompt_widget.dart';
import 'package:lovebug/Screens/SubscriptionPage/ui_subscription_screen.dart';
import 'package:lovebug/Screens/DiscoverPage/controller_discover_screen.dart';
import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class ActivityScreen extends StatelessWidget {
  ActivityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialize controller and theme safely
    ActivityController? controller;
    ThemeController? themeController;
    
    try {
      controller = Get.put(ActivityController());
      themeController = Get.find<ThemeController>();
    } catch (e) {
      print('❌ Error initializing ActivityScreen: $e');
      return Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, color: Colors.white, size: 48),
                SizedBox(height: 16),
                Text(
                  'Error loading Activity screen',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
                SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => Get.back(),
                  child: Text('Go Back'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final theme = themeController!;
    final ctrl = controller!;

    return Scaffold(
      backgroundColor: theme.blackColor,
      body: SafeArea(
        child: Container(
          width: Get.width,
          height: Get.height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.blackColor,
                theme.bgGradient1,
                theme.blackColor,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Column(
            children: [
              // Header
              Padding(
                padding: EdgeInsets.fromLTRB(15.w, 20.h, 15.w, 16.h),
                child: Row(
                  children: [
                    TextConstant(
                      fontSize: 24,
                      title: 'activity'.tr,
                      fontWeight: FontWeight.bold,
                      color: theme.whiteColor,
                    ),
                  ],
                ),
              ),
              
              // Potential Matches Bar
              Obx(() {
                if (ctrl.isPremium.value || ctrl.potentialMatchesCount.value == 0) {
                  return SizedBox.shrink();
                }
                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: 15.w),
                  child: Column(
                    children: [
                      _buildPotentialMatchesBar(ctrl, theme),
                      SizedBox(height: 16.h),
                    ],
                  ),
                );
              }),
              
              // Ghost Mode Card
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 15.w),
                child: _buildGhostModeCard(ctrl, theme),
              ),
              
              SizedBox(height: 16.h),
              
              // Activities List
              Expanded(
                child: Obx(() {
                  // Loading state
                  if (ctrl.isLoading.value && ctrl.activities.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            color: theme.lightPinkColor,
                          ),
                          SizedBox(height: 16.h),
                          TextConstant(
                            title: 'Loading activities...',
                            fontSize: 14,
                            color: theme.whiteColor.withValues(alpha: 0.7),
                          ),
                        ],
                      ),
                    );
                  }

                  // Error state
                  if (ctrl.hasError.value) {
                    return Center(
                      child: Padding(
                        padding: EdgeInsets.all(20.w),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 48.sp,
                              color: theme.lightPinkColor,
                            ),
                            SizedBox(height: 16.h),
                            TextConstant(
                              title: 'Failed to load activities',
                              fontSize: 14,
                              color: theme.whiteColor,
                            ),
                            SizedBox(height: 16.h),
                            ElevatedButton(
                              onPressed: () => ctrl.loadActivities(),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: theme.lightPinkColor,
                              ),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  // Empty state
                  if (ctrl.activities.isEmpty) {
                    return SingleChildScrollView(
                      child: Padding(
                        padding: EdgeInsets.all(20.w),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(height: 40.h),
                            Container(
                              padding: EdgeInsets.all(24.w),
                              decoration: BoxDecoration(
                                color: theme.lightPinkColor.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                LucideIcons.bell,
                                size: 64.sp,
                                color: theme.lightPinkColor,
                              ),
                            ),
                            SizedBox(height: 24.h),
                            TextConstant(
                              title: 'No activities yet',
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: theme.whiteColor,
                            ),
                            SizedBox(height: 8.h),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 32.w),
                              child: TextConstant(
                                title: 'Start swiping to see who likes you!',
                                fontSize: 14,
                                color: theme.whiteColor.withValues(alpha: 0.7),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            SizedBox(height: 32.h),
                            // Tips section
                            Container(
                              margin: EdgeInsets.symmetric(horizontal: 20.w),
                              padding: EdgeInsets.all(20.w),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    theme.lightPinkColor.withValues(alpha: 0.15),
                                    theme.purpleColor.withValues(alpha: 0.1),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(16.r),
                                border: Border.all(
                                  color: theme.lightPinkColor.withValues(alpha: 0.3),
                                  width: 1.w,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        LucideIcons.lightbulb,
                                        color: theme.lightPinkColor,
                                        size: 20.sp,
                                      ),
                                      SizedBox(width: 8.w),
                                      TextConstant(
                                        title: 'Tips to get more activity',
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: theme.whiteColor,
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 16.h),
                                  _buildTipItem(
                                    theme: theme,
                                    icon: LucideIcons.heart,
                                    text: 'Swipe right on profiles you like',
                                  ),
                                  SizedBox(height: 12.h),
                                  _buildTipItem(
                                    theme: theme,
                                    icon: LucideIcons.star,
                                    text: 'Use Super Likes to stand out',
                                  ),
                                  SizedBox(height: 12.h),
                                  _buildTipItem(
                                    theme: theme,
                                    icon: LucideIcons.messageCircle,
                                    text: 'Start conversations with your matches',
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  // Activities list
                  return RefreshIndicator(
                    onRefresh: ctrl.refresh,
                    color: theme.lightPinkColor,
                    child: ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(15.w, 0, 15.w, 100.h),
                      itemCount: ctrl.activities.length,
                      separatorBuilder: (context, index) => SizedBox(height: 10.h),
                      itemBuilder: (context, index) {
                        final activity = ctrl.activities[index];
                        return _buildActivityCard(activity, index, ctrl, theme);
                      },
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: Obx(() {
        if (ctrl.activities.isEmpty) {
          return SizedBox.shrink();
        }
        return FloatingActionButton(
          onPressed: () => _showClearAllConfirmation(ctrl, theme),
          backgroundColor: theme.lightPinkColor,
          mini: true,
          child: Icon(
            LucideIcons.trash2,
            color: theme.whiteColor,
            size: 20.sp,
          ),
        );
      }),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildActivityCard(Activity activity, int index, ActivityController controller, ThemeController theme) {
    final isBffActivity = activity.type.toString().contains('bff');
    final backgroundColor = isBffActivity
        ? theme.bffPrimaryColor.withValues(alpha: 0.2)
        : (index % 2 != 0
            ? theme.lightPinkColor.withValues(alpha: 0.2)
            : theme.purpleColor.withValues(alpha: 0.2));
    final iconColor = isBffActivity
        ? theme.bffPrimaryColor
        : (index % 2 != 0
            ? theme.lightPinkColor
            : theme.purpleColor);

    final bool hideIdentity = !controller.isPremium.value &&
        (activity.type == ActivityType.like || activity.type == ActivityType.superLike);
    final bool shouldBlur = !controller.isPremium.value &&
        (activity.type == ActivityType.premiumMessage || hideIdentity);

    final String displayMessage = hideIdentity
        ? (activity.type == ActivityType.superLike
            ? 'Someone super loved you!'
            : 'Someone liked your profile')
        : activity.displayMessage;

    final String? displayPhoto = activity.otherUserPhoto;

    final VoidCallback handleTap = shouldBlur
        ? () => _showUpgradePrompt(activity, theme)
        : () => controller.onActivityTap(activity);

    Widget card = InkWell(
      onTap: handleTap,
      child: Container(
        width: Get.width,
        decoration: BoxDecoration(
          gradient: isBffActivity
              ? LinearGradient(
                  colors: [
                    theme.bffPrimaryColor.withValues(alpha: 0.15),
                    theme.bffSecondaryColor.withValues(alpha: 0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isBffActivity
              ? null
              : theme.lightPinkColor.withValues(alpha: 0.15),
          border: Border.all(
            color: isBffActivity
                ? theme.bffPrimaryColor.withValues(alpha: 0.3)
                : theme.lightPinkColor.withValues(alpha: 0.3),
            width: 1.w,
          ),
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: isBffActivity
                  ? theme.bffPrimaryColor.withValues(alpha: 0.2)
                  : theme.lightPinkColor.withValues(alpha: 0.2),
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
                image: displayPhoto != null && displayPhoto.isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(displayPhoto),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: (displayPhoto == null || displayPhoto.isEmpty)
                  ? Icon(
                      Icons.person,
                      color: iconColor,
                      size: 20.sp,
                    )
                  : (shouldBlur
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(20.h),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
                            child: Container(
                              color: Colors.black.withOpacity(0.2),
                            ),
                          ),
                        )
                      : null),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayMessage,
                    style: TextStyle(
                      color: theme.whiteColor,
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    shouldBlur ? 'Upgrade to see who it is' : activity.timeAgo,
                    style: TextStyle(
                      color: theme.whiteColor.withValues(alpha: 0.6),
                      fontSize: 11.sp,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 8.w),
            Icon(
              activity.icon,
              color: iconColor,
              size: 20.sp,
            ),
            SizedBox(width: 8.w),
            if (activity.isUnread)
              Container(
                width: 8.h,
                height: 8.h,
                decoration: BoxDecoration(
                  color: theme.lightPinkColor,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );

    return Slidable(
      key: ValueKey('slidable_${activity.id}'),
      endActionPane: ActionPane(
        motion: const BehindMotion(),
        extentRatio: 0.25,
        children: [
          CustomSlidableAction(
            backgroundColor: Colors.transparent,
            onPressed: (context) async {
              final confirmed = await _showDeleteConfirmDialog(activity, theme);
              if (confirmed && context.mounted) {
                Slidable.of(context)?.close();
              }
            },
            flex: 1,
            child: Container(
              decoration: BoxDecoration(
                color: theme.lightPinkColor,
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(16.r),
                  bottomRight: Radius.circular(16.r),
                ),
              ),
              alignment: Alignment.center,
              child: Icon(
                LucideIcons.trash2,
                color: theme.whiteColor,
                size: 22.sp,
              ),
            ),
          ),
        ],
      ),
      child: card,
    );
  }

  Widget _buildPotentialMatchesBar(ActivityController controller, ThemeController theme) {
    return Obx(() {
      final count = controller.potentialMatchesCount.value;
      final lastPhoto = controller.lastLikerPhoto.value;
      
      if (count == 0 || controller.isPremium.value) {
        return SizedBox.shrink();
      }
      
      final remainingCount = count > 1 ? count - 1 : 0;
      
      return InkWell(
        onTap: () => Get.to(() => SubscriptionScreen()),
        child: Container(
          width: Get.width,
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.lightPinkColor.withValues(alpha: 0.3),
                theme.purpleColor.withValues(alpha: 0.2),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: theme.lightPinkColor.withValues(alpha: 0.4),
              width: 1.w,
            ),
          ),
          child: Row(
            children: [
              Stack(
                children: [
                  Container(
                    width: 56.w,
                    height: 56.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: theme.whiteColor.withValues(alpha: 0.1),
                    ),
                    child: lastPhoto.isNotEmpty
                        ? ClipOval(
                            child: ImageFiltered(
                              imageFilter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                              child: Image.network(
                                lastPhoto,
                                width: 56.w,
                                height: 56.w,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Icon(
                                    Icons.person,
                                    color: theme.whiteColor.withValues(alpha: 0.5),
                                    size: 28.sp,
                                  );
                                },
                              ),
                            ),
                          )
                        : Icon(
                            Icons.person,
                            color: theme.whiteColor.withValues(alpha: 0.5),
                            size: 28.sp,
                          ),
                  ),
                  if (remainingCount > 0)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 24.w,
                        height: 24.w,
                        decoration: BoxDecoration(
                          color: theme.lightPinkColor,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: theme.blackColor,
                            width: 2.w,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '+$remainingCount',
                            style: TextStyle(
                              color: theme.whiteColor,
                              fontSize: 10.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'You have $count potential match${count > 1 ? 'es' : ''}',
                      style: TextStyle(
                        color: theme.whiteColor,
                        fontSize: 15.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    TextConstant(
                      title: 'upgrade_to_view_who_all',
                      fontSize: 12,
                      color: theme.whiteColor.withValues(alpha: 0.7),
                    ),
                  ],
                ),
              ),
              Icon(
                LucideIcons.chevronRight,
                color: theme.whiteColor.withValues(alpha: 0.7),
                size: 20.sp,
              ),
            ],
          ),
        ),
      );
    });
  }
  
  Widget _buildGhostModeCard(ActivityController controller, ThemeController theme) {
    return Obx(() {
      final isActive = controller.isGhostModeActive.value;
      final timeRemaining = controller.getGhostModeTimeRemaining();
      
      return Container(
        width: Get.width,
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.purpleColor.withValues(alpha: 0.3),
              theme.purpleColor.withValues(alpha: 0.2),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: theme.purpleColor.withValues(alpha: 0.4),
            width: 1.w,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48.w,
              height: 48.w,
              decoration: BoxDecoration(
                color: theme.purpleColor.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                LucideIcons.ghost,
                color: theme.whiteColor,
                size: 24.sp,
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextConstant(
                    title: 'ghost_mode',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: theme.whiteColor,
                  ),
                  SizedBox(height: 4.h),
                  TextConstant(
                    title: 'become_hours',
                    fontSize: 12,
                    color: theme.whiteColor.withValues(alpha: 0.7),
                  ),
                  if (isActive && timeRemaining.isNotEmpty) ...[
                    SizedBox(height: 4.h),
                    Text(
                      timeRemaining,
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: theme.whiteColor.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Switch(
              value: isActive,
              onChanged: (value) => controller.toggleGhostMode(),
              activeColor: theme.purpleColor,
              inactiveThumbColor: theme.whiteColor.withValues(alpha: 0.5),
              inactiveTrackColor: theme.whiteColor.withValues(alpha: 0.2),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildTipItem({required ThemeController theme, required IconData icon, required String text}) {
    return Row(
      children: [
        Icon(
          icon,
          color: theme.lightPinkColor.withValues(alpha: 0.8),
          size: 16.sp,
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: TextConstant(
            title: text,
            fontSize: 13,
            color: theme.whiteColor.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }

  void _showUpgradePrompt(Activity activity, ThemeController theme) {
    final bool isSuperLike = activity.type == ActivityType.superLike;
    final bool isLike = activity.type == ActivityType.like;
    final bool isPremiumMessage = activity.type == ActivityType.premiumMessage;

    String title;
    String message;
    String limitType;
    IconData icon;
    List<Color> gradient;

    if (isPremiumMessage) {
      title = 'Unlock Premium Messages';
      message = 'Upgrade to see who sent this message and keep the conversation going instantly.';
      limitType = 'message';
      icon = Icons.forum_rounded;
      gradient = [
        theme.purpleColor.withValues(alpha: 0.2),
        theme.lightPinkColor.withValues(alpha: 0.25),
        theme.blackColor.withValues(alpha: 0.85),
      ];
    } else if (isSuperLike) {
      title = 'See Your Super Lover';
      message = 'Someone is really into you! Upgrade to reveal who super loved you and match instantly.';
      limitType = 'swipe';
      icon = Icons.star_rounded;
      gradient = [
        theme.lightPinkColor.withValues(alpha: 0.2),
        theme.purpleColor.withValues(alpha: 0.25),
        theme.blackColor.withValues(alpha: 0.85),
      ];
    } else if (isLike) {
      title = 'See Who Liked You';
      message = 'Upgrade to reveal everyone who liked you and start chatting before the spark fades.';
      limitType = 'swipe';
      icon = Icons.favorite_rounded;
      gradient = [
        theme.lightPinkColor.withValues(alpha: 0.2),
        theme.purpleColor.withValues(alpha: 0.2),
        theme.blackColor.withValues(alpha: 0.85),
      ];
    } else {
      title = 'Premium Feature';
      message = 'Upgrade to unlock this premium activity and experience the full LoveBug magic.';
      limitType = 'swipe';
      icon = Icons.lock_outline;
      gradient = [
        theme.lightPinkColor.withValues(alpha: 0.2),
        theme.purpleColor.withValues(alpha: 0.2),
        theme.blackColor.withValues(alpha: 0.85),
      ];
    }

    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
        child: UpgradePromptWidget(
          title: title,
          message: message,
          action: 'Upgrade Now',
          limitType: limitType,
          icon: icon,
          gradientColors: gradient,
          dismissLabel: 'Maybe Later',
          onUpgrade: () {
            Get.back();
            Get.to(() => SubscriptionScreen());
          },
          onDismiss: () => Get.back(),
        ),
      ),
      barrierDismissible: true,
    );
  }

  void _showClearAllConfirmation(ActivityController controller, ThemeController theme) {
    Get.dialog(
      Dialog(
        backgroundColor: theme.blackColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Padding(
          padding: EdgeInsets.all(20.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.warning_rounded,
                size: 32.sp,
                color: theme.lightPinkColor,
              ),
              SizedBox(height: 16.h),
              TextConstant(
                title: 'Clear all activities?',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: theme.whiteColor,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8.h),
              TextConstant(
                title: 'This will remove all activities from your feed',
                fontSize: 14,
                color: theme.whiteColor.withValues(alpha: 0.8),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20.h),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Get.back(),
                      child: TextConstant(
                        title: 'Cancel',
                        color: theme.greyColor,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Get.back();
                        controller.clearAllActivities();
                        Get.snackbar(
                          'Cleared',
                          'All activities cleared',
                          backgroundColor: theme.lightPinkColor.withValues(alpha: 0.9),
                          colorText: theme.whiteColor,
                          duration: Duration(seconds: 2),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.lightPinkColor,
                      ),
                      child: TextConstant(
                        title: 'Clear',
                        color: theme.whiteColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool> _showDeleteConfirmDialog(Activity activity, ThemeController theme) async {
    final confirmed = await Get.dialog<bool>(
      Dialog(
        backgroundColor: theme.blackColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Padding(
          padding: EdgeInsets.all(20.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.warning_rounded,
                size: 32.sp,
                color: theme.lightPinkColor,
              ),
              SizedBox(height: 16.h),
              TextConstant(
                title: 'Delete activity?',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: theme.whiteColor,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8.h),
              TextConstant(
                title: 'This activity will be removed from your feed',
                fontSize: 14,
                color: theme.whiteColor.withValues(alpha: 0.8),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20.h),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Get.back(result: false),
                      child: TextConstant(
                        title: 'Cancel',
                        color: theme.greyColor,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Get.back(result: true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.lightPinkColor,
                      ),
                      child: TextConstant(
                        title: 'Delete',
                        color: theme.whiteColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed == true) {
      final ctrl = Get.find<ActivityController>();
      await ctrl.deleteActivity(activity.id);
      Get.snackbar(
        'Deleted',
        'Activity deleted',
        backgroundColor: theme.lightPinkColor.withValues(alpha: 0.9),
        colorText: theme.whiteColor,
        duration: Duration(seconds: 2),
      );
      return true;
    }
    return false;
  }
}

