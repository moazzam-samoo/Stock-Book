import 'package:flutter_test/flutter_test.dart';
import 'package:stock_investment_tracker/presentation/alerts/providers/alerts_providers.dart';

void main() {
  group('Price Alert Trigger Logic', () {
    test('Threshold boundary — exactly target * 1.01 fires', () {
      const currentPrice = 8.686;
      const targetPrice = 8.60;
      const tolerancePercent = 1.0;
      
      final triggered = isAlertTriggered(currentPrice, targetPrice, tolerancePercent);
      expect(triggered, isTrue);
    });

    test('A hair above the threshold does not fire', () {
      const currentPrice = 8.687; // slightly above 8.686
      const targetPrice = 8.60;
      const tolerancePercent = 1.0;
      
      final triggered = isAlertTriggered(currentPrice, targetPrice, tolerancePercent);
      expect(triggered, isFalse);
    });

    test('Exactly at target fires', () {
      const currentPrice = 8.60;
      const targetPrice = 8.60;
      const tolerancePercent = 1.0;
      
      final triggered = isAlertTriggered(currentPrice, targetPrice, tolerancePercent);
      expect(triggered, isTrue);
    });

    test('tolerancePercent: 0 means exact-or-below only', () {
      const targetPrice = 8.60;
      const tolerancePercent = 0.0;
      
      expect(isAlertTriggered(8.60, targetPrice, tolerancePercent), isTrue); // Exact
      expect(isAlertTriggered(8.59, targetPrice, tolerancePercent), isTrue); // Below
      expect(isAlertTriggered(8.61, targetPrice, tolerancePercent), isFalse); // Above
    });
  });
}
