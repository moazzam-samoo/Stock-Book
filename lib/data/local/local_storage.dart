import 'package:hive_flutter/hive_flutter.dart';

class LocalStorage {
  static const String settingsBox = 'settings';
  static const String authBox = 'auth';
  static const String cacheBox = 'cache';
  static const String marketPricesCacheBox = 'market_prices_cache';

  static Future<void> init() async {
    await Hive.initFlutter();
    
    // Open boxes
    await Hive.openBox(settingsBox);
    await Hive.openBox('settingsBox');
    await Hive.openBox(authBox);
    await Hive.openBox(cacheBox);
    await Hive.openBox(marketPricesCacheBox);
  }

  static String? getCachedThemeMode() {
    try {
      if (Hive.isBoxOpen('settingsBox')) {
        final box = Hive.box('settingsBox');
        final data = box.get('user_settings');
        if (data is Map && data['themeMode'] is String) {
          return data['themeMode'] as String;
        }
      }
    } catch (_) {}
    return null;
  }
}
