import 'package:stock_investment_tracker/domain/entities/pin_result.dart';
import 'package:stock_investment_tracker/domain/entities/premium_code_result.dart';
import 'package:stock_investment_tracker/domain/entities/user_settings.dart';

abstract class SettingsRepository {
  Stream<UserSettings> watchSettings();
  Future<void> updateSettings(UserSettings settings);
  Future<void> addFavorite(String ticker);
  Future<void> removeFavorite(String ticker);
  Future<void> updateStartingCapital(double capital);
  Future<void> updateCurrency(String currency);
  Future<void> updateThemeMode(String themeMode);
  Future<void> updateStockColor(String ticker, int colorValue);

  /// Free tier: max 5 pinned tickers, enforced here. Returns
  /// [PinResult.limitReached] (without writing anything) rather than
  /// throwing when pinning a 6th ticker without [UserSettings.isPremiumUnlocked].
  Future<PinResult> togglePin(String ticker);

  /// Redeems a unique, one-time-use code from the top-level `premium_codes`
  /// collection (see `scripts/generate_premium_codes.py`). On
  /// [PremiumCodeOutcome.success], sets [UserSettings.isPremiumUnlocked] to
  /// `true`. Never throws — every failure mode is a typed outcome.
  Future<PremiumCodeResult> redeemPremiumCode(String code);
}
