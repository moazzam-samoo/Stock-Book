import 'package:flutter/material.dart';

class StockColorUtils {
  static const List<Color> _palette = [
    Color(0xFF00E676), // Green A400
    Color(0xFFFF1744), // Red A400
    Color(0xFF2979FF), // Blue A400
    Color(0xFFFF9100), // Orange A200
    Color(0xFFD500F9), // Purple A400
    Color(0xFF00B8D4), // Cyan A700
    Color(0xFFFF4081), // Pink A200
    Color(0xFFFFD600), // Yellow A700
    Color(0xFF3D5AFE), // Indigo A400
    Color(0xFF00E5FF), // Cyan A400
    Color(0xFFF50057), // Pink A400
    Color(0xFF651FFF), // Deep Purple A400
    Color(0xFFFF3D00), // Deep Orange A400
    Color(0xFF76FF03), // Light Green A400
    Color(0xFF1DE9B6), // Teal A400
    Color(0xFF00B0FF), // Light Blue A400
  ];

  /// Generates a highly distinct Color for any stock ticker string using a curated vibrant palette.
  static Color getColorForTicker(String ticker) {
    if (ticker.isEmpty) return _palette[0];

    int hash = 0;
    for (int i = 0; i < ticker.length; i++) {
      hash = ticker.codeUnitAt(i) + ((hash << 5) - hash);
    }
    
    return _palette[hash.abs() % _palette.length];
  }

  /// Generates a distinct color based on integer index.
  static Color getColorForIndex(int index) {
    return _palette[index.abs() % _palette.length];
  }
}
