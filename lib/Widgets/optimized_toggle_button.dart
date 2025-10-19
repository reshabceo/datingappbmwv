import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lovebug/ThemeController/theme_controller.dart';

class OptimizedToggleButton extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final bool isBffMode;

  const OptimizedToggleButton({
    super.key,
    required this.label,
    required this.isActive,
    required this.onTap,
    this.isBffMode = false,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeController themeController = Get.find<ThemeController>();
    
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: isActive 
              ? (isBffMode ? themeController.bffPrimaryColor : themeController.lightPinkColor)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: isBffMode 
                ? themeController.bffPrimaryColor.withOpacity(0.3)
                : themeController.lightPinkColor.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isActive 
                  ? Colors.white 
                  : (isBffMode ? themeController.bffPrimaryColor : themeController.lightPinkColor),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
