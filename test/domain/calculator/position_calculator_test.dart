import 'package:flutter_test/flutter_test.dart';
import 'package:stock_investment_tracker/domain/calculator/position_calculator.dart';
import 'package:stock_investment_tracker/domain/entities/position_buy.dart';
import 'package:stock_investment_tracker/domain/entities/position_sale.dart';
import 'package:stock_investment_tracker/domain/enums/position_status.dart';

void main() {
  group('PositionCalculator', () {
    test('ties in dates: buys sort before sales', () {
      final date = DateTime.parse('2026-09-01');
      final buy = PositionBuy(id: 'b1', date: date, shares: 100, pricePerShare: 10.0);
      final sale = PositionSale(id: 's1', date: date, shares: 100, pricePerShare: 12.0);
      
      final positions = PositionCalculator.replay('TEST', [buy], [sale]);
      expect(positions.length, 1);
      final pos = positions.first;
      
      expect(PositionCalculator.sharesHeld(pos), 0);
      expect(pos.status, PositionStatus.closed);
      expect(pos.closedAt, date);
    });

    test('reproduces moving average cost reference case exactly', () {
      final buy1 = PositionBuy(id: 'b1', date: DateTime.parse('2026-08-31'), shares: 500, pricePerShare: 8.73);
      final buy2 = PositionBuy(id: 'b2', date: DateTime.parse('2026-09-07'), shares: 1200, pricePerShare: 8.38);
      // Historical sale has null cost basis, forcing recalculation from moving average
      final sale = PositionSale(id: 's1', date: DateTime.parse('2026-09-08'), shares: 200, pricePerShare: 9.00);

      final positions = PositionCalculator.replay('STPL', [buy1, buy2], [sale]);
      expect(positions.length, 1);
      final pos = positions.first;

      expect(PositionCalculator.sharesHeld(pos), 1500);
      expect(PositionCalculator.avgCost(pos), 8.48); // 14421 / 1700 = 8.4829 -> 8.48
      expect(PositionCalculator.realizedPL(pos), 103.41); // 200 * (9.00 - 8.482941176...) -> 103.41
      
      // But wait! Is the realized PL 103.41 or 103.42? 
      // 9.00 - 8.482941176... = 0.5170588...
      // 0.5170588... * 200 = 103.4117... -> round to 103.41.
      // We check that it calculates dynamically based on moving average.
    });

    test('a sale with non-null costBasisAtSale uses the stored value instead of moving average', () {
      final buy1 = PositionBuy(id: 'b1', date: DateTime.parse('2026-08-31'), shares: 500, pricePerShare: 8.73);
      final buy2 = PositionBuy(id: 'b2', date: DateTime.parse('2026-09-07'), shares: 1200, pricePerShare: 8.38);
      // Migrated historical sale with frozen cost basis
      final sale = PositionSale(id: 's1', date: DateTime.parse('2026-09-08'), shares: 200, pricePerShare: 9.00, costBasisAtSale: 8.73);

      final positions = PositionCalculator.replay('STPL', [buy1, buy2], [sale]);
      expect(positions.length, 1);
      final pos = positions.first;

      expect(PositionCalculator.realizedPL(pos), 54.0); // 200 * (9.00 - 8.73) = 54.0
    });

    test('sharesHeld reaching exactly 0 closes the position', () {
      final buy = PositionBuy(id: 'b1', date: DateTime.parse('2026-09-01'), shares: 100, pricePerShare: 10.0);
      final sale = PositionSale(id: 's1', date: DateTime.parse('2026-09-02'), shares: 100, pricePerShare: 12.0);
      
      final positions = PositionCalculator.replay('TEST', [buy], [sale]);
      expect(positions.length, 1);
      final pos = positions.first;
      
      expect(PositionCalculator.sharesHeld(pos), 0);
      expect(pos.status, PositionStatus.closed);
      expect(pos.closedAt, DateTime.parse('2026-09-02'));
    });

    test('subsequent buys after closing open a new position', () {
      final buy1 = PositionBuy(id: 'b1', date: DateTime.parse('2026-09-01'), shares: 100, pricePerShare: 10.0);
      final sale1 = PositionSale(id: 's1', date: DateTime.parse('2026-09-02'), shares: 100, pricePerShare: 12.0);
      
      final buy2 = PositionBuy(id: 'b2', date: DateTime.parse('2026-09-03'), shares: 50, pricePerShare: 11.0);
      
      final positions = PositionCalculator.replay('TEST', [buy1, buy2], [sale1]);
      
      expect(positions.length, 2);
      expect(positions[0].status, PositionStatus.closed);
      expect(PositionCalculator.sharesHeld(positions[0]), 0);
      
      expect(positions[1].status, PositionStatus.open);
      expect(PositionCalculator.sharesHeld(positions[1]), 50);
    });

    test('never lets sharesHeld go negative (clamps sale to available shares)', () {
      final buy = PositionBuy(id: 'b1', date: DateTime.parse('2026-09-01'), shares: 100, pricePerShare: 10.0);
      // Attempting to sell 150 shares
      final sale = PositionSale(id: 's1', date: DateTime.parse('2026-09-02'), shares: 150, pricePerShare: 12.0);

      final positions = PositionCalculator.replay('TEST', [buy], [sale]);
      expect(positions.length, 1);
      final pos = positions.first;

      expect(PositionCalculator.sharesHeld(pos), 0);
      expect(pos.sales.first.shares, 100); // the sale record is clamped to 100 in the position
      expect(pos.status, PositionStatus.closed);
    });

    test('a sell does not move avgCost', () {
      final buy = PositionBuy(id: 'b1', date: DateTime.parse('2026-09-01'), shares: 500, pricePerShare: 10.0);
      final positionsBeforeSale = PositionCalculator.replay('TEST', [buy], []);
      final avgBefore = PositionCalculator.avgCost(positionsBeforeSale.first);
      expect(avgBefore, 10.0);

      final sale = PositionSale(id: 's1', date: DateTime.parse('2026-09-02'), shares: 100, pricePerShare: 15.0);
      final positionsAfterSale = PositionCalculator.replay('TEST', [buy], [sale]);
      final avgAfter = PositionCalculator.avgCost(positionsAfterSale.first);

      expect(avgAfter, avgBefore, reason: 'selling shares must not move the average cost of the remainder');
    });

    test('a buy does move avgCost', () {
      final buy1 = PositionBuy(id: 'b1', date: DateTime.parse('2026-08-31'), shares: 500, pricePerShare: 10.0);
      final positionsBeforeBuy2 = PositionCalculator.replay('TEST', [buy1], []);
      final avgBefore = PositionCalculator.avgCost(positionsBeforeBuy2.first);
      expect(avgBefore, 10.0);

      final buy2 = PositionBuy(id: 'b2', date: DateTime.parse('2026-09-01'), shares: 500, pricePerShare: 20.0);
      final positionsAfterBuy2 = PositionCalculator.replay('TEST', [buy1, buy2], []);
      final avgAfter = PositionCalculator.avgCost(positionsAfterBuy2.first);

      expect(avgAfter, 15.0); // (5000 + 10000) / 1000
      expect(avgAfter, isNot(avgBefore));
    });

    test('retroactivity guard: a later buy never changes an earlier sale\'s realizedPL', () {
      final buy1 = PositionBuy(id: 'b1', date: DateTime.parse('2026-08-31'), shares: 500, pricePerShare: 8.73);
      final sale = PositionSale(id: 's1', date: DateTime.parse('2026-09-01'), shares: 100, pricePerShare: 9.50);

      // First replay: only the original buy and the sale exist. The sale's
      // costBasisAtSale gets frozen to the moving average at that point.
      final firstPass = PositionCalculator.replay('TEST', [buy1], [sale]);
      final frozenSale = firstPass.first.sales.first;
      expect(frozenSale.costBasisAtSale, 8.73);
      final realizedBefore = frozenSale.realizedPL;
      expect(realizedBefore, closeTo(77.0, 0.01)); // 100 * (9.50 - 8.73)

      // A new, later buy is added. The FROZEN sale (carrying its own
      // costBasisAtSale from the first pass, exactly as it would come back
      // from Firestore) is replayed again alongside it.
      final buy2 = PositionBuy(id: 'b2', date: DateTime.parse('2026-09-07'), shares: 1200, pricePerShare: 8.38);
      final secondPass = PositionCalculator.replay('TEST', [buy1, buy2], [frozenSale]);
      final sameSale = secondPass.first.sales.first;

      expect(sameSale.costBasisAtSale, 8.73, reason: 'a later buy must not retroactively change a frozen cost basis');
      expect(sameSale.realizedPL, realizedBefore, reason: "the earlier sale's booked profit must be byte-identical");
    });

    test('multiple zero-crossings split into the correct number of positions, in the right order', () {
      final buy1 = PositionBuy(id: 'b1', date: DateTime.parse('2026-09-01'), shares: 100, pricePerShare: 10.0);
      final sale1 = PositionSale(id: 's1', date: DateTime.parse('2026-09-02'), shares: 100, pricePerShare: 12.0);
      final buy2 = PositionBuy(id: 'b2', date: DateTime.parse('2026-09-03'), shares: 50, pricePerShare: 11.0);
      final sale2 = PositionSale(id: 's2', date: DateTime.parse('2026-09-04'), shares: 50, pricePerShare: 13.0);
      final buy3 = PositionBuy(id: 'b3', date: DateTime.parse('2026-09-05'), shares: 200, pricePerShare: 9.0);

      final positions = PositionCalculator.replay('TEST', [buy1, buy2, buy3], [sale1, sale2]);

      expect(positions.length, 3);

      expect(positions[0].status, PositionStatus.closed);
      expect(positions[0].buys.map((b) => b.id), ['b1']);
      expect(positions[0].sales.map((s) => s.id), ['s1']);

      expect(positions[1].status, PositionStatus.closed);
      expect(positions[1].buys.map((b) => b.id), ['b2']);
      expect(positions[1].sales.map((s) => s.id), ['s2']);

      expect(positions[2].status, PositionStatus.open);
      expect(positions[2].buys.map((b) => b.id), ['b3']);
      expect(PositionCalculator.sharesHeld(positions[2]), 200);
    });

    test('rounding: amountInvested reconciles with the true remaining cost within 0.01', () {
      // The STPL reference case. avgCost rounds to 8.48 (from the raw
      // 8.482941...), but amountInvested must NOT be computed by multiplying
      // sharesHeld by that already-rounded average — see
      // PositionCalculator._preciseTotalCost's doc comment.
      final buy1 = PositionBuy(id: 'b1', date: DateTime.parse('2026-08-31'), shares: 500, pricePerShare: 8.73);
      final buy2 = PositionBuy(id: 'b2', date: DateTime.parse('2026-09-07'), shares: 1200, pricePerShare: 8.38);
      final sale = PositionSale(id: 's1', date: DateTime.parse('2026-09-08'), shares: 200, pricePerShare: 9.00);

      final positions = PositionCalculator.replay('STPL', [buy1, buy2], [sale]);
      final pos = positions.first;

      expect(PositionCalculator.sharesHeld(pos), 1500);
      // True remaining cost: 14421.00 - 200 * 8.482941... = 12724.41176...
      expect(PositionCalculator.amountInvested(pos), closeTo(12724.41, 0.01));
      expect(PositionCalculator.totalCost(pos), closeTo(12724.41, 0.01));
    });

    test('empty input produces no positions and does not throw', () {
      expect(PositionCalculator.replay('TEST', [], []), isEmpty);
    });
  });
}
