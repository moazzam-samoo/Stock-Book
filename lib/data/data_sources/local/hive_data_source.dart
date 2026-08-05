import 'package:hive/hive.dart';
import 'package:stock_investment_tracker/data/models/user_settings_model.dart';

class HiveDataSource {
  static const String settingsBoxName = 'settingsBox';
  
  // Settings
  Future<void> saveSettings(UserSettingsModel settings) async {
    final box = await Hive.openBox(settingsBoxName);
    await box.put('user_settings', settings.toJson());
  }

  Future<UserSettingsModel?> getSettings() async {
    final box = await Hive.openBox(settingsBoxName);
    final data = box.get('user_settings');
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
