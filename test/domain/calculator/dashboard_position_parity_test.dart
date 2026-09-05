import 'package:flutter_test/flutter_test.dart';
import 'package:stock_investment_tracker/domain/calculator/portfolio_calculator.dart';
import 'package:stock_investment_tracker/domain/calculator/position_migration.dart';

import '../../fixtures/portfolio_fixture.dart';

/// Phase 03B required test 7 — the user-facing proof that nothing moved on
/// the dashboard: for the shared Phase 00 fixture, the position-derived
/// PortfolioSummary must equal the lot-derived one on every money figure.
///
/// `openLots` is the one deliberate exception. Pre-migration it counts
/// individual open/partial *lots*; post-migration `calculatePortfolioSummaryFromPositions`
/// counts open/partial *positions* — and the fixture has 2 lots per ticker,
/// so a lot that closed (fully sold) can end up merged into the same
/// position as a sibling lot that's still open, changing the count. That's
/// the entire point of the merge feature, not a regression — see the "STPL
/// shows as one card" acceptance criterion in PHASE-03B-position-ui.md.
void main() {
  group('Dashboard parity: positions vs lots', () {
    final positions = PositionMigration.buildPositions(PortfolioFixture.baseLots).positions;

    test('migration reports the fixture as valid (sanity check for the rest of this test)', () {
      final result = PositionMigration.buildPositions(PortfolioFixture.baseLots);
      expect(result.isValid, isTrue, reason: result.warnings.join(', '));
    });

    test('every money figure matches field-for-field with no starting capital set', () {
      final fromLots = PortfolioCalculator.calculatePortfolioSummary(
        PortfolioFixture.enrichedLots,
        0.0,
        PortfolioFixture.totalWithdrawn,
      );
      final fromPositions = PortfolioCalculator.calculatePortfolioSummaryFromPositions(
        positions,
        0.0,
        PortfolioFixture.totalWithdrawn,
      );

      expect(fromPositions.startingCapital, fromLots.startingCapital);
      expect(fromPositions.totalInvested, fromLots.totalInvested);
      expect(fromPositions.currentlyInvested, fromLots.currentlyInvested);
      expect(fromPositions.realizedPL, fromLots.realizedPL);
      expect(fromPositions.grossRealizedPL, fromLots.grossRealizedPL);
      expect(fromPositions.totalWithdrawn, fromLots.totalWithdrawn);
      expect(fromPositions.freeCash, fromLots.freeCash);
      expect(fromPositions.totalCash, fromLots.totalCash);
      expect(fromPositions.portfolioValue, fromLots.portfolioValue);
    });

    test('every money figure matches field-for-field with starting capital set', () {
      const startingCapital = 500000.0;
      final fromLots = PortfolioCalculator.calculatePortfolioSummary(
        PortfolioFixture.enrichedLots,
        startingCapital,
        PortfolioFixture.totalWithdrawn,
      );
      final fromPositions = PortfolioCalculator.calculatePortfolioSummaryFromPositions(
        positions,
        startingCapital,
        PortfolioFixture.totalWithdrawn,
      );

      expect(fromPositions.totalInvested, fromLots.totalInvested);
      expect(fromPositions.currentlyInvested, fromLots.currentlyInvested);
      expect(fromPositions.realizedPL, fromLots.realizedPL);
      expect(fromPositions.freeCash, fromLots.freeCash);
      expect(fromPositions.totalCash, fromLots.totalCash);
      expect(fromPositions.portfolioValue, fromLots.portfolioValue);
    });

    test('openLots deliberately differs: 4 tickers with 2 lots each merge to fewer open groups', () {
      final fromLots = PortfolioCalculator.calculatePortfolioSummary(
        PortfolioFixture.enrichedLots,
        0.0,
        PortfolioFixture.totalWithdrawn,
      );
      final fromPositions = PortfolioCalculator.calculatePortfolioSummaryFromPositions(
        positions,
        0.0,
        PortfolioFixture.totalWithdrawn,
      );

      // 8 lots across 4 tickers -> at most 4 open/partial positions, but more
      // than 4 open/partial lots (several lots per ticker are individually
      // still open/partial even where their sibling has fully closed).
      expect(positions.length, 4, reason: 'one merged position per ticker');
      expect(fromPositions.openLots, 4);
      expect(fromLots.openLots, greaterThan(fromPositions.openLots));
    });

    test('stock summaries: total invested and realized P/L match in aggregate', () {
      final lotSummaries = PortfolioCalculator.calculateStockSummaries(PortfolioFixture.enrichedLots);
      final positionSummaries = PortfolioCalculator.calculateStockSummariesFromPositions(positions);

      final lotsTotalInvested = lotSummaries.fold<double>(0, (sum, s) => sum + s.amountInvestedOpen);
      final positionsTotalInvested = positionSummaries.fold<double>(0, (sum, s) => sum + s.amountInvestedOpen);
      expect(positionsTotalInvested, closeTo(lotsTotalInvested, 0.01));

      final lotsTotalRealized = lotSummaries.fold<double>(0, (sum, s) => sum + s.realizedPL);
      final positionsTotalRealized = positionSummaries.fold<double>(0, (sum, s) => sum + s.realizedPL);
      expect(positionsTotalRealized, closeTo(lotsTotalRealized, 0.01));

      // One row per ticker post-merge, same 4 tickers as the lot-based rows.
      expect(positionSummaries.map((s) => s.ticker).toSet(), lotSummaries.map((s) => s.ticker).toSet());
    });
  });
}
