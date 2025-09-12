import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:boliler_plate/Common/text_constant.dart';
import 'package:boliler_plate/ThemeController/theme_controller.dart';

class BlockedUsersScreen extends StatelessWidget {
  BlockedUsersScreen({super.key});
  final ThemeController theme = Get.find<ThemeController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: TextConstant(title: 'Blocked users', color: theme.whiteColor), backgroundColor: theme.blackColor),
      backgroundColor: theme.blackColor,
      body: Center(
        child: TextConstant(title: 'No blocked users', color: theme.whiteColor),
      ),
    );
  }
}
