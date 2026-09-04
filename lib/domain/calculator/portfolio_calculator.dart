import 'package:stock_investment_tracker/domain/entities/allocation_segment.dart';
import 'package:stock_investment_tracker/domain/entities/lot.dart';
import 'package:stock_investment_tracker/domain/entities/portfolio_summary.dart';
import 'package:stock_investment_tracker/domain/entities/sale.dart';
import 'package:stock_investment_tracker/domain/entities/stock_summary.dart';
import 'package:stock_investment_tracker/domain/entities/withdrawal.dart';
import 'package:stock_investment_tracker/domain/enums/lot_status.dart';
import 'package:stock_investment_tracker/domain/entities/position.dart';
import 'package:stock_investment_tracker/domain/calculator/position_calculator.dart';
import 'package:stock_investment_tracker/domain/enums/position_status.dart';

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

    final totalPortfolioInvested = _round(
      allLots.fold(
        0.0,
        (sum, lot) => sum + calculateAmountInvestedRemaining(lot),
      ),
    );

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
        final anyPartial = lots.any(
          (lot) => calculateLotStatus(lot) == LotStatus.partiallySold,
        );
        if (anyPartial ||
            (sharesHeld <
                lots.fold(0, (sum, lot) => sum + lot.sharesPurchased))) {
          status = LotStatus.partiallySold;
        } else {
          status = LotStatus.open;
        }
      }

      double allocationPercent = 0.0;
      if (totalPortfolioInvested > 0) {
        allocationPercent = (amountInvestedOpen / totalPortfolioInvested) * 100;
      }

      summaries.add(
        StockSummary(
          ticker: ticker,
          sharesHeld: sharesHeld,
          amountInvestedOpen: _round(amountInvestedOpen),
          realizedPL: _round(realizedPL),
          avgBuyPrice: _round(avgBuyPrice),
          status: status,
          allocationPercent: _round(allocationPercent),
        ),
      );
    }

    summaries.sort(
      (a, b) => b.amountInvestedOpen.compareTo(a.amountInvestedOpen),
    );
    return summaries;
  }

  static double calculateTotalWithdrawn(List<Withdrawal> withdrawals) {
    if (withdrawals.isEmpty) return 0.0;
    return _round(withdrawals.fold(0.0, (sum, w) => sum + w.amount));
  }

  /// Aggregates the dashboard figures.
  ///
  /// [totalWithdrawn] is cash taken out of profit. It is subtracted from the
  /// realized P/L, which in turn pulls down the portfolio value and the liquid
  /// capital. Starting capital, currently-invested and free cash are
  /// deliberately left untouched — withdrawing profit does not change how much
  /// capital you started with or how much is sitting in stocks.
  static PortfolioSummary calculatePortfolioSummary(
    List<Lot> allLots,
    double startingCapital, [
    double totalWithdrawn = 0.0,
  ]) {
    double currentlyInvested = 0.0;
    double grossRealizedPL = 0.0;
    int openLots = 0;

    for (final lot in allLots) {
      currentlyInvested += calculateAmountInvestedRemaining(lot);
      grossRealizedPL += calculateRealizedProfitLoss(lot);
      if (calculateLotStatus(lot) != LotStatus.closed) {
        openLots++;
      }
    }

    // Net of withdrawals: everything downstream inherits the reduction.
    final realizedPL = grossRealizedPL - totalWithdrawn;

    final bool hasStartingCapital = startingCapital > 0;
    final totalInvested = hasStartingCapital
        ? startingCapital
        : currentlyInvested;
    final freeCash = hasStartingCapital
        ? (startingCapital - currentlyInvested)
        : 0.0;
    final portfolioValue = hasStartingCapital
        ? (startingCapital + realizedPL)
        : (currentlyInvested + realizedPL);
    final totalCash = hasStartingCapital
        ? (startingCapital - currentlyInvested + realizedPL)
        : realizedPL;

    return PortfolioSummary(
      startingCapital: _round(startingCapital),
      totalInvested: _round(totalInvested),
      currentlyInvested: _round(currentlyInvested),
      realizedPL: _round(realizedPL),
      grossRealizedPL: _round(grossRealizedPL),
      totalWithdrawn: _round(totalWithdrawn),
      freeCash: _round(freeCash),
      totalCash: _round(totalCash),
      openLots: openLots,
      portfolioValue: _round(portfolioValue),
    );
  }

  static PortfolioSummary calculatePortfolioSummaryFromPositions(
    List<Position> allPositions,
    double startingCapital, [
    double totalWithdrawn = 0.0,
  ]) {
    double currentlyInvested = 0.0;
    double grossRealizedPL = 0.0;
    int openLots = 0; // Using "openLots" to match PortfolioSummary field (it means open positions now)

    for (final position in allPositions) {
      currentlyInvested += PositionCalculator.amountInvested(position);
      grossRealizedPL += PositionCalculator.realizedPL(position);
      if (position.status != PositionStatus.closed) {
        openLots++;
      }
    }

    // Net of withdrawals: everything downstream inherits the reduction.
    final realizedPL = grossRealizedPL - totalWithdrawn;

    final bool hasStartingCapital = startingCapital > 0;
    final totalInvested = hasStartingCapital
        ? startingCapital
        : currentlyInvested;
    final freeCash = hasStartingCapital
        ? (startingCapital - currentlyInvested)
        : 0.0;
    final portfolioValue = hasStartingCapital
        ? (startingCapital + realizedPL)
        : (currentlyInvested + realizedPL);
    final totalCash = hasStartingCapital
        ? (startingCapital - currentlyInvested + realizedPL)
        : realizedPL;

    return PortfolioSummary(
      startingCapital: _round(startingCapital),
      totalInvested: _round(totalInvested),
      currentlyInvested: _round(currentlyInvested),
      realizedPL: _round(realizedPL),
      grossRealizedPL: _round(grossRealizedPL),
      totalWithdrawn: _round(totalWithdrawn),
      freeCash: _round(freeCash),
      totalCash: _round(totalCash),
      openLots: openLots,
      portfolioValue: _round(portfolioValue),
    );
  }

  static List<AllocationSegment> calculateAllocation(
    List<StockSummary> summaries,
  ) {
    return summaries
        .where((s) => s.sharesHeld > 0)
        .map(
          (s) => AllocationSegment(
            ticker: s.ticker,
            amount: s.amountInvestedOpen,
            percentage: s.allocationPercent,
          ),
        )
        .toList();
  }

  /// One row per **ticker**, not per position — a ticker that was sold out and
  /// re-bought has several `Position` cycles, and the dashboard shows it once,
  /// exactly as the lot-based [calculateStockSummaries] always has.
  ///
  /// Closed cycles still contribute their realized P/L here; that profit is
  /// booked and must not disappear. Hiding tickers you no longer hold is the
  /// *dashboard widget's* job, not this function's — `exportOverallPortfolioPdf`
  /// and `MetricDetailCard` both read this list and need it complete.
  static List<StockSummary> calculateStockSummariesFromPositions(
    List<Position> allPositions,
  ) {
    if (allPositions.isEmpty) return [];

    final byTicker = <String, List<Position>>{};
    for (final pos in allPositions) {
      byTicker.putIfAbsent(pos.ticker, () => []).add(pos);
    }

    double totalPortfolioValue = 0.0;
    for (final pos in allPositions) {
      totalPortfolioValue += PositionCalculator.amountInvested(pos);
    }

    final summaries = <StockSummary>[];
    for (final entry in byTicker.entries) {
      final positions = entry.value;

      int sharesHeld = 0;
      double invested = 0.0;
      double realized = 0.0;
      bool anySales = false;
      for (final pos in positions) {
        sharesHeld += PositionCalculator.sharesHeld(pos);
        invested += PositionCalculator.amountInvested(pos);
        realized += PositionCalculator.realizedPL(pos);
        if (pos.sales.isNotEmpty) anySales = true;
      }

      // Aggregate status for the ticker as a whole: nothing held means the
      // ticker is closed even if an individual cycle says otherwise.
      final LotStatus status;
      if (sharesHeld <= 0) {
        status = LotStatus.closed;
      } else if (anySales) {
        status = LotStatus.partiallySold;
      } else {
        status = LotStatus.open;
      }

      final allocation =
          totalPortfolioValue > 0 ? (invested / totalPortfolioValue) * 100 : 0.0;

      summaries.add(StockSummary(
        ticker: entry.key,
        sharesHeld: sharesHeld,
        avgBuyPrice: PositionCalculator.blendedAvgCost(positions),
        amountInvestedOpen: _round(invested),
        realizedPL: _round(realized),
        status: status,
        allocationPercent: _round(allocation),
      ));
    }

    summaries.sort((a, b) => b.amountInvestedOpen.compareTo(a.amountInvestedOpen));
    return summaries;
  }

}
