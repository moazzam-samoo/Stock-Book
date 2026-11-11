import 'package:hive/hive.dart';
import 'package:stock_investment_tracker/data/models/user_settings_model.dart';
import 'package:stock_investment_tracker/data/models/market_price_model.dart';
import 'package:stock_investment_tracker/data/models/admin_tax_rates_model.dart';

class HiveDataSource {
  static const String settingsBoxName = 'settingsBox';
  
  // Settings
  Future<void> saveSettings(String uid, UserSettingsModel settings) async {
    final box = await Hive.openBox(settingsBoxName);
    final json = settings.toJson();
    json['taxSettings'] = settings.taxSettings.toJson();
    await box.put('user_settings_$uid', json);

    // Keep cached theme mode in general cache box for unauthenticated cold start
    try {
      final cache = await Hive.openBox('cache');
      await cache.put('cached_theme_mode', settings.themeMode);
    } catch (_) {}
  }

  Future<UserSettingsModel?> getSettings(String uid) async {
    final box = await Hive.openBox(settingsBoxName);
    final data = box.get('user_settings_$uid');
    if (data != null) {
      try {
        // Sanitize the map to ensure all nested maps are Map<String, dynamic>
        // Hive stores nested maps as Map<dynamic, dynamic> which crashes generated fromJson
        final sanitized = _sanitizeMap(Map<String, dynamic>.from(data as Map));
        return UserSettingsModel.fromJson(sanitized);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  Future<void> clearSettings(String uid) async {
    try {
      final box = await Hive.openBox(settingsBoxName);
      await box.delete('user_settings_$uid');
    } catch (_) {}
  }

  Future<void> clearAllUserSettings() async {
    try {
      final box = await Hive.openBox(settingsBoxName);
      final keysToDelete = box.keys
          .where((k) => k.toString().startsWith('user_settings_'))
          .toList();
      for (final key in keysToDelete) {
        await box.delete(key);
      }
    } catch (_) {}
  }

  // Market Prices
  Future<void> saveMarketPrices(Map<String, MarketPriceModel> prices) async {
    final box = await Hive.openBox('market_prices_cache');
    final jsonMap = prices.map((k, v) => MapEntry(k, v.toJson()));
    await box.put('market_prices', jsonMap);
  }

  Future<Map<String, MarketPriceModel>> getMarketPrices() async {
    final box = await Hive.openBox('market_prices_cache');
    final data = box.get('market_prices');
    if (data != null && data is Map) {
      try {
        final sanitized = _sanitizeMap(Map<String, dynamic>.from(data));
        final result = <String, MarketPriceModel>{};
        sanitized.forEach((key, value) {
          if (value is Map) {
            result[key] = MarketPriceModel.fromJson(Map<String, dynamic>.from(value));
          }
        });
        return result;
      } catch (e) {
        return {};
      }
    }
    return {};
  }

  // Tickers
  Future<void> saveTickers(List<dynamic> tickers) async {
    final box = await Hive.openBox('tickers_cache');
    await box.put('tickers', tickers);
  }

  Future<List<Map<String, dynamic>>> getTickers() async {
    final box = await Hive.openBox('tickers_cache');
    final data = box.get('tickers');
    if (data != null && data is List) {
      return data.map((e) {
        if (e is Map) {
          return _sanitizeMap(Map<String, dynamic>.from(e));
        }
        return <String, dynamic>{};
      }).toList();
    }
    return [];
  }

  // Admin Tax Rates Cache
  Future<void> saveAdminTaxRates(AdminTaxRatesModel rates) async {
    final box = await Hive.openBox('cache');
    await box.put('admin_tax_rates', rates.toJson());
  }

  Future<AdminTaxRatesModel?> getAdminTaxRates() async {
    final box = await Hive.openBox('cache');
    final data = box.get('admin_tax_rates');
    if (data != null && data is Map) {
      try {
        final sanitized = _sanitizeMap(Map<String, dynamic>.from(data));
        return AdminTaxRatesModel.fromJson(sanitized);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  Map<String, dynamic> _sanitizeMap(Map<String, dynamic> map) {
    final sanitized = <String, dynamic>{};
    map.forEach((key, value) {
      if (value is Map) {
        sanitized[key] = value.map((k, v) => MapEntry(k.toString(), v));
      } else {
        sanitized[key] = value;
      }
    });
    return sanitized;
  }
}
