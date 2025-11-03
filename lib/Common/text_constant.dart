import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
// Using app-wide theme font; no direct GoogleFonts here so the global font applies

class TextConstant extends StatelessWidget {
  const TextConstant({
    required this.title,
    this.fontWeight,
    this.fontSize,
    this.color,
    this.overflow,
    super.key,
    this.textAlign,
    this.maxLines,
    this.height,
    this.textDecoration,
    this.decorationColor,
    this.softWrap = false,
    this.fontStyle,
  });

  final FontWeight? fontWeight;
  final double? fontSize;
  final Color? color;
  final String title;
  final TextOverflow? overflow;
  final TextAlign? textAlign;
  final int? maxLines;
  final double? height;
  final TextDecoration? textDecoration;
  final Color? decorationColor;
  final bool softWrap;
  final FontStyle? fontStyle;

  @override
  Widget build(BuildContext context) {
    // Accessing theme's color scheme to adapt text color as per the theme
    final theme = Theme.of(context);
    final Color defaultColor = theme.colorScheme.onSurface;

    // If title contains a translation key (no spaces and looks like a key), use .tr
    // Otherwise, if it's a direct translation key, use .tr
    String displayText = title;
    // Check if it's a translation key (contains underscore and all lowercase or matches known keys)
    if (title.contains('_') || title == title.toLowerCase() || 
        (title.length > 0 && title[0] == title[0].toLowerCase() && !title.contains(' '))) {
      try {
        displayText = title.tr;
      } catch (e) {
        // If translation fails, use original title
        displayText = title;
      }
    }
    
    return Text(
      displayText,
      overflow: overflow ?? TextOverflow.visible,
      textAlign: textAlign,
      softWrap: softWrap ?? true, // Default to true to allow soft wrapping to prevent truncation
      style: textStyle(
        height: height,
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color ?? defaultColor,
        textDecoration: textDecoration,
        decorationColor: decorationColor,
        fontStyle: fontStyle,
      ),
      maxLines: maxLines, // null means unlimited lines
    );
  }
}

TextStyle textStyle({
  Color? color,
  double? height,
  double? fontSize,
  Color? decorationColor,
  FontWeight? fontWeight,
  FontStyle? fontStyle,
  TextDecoration? textDecoration,
}) {
  return TextStyle(
    color: color,
    height: height ?? 0,
    decoration: textDecoration,
    decorationColor: decorationColor,
    fontStyle: fontStyle ?? FontStyle.normal,
    fontWeight: fontWeight ?? FontWeight.normal,
    fontSize: fontSize != null ? fontSize.sp : 14.sp,
  );
}
