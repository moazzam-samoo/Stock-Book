import 'package:flutter/material.dart';

class AppColors {
  static const Color moneyGreen = Color(0xFF00FF7F);
  static const Color vibrantPink = Color(0xFFFF4081);
  static const Color alertRed = Color(0xFFFF5252);
  static const Color warningYellow = Color(0xFFFFD740);

  // Deep Space Theme (Dark Mode Default)
  static const Color deepSpaceBlack = Color(0xFF121212);
  static const Color offBlack = Color(0xFF1E1E1E);
  static const Color darkGray = Color(0xFF2C2C2C);
  
  static const Color textPrimaryDark = Color(0xFFFFFFFF);
  static const Color textSecondaryDark = Color(0xFFB3B3B3);
  
  // Light Mode
  static const Color backgroundLight = Color(0xFFF5F5F5);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  
  static const Color textPrimaryLight = Color(0xFF121212);
  static const Color textSecondaryLight = Color(0xFF757575);

  // Additional Tokens & Aliases
  static const Color brandIndigo = Color(0xFF6366F1);
  static const Color surfaceDark = offBlack;
  static const Color neutral500 = Color(0xFF718096);

  // Semantic Shortcuts & Aliases
  static const Color primary = moneyGreen;
  static const Color onPrimary = deepSpaceBlack;
  static const Color background = deepSpaceBlack;
  static const Color surface = offBlack;
  static const Color surfaceVariant = darkGray;
  static const Color textPrimary = textPrimaryDark;
  static const Color textSecondary = textSecondaryDark;
  static const Color textTertiary = Color(0xFF888888);
  
  static const Color success = moneyGreen;
  static const Color danger = alertRed;
  static const Color warning = warningYellow;
  
  // Chart Colors
  static const Color chartGreen = moneyGreen;
  static const Color chartBlue = Color(0xFF2196F3);
  static const Color chartOrange = Color(0xFFFF9800);
  static const Color chartPurple = Color(0xFF9C27B0);
}

class AppSemanticColors extends ThemeExtension<AppSemanticColors> {
  final Color success;
  final Color danger;
  final Color warning;
  final Color background;
  final Color surface;

  const AppSemanticColors({
    required this.success,
    required this.danger,
    required this.warning,
    required this.background,
    required this.surface,
  });

  @override
  ThemeExtension<AppSemanticColors> copyWith({
    Color? success,
    Color? danger,
    Color? warning,
    Color? background,
    Color? surface,
  }) {
    return AppSemanticColors(
      success: success ?? this.success,
      danger: danger ?? this.danger,
      warning: warning ?? this.warning,
      background: background ?? this.background,
      surface: surface ?? this.surface,
    );
  }

  @override
  ThemeExtension<AppSemanticColors> lerp(ThemeExtension<AppSemanticColors>? other, double t) {
    if (other is! AppSemanticColors) return this;
    return AppSemanticColors(
      success: Color.lerp(success, other.success, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
    );
  }

  static const dark = AppSemanticColors(
    success: AppColors.moneyGreen,
    danger: AppColors.alertRed,
    warning: AppColors.warningYellow,
    background: AppColors.deepSpaceBlack,
    surface: AppColors.offBlack,
  );

  static const light = AppSemanticColors(
    success: AppColors.moneyGreen,
    danger: AppColors.alertRed,
    warning: AppColors.warningYellow,
    background: AppColors.backgroundLight,
    surface: AppColors.surfaceLight,
  );
}
