import 'package:flutter_test/flutter_test.dart';
import 'package:stock_investment_tracker/domain/entities/price_alert.dart';

void main() {
  group('PriceAlert.copyWith re-arm rule', () {
    // This rule didn't exist before this alert kept firing repeatedly —
    // when an alert stopped after one fire, editing a fired alert's target
    // never needed to reactivate anything, since nothing else did either.
    final firedAlert = PriceAlert(
      id: 'a1',
      ticker: 'GUSM',
      targetPrice: 8.60,
      tolerancePercent: 1.0,
      isActive: true,
      alertSent: true,
      alertSentAt: DateTime(2026, 9, 5),
      lastAlertPrice: 8.55,
      createdAt: DateTime(2026, 9, 1),
    );

    test('changing targetPrice resets alertSent, alertSentAt, and lastAlertPrice', () {
      final updated = firedAlert.copyWith(targetPrice: 9.00);

      expect(updated.targetPrice, 9.00);
      expect(updated.alertSent, false);
      expect(updated.alertSentAt, isNull);
      expect(updated.lastAlertPrice, isNull);
    });

    test('changing tolerancePercent alone also re-arms — it changes the effective threshold', () {
      final updated = firedAlert.copyWith(tolerancePercent: 2.0);

      expect(updated.tolerancePercent, 2.0);
      expect(updated.alertSent, false);
      expect(updated.lastAlertPrice, isNull);
    });

    test('re-arming reactivates isActive, so a re-armed alert is watched again', () {
      final pausedAndFired = firedAlert.copyWith(isActive: false);
      final updated = pausedAndFired.copyWith(targetPrice: 9.00);

      expect(updated.isActive, true);
    });

    test('setting the same targetPrice/tolerancePercent again does not re-arm', () {
      final updated = firedAlert.copyWith(targetPrice: 8.60, tolerancePercent: 1.0);

      expect(updated.alertSent, true);
      expect(updated.lastAlertPrice, 8.55);
    });

    test('editing unrelated fields (ticker) leaves alert/repeat state untouched', () {
      final updated = firedAlert.copyWith(ticker: 'GUSM2');

      expect(updated.alertSent, true);
      expect(updated.lastAlertPrice, 8.55);
      expect(updated.isActive, true);
    });
  });
}
