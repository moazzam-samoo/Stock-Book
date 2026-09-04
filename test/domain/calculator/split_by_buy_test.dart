import 'package:flutter_test/flutter_test.dart';
import 'package:stock_investment_tracker/domain/calculator/position_calculator.dart';
import 'package:stock_investment_tracker/domain/entities/position.dart';
import 'package:stock_investment_tracker/domain/entities/position_buy.dart';
import 'package:stock_investment_tracker/domain/entities/position_sale.dart';
import 'package:stock_investment_tracker/domain/enums/position_status.dart';

/// A closed cycle is shown as one card per buy. `splitByBuy` is what produces
/// those cards — and it must not invent or lose a single share or rupee.
void main() {
  group('splitByBuy', () {
    test('the reported STPL case splits into one position per buy', () {
      // Exactly the card from the 2026-09-04 screenshot: 3 buys, 3 sales, each
      // sale booked at its own buy's price (migrated per-lot cost basis).
      final closed = Position(
        id: 'pos-stpl',
        ticker: 'STPL',
        status: PositionStatus.closed,
        openedAt: DateTime.parse('2026-06-19'),
        closedAt: DateTime.parse('2026-08-12'),
        buys: [
          PositionBuy(id: 'b1', date: DateTime.parse('2026-06-19'), shares: 1200, pricePerShare: 8.40),
          PositionBuy(id: 'b2', date: DateTime.parse('2026-07-08'), shares: 650, pricePerShare: 8.41),
          PositionBuy(id: 'b3', date: DateTime.parse('2026-08-03'), shares: 1800, pricePerShare: 8.59),
        ],
        sales: [
          PositionSale(id: 's1', date: DateTime.parse('2026-08-06'), shares: 1200, pricePerShare: 9.05, costBasisAtSale: 8.40),
          PositionSale(id: 's2', date: DateTime.parse('2026-08-06'), shares: 650, pricePerShare: 8.85, costBasisAtSale: 8.41),
          PositionSale(id: 's3', date: DateTime.parse('2026-08-12'), shares: 1800, pricePerShare: 9.67, costBasisAtSale: 8.59),
        ],
      );

      final cards = PositionCalculator.splitByBuy(closed);

      expect(cards.length, 3, reason: 'one card per buy, oldest first');

      expect(PositionCalculator.totalSharesBought(cards[0]), 1200);
      expect(PositionCalculator.historicalAvgCost(cards[0]), 8.40);
      expect(PositionCalculator.totalCapitalDeployed(cards[0]), 10080.0);
      expect(PositionCalculator.realizedPL(cards[0]), 780.0); // 1200 × (9.05 − 8.40)
      expect(cards[0].sales.single.shares, 1200);

      expect(PositionCalculator.totalSharesBought(cards[1]), 650);
      expect(PositionCalculator.realizedPL(cards[1]), 286.0); // 650 × (8.85 − 8.41)

      expect(PositionCalculator.totalSharesBought(cards[2]), 1800);
      expect(PositionCalculator.realizedPL(cards[2]), 1944.0); // 1800 × (9.67 − 8.59)

      // Every card is closed, and the whole thing still adds up to the total
      // the single merged card used to show.
      for (final card in cards) {
        expect(card.status, PositionStatus.closed);
        expect(PositionCalculator.sharesHeld(card), 0);
      }
      final summed = cards.fold<double>(0, (sum, c) => sum + PositionCalculator.realizedPL(c));
      expect(summed, closeTo(PositionCalculator.realizedPL(closed), 0.01));
      expect(summed, closeTo(3010.0, 0.01));
    });

    test('a sale spanning several buys is split across their cards', () {
      // Post-migration shape: buys merged at a blended average, then one sale
      // closes the lot. There is no per-buy sale to hand out, so it's divided.
      final open = PositionCalculator.replay(
        'STPL',
        [
          PositionBuy(id: 'b1', date: DateTime.parse('2026-08-31'), shares: 500, pricePerShare: 8.73),
          PositionBuy(id: 'b2', date: DateTime.parse('2026-09-07'), shares: 1200, pricePerShare: 8.38),
        ],
        [],
      ).first;
      final closed = PositionCalculator.applySell(
        open,
        saleId: 's1',
        date: DateTime.parse('2026-09-10'),
        shares: 1700,
        pricePerShare: 9.0,
      );

      final cards = PositionCalculator.splitByBuy(closed);

      expect(cards.length, 2);
      expect(cards[0].sales.single.shares, 500, reason: 'oldest buy filled first');
      expect(cards[1].sales.single.shares, 1200);

      // Both slices keep the basis the sale was actually booked at.
      final basis = closed.sales.single.costBasisAtSale;
      expect(cards[0].sales.single.costBasisAtSale, basis);
      expect(cards[1].sales.single.costBasisAtSale, basis);

      // Nothing invented, nothing lost.
      final shares = cards.fold<int>(0, (sum, c) => sum + PositionCalculator.totalSharesBought(c));
      expect(shares, 1700);
      final summed = cards.fold<double>(0, (sum, c) => sum + PositionCalculator.realizedPL(c));
      expect(summed, closeTo(PositionCalculator.realizedPL(closed), 0.01));
    });

    test('an open or partial position is never split', () {
      final open = PositionCalculator.replay(
        'ENGRO',
        [
          PositionBuy(id: 'b1', date: DateTime.parse('2026-08-01'), shares: 300, pricePerShare: 350.0),
          PositionBuy(id: 'b2', date: DateTime.parse('2026-08-10'), shares: 200, pricePerShare: 360.0),
        ],
        [],
      ).first;
      expect(PositionCalculator.splitByBuy(open), [open]);

      final partial = PositionCalculator.applySell(
        open,
        saleId: 's1',
        date: DateTime.parse('2026-08-20'),
        shares: 100,
        pricePerShare: 380.0,
      );
      expect(partial.status, PositionStatus.partiallySold);
      expect(PositionCalculator.splitByBuy(partial), [partial]);
    });

    test('a closed position with a single buy is returned untouched', () {
      final closed = PositionCalculator.applySell(
        PositionCalculator.replay(
          'OGDC',
          [PositionBuy(id: 'b1', date: DateTime.parse('2026-08-01'), shares: 100, pricePerShare: 100.0)],
          [],
        ).first,
        saleId: 's1',
        date: DateTime.parse('2026-08-05'),
        shares: 100,
        pricePerShare: 110.0,
      );

      final cards = PositionCalculator.splitByBuy(closed);
      expect(cards.length, 1);
      expect(cards.single.id, closed.id, reason: 'no synthetic id when there is nothing to split');
    });
  });
}
