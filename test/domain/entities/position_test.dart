import 'package:flutter_test/flutter_test.dart';
import 'package:stock_investment_tracker/domain/calculator/position_calculator.dart';
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
      lastAlertPrice: 15.20,
    );

    test('retains alert state if targetPrice is not changed', () {
      final updated = basePosition.copyWith(
        status: PositionStatus.partiallySold,
      );

      expect(updated.targetPrice, 15.0);
      expect(updated.targetAlertSent, true);
      expect(updated.targetAlertSentAt, isNotNull);
      expect(updated.lastAlertPrice, 15.20);
      expect(updated.status, PositionStatus.partiallySold);
    });

    test('resets alert state (including lastAlertPrice) if targetPrice changes', () {
      // A changed target must start the repeat-alert tracking fresh —
      // otherwise a new, lower target would inherit a stale high-water mark
      // from the old one and could silently suppress an alert that should
      // fire immediately.
      final updated = basePosition.copyWith(
        targetPrice: 20.0,
      );

      expect(updated.targetPrice, 20.0);
      expect(updated.targetAlertSent, false);
      expect(updated.targetAlertSentAt, isNull);
      expect(updated.lastAlertPrice, isNull);
    });

    test('clears targetPrice and alert state if clearTargetPrice is true', () {
      final updated = basePosition.copyWith(
        clearTargetPrice: true,
      );

      expect(updated.targetPrice, isNull);
      expect(updated.targetAlertSent, false);
      expect(updated.targetAlertSentAt, isNull);
      expect(updated.lastAlertPrice, isNull);
    });

    test('retains alert state when only shares/date-affecting fields change', () {
      final updated = basePosition.copyWith(
        buys: [
          ...basePosition.buys,
          PositionBuy(id: 'b2', date: DateTime(2026, 1, 5), shares: 50, pricePerShare: 11.0),
        ],
      );

      expect(updated.targetPrice, 15.0);
      expect(updated.targetAlertSent, true);
      expect(updated.targetAlertSentAt, isNotNull);
    });

    test('a buy that also sets a new target resets the flag, via the same '
        'applyBuy + copyWith chain AddBuyController uses', () {
      final afterBuy = PositionCalculator.applyBuy(
        basePosition,
        buyId: 'b2',
        date: DateTime(2026, 1, 5),
        shares: 50,
        pricePerShare: 11.0,
      );
      final updated = afterBuy.copyWith(targetPrice: 20.0);

      expect(updated.targetPrice, 20.0);
      expect(updated.targetAlertSent, false);
      expect(updated.targetAlertSentAt, isNull);
      expect(updated.buys.length, 2);
    });

    test('a buy that carries the existing target forward does not reset the flag', () {
      final afterBuy = PositionCalculator.applyBuy(
        basePosition,
        buyId: 'b2',
        date: DateTime(2026, 1, 5),
        shares: 50,
        pricePerShare: 11.0,
      );
      final updated = afterBuy.copyWith(targetPrice: basePosition.targetPrice);

      expect(updated.targetPrice, 15.0);
      expect(updated.targetAlertSent, true);
      expect(updated.targetAlertSentAt, isNotNull);
    });
  });
}
