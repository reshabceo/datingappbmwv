// import 'package:dropdown_button2/dropdown_button2.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:get/get.dart';
// import 'package:inventory/utils/commons/text_constant.dart';
// import 'package:inventory/utils/theme_controller.dart';
//
// class CustomDropdown extends StatelessWidget {
//   final List<String> items;
//   final String? selectedValue;
//   final String hintText;
//   final ValueChanged<String>? onChanged;
//   final double buttonHeight;
//   final double borderRadius;
//   final Color? textColor;
//   final Color? iconColor;
//   final Color? borderColor;
//
//   CustomDropdown({
//     Key? key,
//     required this.items,
//     this.selectedValue,
//     required this.hintText,
//     this.onChanged,
//     this.buttonHeight = 56,
//     this.borderRadius = 20,
//     this.textColor,
//     this.iconColor,
//     this.borderColor,
//   }) : super(key: key);
//
//   final ThemeController themeController = Get.find<ThemeController>();
//
//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//     final Color effectiveIconColor = iconColor ?? theme.iconTheme.color ?? theme.primaryColor;
//     final Color effectiveBorderColor = borderColor ?? Colors.transparent;
//
//     return DropdownButtonHideUnderline(
//       child: DropdownButton2<String>(
//         isExpanded: true,
//         value: selectedValue,
//         hint: TextConstant(title: hintText, fontWeight: FontWeight.w500),
//         items:
//             items.map((String item) {
//               return DropdownMenuItem<String>(value: item, child: TextConstant(title: item));
//             }).toList(),
//         onChanged: (newValue) {
//           if (newValue != null && onChanged != null) {
//             onChanged!(newValue);
//           }
//         },
//         buttonStyleData: ButtonStyleData(
//           height: buttonHeight,
//           padding: EdgeInsets.only(left: 5.w, right: 16.w),
//           decoration: BoxDecoration(
//             color: themeController.currentSecondaryColour,
//             border: Border.all(color: effectiveBorderColor),
//             borderRadius: BorderRadius.circular(borderRadius),
//           ),
//         ),
//         iconStyleData: IconStyleData(icon: Icon(Icons.arrow_drop_down, color: effectiveIconColor)),
//         dropdownStyleData: DropdownStyleData(
//           openInterval: const Interval(0.0, 1.0, curve: Curves.decelerate),
//           decoration: BoxDecoration(
//             color: themeController.isDarkMode.value ? const Color(0xFF1E1E1E) : themeController.whiteColor,
//             border: Border.all(color: effectiveBorderColor),
//             borderRadius: BorderRadius.circular(borderRadius),
//           ),
//         ),
//       ),
//     );
//   }
// }

import 'package:boliler_plate/Common/text_constant.dart';
import 'package:boliler_plate/ThemeController/theme_controller.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

class CustomDropdown<T> extends StatelessWidget {
  final List<T> items;
  final T? selectedValue;
  final String hintText;
  final ValueChanged<T>? onChanged;
  final String Function(T) displayBuilder; // <-- For display text
  final double buttonHeight;
  final double borderRadius;
  final Color? textColor;
  final Color? iconColor;
  final Color? borderColor;

  CustomDropdown({
    super.key,
    required this.items,
    this.selectedValue,
    required this.hintText,
    required this.displayBuilder,
    this.onChanged,
    this.buttonHeight = 56,
    this.borderRadius = 20,
    this.textColor,
    this.iconColor,
    this.borderColor,
  });

  final ThemeController themeController = Get.find<ThemeController>();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Color effectiveIconColor =
        iconColor ?? theme.iconTheme.color ?? theme.primaryColor;
    final Color effectiveBorderColor = borderColor ?? Colors.transparent;

    return DropdownButtonHideUnderline(
      child: DropdownButton2<T>(
        isExpanded: true,
        value: selectedValue,
        hint: TextConstant(title: hintText, fontWeight: FontWeight.w500),
        items: items.map((T item) {
          return DropdownMenuItem<T>(
            value: item,
            child: TextConstant(
              title: displayBuilder(item),
            ), // Display property you choose
          );
        }).toList(),
        onChanged: (newValue) {
          if (newValue != null && onChanged != null) {
            onChanged!(newValue);
          }
        },
        buttonStyleData: ButtonStyleData(
          height: buttonHeight,
          padding: EdgeInsets.only(left: 5.w, right: 16.w),
          decoration: BoxDecoration(
            color: themeController.currentSecondaryColour,
            border: Border.all(color: effectiveBorderColor),
            borderRadius: BorderRadius.circular(borderRadius),
          ),
        ),
        iconStyleData: IconStyleData(
          icon: Icon(Icons.arrow_drop_down, color: effectiveIconColor),
        ),
        dropdownStyleData: DropdownStyleData(
          openInterval: const Interval(0.0, 1.0, curve: Curves.decelerate),
          decoration: BoxDecoration(
            color: themeController.isDarkMode.value
                ? const Color(0xFF1E1E1E)
                : themeController.whiteColor,
            border: Border.all(color: effectiveBorderColor),
            borderRadius: BorderRadius.circular(borderRadius),
          ),
        ),
      ),
    );
  }
}
