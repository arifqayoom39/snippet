import 'package:shared_preferences/shared_preferences.dart';

class ThemeStorage {
  static const String _themeKey = 'is_dark_theme';

  /// Saves the theme preference to shared preferences
  static Future<void> saveTheme(bool isDarkTheme) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeKey, isDarkTheme);
  }

  /// Retrieves the theme preference from shared preferences
  static Future<bool?> getTheme() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_themeKey);
  }
}
