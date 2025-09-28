import 'package:lovebug/Common/text_constant.dart';
import 'package:lovebug/Common/textfield_constant.dart';
import 'package:lovebug/ThemeController/theme_controller.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

// class CustomDropdown<T> extends StatelessWidget {
//   final List<T> items;
//   final T? selectedValue;
//   final String Function(T) itemLabel;
//   final String hintText;
//   final void Function(T?) onChanged;
//   final double? dropdownHeight;
//   final Color? dropdownColor;
//   final Color? buttonColor;
//
//   const CustomDropdown({
//     Key? key,
//     required this.items,
//     required this.itemLabel,
//     required this.onChanged,
//     required this.hintText,
//     this.selectedValue,
//     this.dropdownHeight,
//     this.dropdownColor,
//     this.buttonColor,
//   }) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       width: double.infinity,
//       // padding: EdgeInsets.symmetric(horizontal: 12.w),
//       child: DropdownButton2<T>(
//         items:
//             items
//                 .map((item) => DropdownMenuItem<T>(value: item, child: Text(itemLabel(item), style: const TextStyle(fontWeight: FontWeight.w500))))
//                 .toList(),
//         value: selectedValue,
//         onChanged: onChanged,
//         dropdownStyleData: DropdownStyleData(
//           maxHeight: dropdownHeight,
//           // width: dropdownWidth,
//           decoration: BoxDecoration(borderRadius: BorderRadius.circular(20.r), color: dropdownColor ?? Colors.white),
//           elevation: 4,
//         ),
//         isExpanded: false,
//         underline: const SizedBox.shrink(),
//         customButton: Container(
//           height: 60,
//           width: double.infinity,
//           padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 16),
//           decoration: BoxDecoration(color: buttonColor ?? Colors.white, borderRadius: BorderRadius.circular(20.r)),
//           alignment: Alignment.centerLeft,
//           child: TextConstant(
//             title: selectedValue != null ? itemLabel(selectedValue!) : hintText,
//             // fontWeight: FontWeight.w500,
//             color: selectedValue != null ? Colors.black : const Color(0xFF787878),
//           ),
//         ),
//       ),
//     );
//   }
// }

class CustomDropdown<T> extends StatelessWidget {
  final List<T> items;
  final T? selectedValue;
  final String Function(T) itemLabel;
  final String hintText;
  final void Function(T?) onChanged;
  final double? dropdownHeight;

  const CustomDropdown({
    Key? key,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
    required this.hintText,
    this.selectedValue,
    this.dropdownHeight,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ThemeController themeController = Get.find();
    final theme = Theme.of(context);

    return SizedBox(
      width: double.infinity,
      child: DropdownButton2<T>(
        items: items
            .map(
              (item) => DropdownMenuItem<T>(
                value: item,
                child: TextConstant(
                  title: itemLabel(item),
                  fontWeight: FontWeight.w500,
                  color: theme.textTheme.bodyMedium?.color,
                ),
              ),
            )
            .toList(),
        value: selectedValue,
        onChanged: onChanged,
        dropdownStyleData: DropdownStyleData(
          maxHeight: dropdownHeight,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20.r),
            color: themeController.isDarkMode.value
                ? const Color(0xFF1E1E1E)
                : themeController.whiteColor,
          ),
          elevation: 4,
        ),
        isExpanded: false,
        underline: const SizedBox.shrink(),
        customButton: Container(
          height: 60,
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 16),
          decoration: BoxDecoration(
            color:
                theme.inputDecorationTheme.fillColor ??
                theme.colorScheme.secondary.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(20.r),
          ),
          alignment: Alignment.centerLeft,
          child: TextConstant(
            title: selectedValue != null ? itemLabel(selectedValue!) : hintText,
            color: selectedValue != null
                ? theme.textTheme.bodyMedium?.color
                : theme.hintColor,
          ),
        ),
      ),
    );
  }
}

class CustomSearchedDropdown<T> extends StatefulWidget {
  final List<T> items;
  final T? selectedValue;
  final String Function(T) itemLabel;
  final String Function(T)? id;
  final String hintText;
  final void Function(T?) onChanged;
  final double? dropdownHeight;
  final Color? dropdownColor;
  final Color? buttonColor;

  const CustomSearchedDropdown({
    super.key,
    required this.items,
    required this.itemLabel,
    this.id,
    required this.onChanged,
    required this.hintText,
    this.selectedValue,
    this.dropdownHeight,
    this.dropdownColor,
    this.buttonColor,
  });

  @override
  State<CustomSearchedDropdown<T>> createState() =>
      _CustomSearchedDropdownState<T>();
}

class _CustomSearchedDropdownState<T> extends State<CustomSearchedDropdown<T>> {
  final TextEditingController searchController = TextEditingController();

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: double.infinity,
      child: DropdownButton2<T>(
        items: widget.items
            .map(
              (item) => DropdownMenuItem<T>(
                value: item,
                child: Row(
                  children: [
                    if (widget.id != null)
                      TextConstant(
                        title: '${widget.id!(item)}. ',
                        fontWeight: FontWeight.w500,
                      ),
                    Expanded(
                      child: TextConstant(
                        title: widget.itemLabel(item),
                        fontWeight: FontWeight.w500,
                        softWrap: true,
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
        value: widget.selectedValue,
        onChanged: widget.onChanged,
        dropdownStyleData: DropdownStyleData(
          maxHeight: widget.dropdownHeight,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            color: widget.dropdownColor ?? Colors.white,
          ),
          elevation: 4,
        ),
        dropdownSearchData: DropdownSearchData(
          searchController: searchController,
          searchInnerWidgetHeight: 0,
          searchInnerWidget: Container(
            // height: 50,
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
            child: TextFieldConstant(
              controller: searchController,
              hintText: 'Search...',
            ),
          ),
          searchMatchFn: (item, searchValue) {
            return widget
                    .itemLabel(item.value!)
                    .toLowerCase()
                    .contains(searchValue.toLowerCase()) ||
                (widget.id != null &&
                    widget.id!(item.value!).toLowerCase().contains(
                      searchValue.toLowerCase(),
                    ));
          },
        ),
        onMenuStateChange: (isOpen) {
          if (!isOpen) {
            searchController.clear();
          }
        },
        isExpanded: false,
        underline: const SizedBox.shrink(),
        customButton: Container(
          height: 60,
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 16),
          decoration: BoxDecoration(
            color:
                theme.inputDecorationTheme.fillColor ??
                theme.colorScheme.secondary.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(20.r),
          ),
          alignment: Alignment.centerLeft,
          child: TextConstant(
            title: widget.selectedValue != null
                ? widget.itemLabel(widget.selectedValue!)
                : widget.hintText,
            color: widget.selectedValue != null
                ? theme.textTheme.bodyMedium?.color
                : theme.hintColor,
          ),
        ),
      ),
    );
  }
}
