import 'package:auto_size_text/auto_size_text.dart';
import 'package:boliler_plate/Common/text_constant.dart';
import 'package:boliler_plate/ThemeController/theme_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:omni_datetime_picker/omni_datetime_picker.dart';

enum Processing { done, waiting, error }

Widget screenPadding({EdgeInsets? customPadding, required Widget child}) {
  return Padding(
    padding: customPadding ?? EdgeInsets.symmetric(horizontal: 15.w),
    child: child,
  );
}

SizedBox heightBox(int height) {
  return SizedBox(height: height.h);
}

SizedBox widthBox(int width) {
  return SizedBox(width: width.h);
}

Widget svgIconWidget({required String icon, Color? color, double height = 35, double width = 35, BoxFit? fit}) {
  return SvgPicture.asset(
    icon,
    height: height.h,
    width: width.h,
    fit: fit ?? BoxFit.cover,
    colorFilter: ColorFilter.mode(color ?? Colors.white, BlendMode.srcIn),
  );
}

Widget elevatedButton({
  double? width,
  double? height,
  double? fontSize,
  Color? textColor,
  Color? backGroundColor,
  bool? isGradient = true,
  bool? isBorder = false,
  required String title,
  Gradient? gradient,
  EdgeInsetsGeometry? padding,
  List<Color>? colorsGradient,
  double? borderRadius,
  required void Function()? onPressed,
}) {
  ThemeController themeController = Get.find<ThemeController>();

  // fallback gradient if none supplied
  final Gradient fallbackGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: colorsGradient ?? [themeController.lightPinkColor, themeController.purpleColor],
  );

  return SizedBox(
    height: height ?? 50.h,
    width: width ?? Get.width,
    child: DecoratedBox(
      decoration: isGradient == true
          ? BoxDecoration(
              gradient: gradient ?? fallbackGradient,
              borderRadius: BorderRadius.circular((borderRadius ?? 4).r),
            )
          : BoxDecoration(
        border: isBorder == true ? Border.all(color: themeController.purpleColor.withValues(alpha: 0.5), width: 1.w) : null,
        color: backGroundColor ?? themeController.greyColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular((borderRadius ?? 4).r),
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ButtonStyle(
          // make the ElevatedButton itself transparent
          backgroundColor: WidgetStatePropertyAll(Colors.transparent),
          shadowColor: WidgetStatePropertyAll(Colors.transparent),
          elevation: WidgetStatePropertyAll(0),
          padding: padding != null ? WidgetStatePropertyAll(padding) : null,
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular((borderRadius ?? 4).r)),
          ),
        ),
        child: TextConstant(title: title, color: textColor, fontSize: fontSize ?? 16, fontWeight: FontWeight.w500),
      ),
    ),
  );
}

Widget elevatedButton2({
  double? width,
  double? height,
  double? fontSize,
  Color? textColor,
  required IconData icon,
  Color? backGroundColor,
  Color? iconColor,
  Color? borderColor,
  bool? isGradient = true,
  required String title,
  Gradient? gradient,
  EdgeInsetsGeometry? padding,
  List<Color>? colorsGradient,
  required void Function()? onPressed,
}) {
  ThemeController themeController = Get.find<ThemeController>();

  // fallback gradient if none supplied
  final Gradient fallbackGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors:
    colorsGradient ??
        [themeController.lightPinkColor.withValues(alpha: 0.2), themeController.purpleColor.withValues(alpha: 0.2)],
  );

  return SizedBox(
    height: height ?? 50.h,
    width: width ?? Get.width,
    child: DecoratedBox(
      decoration: isGradient == true
          ? BoxDecoration(
        gradient: gradient ?? fallbackGradient,
        border: Border.all(color: borderColor ?? themeController.purpleColor.withValues(alpha: 0.4), width: 1.w),
        borderRadius: BorderRadius.circular(4.r),
      )
          : BoxDecoration(
        border: Border.all(color: themeController.purpleColor.withValues(alpha: 0.4), width: 1.w),
        color: backGroundColor ?? themeController.greyColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4.r),
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ButtonStyle(
          // make the ElevatedButton itself transparent
          backgroundColor: WidgetStatePropertyAll(Colors.transparent),
          shadowColor: WidgetStatePropertyAll(Colors.transparent),
          elevation: WidgetStatePropertyAll(0),
          padding: padding != null ? WidgetStatePropertyAll(padding) : null,
          shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(4.r))),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 8.w,
          children: [
            Obx(() {
              return Icon(icon, size: 16.sp,
                  color: iconColor ??
                      (themeController.isDarkMode.value ? themeController.whiteColor : themeController.blackColor));
            }),
            TextConstant(title: title, color: textColor, fontSize: fontSize ?? 16, fontWeight: FontWeight.w500),
          ],
        ),
      ),
    ),
  );
}

Widget backButton() {
  return GestureDetector(
    onTap: () {
      Get.back();
    },
    child: Icon(size: 28, LucideIcons.chevronLeft),
  );
}

AppBar commonAppbar({
  required String title,
  bool isLeadingEnable = true,
  List<Widget>? actionWidget,
  Widget? leadingWidget,
  PreferredSizeWidget? bottom,
  double? toolbarHeight,
  Color? backgroundColor,
  Color? titleColor,
  double? titleSpacing,
  double? elevation,
  isCenterTitle = true,
  required ThemeController themeController,
}) {
  return AppBar(
    centerTitle: isCenterTitle,
    surfaceTintColor: Colors.transparent,
    backgroundColor: backgroundColor,
    scrolledUnderElevation: 0.0,
    automaticallyImplyLeading: false,
    toolbarHeight: toolbarHeight,
    titleSpacing: titleSpacing,
    bottom: bottom,
    elevation: elevation,
    title: TextConstant(title: title, fontSize: 18, fontWeight: FontWeight.bold, color: titleColor),
    actions: actionWidget,
    leading: isLeadingEnable ? leadingWidget ?? backButton() : null,
  );
}

Widget slidAbleActions({
  required Widget child,
  required ThemeController themeController,
  IconData? startIcon,
  IconData? endIcon,
  Color? startBackgroundColor,
  Color? endBackgroundColor,
  Future<bool> Function()? onStartDismiss,
  Future<bool> Function()? onEndDismiss,
}) {
  return Slidable(
    key: UniqueKey(),
    closeOnScroll: true,
    startActionPane: onStartDismiss != null
        ? ActionPane(
      motion: const BehindMotion(),
      dragDismissible: true,
      extentRatio: 0.01,
      dismissible: DismissiblePane(
        key: UniqueKey(),
        confirmDismiss: onStartDismiss,
        dismissThreshold: 0.25,
        closeOnCancel: true,
        onDismissed: () {},
      ),
      children: [
        CustomSlidableAction(
          backgroundColor: Colors.transparent,
          onPressed: (context) {},
          padding: EdgeInsets.zero,
          child: Container(
            margin: EdgeInsets.symmetric(vertical: 4.h),
            decoration: BoxDecoration(
              color: startBackgroundColor,
              borderRadius: BorderRadius.only(topLeft: Radius.circular(12.r), bottomLeft: Radius.circular(12.r)),
            ),
            alignment: Alignment.center,
            child: Icon(startIcon, color: themeController.whiteColor),
          ),
        ),
      ],
    )
        : null,
    endActionPane: onEndDismiss != null
        ? ActionPane(
      motion: const BehindMotion(),
      dragDismissible: true,
      extentRatio: 0.01,
      dismissible: DismissiblePane(
        key: UniqueKey(),
        confirmDismiss: onEndDismiss,
        dismissThreshold: 0.25,
        closeOnCancel: true,
        onDismissed: onEndDismiss,
      ),
      children: [
        CustomSlidableAction(
          backgroundColor: Colors.transparent,
          onPressed: (context) {},
          padding: EdgeInsets.zero,
          child: Container(
            margin: EdgeInsets.symmetric(vertical: 4.h),
            decoration: BoxDecoration(
              color: endBackgroundColor,
              borderRadius: BorderRadius.only(topRight: Radius.circular(12.r), bottomRight: Radius.circular(12.r)),
            ),
            alignment: Alignment.center,
            child: Icon(endIcon, color: themeController.whiteColor),
          ),
        ),
      ],
    )
        : null,
    child: child,
  );
}

Future<DateTime?> pickDateTime(BuildContext context, {bool pickTime = false, DateTime? initialDate}) async {
  DateTime? selectedDate = await showOmniDateTimePicker(
    context: context,
    initialDate: initialDate ?? DateTime.now(),
    firstDate: DateTime(1600).subtract(const Duration(days: 3652)),
    lastDate: DateTime(2100),
    is24HourMode: false,
    isShowSeconds: false,
    minutesInterval: 1,
    secondsInterval: 1,
    borderRadius: const BorderRadius.all(Radius.circular(16)),
    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
    constraints: const BoxConstraints(maxWidth: 350, maxHeight: 650),
    type: pickTime ? OmniDateTimePickerType.time : OmniDateTimePickerType.date,
    transitionBuilder: (context, anim1, anim2, child) {
      return FadeTransition(opacity: anim1.drive(Tween(begin: 0, end: 1)), child: child);
    },
    transitionDuration: const Duration(milliseconds: 200),
    barrierDismissible: true,
  );
  return selectedDate;
}

Widget loader({required ThemeController themeController, double? size, double? strokeWidth, Color? color}) {
  return Container(
    alignment: Alignment.center,
    height: size ?? 40.w,
    width: size ?? 40.w,
    child: CircularProgressIndicator.adaptive(
      strokeWidth: strokeWidth ?? 5.w,
      valueColor: AlwaysStoppedAnimation<Color>(color ?? themeController.primaryColor.value),
    ),
  );
}

Future<void> showConfirmationDialogue({
  required ThemeController themeController,
  required String title,
  required dynamic description,
  required String buttonText,
  Color? buttonColor,
  bool oneOption = false,
  required void Function()? onPressedAction,
  Rx<Processing>? isProcessing,
}) async {
  await Get.dialog(
    Dialog(
      alignment: Alignment.center,
      insetPadding: EdgeInsets.symmetric(horizontal: 20.w),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.r), // Rounded corners
      ),
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextConstant(title: title,
                fontWeight: FontWeight.bold,
                textAlign: TextAlign.center,
                fontSize: 16,
                softWrap: true),
            heightBox(16),
            if (description is String) TextConstant(title: description, softWrap: true, textAlign: TextAlign.center),
            if (description is Widget) description,
            heightBox(24),
            Obx(() {
              return AnimatedSwitcher(
                duration: Duration(milliseconds: 500),
                child: isProcessing != null && isProcessing.value == Processing.waiting
                    ? loader(themeController: themeController)
                    : Row(
                  spacing: 24.w,
                  children: [
                    if (!oneOption)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Get.back();
                          },
                          style: ButtonStyle(
                            fixedSize: WidgetStatePropertyAll(Size(Get.width, 46.h)),
                            side: WidgetStatePropertyAll(BorderSide(color: themeController.primaryColor.value)),
                            shape: WidgetStatePropertyAll(
                              RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15.0), // Adjust the radius here for rounded corners
                              ),
                            ),
                          ),
                          child: TextConstant(title: 'Cancel', fontWeight: FontWeight.w500),
                        ),
                      ),
                    Expanded(
                      child: elevatedButton(
                        height: 46.h,
                        fontSize: 14,
                        // backgroundColor: buttonColor,
                        title: buttonText,
                        onPressed: onPressedAction,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    ),
  );
}

Future showCustomDialog({required Widget child}) {
  return Get.dialog(Dialog(backgroundColor: Colors.transparent, child: child));
}

showCustomSnackBar({String? title, String? message}) {
  Get.snackbar(title!, message!);
}

AutoSizeText autoSizeText(String text, {FontWeight? fontWeight, int? maxLine, double? maxFontSize, Color? color}) {
  return AutoSizeText(
    text,
    style: textStyle(fontWeight: fontWeight ?? FontWeight.bold, color: color),
    maxFontSize: maxFontSize ?? 14,
    presetFontSizes: const [16, 15, 14, 13, 12, 11],
    minFontSize: 11,
    stepGranularity: 1,
    maxLines: maxLine ?? 1,
    overflow: TextOverflow.ellipsis,
  );
}

Future showCustomBottomSheet(ThemeController themeController, {
  required String title,
  required List<Widget> children,
  double? fontSize,
  bool isDismissibleBox = true,
}) async {
  await showModalBottomSheet(
    context: Get.context!,
    builder: (context) {
      return Padding(
        padding: MediaQuery
            .of(context)
            .viewInsets,
        child: screenPadding(
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.only(bottom: 15.h, left: 16.w, right: 16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextConstant(title: title, fontWeight: FontWeight.bold, fontSize: fontSize),
                      // IconButton(
                      //     onPressed: () {
                      //       Get.back();
                      //     },
                      //     icon: Icon(LucideIcons.x))
                    ],
                  ),
                  ...children,
                ],
              ),
            ),
          ),
        ),
      );
    },
    isScrollControlled: true,
    isDismissible: isDismissibleBox,
    showDragHandle: isDismissibleBox,
    enableDrag: isDismissibleBox,
    backgroundColor: themeController.greyColor,
  );
}

showImagePickerSheet({
  required ThemeController themeController,
  required VoidCallback onTapCamera,
  required VoidCallback onTapGallery,
}) {
  Get.bottomSheet(
    Obx(() {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: themeController.isDarkMode.value ? themeController.blackColor : themeController.whiteColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextConstant(title: 'choose_image'.tr, fontSize: 18, fontWeight: FontWeight.bold),
            heightBox(20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: elevatedButton(
                    title: 'Camera',
                    width: MediaQuery
                        .sizeOf(Get.context!)
                        .width,
                    textColor: themeController.whiteColor,

                    onPressed: onTapCamera,
                  ),
                ),
                widthBox(20),
                Expanded(
                  child: elevatedButton(
                    title: 'Gallery',
                    width: MediaQuery
                        .sizeOf(Get.context!)
                        .width,
                    textColor: themeController.whiteColor,
                    onPressed: onTapGallery,
                  ),
                ),
              ],
            ),
            heightBox(20),
          ],
        ),
      );
    }),
  );
}

class ButtonSquare extends StatelessWidget {
  final VoidCallback? onTap;
  final double? height;
  final double? width;
  final Color? backgroundColor;
  final Color? iconColor;
  final Color? borderColor;
  final double? borderRadius;
  final double? iconSize;
  final IconData? icon;
  final bool isCircular;

  const ButtonSquare({
    Key? key,
    this.onTap,
    this.height,
    this.width,
    this.backgroundColor,
    this.iconColor,
    this.borderColor,
    this.borderRadius,
    this.iconSize,
    this.icon,
    this.isCircular = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width?.w ?? 56.w,
        height: height?.h ?? 56.h,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: backgroundColor ?? Colors.transparent,
          borderRadius: BorderRadius.circular(
            isCircular ? (width?.w ?? 56.w) / 2 : (borderRadius ?? 5.r)
          ),
          border: Border.all(
            color: borderColor ?? Colors.transparent, 
            width: 2.w
          ),
          boxShadow: [
            BoxShadow(
              color: (backgroundColor ?? Colors.transparent).withValues(alpha: 0.3),
              blurRadius: 15.r,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Center(
          child: Icon(icon, color: iconColor, size: iconSize?.sp ?? 30.sp),
        ),
      ),
    );
  }
}

class ProfileAvatar extends StatelessWidget {
  final String imageUrl;
  final double? size;
  final Color? borderColor;
  final double? borderWidth;

  ProfileAvatar({super.key, required this.imageUrl, this.size, this.borderColor, this.borderWidth});

  final ThemeController themeController = Get.find<ThemeController>();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size?.h ?? 30.h,
      height: size?.w ?? 30.w,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: borderColor ?? themeController.lightPinkColor, width: borderWidth?.w ?? 1.w),
      ),
      child: ClipOval(
        child: Image.network(imageUrl, fit: BoxFit.cover, width: size?.h ?? 30.h, height: size?.w ?? 30.w),
      ),
    );
  }
}

class CustomBottomSheet {
  static void show({
    required Widget child,
    bool isDismissible = true,
    bool enableDrag = true,
    Color? backgroundColor,
    double? borderRadius = 20,
    double? height,
    required String title,
  }) {
    showModalBottomSheet(
      context: Get.context!,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery
              .of(Get.context!)
              .viewInsets
              .bottom),
          child: DraggableScrollableSheet(
            expand: false,
            minChildSize: height ?? 0.3,
            maxChildSize: height ?? 0.9,
            initialChildSize: height ?? 0.5,
            builder: (context, scrollController) {
              return Container(
                padding: EdgeInsets.only(top: 12.h, left: 20.w, right: 20.w),
                decoration: BoxDecoration(
                  color: backgroundColor ?? Theme
                      .of(Get.context!)
                      .scaffoldBackgroundColor,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(borderRadius ?? 20)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 0.w),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: TextConstant(
                              title: title,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          CircleAvatar(
                            radius: 15.r,
                            backgroundColor: Theme
                                .of(Get.context!)
                                .iconTheme
                                .color!
                                .withValues(alpha: 0.4),
                            child: InkWell(
                              onTap: () => Get.back(),
                              child: Icon(size: 15.sp, Icons.close),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(controller: scrollController, child: child),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}
