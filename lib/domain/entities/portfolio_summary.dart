class PortfolioSummary {
  final double totalInvested;
  final double currentlyInvested;
  final double realizedPL;
  final double freeCash;
  final int openLots;
  final double portfolioValue; // freeCash + currentlyInvested + realizedPL depending on definition. Actually from PRD Dashboard, "TOTAL PORTFOLIO VALUE" and 4 stat cards. Wait, PRD 5: Portfolio Value = Free Cash + Currently Invested.

  const PortfolioSummary({
    required this.totalInvested,
    required this.currentlyInvested,
    required this.realizedPL,
    required this.freeCash,
    required this.openLots,
    required this.portfolioValue,
  });
}
