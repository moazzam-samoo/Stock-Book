import 'package:hive_flutter/hive_flutter.dart';

class LocalStorage {
  static const String settingsBox = 'settingsBox';
  static const String authBox = 'auth';
  static const String cacheBox = 'cache';
  static const String marketPricesCacheBox = 'market_prices_cache';
  static const String tickersCacheBox = 'tickers_cache';

  static Future<void> init() async {
    try {
      await Hive.initFlutter();
      await _openBoxes();
    } catch (_) {
      await recoverFromCorruption();
    }
  }

  static Future<void> _openBoxes() async {
    await Hive.openBox(settingsBox);
    await Hive.openBox(authBox);
    await Hive.openBox(cacheBox);
    await Hive.openBox(marketPricesCacheBox);
    await Hive.openBox(tickersCacheBox);
  }

  static Future<void> recoverFromCorruption() async {
    try {
      final boxes = [
        settingsBox,
        authBox,
        cacheBox,
        marketPricesCacheBox,
        tickersCacheBox,
      ];
      for (final boxName in boxes) {
        try {
          if (Hive.isBoxOpen(boxName)) {
            await Hive.box(boxName).close();
          }
          await Hive.deleteBoxFromDisk(boxName);
        } catch (_) {}
      }
      await _openBoxes();
    } catch (_) {
      // Best effort recovery: prevent startup crash even if disk cleanup fails
    }
  }

  static String? getCachedThemeMode() {
    try {
      if (Hive.isBoxOpen(cacheBox)) {
        final box = Hive.box(cacheBox);
        final cached = box.get('cached_theme_mode');
        if (cached is String) return cached;
      }
      if (Hive.isBoxOpen(settingsBox)) {
        final box = Hive.box(settingsBox);
        for (final key in box.keys) {
          if (key.toString().startsWith('user_settings')) {
            final data = box.get(key);
            if (data is Map && data['themeMode'] is String) {
              return data['themeMode'] as String;
            }
          }
        }
      }
    } catch (_) {}
    return null;
  }
}
