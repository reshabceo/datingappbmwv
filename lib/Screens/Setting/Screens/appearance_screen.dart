import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lovebug/Common/text_constant.dart';
import 'package:lovebug/ThemeController/theme_controller.dart';

class AppearanceSettingsScreen extends StatelessWidget {
  AppearanceSettingsScreen({super.key});
  final ThemeController theme = Get.find<ThemeController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: TextConstant(title: 'Appearance', color: theme.whiteColor), backgroundColor: theme.blackColor),
      backgroundColor: theme.blackColor,
      body: ListView(
        children: [
          SwitchListTile(
            value: theme.isDarkMode.value,
            onChanged: (v) => theme.toggleTheme(),
            title: TextConstant(title: 'Dark mode', color: theme.whiteColor),
          ),
        ],
      ),
    );
  }
}
