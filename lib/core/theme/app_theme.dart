import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_typography.dart';

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.deepSpaceBlack,
      primaryColor: AppColors.moneyGreen,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.moneyGreen,
        secondary: AppColors.vibrantPink,
        surface: AppColors.offBlack,
        error: AppColors.alertRed,
      ),
      textTheme: AppTypography.darkTextTheme,
      extensions: const <ThemeExtension<dynamic>>[
        AppSemanticColors.dark,
      ],
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.deepSpaceBlack,
        elevation: 0,
        centerTitle: true,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.moneyGreen,
          foregroundColor: AppColors.deepSpaceBlack,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.offBlack,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 4,
        margin: EdgeInsets.zero,
      ),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.backgroundLight,
      primaryColor: AppColors.moneyGreen,
      colorScheme: const ColorScheme.light(
        primary: AppColors.moneyGreen,
        secondary: AppColors.vibrantPink,
        surface: AppColors.surfaceLight,
        error: AppColors.alertRed,
      ),
      textTheme: AppTypography.lightTextTheme,
      extensions: const <ThemeExtension<dynamic>>[
        AppSemanticColors.light,
      ],
    );
  }
}
