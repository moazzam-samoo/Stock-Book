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

final sampleMockLots = [
  Lot(
    id: '1',
    ticker: 'SYS',
    buyDate: DateTime.now().subtract(const Duration(days: 45)),
    sharesPurchased: 500,
    buyPricePerShare: 420.0,
    amountInvested: 210000.0,
    sharesRemaining: 300,
    amountInvestedRemaining: 126000.0,
    realizedProfitLoss: 18000.0,
    status: LotStatus.partiallySold,
    sales: [
      Sale(
        id: 's1',
        sellDate: DateTime.now().subtract(const Duration(days: 10)),
        sharesSold: 200,
        sellPricePerShare: 510.0,
        amountReceived: 102000.0,
      ),
    ],
  ),
  Lot(
    id: '2',
    ticker: 'TRG',
    buyDate: DateTime.now().subtract(const Duration(days: 30)),
    sharesPurchased: 1000,
    buyPricePerShare: 85.5,
    amountInvested: 85500.0,
    sharesRemaining: 1000,
    amountInvestedRemaining: 85500.0,
    realizedProfitLoss: 0.0,
    status: LotStatus.open,
  ),
  Lot(
    id: '3',
    ticker: 'OGDC',
    buyDate: DateTime.now().subtract(const Duration(days: 60)),
    sharesPurchased: 800,
    buyPricePerShare: 110.0,
    amountInvested: 88000.0,
    sharesRemaining: 800,
    amountInvestedRemaining: 88000.0,
    realizedProfitLoss: 12500.0,
    status: LotStatus.open,
  ),
  Lot(
    id: '4',
    ticker: 'LUCK',
    buyDate: DateTime.now().subtract(const Duration(days: 90)),
    sharesPurchased: 250,
    buyPricePerShare: 640.0,
    amountInvested: 160000.0,
    sharesRemaining: 0,
    amountInvestedRemaining: 0.0,
    realizedProfitLoss: -8500.0,
    status: LotStatus.closed,
    sales: [
      Sale(
        id: 's2',
        sellDate: DateTime.now().subtract(const Duration(days: 5)),
        sharesSold: 250,
        sellPricePerShare: 606.0,
        amountReceived: 151500.0,
      ),
    ],
  ),
];

@riverpod
Stream<List<Lot>> allLots(AllLotsRef ref) async* {
  final repo = ref.watch(lotRepositoryProvider);
  if (repo == null) {
    yield sampleMockLots;
    return;
  }
  try {
    await for (final lots in repo.watchAllLots()) {
      if (lots.isEmpty) {
        yield sampleMockLots;
      } else {
        yield lots;
      }
    }
  } catch (e) {
    yield sampleMockLots;
  }
}

@riverpod
PortfolioSummary portfolioSummary(PortfolioSummaryRef ref) {
  final lots = ref.watch(allLotsProvider).valueOrNull ?? sampleMockLots;
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
  final lots = ref.watch(allLotsProvider).valueOrNull ?? sampleMockLots;
  return PortfolioCalculator.calculateStockSummaries(lots);
}

@riverpod
List<AllocationSegment> allocationData(AllocationDataRef ref) {
  final stockSummariesList = ref.watch(stockSummariesProvider);
  return PortfolioCalculator.calculateAllocation(stockSummariesList);
}
