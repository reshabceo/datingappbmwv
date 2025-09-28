import 'package:get/get.dart';
import 'package:lovebug/Constant/app_assets.dart';

class SettingsController extends GetxController {

  RxBool isOn = false.obs;

  final settingsList = <SettingItem>[
    SettingItem(title: 'account_settings'.tr, icon: AppAssets.accountSvg),
    SettingItem(title: 'privacy'.tr, icon: AppAssets.privacySvg),
    SettingItem(title: 'notifications'.tr, icon: AppAssets.notificationSvg),
    SettingItem(title: 'appearance'.tr, icon: AppAssets.appearanceSvg),
    SettingItem(title: 'blocked_users'.tr, icon: AppAssets.blockSvg),
    SettingItem(title: 'help_support'.tr, icon: AppAssets.helpSvg),
    SettingItem(title: 'logout'.tr, icon: AppAssets.logoutSvg),
  ];
}

class SettingItem {
  final String title;
  final String icon;

  SettingItem({required this.title, required this.icon});
}
