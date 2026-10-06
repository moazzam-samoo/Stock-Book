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

    group('formatCompact', () {
      test('formats amounts below threshold normally', () {
        expect(AppCurrencyFormatter.formatCompact(50000), 'Rs 50,000');
        expect(AppCurrencyFormatter.formatCompact(99999), 'Rs 99,999');
      });

      test('formats amounts >= 100K with K suffix', () {
        expect(AppCurrencyFormatter.formatCompact(100000), 'Rs 100K');
        expect(AppCurrencyFormatter.formatCompact(120000), 'Rs 120K');
        expect(AppCurrencyFormatter.formatCompact(120400), 'Rs 120.4K');
      });

      test('formats amounts >= 1M with M suffix and cleans whole decimals', () {
        expect(AppCurrencyFormatter.formatCompact(1000000), 'Rs 1M');
        expect(AppCurrencyFormatter.formatCompact(1500000), 'Rs 1.5M');
        expect(AppCurrencyFormatter.formatCompact(2250000), 'Rs 2.3M');
        expect(AppCurrencyFormatter.formatCompact(45000000), 'Rs 45M');
        expect(AppCurrencyFormatter.formatCompact(45003010), 'Rs 45M');
        expect(AppCurrencyFormatter.formatCompact(45200000), 'Rs 45.2M');
      });

      test('formats amounts >= 1B with B suffix', () {
        expect(AppCurrencyFormatter.formatCompact(1000000000), 'Rs 1B');
        expect(AppCurrencyFormatter.formatCompact(1500000000), 'Rs 1.5B');
        expect(AppCurrencyFormatter.formatCompact(450000000000), 'Rs 450B');
        expect(AppCurrencyFormatter.formatCompact(450000003010), 'Rs 450B');
      });

      test('formats amounts >= 1T with T suffix', () {
        expect(AppCurrencyFormatter.formatCompact(1000000000000), 'Rs 1T');
        expect(AppCurrencyFormatter.formatCompact(2500000000000), 'Rs 2.5T');
      });

      test('handles signed and negative compact amounts', () {
        expect(AppCurrencyFormatter.formatCompact(-120000), '-Rs 120K');
        expect(AppCurrencyFormatter.formatCompact(-450000000000), '-Rs 450B');
        expect(
          AppCurrencyFormatter.formatCompact(120000, showSign: true),
          '+Rs 120K',
        );
        expect(
          AppCurrencyFormatter.formatCompact(450000000000, showSign: true),
          '+Rs 450B',
        );
      });
    });
  });
}
