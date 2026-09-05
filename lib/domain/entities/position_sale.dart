import 'package:equatable/equatable.dart';

class PositionSale extends Equatable {
  final String id;
  final DateTime date;
  final int shares;
  final double pricePerShare;
  final double? costBasisAtSale;

  const PositionSale({
    required this.id,
    required this.date,
    required this.shares,
    required this.pricePerShare,
    this.costBasisAtSale,
  });

  double get amountReceived => shares * pricePerShare;
  double get realizedPL => shares * (pricePerShare - (costBasisAtSale ?? 0.0));

  PositionSale copyWith({
    String? id,
    DateTime? date,
    int? shares,
    double? pricePerShare,
    double? costBasisAtSale,
  }) {
    return PositionSale(
      id: id ?? this.id,
      date: date ?? this.date,
      shares: shares ?? this.shares,
      pricePerShare: pricePerShare ?? this.pricePerShare,
      costBasisAtSale: costBasisAtSale ?? this.costBasisAtSale,
    );
  }

  @override
  List<Object?> get props => [id, date, shares, pricePerShare, costBasisAtSale];
}
