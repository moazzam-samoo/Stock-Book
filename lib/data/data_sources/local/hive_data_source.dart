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
      final Map<String, dynamic> jsonMap = Map<String, dynamic>.from(data as Map);
      return UserSettingsModel.fromJson(jsonMap);
    }
    return null;
  }
}
