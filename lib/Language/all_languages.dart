import 'package:get/get.dart';
import 'language_map/ar_sa.dart';
import 'language_map/de_gr.dart';
import 'language_map/en_us.dart';
import 'language_map/hi_in.dart';

class AppTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
    'en': enUS,
    'hi': hiIN,
    'ar': arSA,
    'de': deGR,
  };
}
