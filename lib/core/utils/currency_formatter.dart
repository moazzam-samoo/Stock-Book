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
}
