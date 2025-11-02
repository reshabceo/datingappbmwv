import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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

    return Text(
      title,
      overflow: overflow,
      textAlign: textAlign,
      softWrap: softWrap,
      style: textStyle(
        height: height,
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color ?? defaultColor,
        textDecoration: textDecoration,
        decorationColor: decorationColor,
        fontStyle: fontStyle,
      ),
      maxLines: maxLines,
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
