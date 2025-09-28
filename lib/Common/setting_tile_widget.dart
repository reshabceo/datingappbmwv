import 'package:lovebug/Common/text_constant.dart';
import 'package:lovebug/Common/widget_constant.dart';
import 'package:lovebug/ThemeController/theme_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';

Widget buildMenuItem({required String title, required String icon, required int index}) {
  final ThemeController themeController = Get.find<ThemeController>();
  return Material(
    color: Colors.transparent,
    child: Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        children: [
          Container(
            width: 35.w,
            height: 35.h,
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(shape: BoxShape.circle, color: themeController.whiteColor.withValues(alpha: 0.1)),
            child: SvgPicture.asset(icon),
          ),
          widthBox(18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextConstant(title: title, fontSize: 14.sp, fontWeight: FontWeight.w400),
              ],
            ),
          ),
          index == 3
              ? Obx(() {
                  return Switch.adaptive(
                    value: themeController.isDarkMode.value,
                    onChanged: (v) async {
                      themeController.toggleTheme();
                    },
                    trackOutlineWidth: WidgetStatePropertyAll(0.1),
                    activeTrackColor: themeController.purpleColor.withValues(alpha: 0.3),
                    inactiveTrackColor: themeController.greyColor.withValues(alpha: 0.3),
                    thumbColor: themeController.isDarkMode.value
                        ? WidgetStateProperty.all(themeController.purpleColor)
                        : WidgetStateProperty.all(themeController.whiteColor.withValues(alpha: 0.7)),
                  );
                })
              : Icon(size: 18, Icons.arrow_forward_ios),
        ],
      ),
    ),
  );
}
