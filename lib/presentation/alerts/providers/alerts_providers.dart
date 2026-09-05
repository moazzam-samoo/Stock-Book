import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:stock_investment_tracker/domain/entities/price_alert.dart';
import 'package:stock_investment_tracker/providers/repository_providers.dart';
import 'package:uuid/uuid.dart';

part 'alerts_providers.g.dart';

@riverpod
Stream<List<PriceAlert>> allAlerts(AllAlertsRef ref) {
  final repository = ref.watch(priceAlertRepositoryProvider);
  if (repository == null) {
    return Stream.value([]);
  }
  return repository.watchAllAlerts();
}

/// The price at or below which an alert fires. The single reference
/// definition Phase 08's Python backend mirrors — UI previews must call this,
/// not re-derive the formula, so the displayed threshold can never drift from
/// what actually triggers.
double alertThreshold(double targetPrice, double tolerancePercent) {
  return targetPrice * (1 + tolerancePercent / 100);
}

/// Pure function for trigger logic.
bool isAlertTriggered(double currentPrice, double targetPrice, double tolerancePercent) {
  return currentPrice <= alertThreshold(targetPrice, tolerancePercent);
}

@Riverpod(keepAlive: true)
class AlertsController extends _$AlertsController {
  @override
  FutureOr<void> build() {}

  Future<void> addAlert({
    required String ticker,
    required double targetPrice,
    required double tolerancePercent,
  }) async {
    final repo = ref.read(priceAlertRepositoryProvider);
    if (repo == null) return;

    final alert = PriceAlert(
      id: const Uuid().v4(),
      ticker: ticker,
      targetPrice: targetPrice,
      tolerancePercent: tolerancePercent,
      createdAt: DateTime.now(),
    );

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => repo.addAlert(alert));
  }

  Future<void> updateAlert(PriceAlert alert) async {
    final repo = ref.read(priceAlertRepositoryProvider);
    if (repo == null) return;

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => repo.updateAlert(alert));
  }

  Future<void> deleteAlert(String alertId) async {
    final repo = ref.read(priceAlertRepositoryProvider);
    if (repo == null) return;

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => repo.deleteAlert(alertId));
  }
}
