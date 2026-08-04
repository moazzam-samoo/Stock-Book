import 'package:intl/intl.dart';

class AppCurrencyFormatter {
  static String format(
    num amount, {
    int decimalDigits = 0,
    bool showSign = false,
  }) {
    final formatter = NumberFormat.currency(
      symbol: 'Rs ',
      decimalDigits: decimalDigits,
    );
    final formatted = formatter.format(amount.abs());
    if (showSign && amount > 0) return '+$formatted';
    if (amount < 0) return '-$formatted';
    return formatted;
  }
}
