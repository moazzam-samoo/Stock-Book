import 'package:flutter_test/flutter_test.dart';
import 'package:stock_investment_tracker/core/utils/currency_formatter.dart';

void main() {
  group('AppCurrencyFormatter Tests', () {
    test('formats positive amounts with space after Rs', () {
      final result = AppCurrencyFormatter.format(22132, decimalDigits: 0);
      expect(result, 'Rs 22,132');
    });

    test('formats decimals correctly', () {
      final result = AppCurrencyFormatter.format(8.59, decimalDigits: 2);
      expect(result, 'Rs 8.59');
    });

    test('formats positive signed amounts correctly', () {
      final result = AppCurrencyFormatter.format(1066, decimalDigits: 2, showSign: true);
      expect(result, '+Rs 1,066.00');
    });

    test('formats negative amounts correctly', () {
      final result = AppCurrencyFormatter.format(-500.50, decimalDigits: 2);
      expect(result, '-Rs 500.50');
    });
  });
}
