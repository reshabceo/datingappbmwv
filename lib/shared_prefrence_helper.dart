
import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferenceHelper {
  static late SharedPreferences _preferences;

  static String userId = 'userId';
  static String languageCode = 'languageCode';
  static String languageName = 'languageName';

  // Initialize SharedPreferences once
  static Future<void> init() async {
    _preferences = await SharedPreferences.getInstance();
  }

  // Set a boolean value
  static Future<void> setBool(String key, bool value) async {
    await _preferences.setBool(key, value);
  }

  // Get a boolean value
  static bool getBool(String key, {bool defaultValue = false}) {
    return _preferences.getBool(key) ?? defaultValue;
  }

  // Set a string value
  static Future<void> setString(String key, String value) async {
    await _preferences.setString(key, value);
  }

  // Get a string value
  static String getString(String key, {String defaultValue = ''}) {
    return _preferences.getString(key) ?? defaultValue;
  }

  // Set an integer value
  static Future<void> setInt(String key, int value) async {
    await _preferences.setInt(key, value);
  }

  // Get an integer value
  static int getInt(String key, {int defaultValue = 0}) {
    return _preferences.getInt(key) ?? defaultValue;
  }

  // Set a list of strings
  static Future<void> setStringList(String key, List<String> value) async {
    await _preferences.setStringList(key, value);
  }

  // Get a list of strings
  static List<String> getStringList(
    String key, {
    List<String> defaultValue = const [],
  }) {
    return _preferences.getStringList(key) ?? defaultValue;
  }

  // Remove a key-value pair
  static Future<void> remove(String key) async {
    await _preferences.remove(key);
  }

  // Clear all data
  static Future<void> clearAll() async {
    await _preferences.clear();
  }
}
