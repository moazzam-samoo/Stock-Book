import 'package:intl/intl.dart';

class AppCurrencyFormatter {
  static String format(
    num amount, {
    int? decimalDigits,
    bool showSign = false,
  }) {
    final digits = decimalDigits ?? (amount % 1 == 0 ? 0 : 2);
    final formatter = NumberFormat.currency(
      symbol: 'Rs ',
      decimalDigits: digits,
    );
    final formatted = formatter.format(amount.abs());
    if (showSign && amount > 0) return '+$formatted';
    if (amount < 0) return '-$formatted';
    return formatted;
  }

  /// Formats currency with compact suffixes when exceeding thresholds:
  /// - If amount >= 1,000,000,000,000 (1T): 'Rs 1T' or 'Rs 1.5T'
  /// - If amount >= 1,000,000,000 (1B): 'Rs 450B' or 'Rs 1.5B'
  /// - If amount >= 1,000,000 (1M): 'Rs 45M' or 'Rs 1.2M'
  /// - If amount >= 100,000 (100K): 'Rs 100K' or 'Rs 120.5K'
  /// - Otherwise: standard formatting with no decimals: 'Rs 56,885'
  static String formatCompact(
    num amount, {
    double threshold = 100000,
    bool showSign = false,
  }) {
    final absAmount = amount.abs().toDouble();
    String formattedNumber;
    String suffix = '';

    if (absAmount >= 999950000000) {
      formattedNumber = _formatCompactNumber(absAmount / 1000000000000);
      suffix = 'T';
    } else if (absAmount >= 999950000) {
      formattedNumber = _formatCompactNumber(absAmount / 1000000000);
      suffix = 'B';
    } else if (absAmount >= 999950) {
      formattedNumber = _formatCompactNumber(absAmount / 1000000);
      suffix = 'M';
    } else if (absAmount >= threshold) {
      formattedNumber = _formatCompactNumber(absAmount / 1000);
      suffix = 'K';
    } else {
      return format(amount, decimalDigits: 0, showSign: showSign);
    }

    final res = 'Rs $formattedNumber$suffix';
    if (showSign && amount > 0) return '+$res';
    if (amount < 0) return '-$res';
    return res;
  }

  static String _formatCompactNumber(double value) {
    // Round to at most 1 decimal place; strip trailing .0
    final rounded = (value * 10).round() / 10;
    if (rounded % 1 == 0) {
      return rounded.toInt().toString();
    }
    return rounded.toStringAsFixed(1);
  }
}
