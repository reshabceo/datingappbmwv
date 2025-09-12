import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:boliler_plate/Common/text_constant.dart';
import 'package:boliler_plate/ThemeController/theme_controller.dart';

class AccountSettingsScreen extends StatelessWidget {
  AccountSettingsScreen({super.key});
  final ThemeController theme = Get.find<ThemeController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: TextConstant(title: 'Account', color: theme.whiteColor), backgroundColor: theme.blackColor),
      backgroundColor: theme.blackColor,
      body: ListView(
        children: [
          ListTile(
            title: TextConstant(title: 'Change email', color: theme.whiteColor),
            onTap: () {},
          ),
          ListTile(
            title: TextConstant(title: 'Change password', color: theme.whiteColor),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}
