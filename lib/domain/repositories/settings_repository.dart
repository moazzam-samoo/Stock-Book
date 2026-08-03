import 'package:stock_investment_tracker/domain/entities/user_settings.dart';

abstract class SettingsRepository {
  Stream<UserSettings> watchSettings();
  Future<void> updateSettings(UserSettings settings);
  Future<void> addFavorite(String ticker);
  Future<void> removeFavorite(String ticker);
  Future<void> updateStartingCapital(double capital);
  Future<void> updateCurrency(String currency);
  Future<void> updateThemeMode(String themeMode);
}
