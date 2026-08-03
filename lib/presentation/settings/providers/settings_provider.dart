import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:stock_investment_tracker/domain/entities/user_settings.dart';
import 'package:stock_investment_tracker/providers/repository_providers.dart';

part 'settings_provider.g.dart';

@riverpod
Stream<UserSettings> settings(SettingsRef ref) {
  final repo = ref.watch(settingsRepositoryProvider);
  if (repo == null) {
    return Stream.value(const UserSettings(
      favorites: [],
      startingCapital: 10000.0,
      currency: 'PKR',
      themeMode: 'dark',
    ));
  }
  return repo.watchSettings();
}

@riverpod
class SettingsController extends _$SettingsController {
  @override
  FutureOr<void> build() {}

  Future<void> addFavorite(String ticker) async {
    final repo = ref.read(settingsRepositoryProvider);
    if (repo == null) return;

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => repo.addFavorite(ticker));
  }

  Future<void> removeFavorite(String ticker) async {
    final repo = ref.read(settingsRepositoryProvider);
    if (repo == null) return;

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => repo.removeFavorite(ticker));
  }

  Future<void> updateStartingCapital(double capital) async {
    final repo = ref.read(settingsRepositoryProvider);
    if (repo == null) return;

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => repo.updateStartingCapital(capital));
  }

  Future<void> updateCurrency(String currency) async {
    final repo = ref.read(settingsRepositoryProvider);
    if (repo == null) return;

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => repo.updateCurrency(currency));
  }

  Future<void> updateThemeMode(String themeMode) async {
    final repo = ref.read(settingsRepositoryProvider);
    if (repo == null) return;

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => repo.updateThemeMode(themeMode));
  }
}
