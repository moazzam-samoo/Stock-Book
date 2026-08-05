import 'package:stock_investment_tracker/data/data_sources/local/hive_data_source.dart';
import 'package:stock_investment_tracker/data/data_sources/remote/firestore_data_source.dart';
import 'package:stock_investment_tracker/data/models/user_settings_model.dart';
import 'package:stock_investment_tracker/domain/entities/user_settings.dart';
import 'package:stock_investment_tracker/domain/repositories/settings_repository.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  final String _uid;
  final FirestoreDataSource _firestoreDataSource;
  final HiveDataSource _hiveDataSource;

  SettingsRepositoryImpl({
    required String uid,
    required FirestoreDataSource firestoreDataSource,
    required HiveDataSource hiveDataSource,
  })  : _uid = uid,
        _firestoreDataSource = firestoreDataSource,
        _hiveDataSource = hiveDataSource;

  @override
  Stream<UserSettings> watchSettings() async* {
    // Emit local cache first if available
    final localSettings = await _hiveDataSource.getSettings();
    if (localSettings != null) {
      yield localSettings.toEntity();
    } else {
      yield const UserSettings(
        favorites: [],
        startingCapital: 0.0,
        currency: 'PKR',
        themeMode: 'dark',
      );
    }

    // Then listen to remote stream and update local cache
    yield* _firestoreDataSource.watchSettings(_uid).map((model) {
      if (model != null) {
        _hiveDataSource.saveSettings(model);
        return model.toEntity();
      }
      return const UserSettings(
        favorites: [],
        startingCapital: 0.0,
        currency: 'PKR',
        themeMode: 'dark',
      );
    });
  }

  @override
  Future<void> updateSettings(UserSettings settings) async {
    final model = UserSettingsModelExtension.fromEntity(settings);
    await _hiveDataSource.saveSettings(model);
    await _firestoreDataSource.updateSettings(_uid, model);
  }

  @override
  Future<void> addFavorite(String ticker) async {
    final clean = ticker.toUpperCase().trim();
    if (clean.isEmpty) return;
    final current = await _getCurrentSettings();
    if (!current.favorites.contains(clean)) {
      final updated = current.copyWith(
        favorites: [...current.favorites, clean],
      );
      await updateSettings(updated);
    }
  }

  @override
  Future<void> removeFavorite(String ticker) async {
    final clean = ticker.toUpperCase().trim();
    final current = await _getCurrentSettings();
    final updatedFavorites = current.favorites.where((t) => t.toUpperCase().trim() != clean).toList();
    final updated = current.copyWith(favorites: updatedFavorites);
    await updateSettings(updated);
  }

  @override
  Future<void> updateStartingCapital(double capital) async {
    final current = await _getCurrentSettings();
    await updateSettings(current.copyWith(startingCapital: capital));
  }

  @override
  Future<void> updateCurrency(String currency) async {
    final current = await _getCurrentSettings();
    await updateSettings(current.copyWith(currency: currency));
  }

  @override
  Future<void> updateThemeMode(String themeMode) async {
    final current = await _getCurrentSettings();
    await updateSettings(current.copyWith(themeMode: themeMode));
  }

  @override
  Future<void> updateStockColor(String ticker, int colorValue) async {
    final clean = ticker.toUpperCase().trim();
    final current = await _getCurrentSettings();
    final newColors = Map<String, int>.from(current.stockColors);
    if (colorValue == 0) {
      newColors.remove(clean);
    } else {
      newColors[clean] = colorValue;
    }
    await updateSettings(current.copyWith(stockColors: newColors));
  }

  Future<UserSettings> _getCurrentSettings() async {
    final local = await _hiveDataSource.getSettings();
    if (local != null) return local.toEntity();
    return const UserSettings(
      favorites: [],
      startingCapital: 0.0,
      currency: 'PKR',
      themeMode: 'dark',
    );
  }
}
