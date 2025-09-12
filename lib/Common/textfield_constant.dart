import 'package:boliler_plate/Common/text_constant.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:glass/glass.dart';

import '../ThemeController/theme_controller.dart';

class TextFieldConstant extends StatelessWidget {
  const TextFieldConstant({
    super.key,
    this.onTap,
    this.height,
    this.minLines,
    this.onChanged,
    this.validator,
    this.prefixIcon,
    this.suffixIcon,
    this.suffixIconColor,
    this.suffixOnTap,
    this.prefixOnTap,
    this.maxLines = 1,
    this.hintFontSize,
    this.fontStyle,
    this.keyboardType,
    this.focusedBorder,
    this.enabledBorder,
    this.onFieldSubmit,
    this.contentPadding,
    this.borderColor,
    this.hintFontWeight,
    this.inputFormatters,
    required this.hintText,
    this.isReadOnly = false,
    this.obscureText = false,
    required this.controller,
    this.textAlign = TextAlign.start,
    this.focusNode,
  });

  final int? maxLines;
  final int? minLines;
  final double? height;
  final String hintText;
  final bool isReadOnly;
  final bool obscureText;
  final dynamic suffixIcon;
  final dynamic prefixIcon;
  final TextAlign textAlign;
  final double? hintFontSize;
  final Color? borderColor;
  final Color? suffixIconColor;
  final void Function()? onTap;
  final InputBorder? enabledBorder;
  final InputBorder? focusedBorder;
  final FontWeight? hintFontWeight;
  final FontStyle? fontStyle;
  final VoidCallback? prefixOnTap;
  final VoidCallback? suffixOnTap;
  final EdgeInsets? contentPadding;
  final TextInputType? keyboardType;
  final Function(String)? onChanged;
  final Function(String)? onFieldSubmit;
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final List<TextInputFormatter>? inputFormatters;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    final ThemeController themeController = Get.find<ThemeController>();
    final theme = Theme.of(context);
    return TextFormField(
      onTap: onTap,
      minLines: minLines,
      maxLines: maxLines,
      readOnly: isReadOnly,
      textAlign: textAlign,
      validator: validator,
      onChanged: onChanged,
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      onFieldSubmitted: onFieldSubmit,
      inputFormatters: inputFormatters,
      cursorColor: theme.textSelectionTheme.cursorColor,
      cursorOpacityAnimates: true,
      focusNode: focusNode,
      style: textStyle(fontSize: hintFontSize ?? 14, fontWeight: hintFontWeight, fontStyle: fontStyle ?? FontStyle.normal),
      decoration: InputDecoration(
        filled: false,
        hintText: hintText,
        hintStyle: textStyle(
          fontWeight: hintFontWeight,
          fontSize: hintFontSize ?? 14,
          fontStyle: fontStyle ?? FontStyle.normal,
          color: themeController.greyColor,
        ),
        disabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: borderColor ?? theme.colorScheme.outline),
          borderRadius: BorderRadius.circular(10.r),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: borderColor ?? theme.colorScheme.outline),
          borderRadius: BorderRadius.circular(15.r),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: borderColor ?? theme.colorScheme.outline),
          borderRadius: BorderRadius.circular(15.r),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15.r),
          borderSide: const BorderSide(color: Colors.red, width: 1.0),
        ),
        border: OutlineInputBorder(
          borderSide: BorderSide(color: borderColor ?? themeController.transparentColor),
          borderRadius: BorderRadius.circular(15.r),
        ),
        prefixIcon: prefixIcon != null
            ? (prefixIcon is IconData ? GestureDetector(onTap: prefixOnTap, child: Icon(prefixIcon)) : prefixIcon)
            : null,
        suffixIcon: suffixIcon != null
            ? (suffixIcon is IconData
                  ? GestureDetector(
                      onTap: suffixOnTap,
                      child: Icon(suffixIcon, color: suffixIconColor ?? themeController.whiteColor),
                    )
                  : suffixIcon)
            : null,
      ),
    ).asGlass(clipBorderRadius: BorderRadius.circular(15.r));
  }
}

class TextValidations {
  TextInputFormatter noSpace() {
    return FilteringTextInputFormatter.deny(RegExp(r'[ ]'));
  }

  String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email address.';
    }

    // Regular expression to match valid email addresses
    String pattern =
        r"^(?![.])([a-zA-Z0-9!#$%&'+/=?^_`{|}~-]+(?:\.[a-zA-Z0-9!#$%&'+/=?^_`{|}~-]+)*)@([a-zA-Z0-9-]+\.)+[a-zA-Z]{2,}$";
    RegExp regex = RegExp(pattern);

    // Additional check for consecutive dots
    if (!regex.hasMatch(value) || value.contains('..')) {
      return 'Enter provide a valid email address.';
    }

    return null;
  }

  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 10) {
      return 'Password must be at least 10 characters';
    }
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Password must contain at least one uppercase letter';
    }
    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return 'Password must contain at least one lowercase letter';
    }
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Password must contain at least one number';
    }
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(value)) {
      return 'Password must contain at least one special character';
    }
    return null;
  }
}

class LimitedDoubleInputFormatter extends TextInputFormatter {
  final int maxIntegerDigits;
  final int decimalPlaces;

  LimitedDoubleInputFormatter(this.maxIntegerDigits, {this.decimalPlaces = 2});

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    String newText = newValue.text;

    // Allow empty value
    if (newText.isEmpty) {
      return newValue;
    }

    // Check for valid double input using regex
    final regExp = RegExp(r'^\d*\.?\d*$');
    if (!regExp.hasMatch(newText)) {
      return oldValue;
    }

    // Split integer and decimal parts
    List<String> parts = newText.split('.');
    String integerPart = parts[0];

    // Limit integer digits
    if (integerPart.length > maxIntegerDigits) {
      return oldValue;
    }

    // Limit decimal digits
    if (parts.length > 1 && parts[1].length > decimalPlaces) {
      return oldValue;
    }

    return newValue;
  }
}

class LimitedIntegerInputFormatter extends TextInputFormatter {
  final int maxLength;

  LimitedIntegerInputFormatter(this.maxLength);

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    String newText = newValue.text;

    // Allow empty value
    if (newText.isEmpty) return newValue;

    // Only digits allowed
    if (!RegExp(r'^\d+$').hasMatch(newText)) {
      return oldValue;
    }

    // Limit to maxLength digits
    if (newText.length > maxLength) {
      return oldValue;
    }

    return newValue;
  }
}

class PhoneNumberInputFormatter extends TextInputFormatter {
  final RegExp _allowedRegex = RegExp(r'^[\d\s\-\+\(\)]*$');

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (_allowedRegex.hasMatch(newValue.text)) {
      return newValue;
    }
    return oldValue;
  }
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    return TextEditingValue(text: newValue.text.toUpperCase(), selection: newValue.selection);
  }
}
