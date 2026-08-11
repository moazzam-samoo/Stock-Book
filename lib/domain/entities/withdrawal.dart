import 'package:freezed_annotation/freezed_annotation.dart';

/// A cash withdrawal taken out of realized trading profit.
///
/// Withdrawals are not tied to any lot or ticker: they reduce the net realized
/// P/L, the portfolio value and the liquid capital shown on the dashboard.
@immutable
class Withdrawal {
  final String id;
  final DateTime date;
  final double amount;
  final String note;

  const Withdrawal({
    required this.id,
    required this.date,
    required this.amount,
    this.note = '',
  });

  Withdrawal copyWith({
    String? id,
    DateTime? date,
    double? amount,
    String? note,
  }) {
    return Withdrawal(
      id: id ?? this.id,
      date: date ?? this.date,
      amount: amount ?? this.amount,
      note: note ?? this.note,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Withdrawal &&
          other.id == id &&
          other.date == date &&
          other.amount == amount &&
          other.note == note;

  @override
  int get hashCode => Object.hash(id, date, amount, note);
}
