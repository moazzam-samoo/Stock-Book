import 'package:equatable/equatable.dart';

class MarketStatus extends Equatable {
  final bool isOpen;
  final String label;
  final DateTime checkedAt;

  const MarketStatus({
    required this.isOpen,
    required this.label,
    required this.checkedAt,
  });

  @override
  List<Object?> get props => [isOpen, label, checkedAt];
}
