import 'package:flutter/material.dart';
import 'package:snippet/theme/pallete.dart';

class AppTheme {
  static ThemeData darkTheme = ThemeData.dark().copyWith(
    scaffoldBackgroundColor: Pallete.backgroundColorDark,
    appBarTheme: const AppBarTheme(
      backgroundColor: Pallete.backgroundColorDark,
      elevation: 0,
      iconTheme: IconThemeData(color: Pallete.whiteColor),
      titleTextStyle: TextStyle(color: Pallete.whiteColor),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Pallete.blueColor,
    ),
    textTheme: ThemeData.dark().textTheme.apply(
      bodyColor: Pallete.whiteColor,
      displayColor: Pallete.whiteColor,
    ),
  );

  static ThemeData lightTheme = ThemeData.light().copyWith(
    scaffoldBackgroundColor: Pallete.backgroundColorLight,
    appBarTheme: const AppBarTheme(
      backgroundColor: Pallete.backgroundColorLight,
      elevation: 0,
      iconTheme: IconThemeData(color: Pallete.textColorLight),
      titleTextStyle: TextStyle(color: Pallete.textColorLight),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Pallete.blueColor,
    ),
    textTheme: ThemeData.light().textTheme.apply(
      bodyColor: Pallete.textColorLight,
      displayColor: Pallete.textColorLight,
    ),
  );

  static ThemeData getTheme(bool isDarkTheme) {
    return isDarkTheme ? darkTheme : lightTheme;
  }
}
