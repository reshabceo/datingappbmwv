import 'package:boliler_plate/global_data.dart';
import 'package:boliler_plate/shared_prefrence_helper.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class Language {
  final int id;
  final String flag;
  final String name;
  final String languageCode;

  Language(this.id, this.flag, this.name, this.languageCode);

  static List<Language> languageList = <Language>[
    Language(0, "🇺🇸", "English", "en"),
    Language(1, "🇮🇳", "Hindi", "hi"),
    Language(2, "🇦🇪", "Arabic", "ar"),
    Language(3, "🇩🇪", "German", "de"),
  ];
}

/// set Locale Language
Future setLocale(String languageCode, String languageName) async {
  await SharedPreferenceHelper.setString(
    SharedPreferenceHelper.languageCode,
    languageCode,
  );
  await SharedPreferenceHelper.setString(
    SharedPreferenceHelper.languageName,
    languageName,
  );
  Get.updateLocale(Locale(languageCode));
  lanCode.value = SharedPreferenceHelper.getString(
    SharedPreferenceHelper.languageCode,
  );
  lanName.value = SharedPreferenceHelper.getString(
    SharedPreferenceHelper.languageName,
  );
}
