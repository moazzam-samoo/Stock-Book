enum LotStatus {
  open,
  partiallySold,
  closed,
}

extension LotStatusExtension on LotStatus {
  String get displayName {
    switch (this) {
      case LotStatus.open:
        return 'Open';
      case LotStatus.partiallySold:
        return 'Partial';
      case LotStatus.closed:
        return 'Closed';
    }
  }
}
