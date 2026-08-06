import 'package:flutter/material.dart';
import 'package:stock_investment_tracker/core/theme/app_colors.dart';
import 'package:stock_investment_tracker/core/theme/app_spacing.dart';
import 'package:stock_investment_tracker/domain/entities/portfolio_summary.dart';
import 'package:stock_investment_tracker/presentation/dashboard/widgets/stat_card.dart';

enum DashboardMetricType {
  totalInvested,
  currentlyInvested,
  realizedPL,
  totalFree,
  freeCash,
  openLots,
}

class StatCardGrid extends StatelessWidget {
  final PortfolioSummary summary;
  final DashboardMetricType? selectedMetric;
  final ValueChanged<DashboardMetricType>? onSelectMetric;

  const StatCardGrid({
    super.key,
    required this.summary,
    this.selectedMetric,
    this.onSelectMetric,
  });

  @override
  Widget build(BuildContext context) {
    final liquidFreeCash = summary.freeCash + summary.realizedPL;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: StatCard(
                label: 'TOTAL INVESTED MONEY',
                value: summary.startingCapital,
                isCurrency: true,
                animationDelayMs: 100,
                isSelected: selectedMetric == DashboardMetricType.totalInvested,
                onTap: () =>
                    onSelectMetric?.call(DashboardMetricType.totalInvested),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: StatCard(
                label: 'TOTAL INVESTED (STOCKS)',
                value: summary.currentlyInvested,
                isCurrency: true,
                animationDelayMs: 200,
                isSelected:
                    selectedMetric == DashboardMetricType.currentlyInvested,
                onTap: () =>
                    onSelectMetric?.call(DashboardMetricType.currentlyInvested),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: StatCard(
                label: 'REALIZED P/L',
                value: summary.realizedPL,
                isCurrency: true,
                valueColor: summary.realizedPL >= 0
                    ? AppColors.moneyGreen
                    : AppColors.alertRed,
                animationDelayMs: 300,
                isSelected: selectedMetric == DashboardMetricType.realizedPL,
                onTap: () =>
                    onSelectMetric?.call(DashboardMetricType.realizedPL),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: StatCard(
                label: 'FREE CASH (UN-INVESTED)',
                value: summary.freeCash,
                isCurrency: true,
                animationDelayMs: 400,
                isSelected: selectedMetric == DashboardMetricType.totalFree,
                onTap: () =>
                    onSelectMetric?.call(DashboardMetricType.totalFree),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: StatCard(
                label: 'TOTAL LIQUID CAPITAL',
                value: liquidFreeCash,
                isCurrency: true,
                animationDelayMs: 500,
                isSelected: selectedMetric == DashboardMetricType.freeCash,
                onTap: () => onSelectMetric?.call(DashboardMetricType.freeCash),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: StatCard(
                label: 'OPEN TRADES',
                value: summary.openLots,
                isCurrency: false,
                animationDelayMs: 600,
                isSelected: selectedMetric == DashboardMetricType.openLots,
                onTap: () => onSelectMetric?.call(DashboardMetricType.openLots),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
