import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:stock_investment_tracker/domain/entities/lot.dart';
import 'package:stock_investment_tracker/domain/entities/sale.dart';
import 'package:stock_investment_tracker/domain/enums/lot_status.dart';
import 'package:stock_investment_tracker/domain/entities/portfolio_summary.dart';
import 'package:stock_investment_tracker/domain/entities/stock_summary.dart';
import 'package:stock_investment_tracker/domain/entities/allocation_segment.dart';
import 'package:stock_investment_tracker/domain/calculator/portfolio_calculator.dart';
import 'package:stock_investment_tracker/presentation/settings/providers/settings_provider.dart';
import 'package:stock_investment_tracker/providers/repository_providers.dart';

part 'dashboard_providers.g.dart';

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
PortfolioSummary portfolioSummary(PortfolioSummaryRef ref) {
  final lots = ref.watch(allLotsProvider).valueOrNull ?? [];
  final settings = ref.watch(settingsProvider).valueOrNull;
  
  // Starting capital from settings, default to 500,000 PKR if not loaded
  final startingCapital = settings?.startingCapital ?? 500000.0;

  return PortfolioCalculator.calculatePortfolioSummary(
    lots,
    startingCapital,
  );
}

@riverpod
List<StockSummary> stockSummaries(StockSummariesRef ref) {
  final lots = ref.watch(allLotsProvider).valueOrNull ?? [];
  return PortfolioCalculator.calculateStockSummaries(lots);
}

@riverpod
List<AllocationSegment> allocationData(AllocationDataRef ref) {
  final stockSummariesList = ref.watch(stockSummariesProvider);
  return PortfolioCalculator.calculateAllocation(stockSummariesList);
}
