import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:stock_investment_tracker/domain/entities/user_settings.dart';
import 'package:stock_investment_tracker/providers/repository_providers.dart';

part 'settings_provider.g.dart';

@riverpod
Stream<UserSettings> settings(SettingsRef ref) async* {
  final repo = ref.watch(settingsRepositoryProvider);
  const defaultSettings = UserSettings(
    favorites: [],
    startingCapital: 0.0,
    currency: 'PKR',
    themeMode: 'light',
  );

  if (repo == null) {
    yield defaultSettings;
    return;
  }

  try {
    await for (final s in repo.watchSettings()) {
      yield s;
    }
  } catch (e) {
    yield defaultSettings;
  }
}

// keepAlive: this notifier is only ever reached via ref.read(...notifier),
// never ref.watch, so a plain autoDispose instance can be torn down mid-write
// and throw "Bad state: Future already completed" when it tries to finalize
// its state afterwards. Same fix as WithdrawalController.
@Riverpod(keepAlive: true)
class SettingsController extends _$SettingsController {
  @override
  FutureOr<void> build() {}

  Future<void> addFavorite(String ticker) async {
    final repo = ref.read(settingsRepositoryProvider);
    if (repo == null) return;

    final cleanTicker = ticker.toUpperCase().trim();
    if (cleanTicker.isEmpty) return;

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => repo.addFavorite(cleanTicker));
    ref.invalidate(settingsProvider);
  }

  Future<void> removeFavorite(String ticker) async {
    final repo = ref.read(settingsRepositoryProvider);
    if (repo == null) return;

    final cleanTicker = ticker.toUpperCase().trim();

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => repo.removeFavorite(cleanTicker));
    ref.invalidate(settingsProvider);
  }

  Future<void> updateStartingCapital(double capital) async {
    final repo = ref.read(settingsRepositoryProvider);
    if (repo == null) return;

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => repo.updateStartingCapital(capital));
    ref.invalidate(settingsProvider);
  }

  Future<void> updateCurrency(String currency) async {
    final repo = ref.read(settingsRepositoryProvider);
    if (repo == null) return;

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => repo.updateCurrency(currency));
    ref.invalidate(settingsProvider);
  }

  Future<void> updateThemeMode(String themeMode) async {
    final repo = ref.read(settingsRepositoryProvider);
    if (repo == null) return;

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => repo.updateThemeMode(themeMode));
    ref.invalidate(settingsProvider);
  }

  Future<void> updateStockColor(String ticker, int colorValue) async {
    final repo = ref.read(settingsRepositoryProvider);
    if (repo == null) return;

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => repo.updateStockColor(ticker, colorValue));
    ref.invalidate(settingsProvider);
  }
}
