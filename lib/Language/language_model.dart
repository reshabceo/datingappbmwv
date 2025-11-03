import 'package:lovebug/global_data.dart';
import 'package:lovebug/shared_prefrence_helper.dart';
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
  print('🌍 DEBUG: setLocale called with code: $languageCode, name: $languageName');
  
  // Save to SharedPreferences first
  await SharedPreferenceHelper.setString(
    SharedPreferenceHelper.languageCode,
    languageCode,
  );
  await SharedPreferenceHelper.setString(
    SharedPreferenceHelper.languageName,
    languageName,
  );
  
  // Update reactive values AFTER saving to trigger UI rebuilds
  lanCode.value = languageCode;
  lanName.value = languageName;
  
  // Update GetX locale - this should trigger UI rebuild for all .tr calls
  Get.updateLocale(Locale(languageCode));
  
  // Force rebuild of GetMaterialApp by updating the locale again
  // This ensures all widgets using .tr are rebuilt
  await Future.delayed(Duration(milliseconds: 100));
  Get.updateLocale(Locale(languageCode));
  
  print('🌍 DEBUG: Locale updated to: $languageCode');
  print('🌍 DEBUG: Current Get.locale: ${Get.locale}');
}
