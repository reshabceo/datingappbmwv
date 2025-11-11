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

  final ActivityController controller = Get.put(ActivityController());
  final ThemeController themeController = Get.find<ThemeController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: themeController.blackColor,
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
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
                    heightBox(16),
                    
                    // Potential Matches Notification Bar - Only for free users with matches
                    Obx(() {
                      if (controller.isPremium.value || controller.potentialMatchesCount.value == 0) {
                        return SizedBox.shrink();
                      }
                      return Column(
                        children: [
                          _buildPotentialMatchesBar(),
                          heightBox(16),
                        ],
                      );
                    }),
                    
                    // Ghost Mode Card - Always visible
                    _buildGhostModeCard(),
                    
                    heightBox(16),
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
                      padding: EdgeInsets.only(bottom: 160.h), // Space for floating button to prevent overlap
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

                        final String blurredActivityType = () {
                          switch (activity.type) {
                            case ActivityType.superLike:
                              return 'super_like';
                            case ActivityType.premiumMessage:
                            case ActivityType.message:
                            case ActivityType.bffMessage:
                              return 'message';
                            case ActivityType.match:
                            case ActivityType.bffMatch:
                              return 'match';
                            case ActivityType.storyReply:
                              return 'message';
                            case ActivityType.like:
                            default:
                              return 'like';
                          }
                        }();
                        
                        final VoidCallback handleTap = shouldBlur
                            ? () => _showUpgradePrompt(activity)
                            : () => controller.onActivityTap(activity);

                        Widget activityWidget = LayoutBuilder(
                          builder: (context, constraints) {
                            print('✅ DEBUG: Activity card - type: ${activity.type}, shouldBlur: $shouldBlur');
                            print('✅ DEBUG: Activity card constraints: width=${constraints.maxWidth}, height=${constraints.maxHeight}');
                            return InkWell(
                              onTap: () {
                                print('✅ DEBUG: Activity card tapped - type: ${activity.type}, shouldBlur: $shouldBlur');
                                handleTap();
                              },
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
                                          : null,
                                    ),
                                    widthBox(12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            displayMessage,
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
                          },
                            );
                        
                        // Wrap with blurring for free users - using same structure as normal notification
                        if (shouldBlur) {
                          print('✅ DEBUG: Creating blurred notification - type: ${activity.type}');
                          final blurredWidget = InkWell(
                            onTap: handleTap,
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
                                  // Blurred profile photo - show actual photo with blur
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
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(20.h),
                                      child: displayPhoto != null && displayPhoto.isNotEmpty
                                          ? BackdropFilter(
                                              filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
                                              child: Container(
                                                color: Colors.black.withOpacity(0.2),
                                              ),
                                            )
                                          : Container(
                                              color: Colors.black.withOpacity(0.3),
                                              child: Icon(
                                                Icons.person,
                                                color: iconColor.withValues(alpha: 0.5),
                                                size: 20.sp,
                                              ),
                                            ),
                                    ),
                                  ),
                                  widthBox(12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          displayMessage,
                                          style: TextStyle(
                                            color: themeController.whiteColor,
                                            fontSize: 13.sp,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        heightBox(4),
                                        Text(
                                          'Upgrade to see who it is',
                                          style: TextStyle(
                                            color: themeController.whiteColor.withValues(alpha: 0.6),
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
                                        color: themeController.lightPinkColor,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                          
                          // Wrap blurred widget with Slidable
                          return _buildSlidableActivity(
                            activity: activity,
                            child: blurredWidget,
                          );
                        }
                        
                        print('✅ DEBUG: Returning unwrapped activityWidget - type: ${activity.type}');
                        
                        // Wrap with Slidable for swipe-to-delete
                        return _buildSlidableActivity(
                          activity: activity,
                          child: activityWidget,
                        );
                      },
                    ),
                  );
                }),
                  ),
                  ],
                ),
              ),
            ),
          ),
          // Floating Clear All Button - positioned above bottom nav bar
          _buildClearAllButton(),
        ],
      ),
    );
  }

  void _showUpgradePrompt(Activity activity) {
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
        themeController.purpleColor.withValues(alpha: 0.2),
        themeController.lightPinkColor.withValues(alpha: 0.25),
        themeController.blackColor.withValues(alpha: 0.85),
      ];
    } else if (isSuperLike) {
      title = 'See Your Super Lover';
      message = 'Someone is really into you! Upgrade to reveal who super loved you and match instantly.';
      limitType = 'swipe';
      icon = Icons.star_rounded;
      gradient = [
        themeController.lightPinkColor.withValues(alpha: 0.2),
        themeController.purpleColor.withValues(alpha: 0.25),
        themeController.blackColor.withValues(alpha: 0.85),
      ];
    } else if (isLike) {
      title = 'See Who Liked You';
      message = 'Upgrade to reveal everyone who liked you and start chatting before the spark fades.';
      limitType = 'swipe';
      icon = Icons.favorite_rounded;
      gradient = [
        themeController.lightPinkColor.withValues(alpha: 0.2),
        themeController.purpleColor.withValues(alpha: 0.2),
        themeController.blackColor.withValues(alpha: 0.85),
      ];
    } else {
      title = 'Premium Feature';
      message = 'Upgrade to unlock this premium activity and experience the full LoveBug magic.';
      limitType = 'swipe';
      icon = Icons.lock_outline;
      gradient = [
        themeController.lightPinkColor.withValues(alpha: 0.2),
        themeController.purpleColor.withValues(alpha: 0.2),
        themeController.blackColor.withValues(alpha: 0.85),
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

  Widget _buildPotentialMatchesBar() {
    return Obx(() {
      final count = controller.potentialMatchesCount.value;
      final lastPhoto = controller.lastLikerPhoto.value;
      
      // Only show if count > 0 and user is free
      if (count == 0 || controller.isPremium.value) {
        return SizedBox.shrink();
      }
      
      final remainingCount = count > 1 ? count - 1 : 0;
      
      return InkWell(
        onTap: () {
          // Navigate to subscription screen
          Get.to(() => SubscriptionScreen());
        },
        child: Container(
          width: Get.width,
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                themeController.lightPinkColor.withValues(alpha: 0.3),
                themeController.purpleColor.withValues(alpha: 0.2),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: themeController.lightPinkColor.withValues(alpha: 0.4),
              width: 1.w,
            ),
          ),
          child: Row(
            children: [
              // Profile picture with blur effect
              Stack(
                children: [
                  Container(
                    width: 56.w,
                    height: 56.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: themeController.whiteColor.withValues(alpha: 0.1),
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
                                    color: themeController.whiteColor.withValues(alpha: 0.5),
                                    size: 28.sp,
                                  );
                                },
                              ),
                            ),
                          )
                        : Icon(
                            Icons.person,
                            color: themeController.whiteColor.withValues(alpha: 0.5),
                            size: 28.sp,
                          ),
                  ),
                  // +X badge
                  if (remainingCount > 0)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 24.w,
                        height: 24.w,
                        decoration: BoxDecoration(
                          color: themeController.lightPinkColor,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: themeController.blackColor,
                            width: 2.w,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '+$remainingCount',
                            style: TextStyle(
                              color: themeController.whiteColor,
                              fontSize: 10.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              widthBox(16),
              
              // Text section
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'you_have_potential_matches'.tr.replaceAll('{count}', count.toString()),
                      style: TextStyle(
                        color: themeController.whiteColor,
                        fontSize: 15.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    heightBox(4),
                    TextConstant(
                      title: 'upgrade_to_view_who_all',
                      fontSize: 12,
                      color: themeController.whiteColor.withValues(alpha: 0.7),
                    ),
                  ],
                ),
              ),
              
              // Arrow icon
              Icon(
                LucideIcons.chevronRight,
                color: themeController.whiteColor.withValues(alpha: 0.7),
                size: 20.sp,
              ),
            ],
          ),
        ),
      );
    });
  }
  
  Widget _buildGhostModeCard() {
    return Obx(() {
      final isActive = controller.isGhostModeActive.value;
      final timeRemaining = controller.getGhostModeTimeRemaining();
      
      return Container(
        width: Get.width,
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              themeController.purpleColor.withValues(alpha: 0.3),
              themeController.purpleColor.withValues(alpha: 0.2),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: themeController.purpleColor.withValues(alpha: 0.4),
            width: 1.w,
          ),
        ),
        child: Row(
          children: [
            // Ghost icon container
            Container(
              width: 48.w,
              height: 48.w,
              decoration: BoxDecoration(
                color: themeController.purpleColor.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                LucideIcons.ghost,
                color: themeController.whiteColor,
                size: 24.sp,
              ),
            ),
            widthBox(16),
            
            // Text section
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextConstant(
                    title: 'ghost_mode',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: themeController.whiteColor,
                  ),
                  heightBox(4),
                  TextConstant(
                    title: 'become_hours',
                    fontSize: 12,
                    color: themeController.whiteColor.withValues(alpha: 0.7),
                  ),
                  if (isActive && timeRemaining.isNotEmpty) ...[
                    heightBox(4),
                    Text(
                      timeRemaining,
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: themeController.whiteColor.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            
            // Toggle switch
            Switch(
              value: isActive,
              onChanged: (value) {
                controller.toggleGhostMode();
              },
              activeColor: themeController.purpleColor,
              inactiveThumbColor: themeController.whiteColor.withValues(alpha: 0.5),
              inactiveTrackColor: themeController.whiteColor.withValues(alpha: 0.2),
            ),
          ],
        ),
      );
    });
  }
  
  Widget _buildSlidableActivity({required Activity activity, required Widget child}) {
    return Slidable(
      key: ValueKey('slidable_${activity.id}'),
      groupTag: 'activity_list', // Ensures only one Slidable can be open at a time - must be same String for all
      closeOnScroll: true,
      endActionPane: ActionPane(
        motion: const BehindMotion(),
        extentRatio: 0.25,
        children: [
          CustomSlidableAction(
            backgroundColor: Colors.transparent,
            onPressed: (context) async {
              final confirmed = await _showDeleteConfirmDialog(activity);
              if (confirmed && context.mounted) {
                Slidable.of(context)?.close();
              }
            },
            padding: EdgeInsets.zero,
            flex: 1,
            child: Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                color: themeController.lightPinkColor,
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(16.r), // Match card's border radius exactly
                  bottomRight: Radius.circular(16.r),
                ),
              ),
              alignment: Alignment.center,
              child: Icon(
                LucideIcons.trash2,
                color: themeController.whiteColor,
                size: 22.sp,
              ),
            ),
          ),
        ],
      ),
      child: child,
    );
  }
  
  Widget _buildClearAllButton() {
    return Obx(() {
      // Only show if there are activities
      if (controller.activities.isEmpty) {
        return SizedBox.shrink();
      }
      
      return Positioned(
        bottom: 70.h, // Right above bottom nav bar (70.h)
        left: 0,
        right: 0,
        child: SafeArea(
          bottom: false, // Don't add extra bottom padding
          child: Center(
            child: InkWell(
              onTap: () => _showClearAllConfirmation(),
              borderRadius: BorderRadius.circular(30.r), // Circular
              child: Container(
                width: 50.w, // Smaller circular size
                height: 50.w, // Same as width for perfect circle
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      themeController.getAccentColor(),
                      themeController.getSecondaryColor(),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle, // Circular shape
                  boxShadow: [
                    BoxShadow(
                      color: themeController.getAccentColor().withValues(alpha: 0.4),
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  LucideIcons.trash2,
                  color: themeController.whiteColor,
                  size: 20.sp,
                ),
              ),
            ),
          ),
        ),
      );
    });
  }
  
  void _showClearAllConfirmation() {
    // Detect current mode (dating/bff) for styling
    bool isBffMode = false;
    if (Get.isRegistered<DiscoverController>()) {
      try {
        final d = Get.find<DiscoverController>();
        isBffMode = (d.currentMode.value == 'bff');
      } catch (_) {}
    }

    // Pick gradient colors based on mode
    final List<Color> bgColors = isBffMode
        ? [
            themeController.bffPrimaryColor.withValues(alpha: 0.15),
            themeController.bffSecondaryColor.withValues(alpha: 0.15),
          ]
        : [
            themeController.getAccentColor().withValues(alpha: 0.15),
            themeController.getSecondaryColor().withValues(alpha: 0.15),
          ];
    final Color borderColor = isBffMode
        ? themeController.bffPrimaryColor
        : themeController.getAccentColor();
    final Color iconColor = isBffMode
        ? themeController.bffPrimaryColor
        : themeController.getAccentColor();
    final List<Color> ctaColors = isBffMode
        ? [themeController.bffPrimaryColor, themeController.bffSecondaryColor]
        : [themeController.getAccentColor(), themeController.getSecondaryColor()];

    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.symmetric(horizontal: 24.w),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: bgColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22.r),
              border: Border.all(
                color: borderColor.withValues(alpha: 0.35),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: borderColor.withValues(alpha: 0.15),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.all(20.w),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Warning icon in circular container
                    Container(
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        color: iconColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.warning_rounded,
                        size: 32.sp,
                        color: iconColor,
                      ),
                    ),
                    heightBox(16),
                    // Title
                    TextConstant(
                      title: 'clear_all_activities',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: themeController.whiteColor,
                      textAlign: TextAlign.center,
                    ),
                    heightBox(8),
                    // Message with proper text overflow handling - wrapped with constraints
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8.w),
                      child: TextConstant(
                        title: 'clear_all_activities_message',
                        fontSize: 14,
                        color: themeController.whiteColor.withValues(alpha: 0.8),
                        textAlign: TextAlign.center,
                        softWrap: true,
                        maxLines: 3,
                      ),
                    ),
                    SizedBox(height: 20.h),
                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => Get.back(),
                            child: Container(
                              padding: EdgeInsets.symmetric(vertical: 12.h),
                              decoration: BoxDecoration(
                                color: themeController.whiteColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20.r),
                                border: Border.all(
                                  color: themeController.whiteColor.withValues(alpha: 0.3),
                                  width: 1.5,
                                ),
                              ),
                              child: TextConstant(
                                title: 'cancel',
                                textAlign: TextAlign.center,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: themeController.whiteColor,
                              ),
                            ),
                          ),
                        ),
                        widthBox(12),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              Get.back();
                              controller.clearAllActivities();
                              Get.snackbar(
                                'Cleared',
                                'All activities cleared',
                                backgroundColor: themeController.lightPinkColor.withValues(alpha: 0.9),
                                colorText: themeController.whiteColor,
                                duration: Duration(seconds: 2),
                              );
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(vertical: 12.h),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(colors: ctaColors),
                                borderRadius: BorderRadius.circular(20.r),
                                border: Border.all(
                                  color: borderColor.withValues(alpha: 0.5),
                                  width: 1.5,
                                ),
                              ),
                              child: TextConstant(
                                title: 'clear',
                                textAlign: TextAlign.center,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: themeController.whiteColor,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      barrierDismissible: true,
    );
  }

  Future<bool> _showDeleteConfirmDialog(Activity activity) async {
    // Detect current mode (dating/bff) for styling
    bool isBffMode = false;
    if (Get.isRegistered<DiscoverController>()) {
      try {
        final d = Get.find<DiscoverController>();
        isBffMode = (d.currentMode.value == 'bff');
      } catch (_) {}
    }

    // Pick gradient colors based on mode
    final List<Color> bgColors = isBffMode
        ? [
            themeController.bffPrimaryColor.withValues(alpha: 0.15),
            themeController.bffSecondaryColor.withValues(alpha: 0.15),
          ]
        : [
            themeController.getAccentColor().withValues(alpha: 0.15),
            themeController.getSecondaryColor().withValues(alpha: 0.15),
          ];
    final Color borderColor = isBffMode
        ? themeController.bffPrimaryColor
        : themeController.getAccentColor();
    final Color iconColor = isBffMode
        ? themeController.bffPrimaryColor
        : themeController.getAccentColor();
    final List<Color> ctaColors = isBffMode
        ? [themeController.bffPrimaryColor, themeController.bffSecondaryColor]
        : [themeController.getAccentColor(), themeController.getSecondaryColor()];

    final confirmed = await Get.dialog<bool>(
      Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.symmetric(horizontal: 24.w),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: bgColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22.r),
              border: Border.all(
                color: borderColor.withValues(alpha: 0.35),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: borderColor.withValues(alpha: 0.15),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.all(20.w),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Warning icon in circular container
                    Container(
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        color: iconColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.warning_rounded,
                        size: 32.sp,
                        color: iconColor,
                      ),
                    ),
                    heightBox(16),
                    // Title
                    TextConstant(
                      title: 'delete_activity',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: themeController.whiteColor,
                      textAlign: TextAlign.center,
                    ),
                    heightBox(8),
                    // Message with proper text overflow handling - wrapped with constraints
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8.w),
                      child: TextConstant(
                        title: 'delete_activity_message',
                        fontSize: 14,
                        color: themeController.whiteColor.withValues(alpha: 0.8),
                        textAlign: TextAlign.center,
                        softWrap: true,
                        maxLines: 3,
                      ),
                    ),
                    SizedBox(height: 20.h),
                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => Get.back(result: false),
                            child: Container(
                              padding: EdgeInsets.symmetric(vertical: 12.h),
                              decoration: BoxDecoration(
                                color: themeController.whiteColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20.r),
                                border: Border.all(
                                  color: themeController.whiteColor.withValues(alpha: 0.3),
                                  width: 1.5,
                                ),
                              ),
                              child: TextConstant(
                                title: 'cancel',
                                textAlign: TextAlign.center,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: themeController.whiteColor,
                              ),
                            ),
                          ),
                        ),
                        widthBox(12),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => Get.back(result: true),
                            child: Container(
                              padding: EdgeInsets.symmetric(vertical: 12.h),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(colors: ctaColors),
                                borderRadius: BorderRadius.circular(20.r),
                                border: Border.all(
                                  color: borderColor.withValues(alpha: 0.5),
                                  width: 1.5,
                                ),
                              ),
                              child: TextConstant(
                                title: 'delete',
                                textAlign: TextAlign.center,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: themeController.whiteColor,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      barrierDismissible: true,
    );

    if (confirmed == true) {
      await controller.deleteActivity(activity.id);
      Get.snackbar(
        'Deleted',
        'Activity deleted',
        backgroundColor: themeController.lightPinkColor.withValues(alpha: 0.9),
        colorText: themeController.whiteColor,
        duration: Duration(seconds: 2),
      );
      return true;
    }
    return false;
  }
}
