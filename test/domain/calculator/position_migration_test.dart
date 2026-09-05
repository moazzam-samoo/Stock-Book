import 'package:flutter_test/flutter_test.dart';
import 'package:stock_investment_tracker/domain/calculator/position_calculator.dart';
import 'package:stock_investment_tracker/domain/calculator/position_migration.dart';
import 'package:stock_investment_tracker/domain/entities/lot.dart';
import 'package:stock_investment_tracker/domain/entities/sale.dart';
import 'package:stock_investment_tracker/domain/enums/position_status.dart';
import '../../fixtures/portfolio_fixture.dart';

void main() {
  group('PositionMigration Builder', () {
    test('builds positions from lots with exactly identical total math', () {
      final lots = PortfolioFixture.baseLots;
      final result = PositionMigration.buildPositions(lots);

      // ---- The most important output of this phase: print the actual
      // lot-based vs. position-based totals side by side. ----
      // ignore: avoid_print
      print('--- Migration invariant check (shared Phase 00 fixture) ---');
      // ignore: avoid_print
      print('Gross realized P/L  — lots: ${result.lotsGrossRealizedPL}, positions: ${result.positionsGrossRealizedPL}');
      // ignore: avoid_print
      print('Currently invested  — lots: ${result.lotsCurrentlyInvested}, positions: ${result.positionsCurrentlyInvested}');
      // ignore: avoid_print
      print('isValid: ${result.isValid}, warnings: ${result.warnings}');

      expect(result.isValid, isTrue, reason: 'Migration failed math assertions: ${result.warnings}');
      expect(result.warnings, isEmpty);
      expect(result.lotsGrossRealizedPL, closeTo(result.positionsGrossRealizedPL, 0.01));
      expect(result.lotsCurrentlyInvested, closeTo(result.positionsCurrentlyInvested, 0.01));

      // Independently re-verify shares held per ticker, not just trusting
      // isValid — this is the specific check that was missing before this
      // review (see position_migration.dart's validation step).
      final sharesByTicker = <String, int>{};
      for (final pos in result.positions) {
        sharesByTicker[pos.ticker] = (sharesByTicker[pos.ticker] ?? 0) + PositionCalculator.sharesHeld(pos);
      }
      final lotSharesByTicker = <String, int>{};
      for (final lot in lots) {
        lotSharesByTicker[lot.ticker] = (lotSharesByTicker[lot.ticker] ?? 0) +
            (lot.sharesPurchased - lot.sales.fold(0, (sum, s) => sum + s.sharesSold));
      }
      expect(sharesByTicker, lotSharesByTicker);

      // STPL and SYS never touch zero across the fixture's date range (a
      // later buy always lands before the pool empties — see AGENTS.md
      // §migration or the calculator's own zero-crossing test for why),
      // so they stay a single position each. Same for ENGRO: lot2's buy
      // (2026-08-01) happens before lot1's three sales fully deplete it, so
      // the combined pool never actually reaches zero either.
      final engroPositions = result.positions.where((p) => p.ticker == 'ENGRO').toList();
      expect(engroPositions.length, 1);
      expect(engroPositions[0].targetPrice, 400.0);

      final sysPositions = result.positions.where((p) => p.ticker == 'SYS').toList();
      expect(sysPositions.length, 1);

      final ogdcPositions = result.positions.where((p) => p.ticker == 'OGDC').toList();
      expect(ogdcPositions.length, 1);
      expect(ogdcPositions[0].targetPrice, 120.0);

      final stplPositions = result.positions.where((p) => p.ticker == 'STPL').toList();
      expect(stplPositions.length, 1);
    });

    test('is idempotent: running it twice on the same lots produces the same numbers', () {
      final lots = PortfolioFixture.baseLots;
      final first = PositionMigration.buildPositions(lots);
      final second = PositionMigration.buildPositions(lots);

      // Position ids are freshly generated (uuid.v4()) each call by design,
      // so object identity isn't the right check — the derived numbers are.
      expect(second.isValid, first.isValid);
      expect(second.positions.length, first.positions.length);
      expect(second.lotsGrossRealizedPL, first.lotsGrossRealizedPL);
      expect(second.positionsGrossRealizedPL, first.positionsGrossRealizedPL);
      expect(second.lotsCurrentlyInvested, first.lotsCurrentlyInvested);
      expect(second.positionsCurrentlyInvested, first.positionsCurrentlyInvested);

      for (var i = 0; i < first.positions.length; i++) {
        expect(second.positions[i].ticker, first.positions[i].ticker);
        expect(second.positions[i].status, first.positions[i].status);
        expect(PositionCalculator.sharesHeld(second.positions[i]), PositionCalculator.sharesHeld(first.positions[i]));
        expect(PositionCalculator.realizedPL(second.positions[i]), PositionCalculator.realizedPL(first.positions[i]));
      }
    });

    test("deliberately corrupt input (a sale exceeding its lot's shares) is caught: isValid is false with warnings", () {
      final corruptLot = Lot(
        id: 'corrupt-1',
        ticker: 'CORRUPT',
        buyDate: DateTime.parse('2026-01-01'),
        sharesPurchased: 100,
        buyPricePerShare: 10.0,
        amountInvested: 1000.0,
        sales: [
          // Selling 150 against a 100-share lot cannot happen through the
          // app's own flows (AddSellController clamps), but Firestore data
          // can be hand-edited or corrupted, and the migration must not
          // silently trust it.
          Sale(id: 'bad-sale', sellDate: DateTime.parse('2026-01-02'), sharesSold: 150, sellPricePerShare: 12.0, amountReceived: 1800.0),
        ],
      );

      final result = PositionMigration.buildPositions([corruptLot]);

      expect(result.isValid, isFalse);
      expect(result.warnings, isNotEmpty);
    });

    test("a target price conflict keeps the most recent buy's value and logs a warning", () {
      final olderLot = Lot(
        id: 'target-old',
        ticker: 'CONFLICT',
        buyDate: DateTime.parse('2026-01-01'),
        sharesPurchased: 100,
        buyPricePerShare: 10.0,
        amountInvested: 1000.0,
        targetPrice: 15.0,
        sales: const [],
      );
      final newerLot = Lot(
        id: 'target-new',
        ticker: 'CONFLICT',
        buyDate: DateTime.parse('2026-02-01'),
        sharesPurchased: 100,
        buyPricePerShare: 11.0,
        amountInvested: 1100.0,
        targetPrice: 20.0,
        sales: const [],
      );

      final result = PositionMigration.buildPositions([olderLot, newerLot]);

      final conflictPositions = result.positions.where((p) => p.ticker == 'CONFLICT').toList();
      expect(conflictPositions.length, 1);
      expect(conflictPositions.first.targetPrice, 20.0, reason: "the more recent buy's target price must win");
      expect(
        result.warnings.any((w) => w.toLowerCase().contains('target') && w.contains('CONFLICT')),
        isTrue,
        reason: 'a discarded target price conflict must be recorded as a warning',
      );
    });

    test('a single lot with no sales becomes one open position with avg == buy price', () {
      final lot = Lot(
        id: 'solo-1',
        ticker: 'SOLO',
        buyDate: DateTime.parse('2026-01-01'),
        sharesPurchased: 100,
        buyPricePerShare: 25.5,
        amountInvested: 2550.0,
        sales: const [],
      );

      final result = PositionMigration.buildPositions([lot]);
      final soloPositions = result.positions.where((p) => p.ticker == 'SOLO').toList();

      expect(soloPositions.length, 1);
      final pos = soloPositions.first;
      expect(pos.status, PositionStatus.open);
      expect(PositionCalculator.sharesHeld(pos), 100);
      expect(PositionCalculator.avgCost(pos), 25.5);
      expect(result.isValid, isTrue);
    });
  });
}
