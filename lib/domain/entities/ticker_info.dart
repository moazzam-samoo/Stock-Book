import 'package:equatable/equatable.dart';

class TickerInfo extends Equatable {
  final String symbol;
  final String name;
  final String? sector;

  const TickerInfo({
    required this.symbol,
    required this.name,
    this.sector,
  });

  @override
  List<Object?> get props => [symbol, name, sector];
}
