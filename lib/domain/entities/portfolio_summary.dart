class PortfolioSummary {
  final double startingCapital;
  final double totalInvested;
  final double currentlyInvested;

  /// Realized P/L **net of profit withdrawals** — this is what the dashboard
  /// shows. Withdrawing profit reduces this, the portfolio value and the
  /// liquid capital, and nothing else.
  final double realizedPL;

  /// Realized P/L from trading alone, before any withdrawals are subtracted.
  final double grossRealizedPL;

  /// Total cash withdrawn out of profit to date.
  final double totalWithdrawn;

  final double freeCash;
  final double totalCash;
  final int openLots;
  final double portfolioValue;

  const PortfolioSummary({
    required this.startingCapital,
    required this.totalInvested,
    required this.currentlyInvested,
    required this.realizedPL,
    required this.freeCash,
    required this.totalCash,
    required this.openLots,
    required this.portfolioValue,
    this.grossRealizedPL = 0.0,
    this.totalWithdrawn = 0.0,
  });
}
