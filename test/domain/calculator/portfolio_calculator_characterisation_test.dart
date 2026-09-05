// CHARACTERISATION TEST — DO NOT "FIX" THESE NUMBERS.
//
// This file records what PortfolioCalculator produced BEFORE the Phase 03
// position-merge migration. Phase 03 must reproduce every value here exactly.
//
// If a change makes this file fail, the change altered user-visible financial
// figures. That is the signal this test exists to raise. Investigate the change
// — do not update the expected values to match new output.

import 'package:flutter_test/flutter_test.dart';
import 'package:stock_investment_tracker/domain/calculator/portfolio_calculator.dart';
import 'package:stock_investment_tracker/domain/enums/lot_status.dart';
import '../../fixtures/portfolio_fixture.dart';

void main() {
  group('PortfolioCalculator Characterisation', () {
    final enrichedLots = PortfolioFixture.enrichedLots;
    final totalWithdrawn = PortfolioFixture.totalWithdrawn;

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
