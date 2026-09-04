import 'package:flutter_test/flutter_test.dart';
import 'package:stock_investment_tracker/domain/entities/position.dart';
import 'package:stock_investment_tracker/domain/entities/position_buy.dart';
import 'package:stock_investment_tracker/domain/enums/position_status.dart';

void main() {
  group('Position Entity copyWith', () {
    final basePosition = Position(
      id: 'p1',
      ticker: 'TEST',
      status: PositionStatus.open,
      openedAt: DateTime(2026, 1, 1),
      buys: [
        PositionBuy(id: 'b1', date: DateTime(2026, 1, 1), shares: 100, pricePerShare: 10.0),
      ],
      sales: const [],
      targetPrice: 15.0,
      targetAlertSent: true,
      targetAlertSentAt: DateTime(2026, 1, 2),
    );

    test('retains alert state if targetPrice is not changed', () {
      final updated = basePosition.copyWith(
        status: PositionStatus.partiallySold,
      );

      expect(updated.targetPrice, 15.0);
      expect(updated.targetAlertSent, true);
      expect(updated.targetAlertSentAt, isNotNull);
      expect(updated.status, PositionStatus.partiallySold);
    });

    test('resets alert state if targetPrice is changed to a new value', () {
      final updated = basePosition.copyWith(
        targetPrice: 20.0,
      );

      expect(updated.targetPrice, 20.0);
      expect(updated.targetAlertSent, false);
      expect(updated.targetAlertSentAt, isNull);
    });

    test('clears targetPrice and alert state if clearTargetPrice is true', () {
      final updated = basePosition.copyWith(
        clearTargetPrice: true,
      );

      expect(updated.targetPrice, isNull);
      expect(updated.targetAlertSent, false);
      expect(updated.targetAlertSentAt, isNull);
    });
  });
}
