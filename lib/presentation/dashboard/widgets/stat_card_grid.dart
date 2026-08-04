import 'package:flutter/material.dart';
import 'package:stock_investment_tracker/core/theme/app_colors.dart';
import 'package:stock_investment_tracker/core/theme/app_spacing.dart';
import 'package:stock_investment_tracker/domain/entities/portfolio_summary.dart';
import 'package:stock_investment_tracker/presentation/dashboard/widgets/stat_card.dart';

enum DashboardMetricType { invested, realizedPL, freeCash, openLots }

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
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: StatCard(
                label: 'INVESTED',
                value: summary.currentlyInvested,
                isCurrency: true,
                animationDelayMs: 100,
                isSelected: selectedMetric == DashboardMetricType.invested,
                onTap: () => onSelectMetric?.call(DashboardMetricType.invested),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: StatCard(
                label: 'REALIZED P/L',
                value: summary.realizedPL,
                isCurrency: true,
                valueColor: summary.realizedPL >= 0 ? AppColors.moneyGreen : AppColors.alertRed,
                animationDelayMs: 200,
                isSelected: selectedMetric == DashboardMetricType.realizedPL,
                onTap: () => onSelectMetric?.call(DashboardMetricType.realizedPL),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: StatCard(
                label: 'FREE CASH',
                value: summary.freeCash,
                isCurrency: true,
                animationDelayMs: 300,
                isSelected: selectedMetric == DashboardMetricType.freeCash,
                onTap: () => onSelectMetric?.call(DashboardMetricType.freeCash),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: StatCard(
                label: 'OPEN LOTS',
                value: summary.openLots,
                isCurrency: false,
                animationDelayMs: 400,
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
