import 'package:equatable/equatable.dart';

class MarketPrice extends Equatable {
  final String ticker;
  final double price;
  final double previousClose;
  final DateTime updatedAt;

  const MarketPrice({
    required this.ticker,
    required this.price,
    required this.previousClose,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [ticker, price, previousClose, updatedAt];
}
