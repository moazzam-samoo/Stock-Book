import 'package:stock_investment_tracker/domain/entities/allocation_segment.dart';
import 'package:stock_investment_tracker/domain/entities/lot.dart';
import 'package:stock_investment_tracker/domain/entities/portfolio_summary.dart';
import 'package:stock_investment_tracker/domain/entities/sale.dart';
import 'package:stock_investment_tracker/domain/entities/stock_summary.dart';
import 'package:stock_investment_tracker/domain/enums/lot_status.dart';

class PortfolioCalculator {
  static double _round(double value) {
    return (value * 100).roundToDouble() / 100;
  }

  static int calculateTotalSharesSold(List<Sale> sales) {
    if (sales.isEmpty) return 0;
    return sales.fold(0, (sum, sale) => sum + sale.sharesSold);
  }

  static int calculateSharesRemaining(Lot lot) {
    return lot.sharesPurchased - calculateTotalSharesSold(lot.sales);
  }

  static double calculateAmountInvestedRemaining(Lot lot) {
    final remainingShares = calculateSharesRemaining(lot);
    return _round(remainingShares * lot.buyPricePerShare);
  }

  static double calculateTotalAmountReceived(List<Sale> sales) {
    if (sales.isEmpty) return 0.0;
    return _round(sales.fold(0.0, (sum, sale) => sum + sale.amountReceived));
  }

  static double calculateRealizedProfitLoss(Lot lot) {
    if (lot.sales.isEmpty) return 0.0;
    double realized = 0.0;
    for (final sale in lot.sales) {
      final costBasis = sale.sharesSold * lot.buyPricePerShare;
      realized += (sale.amountReceived - costBasis);
    }
    return _round(realized);
  }

  static LotStatus calculateLotStatus(Lot lot) {
    final remaining = calculateSharesRemaining(lot);
    if (remaining == lot.sharesPurchased) return LotStatus.open;
    if (remaining == 0) return LotStatus.closed;
    return LotStatus.partiallySold;
  }

  static Lot enrichLot(Lot lot) {
    return lot.copyWith(
      sharesRemaining: calculateSharesRemaining(lot),
      amountInvestedRemaining: calculateAmountInvestedRemaining(lot),
      realizedProfitLoss: calculateRealizedProfitLoss(lot),
      status: calculateLotStatus(lot),
    );
  }

  static List<StockSummary> calculateStockSummaries(List<Lot> allLots) {
    final map = <String, List<Lot>>{};
    for (final lot in allLots) {
      map.putIfAbsent(lot.ticker, () => []).add(lot);
    }

    final totalPortfolioInvested = _round(allLots.fold(
      0.0,
      (sum, lot) => sum + calculateAmountInvestedRemaining(lot),
    ));

    final summaries = <StockSummary>[];
    for (final entry in map.entries) {
      final ticker = entry.key;
      final lots = entry.value;

      int sharesHeld = 0;
      double amountInvestedOpen = 0.0;
      double realizedPL = 0.0;

      for (final lot in lots) {
        sharesHeld += calculateSharesRemaining(lot);
        amountInvestedOpen += calculateAmountInvestedRemaining(lot);
        realizedPL += calculateRealizedProfitLoss(lot);
      }

      double avgBuyPrice = 0.0;
      if (sharesHeld > 0) {
        avgBuyPrice = amountInvestedOpen / sharesHeld;
      }

      LotStatus status = LotStatus.closed;
      if (sharesHeld > 0) {
        final anySales = lots.any((lot) => lot.sales.isNotEmpty);
        final anyPartial = lots.any((lot) => calculateLotStatus(lot) == LotStatus.partiallySold);
        if (anyPartial || (sharesHeld < lots.fold(0, (sum, lot) => sum + lot.sharesPurchased))) {
          status = LotStatus.partiallySold;
        } else {
          status = LotStatus.open;
        }
      }

      double allocationPercent = 0.0;
      if (totalPortfolioInvested > 0) {
        allocationPercent = (amountInvestedOpen / totalPortfolioInvested) * 100;
      }

      summaries.add(StockSummary(
        ticker: ticker,
        sharesHeld: sharesHeld,
        amountInvestedOpen: _round(amountInvestedOpen),
        realizedPL: _round(realizedPL),
        avgBuyPrice: _round(avgBuyPrice),
        status: status,
        allocationPercent: _round(allocationPercent),
      ));
    }

    summaries.sort((a, b) => b.amountInvestedOpen.compareTo(a.amountInvestedOpen));
    return summaries;
  }

  static PortfolioSummary calculatePortfolioSummary(
    List<Lot> allLots,
    double startingCapital,
  ) {
    double totalInvested = 0.0;
    double currentlyInvested = 0.0;
    double realizedPL = 0.0;
    int openLots = 0;

    for (final lot in allLots) {
      totalInvested += lot.amountInvested;
      currentlyInvested += calculateAmountInvestedRemaining(lot);
      realizedPL += calculateRealizedProfitLoss(lot);
      if (calculateLotStatus(lot) != LotStatus.closed) {
        openLots++;
      }
    }

    final freeCash = startingCapital - currentlyInvested + realizedPL;
    final portfolioValue = freeCash + currentlyInvested;

    return PortfolioSummary(
      totalInvested: _round(totalInvested),
      currentlyInvested: _round(currentlyInvested),
      realizedPL: _round(realizedPL),
      freeCash: _round(freeCash),
      openLots: openLots,
      portfolioValue: _round(portfolioValue),
    );
  }

  static List<AllocationSegment> calculateAllocation(List<StockSummary> summaries) {
    return summaries
        .where((s) => s.sharesHeld > 0)
        .map((s) => AllocationSegment(
              ticker: s.ticker,
              amount: s.amountInvestedOpen,
              percentage: s.allocationPercent,
            ))
        .toList();
  }
}
