import 'package:lovebug/Common/text_constant.dart';
import 'package:lovebug/Common/widget_constant.dart';
import 'package:lovebug/Constant/app_assets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
// Note: standardized to match chat reply bubble (soft pink gradient + outline)

Widget glassyButton({Widget? widget, String? imagePath, Color? imageColor, required String title, void Function()? onTap}) {
  final theme = Theme.of(Get.context!);

  return GestureDetector(
    onTap: onTap,
    child: SizedBox(
      height: 56.h,
      width: Get.width,
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(Get.context!).primaryColorLight.withValues(alpha: 0.12),
              Theme.of(Get.context!).primaryColorDark.withValues(alpha: 0.10),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(
            color: Theme.of(Get.context!).primaryColorLight.withValues(alpha: 0.35),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Theme.of(Get.context!).primaryColorLight.withValues(alpha: 0.10),
              blurRadius: 15,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: widget ?? Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (imagePath != null) ...[
              Image.asset(
                height: 18.h,
                imagePath,
                color: imageColor ?? theme.iconTheme.color,
              ),
              widthBox(10),
            ],
            TextConstant(title: title, fontSize: 14.sp, fontWeight: FontWeight.w700),
          ],
        ),
      ),
    ),
  );
}
