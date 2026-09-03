// CHARACTERISATION TEST — DO NOT "FIX" THESE NUMBERS.
//
// This file records what PortfolioCalculator produced BEFORE the Phase 03
// position-merge migration. Phase 03 must reproduce every value here exactly.
//
// If a change makes this file fail, the change altered user-visible financial
// figures. That is the signal this test exists to raise. Investigate the change
// — do not update the expected values to match new output.

import 'package:flutter_test/flutter_test.dart';
import 'package:stock_investment_tracker/domain/entities/lot.dart';
import 'package:stock_investment_tracker/domain/entities/sale.dart';
import 'package:stock_investment_tracker/domain/enums/lot_status.dart';
import 'package:stock_investment_tracker/domain/calculator/portfolio_calculator.dart';
import 'package:stock_investment_tracker/domain/entities/withdrawal.dart';

void main() {
  group('PortfolioCalculator Characterisation', () {
    final lots = [
      Lot(
        id: 'lot-stpl-1',
        ticker: 'STPL',
        buyDate: DateTime.parse('2026-08-31'),
        sharesPurchased: 500,
        buyPricePerShare: 8.73,
        amountInvested: 4365.0,
        targetPrice: 10.00,
        sales: [
          Sale(id: 's1', sellDate: DateTime.parse('2026-09-01'), sharesSold: 200, sellPricePerShare: 9.0, amountReceived: 1800.0),
          Sale(id: 's2', sellDate: DateTime.parse('2026-09-02'), sharesSold: 100, sellPricePerShare: 8.50, amountReceived: 850.0),
        ],
      ),
      Lot(
        id: 'lot-stpl-2',
        ticker: 'STPL',
        buyDate: DateTime.parse('2026-09-07'),
        sharesPurchased: 1200,
        buyPricePerShare: 8.38,
        amountInvested: 10056.0,
        targetPrice: null,
        sales: [
          Sale(id: 's3', sellDate: DateTime.parse('2026-09-08'), sharesSold: 1200, sellPricePerShare: 9.10, amountReceived: 10920.0),
        ],
      ),
      Lot(
        id: 'lot-engro-1',
        ticker: 'ENGRO',
        buyDate: DateTime.parse('2026-07-15'),
        sharesPurchased: 300,
        buyPricePerShare: 350.00,
        amountInvested: 105000.0,
        targetPrice: 400.00,
        sales: [
          Sale(id: 's4', sellDate: DateTime.parse('2026-07-20'), sharesSold: 100, sellPricePerShare: 380.0, amountReceived: 38000.0),
          Sale(id: 's5', sellDate: DateTime.parse('2026-07-25'), sharesSold: 100, sellPricePerShare: 340.0, amountReceived: 34000.0),
          Sale(id: 's6', sellDate: DateTime.parse('2026-08-05'), sharesSold: 100, sellPricePerShare: 390.0, amountReceived: 39000.0),
        ],
      ),
      Lot(
        id: 'lot-engro-2',
        ticker: 'ENGRO',
        buyDate: DateTime.parse('2026-08-01'),
        sharesPurchased: 500,
        buyPricePerShare: 360.00,
        amountInvested: 180000.0,
        targetPrice: null,
        sales: [
          Sale(id: 's7', sellDate: DateTime.parse('2026-08-10'), sharesSold: 200, sellPricePerShare: 370.0, amountReceived: 74000.0),
          Sale(id: 's8', sellDate: DateTime.parse('2026-08-15'), sharesSold: 50, sellPricePerShare: 350.0, amountReceived: 17500.0),
        ],
      ),
      Lot(
        id: 'lot-sys-1',
        ticker: 'SYS',
        buyDate: DateTime.parse('2026-08-20'),
        sharesPurchased: 100,
        buyPricePerShare: 520.00,
        amountInvested: 52000.0,
        targetPrice: 600.00,
        sales: [
          Sale(id: 's9', sellDate: DateTime.parse('2026-08-25'), sharesSold: 40, sellPricePerShare: 550.0, amountReceived: 22000.0),
        ],
      ),
      Lot(
        id: 'lot-sys-2',
        ticker: 'SYS',
        buyDate: DateTime.parse('2026-09-01'),
        sharesPurchased: 200,
        buyPricePerShare: 510.00,
        amountInvested: 102000.0,
        targetPrice: null,
        sales: [
          Sale(id: 's10', sellDate: DateTime.parse('2026-09-05'), sharesSold: 100, sellPricePerShare: 530.0, amountReceived: 53000.0),
          Sale(id: 's11', sellDate: DateTime.parse('2026-09-10'), sharesSold: 100, sellPricePerShare: 490.0, amountReceived: 49000.0),
        ],
      ),
      Lot(
        id: 'lot-ogdc-1',
        ticker: 'OGDC',
        buyDate: DateTime.parse('2026-08-10'),
        sharesPurchased: 400,
        buyPricePerShare: 100.00,
        amountInvested: 40000.0,
        targetPrice: 120.00,
        sales: [],
      ),
      Lot(
        id: 'lot-ogdc-2',
        ticker: 'OGDC',
        buyDate: DateTime.parse('2026-08-15'),
        sharesPurchased: 600,
        buyPricePerShare: 105.00,
        amountInvested: 63000.0,
        targetPrice: null,
        sales: [
          Sale(id: 's12', sellDate: DateTime.parse('2026-08-20'), sharesSold: 200, sellPricePerShare: 98.00, amountReceived: 19600.0),
        ],
      ),
    ];

    final withdrawals = [
      Withdrawal(id: 'w1', date: DateTime.parse('2026-08-20'), amount: 15000.0, note: 'w1'),
      Withdrawal(id: 'w2', date: DateTime.parse('2026-09-01'), amount: 7500.0, note: 'w2'),
    ];

    final enrichedLots = lots.map((l) => PortfolioCalculator.enrichLot(l)).toList();
    final totalWithdrawn = PortfolioCalculator.calculateTotalWithdrawn(withdrawals);

    test('reproduces exact PortfolioSummary values', () {
      final summary = PortfolioCalculator.calculatePortfolioSummary(enrichedLots, 500000.0, totalWithdrawn);
      
      expect(summary.startingCapital, closeTo(500000.0, 0.01));
      expect(summary.totalInvested, closeTo(500000.0, 0.01));
      expect(summary.currentlyInvested, closeTo(204946.0, 0.01));
      expect(summary.realizedPL, closeTo(-14305.0, 0.01));
      expect(summary.grossRealizedPL, closeTo(8195.0, 0.01));
      expect(summary.totalWithdrawn, closeTo(22500.0, 0.01));
      expect(summary.freeCash, closeTo(295054.0, 0.01));
      expect(summary.totalCash, closeTo(280749.0, 0.01));
      expect(summary.openLots, 5);
      expect(summary.portfolioValue, closeTo(485695.0, 0.01));
    });

    test('reproduces exact stock summaries aggregation', () {
      final summaries = PortfolioCalculator.calculateStockSummaries(enrichedLots);
      expect(summaries.length, 4);

      final engro = summaries.firstWhere((s) => s.ticker == 'ENGRO');
      expect(engro.sharesHeld, 250);
      expect(engro.amountInvestedOpen, closeTo(90000.0, 0.01));
      expect(engro.realizedPL, closeTo(7500.0, 0.01));
      expect(engro.avgBuyPrice, closeTo(360.0, 0.01));
      expect(engro.status, LotStatus.partiallySold);
      expect(engro.allocationPercent, closeTo(43.91, 0.01));

      final ogdc = summaries.firstWhere((s) => s.ticker == 'OGDC');
      expect(ogdc.sharesHeld, 800);
      expect(ogdc.amountInvestedOpen, closeTo(82000.0, 0.01));
      expect(ogdc.realizedPL, closeTo(-1400.0, 0.01));
      expect(ogdc.avgBuyPrice, closeTo(102.5, 0.01));
      expect(ogdc.status, LotStatus.partiallySold);
      expect(ogdc.allocationPercent, closeTo(40.01, 0.01));

      final sys = summaries.firstWhere((s) => s.ticker == 'SYS');
      expect(sys.sharesHeld, 60);
      expect(sys.amountInvestedOpen, closeTo(31200.0, 0.01));
      expect(sys.realizedPL, closeTo(1200.0, 0.01));
      expect(sys.avgBuyPrice, closeTo(520.0, 0.01));
      expect(sys.status, LotStatus.partiallySold);
      expect(sys.allocationPercent, closeTo(15.22, 0.01));

      final stpl = summaries.firstWhere((s) => s.ticker == 'STPL');
      expect(stpl.sharesHeld, 200);
      expect(stpl.amountInvestedOpen, closeTo(1746.0, 0.01));
      expect(stpl.realizedPL, closeTo(895.0, 0.01));
      expect(stpl.avgBuyPrice, closeTo(8.73, 0.01));
      expect(stpl.status, LotStatus.partiallySold);
      expect(stpl.allocationPercent, closeTo(0.85, 0.01));
    });

    test('reproduces exact allocation segments', () {
      final summaries = PortfolioCalculator.calculateStockSummaries(enrichedLots);
      final allocations = PortfolioCalculator.calculateAllocation(summaries);
      
      expect(allocations.length, 4);

      final engro = allocations.firstWhere((a) => a.ticker == 'ENGRO');
      expect(engro.amount, closeTo(90000.0, 0.01));
      expect(engro.percentage, closeTo(43.91, 0.01));

      final ogdc = allocations.firstWhere((a) => a.ticker == 'OGDC');
      expect(ogdc.amount, closeTo(82000.0, 0.01));
      expect(ogdc.percentage, closeTo(40.01, 0.01));

      final sys = allocations.firstWhere((a) => a.ticker == 'SYS');
      expect(sys.amount, closeTo(31200.0, 0.01));
      expect(sys.percentage, closeTo(15.22, 0.01));

      final stpl = allocations.firstWhere((a) => a.ticker == 'STPL');
      expect(stpl.amount, closeTo(1746.0, 0.01));
      expect(stpl.percentage, closeTo(0.85, 0.01));

      final sumPercent = allocations.fold(0.0, (sum, a) => sum + a.percentage);
      expect(sumPercent, closeTo(100.0, 0.05));
    });

    test('reproduces enrichLot output for STPL lots', () {
      final stpl1 = enrichedLots.firstWhere((l) => l.id == 'lot-stpl-1');
      expect(stpl1.sharesRemaining, 200);
      expect(stpl1.amountInvestedRemaining, closeTo(1746.0, 0.01));
      expect(stpl1.realizedProfitLoss, closeTo(31.0, 0.01));
      expect(stpl1.status, LotStatus.partiallySold);

      final stpl2 = enrichedLots.firstWhere((l) => l.id == 'lot-stpl-2');
      expect(stpl2.sharesRemaining, 0);
      expect(stpl2.amountInvestedRemaining, closeTo(0.0, 0.01));
      expect(stpl2.realizedProfitLoss, closeTo(864.0, 0.01));
      expect(stpl2.status, LotStatus.closed);
    });
  });
}
