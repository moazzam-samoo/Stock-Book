import 'package:equatable/equatable.dart';

class PositionBuy extends Equatable {
  final String id;
  final DateTime date;
  final int shares;
  final double pricePerShare;

  const PositionBuy({
    required this.id,
    required this.date,
    required this.shares,
    required this.pricePerShare,
  });

  PositionBuy copyWith({
    String? id,
    DateTime? date,
    int? shares,
    double? pricePerShare,
  }) {
    return PositionBuy(
      id: id ?? this.id,
      date: date ?? this.date,
      shares: shares ?? this.shares,
      pricePerShare: pricePerShare ?? this.pricePerShare,
    );
  }

  @override
  List<Object?> get props => [id, date, shares, pricePerShare];
}
