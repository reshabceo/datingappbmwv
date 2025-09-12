import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:boliler_plate/Common/text_constant.dart';
import 'package:boliler_plate/ThemeController/theme_controller.dart';

class NotificationsSettingsScreen extends StatelessWidget {
  NotificationsSettingsScreen({super.key});
  final ThemeController theme = Get.find<ThemeController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: TextConstant(title: 'Notifications', color: theme.whiteColor), backgroundColor: theme.blackColor),
      backgroundColor: theme.blackColor,
      body: ListView(
        children: [
          SwitchListTile(
            value: true,
            onChanged: (_) {},
            title: TextConstant(title: 'Matches', color: theme.whiteColor),
          ),
          SwitchListTile(
            value: true,
            onChanged: (_) {},
            title: TextConstant(title: 'Messages', color: theme.whiteColor),
          ),
          SwitchListTile(
            value: true,
            onChanged: (_) {},
            title: TextConstant(title: 'Stories', color: theme.whiteColor),
          ),
        ],
      ),
    );
  }
}
