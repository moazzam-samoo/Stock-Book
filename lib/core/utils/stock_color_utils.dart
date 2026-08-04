import 'package:flutter/material.dart';

class StockColorUtils {
  /// Generates a unique, vibrant, dark-mode optimized Color for any stock ticker string.
  /// Uses Golden Ratio HSL distribution so every stock (1, 10, 100, 1000+) gets a unique color.
  static Color getColorForTicker(String ticker) {
    if (ticker.isEmpty) return const Color(0xFF00C853);

    // Compute stable string hash
    int hash = 0;
    for (int i = 0; i < ticker.length; i++) {
      hash = ticker.codeUnitAt(i) + ((hash << 5) - hash);
    }

    // Multiply hash by Golden Angle (137.508 degrees) to distribute colors evenly across 360° spectrum
    final double hue = (hash.abs() * 137.508) % 360.0;
    
    // High saturation (85%) and balanced lightness (52%) for high contrast on dark themes
    const double saturation = 0.85;
    const double lightness = 0.52;

    return HSLColor.fromAHSL(1.0, hue, saturation, lightness).toColor();
  }

  /// Generates a unique color based on integer index using Golden Angle spacing.
  static Color getColorForIndex(int index) {
    final double hue = (index * 137.508) % 360.0;
    const double saturation = 0.85;
    const double lightness = 0.52;
    return HSLColor.fromAHSL(1.0, hue, saturation, lightness).toColor();
  }
}
