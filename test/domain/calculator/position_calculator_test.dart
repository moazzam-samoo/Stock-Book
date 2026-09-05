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

    // --- Write-path helpers (Phase 03B Task 4 required tests 8-10) ---

    test('applySell captures costBasisAtSale at write time from current avgCost', () {
      final buy1 = PositionBuy(id: 'b1', date: DateTime.parse('2026-08-31'), shares: 500, pricePerShare: 8.73);
      final buy2 = PositionBuy(id: 'b2', date: DateTime.parse('2026-09-07'), shares: 1200, pricePerShare: 8.38);
      final position = PositionCalculator.replay('STPL', [buy1, buy2], []).first;

      final avgAtSaleTime = PositionCalculator.avgCost(position); // 8.48

      final afterSell = PositionCalculator.applySell(
        position,
        saleId: 's1',
        date: DateTime.parse('2026-09-08'),
        shares: 200,
        pricePerShare: 9.0,
      );

      final bookedSale = afterSell.sales.single;
      expect(bookedSale.costBasisAtSale, avgAtSaleTime);
      expect(afterSell.status, PositionStatus.partiallySold);

      // A later buy must not retroactively change what was already booked.
      final afterLaterBuy = PositionCalculator.applyBuy(
        afterSell,
        buyId: 'b3',
        date: DateTime.parse('2026-09-10'),
        shares: 1000,
        pricePerShare: 20.0,
      );
      final sameSale = afterLaterBuy.sales.single;
      expect(sameSale.costBasisAtSale, avgAtSaleTime,
          reason: 'a later buy must not change a sale already booked');
      expect(sameSale.realizedPL, bookedSale.realizedPL);
    });

    test('findOpenPosition + applyBuy: a buy into an existing open position appends and recomputes avg', () {
      final existing = PositionCalculator.replay(
        'ENGRO',
        [PositionBuy(id: 'b1', date: DateTime.parse('2026-08-01'), shares: 300, pricePerShare: 350.0)],
        [],
      ).first;
      final allPositions = [existing];

      final found = PositionCalculator.findOpenPosition(allPositions, 'ENGRO');
      expect(found, isNotNull);
      expect(found!.id, existing.id);

      final updated = PositionCalculator.applyBuy(
        found,
        buyId: 'b2',
        date: DateTime.parse('2026-08-10'),
        shares: 300,
        pricePerShare: 400.0,
      );

      expect(updated.buys.length, 2);
      expect(PositionCalculator.sharesHeld(updated), 600);
      expect(PositionCalculator.avgCost(updated), 375.0); // (300*350 + 300*400) / 600
    });

    test('findOpenPosition returns null when no open position exists for the ticker (caller must create a new one)', () {
      final closed = PositionCalculator.replay(
        'OGDC',
        [PositionBuy(id: 'b1', date: DateTime.parse('2026-08-01'), shares: 100, pricePerShare: 100.0)],
        [PositionSale(id: 's1', date: DateTime.parse('2026-08-05'), shares: 100, pricePerShare: 110.0)],
      ).first;
      expect(closed.status, PositionStatus.closed);

      expect(PositionCalculator.findOpenPosition([closed], 'OGDC'), isNull);
      expect(PositionCalculator.findOpenPosition([closed], 'UNRELATED'), isNull);
      expect(PositionCalculator.findOpenPosition([], 'ANY'), isNull);
    });

    // --- Historical figures for a closed cycle (Phase 03C tests 1-2) ---

    test('a closed position keeps its historical cost figures while the current ones go to 0', () {
      final buys = [
        PositionBuy(id: 'b1', date: DateTime.parse('2026-06-19'), shares: 1200, pricePerShare: 8.40),
        PositionBuy(id: 'b2', date: DateTime.parse('2026-07-08'), shares: 650, pricePerShare: 8.41),
      ];
      final open = PositionCalculator.replay('STPL', buys, []).first;

      final closed = PositionCalculator.applySell(
        open,
        saleId: 's1',
        date: DateTime.parse('2026-08-06'),
        shares: 1850,
        pricePerShare: 9.0,
      );
      expect(closed.status, PositionStatus.closed);

      // What the card used to show — correct for "still holding", useless here.
      expect(PositionCalculator.avgCost(closed), 0.0);
      expect(PositionCalculator.amountInvested(closed), 0.0);

      // What it must show instead.
      expect(PositionCalculator.totalSharesBought(closed), 1850);
      expect(PositionCalculator.totalCapitalDeployed(closed), closeTo(15546.5, 0.01)); // 1200*8.40 + 650*8.41
      expect(PositionCalculator.historicalAvgCost(closed), closeTo(8.4035, 0.01));
    });

    test('blendedAvgCost across two cycles matches a single precise computation', () {
      // Cycle 1: bought and fully sold — contributes nothing to what's held.
      final closedCycle = PositionCalculator.applySell(
        PositionCalculator.replay(
          'STPL',
          [PositionBuy(id: 'b1', date: DateTime.parse('2026-06-19'), shares: 1000, pricePerShare: 5.0)],
          [],
        ).first,
        saleId: 's1',
        date: DateTime.parse('2026-06-25'),
        shares: 1000,
        pricePerShare: 6.0,
      );
      expect(closedCycle.status, PositionStatus.closed);

      // Cycle 2: still open, two buys at different prices.
      final openCycle = PositionCalculator.replay(
        'STPL',
        [
          PositionBuy(id: 'b2', date: DateTime.parse('2026-08-31'), shares: 500, pricePerShare: 8.73),
          PositionBuy(id: 'b3', date: DateTime.parse('2026-09-07'), shares: 1200, pricePerShare: 8.38),
        ],
        [],
      ).first;

      final blended = PositionCalculator.blendedAvgCost([closedCycle, openCycle]);

      // Only the open cycle's shares count: (500*8.73 + 1200*8.38) / 1700.
      expect(blended, PositionCalculator.avgCost(openCycle));
      expect(blended, 8.48);
    });

    test('blendedAvgCost is 0 when every cycle of the ticker is closed', () {
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
      expect(PositionCalculator.blendedAvgCost([closed]), 0.0);
    });

    test('computeStatus reflects sharesHeld and sales presence', () {
      final open = PositionCalculator.replay(
        'SYS',
        [PositionBuy(id: 'b1', date: DateTime.parse('2026-08-01'), shares: 100, pricePerShare: 500.0)],
        [],
      ).first;
      expect(PositionCalculator.computeStatus(open), PositionStatus.open);

      final partial = PositionCalculator.applySell(
        open,
        saleId: 's1',
        date: DateTime.parse('2026-08-05'),
        shares: 40,
        pricePerShare: 520.0,
      );
      expect(PositionCalculator.computeStatus(partial), PositionStatus.partiallySold);

      final closed = PositionCalculator.applySell(
        partial,
        saleId: 's2',
        date: DateTime.parse('2026-08-10'),
        shares: 60,
        pricePerShare: 510.0,
      );
      expect(PositionCalculator.computeStatus(closed), PositionStatus.closed);
    });
  });
}
