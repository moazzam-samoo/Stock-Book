import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stock_investment_tracker/main.dart';

// Covers the "Toggle -> Light/System/Dark" requirement from
// phases/PHASE-02-white-theme.md: the persisted `settings.themeMode` string
// must round-trip to the exact ThemeMode MaterialApp receives.
void main() {
  group('themeModeFrom', () {
    test("'light' maps to ThemeMode.light", () {
      expect(themeModeFrom('light'), ThemeMode.light);
    });

    test("'system' maps to ThemeMode.system", () {
      expect(themeModeFrom('system'), ThemeMode.system);
    });

    test("'dark' maps to ThemeMode.dark", () {
      expect(themeModeFrom('dark'), ThemeMode.dark);
    });

    test('null falls back to ThemeMode.light (settings still loading)', () {
      expect(themeModeFrom(null), ThemeMode.light);
    });

    test('an unrecognised string falls back to ThemeMode.light', () {
      expect(themeModeFrom('sepia'), ThemeMode.light);
    });
  });
}
