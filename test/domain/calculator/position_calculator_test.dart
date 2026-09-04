import 'package:flutter_test/flutter_test.dart';
import 'package:stock_investment_tracker/domain/calculator/position_calculator.dart';
import 'package:stock_investment_tracker/domain/entities/position.dart';
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
  });
}
