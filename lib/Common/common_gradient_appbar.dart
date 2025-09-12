import 'package:boliler_plate/Common/widget_constant.dart';
import 'package:boliler_plate/Constant/app_assets.dart';
import 'package:boliler_plate/Screens/Setting/Controller/setting_controller.dart';
import 'package:boliler_plate/Screens/Setting/Screens/setting_page.dart';
import 'package:boliler_plate/ThemeController/theme_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:boliler_plate/Screens/DiscoverPage/controller_discover_screen.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class GradientCommonAppBar extends StatelessWidget implements PreferredSizeWidget {
  final List<Widget>? actions;
  final Widget? leading;
  final bool? showBackButton;
  final bool? isCenterTitle;
  final bool? isActionWidget;
  final bool? isNotificationShow;
  final Color? backButtonColor;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onSettingsTap;

  GradientCommonAppBar({
    super.key,
    this.actions,
    this.leading,
    this.showBackButton = false,
    this.isCenterTitle = false,
    this.isActionWidget = true,
    this.isNotificationShow = true,
    this.backButtonColor,
    this.onNotificationTap,
    this.onSettingsTap,
  });

  final ThemeController themeController = Get.find<ThemeController>();
  final SettingsController settingsController = Get.put(SettingsController());

  @override
  Widget build(BuildContext context) {
    return AppBar(
          backgroundColor: themeController.transparentColor,
          elevation: 0,
          leading: showBackButton == true
              ? IconButton(
            icon: Icon(Icons.arrow_back, color: backButtonColor ?? themeController.lightPinkColor),
            onPressed: () {
              Get.back();
            },
          )
              : SizedBox.shrink(),
          leadingWidth: showBackButton == true ? null : 0,
          centerTitle: isCenterTitle,
          title: Obx(() {
            return Image.asset(
                themeController.isDarkMode.value ? AppAssets.logolight : AppAssets.logodark, width: 160.w, fit: BoxFit.fitWidth);
          }),
          actions: isActionWidget == true
              ? actions ??
              [
                // Replace settings gear with Filters square that opens bottom sheet via a global event
                widthBox(8),
                _FiltersSquare(),
                widthBox(10),
              ]
              : [],
      );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _FiltersSquare extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final ThemeController themeController = Get.find<ThemeController>();
    return GestureDetector(
      onTap: () {
        _showFiltersSheet(context, themeController);
      },
      child: Container(
        width: 36.h,
        height: 36.h,
        decoration: BoxDecoration(
          color: themeController.whiteColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(color: themeController.lightPinkColor.withValues(alpha: 0.35)),
        ),
        child: Icon(Icons.tune, color: themeController.whiteColor, size: 20.sp),
      ),
    );
  }

  void _showFiltersSheet(BuildContext context, ThemeController themeController) {
    if (!Get.isRegistered<DiscoverController>()) return;
    final controller = Get.find<DiscoverController>();
    final intents = ['Casual', 'Serious', 'Just Chatting'];
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        return Obx(() => Container(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          decoration: BoxDecoration(
            color: themeController.blackColor.withValues(alpha: 0.9),
            borderRadius: BorderRadius.vertical(top: Radius.circular(22.r)),
            border: Border.all(color: themeController.lightPinkColor.withValues(alpha: 0.3)),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('Filters', style: TextStyle(color: themeController.whiteColor, fontWeight: FontWeight.w700, fontSize: 16.sp)),
                      Spacer(),
                      TextButton(
                        onPressed: () async {
                          controller.minAge.value = 18;
                          controller.maxAge.value = 99;
                          controller.maxDistanceKm.value = 100;
                          controller.gender.value = 'Everyone';
                          controller.selectedIntents.clear();
                          await controller.saveFilters();
                          await controller.reloadWithFilters();
                        },
                        child: Text('Reset', style: TextStyle(color: themeController.lightPinkColor)),
                      )
                    ],
                  ),
                  SizedBox(height: 8.h),
                  Text('Age range', style: TextStyle(color: themeController.whiteColor.withValues(alpha: 0.8))),
                  RangeSlider(
                    min: 18,
                    max: 99,
                    divisions: 81,
                    values: RangeValues(controller.minAge.value.toDouble(), controller.maxAge.value.toDouble()),
                    onChanged: (v) async {
                      controller.minAge.value = v.start.round();
                      controller.maxAge.value = v.end.round();
                      await controller.saveFilters();
                      await controller.reloadWithFilters();
                    },
                  ),
                  SizedBox(height: 8.h),
                  Text('Distance (km)', style: TextStyle(color: themeController.whiteColor.withValues(alpha: 0.8))),
                  Slider(
                    min: 1,
                    max: 200,
                    divisions: 199,
                    value: controller.maxDistanceKm.value.clamp(1.0, 200.0),
                    onChanged: (v) async {
                      controller.maxDistanceKm.value = v;
                      await controller.saveFilters();
                      await controller.reloadWithFilters();
                    },
                  ),
                  SizedBox(height: 8.h),
                  Text('Gender', style: TextStyle(color: themeController.whiteColor.withValues(alpha: 0.8))),
                  Wrap(
                    spacing: 8.w,
                    children: ['Everyone','Male','Female','Non-binary'].map((g) => ChoiceChip(
                      label: Text(g),
                      selected: controller.gender.value == g,
                      onSelected: (_) async {
                        controller.gender.value = g;
                        await controller.saveFilters();
                        await controller.reloadWithFilters();
                      },
                    )).toList(),
                  ),
                  SizedBox(height: 8.h),
                  Text('Intent', style: TextStyle(color: themeController.whiteColor.withValues(alpha: 0.8))),
                  Wrap(
                    spacing: 8.w,
                    children: intents.map((i) => FilterChip(
                      label: Text(i),
                      selected: controller.selectedIntents.contains(i),
                      onSelected: (sel) async {
                        if (sel) {
                          controller.selectedIntents.add(i);
                        } else {
                          controller.selectedIntents.remove(i);
                        }
                        await controller.saveFilters();
                        await controller.reloadWithFilters();
                      },
                    )).toList(),
                  ),
                  SizedBox(height: 8.h),
                ],
              ),
            ),
          ),
        ));
      },
    );
  }
}
