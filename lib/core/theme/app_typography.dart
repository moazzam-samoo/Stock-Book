import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTypography {
  static TextStyle display = GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white);
  static TextStyle h1 = GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white);
  static TextStyle h2 = GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w600, color: Colors.white);
  static TextStyle h3 = GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white);
  static TextStyle body = GoogleFonts.inter(fontSize: 14, color: Colors.white);
  static TextStyle caption = GoogleFonts.inter(fontSize: 12, color: const Color(0xFF718096));

  static TextTheme get darkTextTheme {
    return GoogleFonts.interTextTheme(ThemeData.dark().textTheme).copyWith(
      displayLarge: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
      displayMedium: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w600, color: Colors.white),
      displaySmall: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white),
      bodyLarge: GoogleFonts.inter(fontSize: 16, color: Colors.white),
      bodyMedium: GoogleFonts.inter(fontSize: 14, color: const Color(0xFFB3B3B3)),
      labelLarge: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
    );
  }

  static TextTheme get lightTextTheme {
    return GoogleFonts.interTextTheme(ThemeData.light().textTheme).copyWith(
      displayLarge: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.black),
      displayMedium: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w600, color: Colors.black),
      displaySmall: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.black),
      bodyLarge: GoogleFonts.inter(fontSize: 16, color: Colors.black),
      bodyMedium: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF757575)),
      labelLarge: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black),
    );
  }
}
