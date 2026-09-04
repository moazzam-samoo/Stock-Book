import 'package:flutter_test/flutter_test.dart';
import 'package:stock_investment_tracker/domain/calculator/position_calculator.dart';
import 'package:stock_investment_tracker/domain/entities/position.dart';
import 'package:stock_investment_tracker/domain/entities/position_buy.dart';
import 'package:stock_investment_tracker/domain/entities/position_sale.dart';
import 'package:stock_investment_tracker/domain/enums/position_status.dart';

void main() {
  group('PositionCalculator Live Prices', () {
    final openedAt = DateTime(2023, 1, 1);
    
    test('Calculates unrealized P/L correctly for open position', () {
      final position = Position(
        id: '1',
        ticker: 'SYS',
        status: PositionStatus.open,
        openedAt: openedAt,
        buys: [
          PositionBuy(
            id: 'b1',
            date: openedAt,
            shares: 100,
            pricePerShare: 10.0,
          ),
        ],
        sales: const [],
        targetPrice: null,
      );
      
      expect(PositionCalculator.unrealizedPL(position, 15.0), 500.0);
      expect(PositionCalculator.marketValue(position, 15.0), 1500.0);
      expect(PositionCalculator.unrealizedPLPercent(position, 15.0), 50.0);
    });

    test('Calculates unrealized P/L correctly for partial position', () {
      final position = Position(
        id: '1',
        ticker: 'SYS',
        status: PositionStatus.partiallySold,
        openedAt: openedAt,
        buys: [
          PositionBuy(
            id: 'b1',
            date: openedAt,
            shares: 100,
            pricePerShare: 10.0,
          ),
        ],
        sales: [
          PositionSale(
            id: 's1',
            date: openedAt.add(const Duration(days: 10)),
            shares: 40,
            pricePerShare: 12.0,
          ),
        ],
        targetPrice: null,
      );
      
      expect(PositionCalculator.unrealizedPL(position, 8.0), -120.0);
      expect(PositionCalculator.marketValue(position, 8.0), 480.0);
      expect(PositionCalculator.unrealizedPLPercent(position, 8.0), -20.0);
    });

    test('Returns 0 for null or 0 live price', () {
      final position = Position(
        id: '1',
        ticker: 'SYS',
        status: PositionStatus.open,
        openedAt: openedAt,
        buys: [
          PositionBuy(
            id: 'b1',
            date: openedAt,
            shares: 100,
            pricePerShare: 10.0,
          ),
        ],
        sales: const [],
        targetPrice: null,
      );
      
      expect(PositionCalculator.unrealizedPL(position, null), 0.0);
      expect(PositionCalculator.unrealizedPL(position, 0.0), 0.0);
      expect(PositionCalculator.marketValue(position, null), 0.0);
      expect(PositionCalculator.unrealizedPLPercent(position, null), 0.0);
    });
    
    test('Returns 0 for closed position even if live price is given', () {
      final position = Position(
        id: '1',
        ticker: 'SYS',
        status: PositionStatus.closed,
        openedAt: openedAt,
        buys: [
          PositionBuy(
            id: 'b1',
            date: openedAt,
            shares: 100,
            pricePerShare: 10.0,
          ),
        ],
        sales: [
          PositionSale(
            id: 's1',
            date: openedAt.add(const Duration(days: 10)),
            shares: 100,
            pricePerShare: 12.0,
          ),
        ],
        targetPrice: null,
      );
      
      expect(PositionCalculator.unrealizedPL(position, 15.0), 0.0);
      expect(PositionCalculator.marketValue(position, 15.0), 0.0);
      expect(PositionCalculator.unrealizedPLPercent(position, 15.0), 0.0);
    });
  });
}
