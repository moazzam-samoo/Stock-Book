class Sale {
  final String id;
  final DateTime sellDate;
  final int sharesSold;
  final double sellPricePerShare;
  // amountReceived is derived, but can be passed in if calculated
  final double amountReceived;

  const Sale({
    required this.id,
    required this.sellDate,
    required this.sharesSold,
    required this.sellPricePerShare,
    required this.amountReceived,
  });
}
