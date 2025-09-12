import 'package:flutter/material.dart';

class AppColors {
  static const mainBackgroundColor = Color(0xFF181c1f);
  static const textColor = Color(0xFFD7DADC);
}

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      // base ui colors are based off of redit lol
      colorScheme: ColorScheme.dark(primary: AppColors.mainBackgroundColor),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: AppColors.textColor,
          textStyle: const TextStyle(fontFamily: 'Ntype82-R', fontSize: 14),
        ),
      ),

      textTheme: TextTheme(
        headlineLarge: TextStyle(
          fontFamily: 'Ntype82-R',
          color: AppColors.textColor,
        ),
        headlineMedium: TextStyle(
          fontFamily: 'Ntype82-R',
          color: AppColors.textColor,
        ),
        headlineSmall: TextStyle(
          fontFamily: 'Ntype82-R',
          color: AppColors.textColor,
        ),
        bodyLarge: TextStyle(fontFamily: 'Lettera', color: AppColors.textColor),
        bodyMedium: TextStyle(
          fontFamily: 'Lettera',
          color: AppColors.textColor,
        ),
        bodySmall: TextStyle(fontFamily: 'Lettera', color: AppColors.textColor),
      ),
    );
  }
}
