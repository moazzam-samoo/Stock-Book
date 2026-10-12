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

import 'package:stock_investment_tracker/domain/calculator/position_calculator.dart';
import 'package:stock_investment_tracker/domain/repositories/position_repository.dart';

part 'dashboard_providers.g.dart';

@riverpod
Stream<List<Position>> allPositions(AllPositionsRef ref) async* {
  final repo = ref.watch(positionRepositoryProvider);
  if (repo == null) {
    yield [];
    return;
  }
  await for (final rawList in repo.watchAllPositions()) {
    final consolidated = PositionCalculator.consolidateSameDayPositions(rawList);
    if (consolidated.length < rawList.length) {
      _syncConsolidatedPositions(repo, rawList);
    }
    yield consolidated;
  }
}

void _syncConsolidatedPositions(PositionRepository repo, List<Position> rawList) {
  final Map<String, List<Position>> groups = {};
  for (final p in rawList) {
    final key =
        '${p.ticker.trim().toUpperCase()}::${p.openedAt.year}-${p.openedAt.month}-${p.openedAt.day}';
    groups.putIfAbsent(key, () => []).add(p);
  }

  for (final entry in groups.entries) {
    final group = entry.value;
    if (group.length > 1) {
      final consolidatedList = PositionCalculator.consolidateSameDayPositions(group);
      if (consolidatedList.isNotEmpty) {
        final merged = consolidatedList.first;
        repo.updatePosition(merged);
        for (int i = 1; i < group.length; i++) {
          repo.deletePosition(group[i].id);
        }
      }
    }
  }
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
  final effectiveTaxes = ref.watch(effectiveTaxRatesProvider);

  // Starting capital from settings, default to 0.0 PKR if not loaded
  final startingCapital = settings?.startingCapital ?? 0.0;

  return PortfolioCalculator.calculatePortfolioSummaryFromPositions(
    positions,
    startingCapital,
    PortfolioCalculator.calculateTotalWithdrawn(withdrawals),
    effectiveTaxes,
  );
}

@riverpod
List<StockSummary> stockSummaries(StockSummariesRef ref) {
  final positions = ref.watch(allPositionsProvider).valueOrNull ?? [];
  final effectiveTaxes = ref.watch(effectiveTaxRatesProvider);
  return PortfolioCalculator.calculateStockSummariesFromPositions(
    positions,
    effectiveTaxes,
  );
}

@riverpod
List<AllocationSegment> allocationData(AllocationDataRef ref) {
  final stockSummariesList = ref.watch(stockSummariesProvider);
  return PortfolioCalculator.calculateAllocation(stockSummariesList);
}
