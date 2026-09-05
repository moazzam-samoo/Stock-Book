enum PositionStatus {
  open,
  partiallySold,
  closed;

  String get displayName {
    switch (this) {
      case PositionStatus.open:
        return 'Open';
      case PositionStatus.partiallySold:
        return 'Partial';
      case PositionStatus.closed:
        return 'Closed';
    }
  }
}
