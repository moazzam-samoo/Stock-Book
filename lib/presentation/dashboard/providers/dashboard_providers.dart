import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:stock_investment_tracker/domain/entities/lot.dart';
import 'package:stock_investment_tracker/domain/entities/position.dart';
import 'package:stock_investment_tracker/domain/entities/portfolio_summary.dart';
import 'package:stock_investment_tracker/domain/entities/stock_summary.dart';
import 'package:stock_investment_tracker/domain/entities/allocation_segment.dart';
import 'package:stock_investment_tracker/domain/entities/withdrawal.dart';
import 'package:stock_investment_tracker/domain/calculator/portfolio_calculator.dart';
import 'package:stock_investment_tracker/presentation/settings/providers/settings_provider.dart';
import 'package:stock_investment_tracker/providers/repository_providers.dart';

part 'dashboard_providers.g.dart';

@riverpod
Stream<List<Position>> allPositions(AllPositionsRef ref) async* {
  final repo = ref.watch(positionRepositoryProvider);
  if (repo == null) {
    yield [];
    return;
  }
  yield* repo.watchAllPositions();
}

/// Lots are never deleted by the position migration — they remain the
/// rollback path and the source of truth for the JSON backup export, so this
/// stays available alongside [allPositionsProvider].
@riverpod
Stream<List<Lot>> allLots(AllLotsRef ref) async* {
  final repo = ref.watch(lotRepositoryProvider);
  if (repo == null) {
    yield [];
    return;
  }
  yield* repo.watchAllLots();
}

@riverpod
Stream<List<Withdrawal>> allWithdrawals(AllWithdrawalsRef ref) async* {
  final repo = ref.watch(withdrawalRepositoryProvider);
  if (repo == null) {
    yield [];
    return;
  }
  yield* repo.watchAllWithdrawals();
}

@riverpod
PortfolioSummary portfolioSummary(PortfolioSummaryRef ref) {
  final positions = ref.watch(allPositionsProvider).valueOrNull ?? [];
  final settings = ref.watch(settingsProvider).valueOrNull;
  final withdrawals = ref.watch(allWithdrawalsProvider).valueOrNull ?? [];

  // Starting capital from settings, default to 0.0 PKR if not loaded
  final startingCapital = settings?.startingCapital ?? 0.0;

  return PortfolioCalculator.calculatePortfolioSummaryFromPositions(
    positions,
    startingCapital,
    PortfolioCalculator.calculateTotalWithdrawn(withdrawals),
  );
}

@riverpod
List<StockSummary> stockSummaries(StockSummariesRef ref) {
  final positions = ref.watch(allPositionsProvider).valueOrNull ?? [];
  return PortfolioCalculator.calculateStockSummariesFromPositions(positions);
}

@riverpod
List<AllocationSegment> allocationData(AllocationDataRef ref) {
  final stockSummariesList = ref.watch(stockSummariesProvider);
  return PortfolioCalculator.calculateAllocation(stockSummariesList);
}
