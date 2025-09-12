import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:boliler_plate/Common/text_constant.dart';
import 'package:boliler_plate/ThemeController/theme_controller.dart';

class PrivacySettingsScreen extends StatelessWidget {
  PrivacySettingsScreen({super.key});
  final ThemeController theme = Get.find<ThemeController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: TextConstant(title: 'Privacy', color: theme.whiteColor), backgroundColor: theme.blackColor),
      backgroundColor: theme.blackColor,
      body: ListView(
        children: [
          SwitchListTile(
            value: true,
            onChanged: (_) {},
            title: TextConstant(title: 'Show age', color: theme.whiteColor),
          ),
          SwitchListTile(
            value: true,
            onChanged: (_) {},
            title: TextConstant(title: 'Show distance', color: theme.whiteColor),
          ),
        ],
      ),
    );
  }
}
