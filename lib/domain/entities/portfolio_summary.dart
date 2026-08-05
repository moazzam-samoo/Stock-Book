class PortfolioSummary {
  final double startingCapital;
  final double totalInvested;
  final double currentlyInvested;
  final double realizedPL;
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
  });
}
