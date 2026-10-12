import 'package:flutter_test/flutter_test.dart';
import 'package:stock_investment_tracker/domain/calculator/position_calculator.dart';
import 'package:stock_investment_tracker/domain/entities/position.dart';
import 'package:stock_investment_tracker/domain/entities/position_buy.dart';
import 'package:stock_investment_tracker/domain/entities/position_sale.dart';
import 'package:stock_investment_tracker/domain/enums/position_status.dart';

void main() {
  group('Same-Day Trade Consolidation (V-Trade / Floret Capitals Standard)', () {
    final tradeDate = DateTime(2026, 10, 12, 10, 0, 0);

    test('Screenshot 1: fully squared-off same-day trade merges into 1 closed lot with Rs 380 profit', () {
      final buy1 = PositionBuy(
        id: 'b1',
        date: DateTime(2026, 10, 12, 10, 15),
        shares: 2000,
        pricePerShare: 4.84,
      );
      final sale1 = PositionSale(
        id: 's1',
        date: DateTime(2026, 10, 12, 10, 45),
        shares: 2000,
        pricePerShare: 4.99,
      );
      final buy2 = PositionBuy(
        id: 'b2',
        date: DateTime(2026, 10, 12, 11, 20),
        shares: 2000,
        pricePerShare: 4.90,
      );
      final sale2 = PositionSale(
        id: 's2',
        date: DateTime(2026, 10, 12, 11, 55),
        shares: 2000,
        pricePerShare: 4.94,
      );

      final positions = PositionCalculator.replay('TISL', [buy1, buy2], [sale1, sale2]);

      expect(positions.length, 1, reason: 'Same-day trades must not split on zero crossing');
      final pos = positions.first;

      expect(PositionCalculator.sharesHeld(pos), 0);
      expect(pos.status, PositionStatus.closed);
      expect(PositionCalculator.totalSharesBought(pos), 4000);
      expect(PositionCalculator.historicalAvgCost(pos), 4.87);
      expect(PositionCalculator.historicalAvgSellPrice(pos), 4.97);
      expect(PositionCalculator.realizedPL(pos), 380.00);
      expect(PositionCalculator.unrealizedPL(pos, 4.84), 0.00);
    });

    test('Screenshot 2: intraday trade with 3rd buy merges 3 buys and 2 sales of TISL into 1 lot', () {
      final buy1 = PositionBuy(
        id: 'b1',
        date: DateTime(2026, 10, 12, 10, 15),
        shares: 2000,
        pricePerShare: 4.84,
      );
      final sale1 = PositionSale(
        id: 's1',
        date: DateTime(2026, 10, 12, 10, 45),
        shares: 2000,
        pricePerShare: 4.99,
      );
      final buy2 = PositionBuy(
        id: 'b2',
        date: DateTime(2026, 10, 12, 11, 20),
        shares: 2000,
        pricePerShare: 4.90,
      );
      final sale2 = PositionSale(
        id: 's2',
        date: DateTime(2026, 10, 12, 11, 55),
        shares: 2000,
        pricePerShare: 4.94,
      );
      final buy3 = PositionBuy(
        id: 'b3',
        date: DateTime(2026, 10, 12, 12, 30),
        shares: 2050,
        pricePerShare: 4.84,
      );

      final positions = PositionCalculator.replay('TISL', [buy1, buy2, buy3], [sale1, sale2]);

      expect(positions.length, 1, reason: 'All 3 buys and 2 sales of TISL must merge into 1 position');
      final pos = positions.first;

      expect(pos.buys.length, 3);
      expect(pos.sales.length, 2);
      expect(PositionCalculator.sharesHeld(pos), 2050);
      expect(pos.status, PositionStatus.partiallySold);

      // Total bought: 6,050 sh @ avg 4.86 (unrounded 4.8598347...)
      expect(PositionCalculator.totalSharesBought(pos), 6050);
      expect(PositionCalculator.historicalAvgCost(pos), 4.86);

      // Total sold: 4,000 sh @ avg 4.97 (unrounded 4.965)
      expect(PositionCalculator.historicalAvgSellPrice(pos), 4.97);

      // Realized profit matches Screenshot 2 (Rs 420.80)
      final realized = PositionCalculator.realizedPL(pos);
      expect(realized, closeTo(420.80, 0.20));

      // Unrealized profit matches Screenshot 2 (-Rs 40.59 at live price 4.84)
      final unrealized = PositionCalculator.unrealizedPL(pos, 4.84);
      expect(unrealized, closeTo(-40.59, 0.15));

      // Total Day Profit: 420.80 - 40.59 = 380.21
      expect(realized + unrealized, closeTo(380.21, 0.30));
    });

    test('consolidateSameDayPositions auto-merges fragmented positions from database into 1 position', () {
      // Simulate user having 3 separate Position records in Firestore for TISL
      final pos1 = Position(
        id: 'doc1',
        ticker: 'TISL',
        status: PositionStatus.closed,
        openedAt: tradeDate,
        buys: [
          PositionBuy(id: 'b1', date: tradeDate, shares: 2000, pricePerShare: 4.84),
        ],
        sales: [
          PositionSale(id: 's1', date: tradeDate, shares: 2000, pricePerShare: 4.99),
        ],
      );

      final pos2 = Position(
        id: 'doc2',
        ticker: 'TISL',
        status: PositionStatus.closed,
        openedAt: tradeDate,
        buys: [
          PositionBuy(id: 'b2', date: tradeDate, shares: 2000, pricePerShare: 4.90),
        ],
        sales: [
          PositionSale(id: 's2', date: tradeDate, shares: 2000, pricePerShare: 4.94),
        ],
      );

      final pos3 = Position(
        id: 'doc3',
        ticker: 'TISL',
        status: PositionStatus.open,
        openedAt: tradeDate,
        buys: [
          PositionBuy(id: 'b3', date: tradeDate, shares: 2050, pricePerShare: 4.84),
        ],
      );

      final consolidated = PositionCalculator.consolidateSameDayPositions([pos1, pos2, pos3]);

      expect(consolidated.length, 1, reason: 'Must consolidate all 3 positions into 1');
      final merged = consolidated.first;
      expect(merged.ticker, 'TISL');
      expect(merged.buys.length, 3);
      expect(merged.sales.length, 2);
      expect(PositionCalculator.sharesHeld(merged), 2050);
      expect(merged.status, PositionStatus.partiallySold);
      expect(PositionCalculator.historicalAvgCost(merged), 4.86);
      expect(PositionCalculator.realizedPL(merged), closeTo(420.80, 0.20));
      expect(PositionCalculator.unrealizedPL(merged, 4.84), closeTo(-40.59, 0.15));
    });

    test('findSameDayPosition returns existing position even if closed', () {
      final closedPos = Position(
        id: 'doc1',
        ticker: 'TISL',
        status: PositionStatus.closed,
        openedAt: DateTime(2026, 10, 12, 9, 30),
      );

      final found = PositionCalculator.findSameDayPosition(
        [closedPos],
        'TISL',
        DateTime(2026, 10, 12, 14, 0),
      );

      expect(found, isNotNull);
      expect(found!.id, 'doc1');
    });

    test('Multi-day holding regression guard: different calendar days are NOT merged', () {
      final posDay1 = Position(
        id: 'doc1',
        ticker: 'TISL',
        status: PositionStatus.closed,
        openedAt: DateTime(2026, 10, 11),
        buys: [
          PositionBuy(id: 'b1', date: DateTime(2026, 10, 11), shares: 1000, pricePerShare: 5.0),
        ],
        sales: [
          PositionSale(id: 's1', date: DateTime(2026, 10, 11), shares: 1000, pricePerShare: 6.0),
        ],
      );

      final posDay2 = Position(
        id: 'doc2',
        ticker: 'TISL',
        status: PositionStatus.open,
        openedAt: DateTime(2026, 10, 12),
        buys: [
          PositionBuy(id: 'b2', date: DateTime(2026, 10, 12), shares: 1000, pricePerShare: 5.5),
        ],
      );

      final consolidated = PositionCalculator.consolidateSameDayPositions([posDay1, posDay2]);

      expect(consolidated.length, 2, reason: 'Trades across different days must remain separate');
    });
  });
}
