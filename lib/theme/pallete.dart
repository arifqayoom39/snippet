import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snippet/theme/theme_storage.dart';

class Pallete {
  // Dark Theme Colors
  static const Color backgroundColorDark = Colors.black;
  static const Color searchBarColorDark = Color.fromRGBO(32, 35, 39, 1);
  static const Color blueColor = Color.fromRGBO(0, 122, 255, 1); // Signal app blue color
  static const Color whiteColor = Colors.white;
  static const Color greyColor = Colors.grey;
  static const Color redColor = Color.fromRGBO(255, 59, 48, 1); // Perfect red as per design standards
  static const Color tealColor = Colors.teal;

  // Light Theme Colors
  static const Color backgroundColorLight = Colors.white;
  static const Color purpleColor = Colors.purple;
  static const Color searchBarColorLight = Color.fromRGBO(239, 243, 244, 1);
  static const Color textColorLight = Colors.black;
  static const Color greyColorLight = Color.fromRGBO(101, 119, 134, 1);

  // Current theme dependent colors (will be updated based on current theme)
  static late Color backgroundColor;
  static late Color searchBarColor;
  static late Color textColor;
  static late Color iconColor;
}

// Theme notifier to manage theme state
class ThemeNotifier extends StateNotifier<bool> {
  ThemeNotifier() : super(true); // true = dark theme by default

  void toggleTheme() {
    state = !state;
    updateThemeColors(state);
    // Save theme preference
    ThemeStorage.saveTheme(state);
  }

  // Add this method to set light mode explicitly
  Future<void> setLightMode() async {
    state = false; // false = light theme
    updateThemeColors(false);
    // Save theme preference
    await ThemeStorage.saveTheme(false);
  }

  // Force rebuild widgets by modifying the state
  void forceUpdate() {
    // Temporarily toggle state to trigger listeners
    final current = state;
    state = !current;
    state = current;
    updateThemeColors(state);
  }

  void updateThemeColors(bool isDarkMode) {
    Pallete.backgroundColor = isDarkMode ? Pallete.backgroundColorDark : Pallete.backgroundColorLight;
    Pallete.searchBarColor = isDarkMode ? Pallete.searchBarColorDark : Pallete.searchBarColorLight;
    Pallete.textColor = isDarkMode ? Pallete.whiteColor : Pallete.textColorLight;
    Pallete.iconColor = isDarkMode ? Pallete.whiteColor : Pallete.textColorLight;
  }

  Future<void> initTheme() async {
    // Load saved theme preference
    final savedTheme = await ThemeStorage.getTheme();
    
    // If we have a saved preference, use it
    if (savedTheme != null) {
      state = savedTheme;
    }
    
    updateThemeColors(state);
  }
}

// Theme mode provider
final themeProvider = StateNotifierProvider<ThemeNotifier, bool>((ref) {
  return ThemeNotifier();
});
