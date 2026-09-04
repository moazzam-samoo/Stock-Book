import 'package:stock_investment_tracker/domain/calculator/portfolio_calculator.dart';
import 'package:stock_investment_tracker/domain/calculator/position_calculator.dart';
import 'package:stock_investment_tracker/domain/entities/lot.dart';
import 'package:stock_investment_tracker/domain/entities/position.dart';
import 'package:stock_investment_tracker/domain/entities/position_buy.dart';
import 'package:stock_investment_tracker/domain/entities/position_sale.dart';
import 'package:uuid/uuid.dart';

class MigrationResult {
  final List<Position> positions;
  final bool isValid;
  final List<String> warnings;
  final double lotsGrossRealizedPL;
  final double positionsGrossRealizedPL;
  final double lotsCurrentlyInvested;
  final double positionsCurrentlyInvested;

  MigrationResult({
    required this.positions,
    required this.isValid,
    required this.warnings,
    required this.lotsGrossRealizedPL,
    required this.positionsGrossRealizedPL,
    required this.lotsCurrentlyInvested,
    required this.positionsCurrentlyInvested,
  });
}

class PositionMigration {
  static MigrationResult buildPositions(List<Lot> lots) {
    List<Position> migratedPositions = [];
    List<String> warnings = [];

    // Group lots by ticker
    final map = <String, List<Lot>>{};
    for (final lot in lots) {
      map.putIfAbsent(lot.ticker, () => []).add(lot);
    }

    final uuid = Uuid();

    for (final entry in map.entries) {
      final ticker = entry.key;
      final tickerLots = entry.value;

      List<PositionBuy> buys = [];
      List<PositionSale> sales = [];
      
      // Determine target price by picking the most recent valid target price
      // based on the original lots.
      tickerLots.sort((a, b) => a.buyDate.compareTo(b.buyDate));
      double? activeTargetPrice;
      
      for (final lot in tickerLots) {
        if (lot.targetPrice != null) {
          activeTargetPrice = lot.targetPrice;
        }

        buys.add(PositionBuy(
          id: lot.id, // Re-use the lot ID to map original lot to the buy event
          date: lot.buyDate,
          shares: lot.sharesPurchased,
          pricePerShare: lot.buyPricePerShare,
        ));

        for (final sale in lot.sales) {
          sales.add(PositionSale(
            id: sale.id, // Re-use original sale ID
            date: sale.sellDate,
            shares: sale.sharesSold,
            pricePerShare: sale.sellPricePerShare,
            costBasisAtSale: lot.buyPricePerShare, // FROZEN basis ensures identical historical P/L
          ));
        }
      }

      final positions = PositionCalculator.replay(ticker, buys, sales);

      // If there are multiple positions and the last one is open, assign the target price to it.
      if (positions.isNotEmpty) {
        final last = positions.last;
        final updatedLast = last.copyWith(
          id: uuid.v4(),
          targetPrice: activeTargetPrice,
        );
        for (int i = 0; i < positions.length - 1; i++) {
          migratedPositions.add(positions[i].copyWith(id: uuid.v4()));
        }
        migratedPositions.add(updatedLast);
      }
    }

    // Validation
    double lotsRealized = 0.0;
    double lotsInvested = 0.0;
    for (final lot in lots) {
      lotsRealized += PortfolioCalculator.calculateRealizedProfitLoss(lot);
      lotsInvested += PortfolioCalculator.calculateAmountInvestedRemaining(lot);
    }

    double posRealized = 0.0;
    double posInvested = 0.0;
    for (final pos in migratedPositions) {
      posRealized += PositionCalculator.realizedPL(pos);
      posInvested += PositionCalculator.amountInvested(pos);
    }

    // Need a tiny epsilon for float comparisons
    bool isValid = (lotsRealized - posRealized).abs() < 0.01 &&
                   (lotsInvested - posInvested).abs() < 0.01;

    if (!isValid) {
      warnings.add('Invariant violation: Math does not match original lots.');
      warnings.add('Lots -> Realized: $lotsRealized, Invested: $lotsInvested');
      warnings.add('Pos  -> Realized: $posRealized, Invested: $posInvested');
    }

    return MigrationResult(
      positions: migratedPositions,
      isValid: isValid,
      warnings: warnings,
      lotsGrossRealizedPL: lotsRealized,
      positionsGrossRealizedPL: posRealized,
      lotsCurrentlyInvested: lotsInvested,
      positionsCurrentlyInvested: posInvested,
    );
  }
}
