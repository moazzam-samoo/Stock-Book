import 'package:flutter_test/flutter_test.dart';
import 'package:stock_investment_tracker/domain/calculator/portfolio_calculator.dart';
import 'package:stock_investment_tracker/domain/entities/lot.dart';
import 'package:stock_investment_tracker/domain/entities/sale.dart';
import 'package:stock_investment_tracker/domain/enums/lot_status.dart';

void main() {
  group('PortfolioCalculator', () {
    test('calculateSharesRemaining subtracts sold shares', () {
      final lot = Lot(
        id: '1',
        ticker: 'AAPL',
        buyDate: DateTime.now(),
        sharesPurchased: 100,
        buyPricePerShare: 150.0,
        amountInvested: 15000.0,
        sales: [
          Sale(
            id: 's1',
            sellDate: DateTime.now(),
            sharesSold: 20,
            sellPricePerShare: 160.0,
            amountReceived: 3200.0,
          ),
          Sale(
            id: 's2',
            sellDate: DateTime.now(),
            sharesSold: 30,
            sellPricePerShare: 170.0,
            amountReceived: 5100.0,
          ),
        ],
      );

      final remaining = PortfolioCalculator.calculateSharesRemaining(lot);
      expect(remaining, 50);
    });

    test('calculateAmountInvestedRemaining calculates based on remaining shares', () {
      final lot = Lot(
        id: '1',
        ticker: 'AAPL',
        buyDate: DateTime.now(),
        sharesPurchased: 100,
        buyPricePerShare: 150.0,
        amountInvested: 15000.0,
        sales: [
          Sale(
            id: 's1',
            sellDate: DateTime.now(),
            sharesSold: 20,
            sellPricePerShare: 160.0,
            amountReceived: 3200.0,
          ),
        ],
      );

      final investedRemaining = PortfolioCalculator.calculateAmountInvestedRemaining(lot);
      expect(investedRemaining, 12000.0); // 80 * 150
    });

    test('calculateRealizedProfitLoss calculates correctly', () {
      final lot = Lot(
        id: '1',
        ticker: 'AAPL',
        buyDate: DateTime.now(),
        sharesPurchased: 100,
        buyPricePerShare: 100.0,
        amountInvested: 10000.0,
        sales: [
          Sale(
            id: 's1',
            sellDate: DateTime.now(),
            sharesSold: 50,
            sellPricePerShare: 150.0,
            amountReceived: 7500.0,
          ),
        ],
      );

      // PL = amountReceived - (sharesSold * buyPrice)
      // PL = 7500 - (50 * 100) = 2500
      final realizedPL = PortfolioCalculator.calculateRealizedProfitLoss(lot);
      expect(realizedPL, 2500.0);
    });

    test('calculateLotStatus returns correct status', () {
      final openLot = Lot(
        id: '1',
        ticker: 'AAPL',
        buyDate: DateTime.now(),
        sharesPurchased: 100,
        buyPricePerShare: 100.0,
        amountInvested: 10000.0,
        sales: [],
      );

      final partialLot = openLot.copyWith(sales: [
        Sale(id: 's1', sellDate: DateTime.now(), sharesSold: 50, sellPricePerShare: 150.0, amountReceived: 7500.0)
      ]);

      final closedLot = openLot.copyWith(sales: [
        Sale(id: 's1', sellDate: DateTime.now(), sharesSold: 100, sellPricePerShare: 150.0, amountReceived: 15000.0)
      ]);

      expect(PortfolioCalculator.calculateLotStatus(openLot), LotStatus.open);
      expect(PortfolioCalculator.calculateLotStatus(partialLot), LotStatus.partiallySold);
      expect(PortfolioCalculator.calculateLotStatus(closedLot), LotStatus.closed);
    });

    test('calculateStockSummaries aggregates multiple lots correctly', () {
      final lot1 = Lot(
        id: '1',
        ticker: 'AAPL',
        buyDate: DateTime.now(),
        sharesPurchased: 10,
        buyPricePerShare: 100.0,
        amountInvested: 1000.0,
      );

      final lot2 = Lot(
        id: '2',
        ticker: 'AAPL',
        buyDate: DateTime.now(),
        sharesPurchased: 20,
        buyPricePerShare: 150.0,
        amountInvested: 3000.0,
      );

      final lot3 = Lot(
        id: '3',
        ticker: 'MSFT',
        buyDate: DateTime.now(),
        sharesPurchased: 5,
        buyPricePerShare: 200.0,
        amountInvested: 1000.0,
        sales: [
          Sale(id: 's1', sellDate: DateTime.now(), sharesSold: 5, sellPricePerShare: 250.0, amountReceived: 1250.0)
        ]
      );

      final summaries = PortfolioCalculator.calculateStockSummaries([lot1, lot2, lot3]);
      
      expect(summaries.length, 2);
      
      final aapl = summaries.firstWhere((s) => s.ticker == 'AAPL');
      expect(aapl.sharesHeld, 30);
      expect(aapl.amountInvestedOpen, 4000.0);
      expect(aapl.avgBuyPrice, 133.33);
      expect(aapl.realizedPL, 0.0);
      expect(aapl.status, LotStatus.open);
      expect(aapl.allocationPercent, 100.0); // Only open investments are counted for allocation (MSFT is closed)

      final msft = summaries.firstWhere((s) => s.ticker == 'MSFT');
      expect(msft.sharesHeld, 0);
      expect(msft.amountInvestedOpen, 0.0);
      expect(msft.realizedPL, 250.0); // 1250 - 1000
      expect(msft.status, LotStatus.closed);
      expect(msft.allocationPercent, 0.0);
    });

    test('calculatePortfolioSummary aggregates totals correctly', () {
      final lot1 = Lot(
        id: '1',
        ticker: 'AAPL',
        buyDate: DateTime.now(),
        sharesPurchased: 10,
        buyPricePerShare: 100.0,
        amountInvested: 1000.0,
      );

      final lot2 = Lot(
        id: '2',
        ticker: 'MSFT',
        buyDate: DateTime.now(),
        sharesPurchased: 10,
        buyPricePerShare: 200.0,
        amountInvested: 2000.0,
        sales: [
          Sale(id: 's1', sellDate: DateTime.now(), sharesSold: 10, sellPricePerShare: 300.0, amountReceived: 3000.0)
        ]
      );

      final summary = PortfolioCalculator.calculatePortfolioSummary([lot1, lot2], 10000.0);

      // total invested = starting capital = 10000
      // currently invested = 1000 (AAPL)
      // realized PL = 1000 (MSFT)
      // free cash (uninvested base capital) = 10000 - 1000 = 9000
      // portfolio value = 10000 (starting capital) + 1000 (profit) = 11000
      
      expect(summary.startingCapital, 10000.0);
      expect(summary.totalInvested, 10000.0);
      expect(summary.currentlyInvested, 1000.0);
      expect(summary.realizedPL, 1000.0);
      expect(summary.freeCash, 9000.0);
      expect(summary.openLots, 1);
      expect(summary.portfolioValue, 11000.0);
    });
  });
}
