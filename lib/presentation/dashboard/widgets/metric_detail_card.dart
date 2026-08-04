import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:stock_investment_tracker/core/theme/app_colors.dart';
import 'package:stock_investment_tracker/core/theme/app_typography.dart';
import 'package:stock_investment_tracker/core/theme/app_spacing.dart';
import 'package:stock_investment_tracker/core/utils/currency_formatter.dart';
import 'package:stock_investment_tracker/domain/entities/portfolio_summary.dart';
import 'package:stock_investment_tracker/domain/entities/stock_summary.dart';
import 'package:stock_investment_tracker/domain/entities/lot.dart';
import 'package:stock_investment_tracker/presentation/dashboard/widgets/stat_card_grid.dart';
import 'package:flutter_animate/flutter_animate.dart';

class MetricDetailCard extends StatelessWidget {
  final DashboardMetricType metricType;
  final PortfolioSummary summary;
  final List<StockSummary> stockSummaries;
  final List<Lot> lots;
  final VoidCallback onClose;

  const MetricDetailCard({
    super.key,
    required this.metricType,
    required this.summary,
    required this.stockSummaries,
    required this.lots,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final title = _getTitle();
    final icon = _getIcon();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF13151B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.moneyGreen.withOpacity(0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, color: AppColors.moneyGreen, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    title.toUpperCase(),
                    style: AppTypography.caption.copyWith(
                      color: AppColors.moneyGreen,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: onClose,
                borderRadius: BorderRadius.circular(12),
                child: const Padding(
                  padding: EdgeInsets.all(4.0),
                  child: Icon(Icons.close, color: AppColors.neutral500, size: 18),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          const Divider(color: Color(0xFF242731), height: 1),
          const SizedBox(height: AppSpacing.md),
          _buildMetricBody(),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.05, end: 0, curve: Curves.easeOutCubic);
  }

  String _getTitle() {
    switch (metricType) {
      case DashboardMetricType.totalInvested:
        return 'Total Cumulative Invested Capital';
      case DashboardMetricType.currentlyInvested:
        return 'Currently Invested Capital';
      case DashboardMetricType.realizedPL:
        return 'Realized Profit / Loss Details';
      case DashboardMetricType.totalFree:
        return 'Total Free (Uninvested Base Capital)';
      case DashboardMetricType.freeCash:
        return 'Free Cash & Liquid Capital';
      case DashboardMetricType.openLots:
        return 'Open Purchase Lots';
    }
  }

  IconData _getIcon() {
    switch (metricType) {
      case DashboardMetricType.totalInvested:
        return Icons.account_balance_outlined;
      case DashboardMetricType.currentlyInvested:
        return Icons.pie_chart_outline;
      case DashboardMetricType.realizedPL:
        return Icons.show_chart;
      case DashboardMetricType.totalFree:
        return Icons.savings_outlined;
      case DashboardMetricType.freeCash:
        return Icons.account_balance_wallet_outlined;
      case DashboardMetricType.openLots:
        return Icons.inventory_2_outlined;
    }
  }

  Widget _buildMetricBody() {
    switch (metricType) {
      case DashboardMetricType.totalInvested:
        return _buildTotalInvestedBody();
      case DashboardMetricType.currentlyInvested:
        return _buildInvestedBody();
      case DashboardMetricType.realizedPL:
        return _buildRealizedPLBody();
      case DashboardMetricType.totalFree:
        return _buildTotalFreeBody();
      case DashboardMetricType.freeCash:
        return _buildFreeCashBody();
      case DashboardMetricType.openLots:
        return _buildOpenLotsBody();
    }
  }

  Widget _buildTotalInvestedBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppCurrencyFormatter.format(summary.totalInvested, decimalDigits: 0),
          style: AppTypography.h1.copyWith(
            color: AppColors.textPrimaryDark,
            fontFamily: 'JetBrains Mono',
            fontSize: 24,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(child: _buildDetailStat('Total Purchases', '${lots.length} lots')),
            Expanded(
              child: _buildDetailStat(
                'Deployment',
                '${(summary.currentlyInvested / (summary.totalInvested > 0 ? summary.totalInvested : 1) * 100).toStringAsFixed(1)}% Active',
                color: AppColors.moneyGreen,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTotalFreeBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppCurrencyFormatter.format(summary.freeCash, decimalDigits: 0),
          style: AppTypography.h1.copyWith(
            color: AppColors.textPrimaryDark,
            fontFamily: 'JetBrains Mono',
            fontSize: 24,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(child: _buildDetailStat('Base Uninvested Cash', 'Excludes Sales Profit')),
            Expanded(
              child: _buildDetailStat(
                'Status',
                summary.freeCash > 0 ? 'Cash Available' : 'Fully Deployed',
                color: AppColors.moneyGreen,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInvestedBody() {
    final totalShares = stockSummaries.fold(0, (sum, s) => sum + s.sharesHeld);
    StockSummary? topHolding;
    if (stockSummaries.isNotEmpty) {
      topHolding = stockSummaries.reduce((a, b) => a.amountInvestedOpen > b.amountInvestedOpen ? a : b);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppCurrencyFormatter.format(summary.currentlyInvested, decimalDigits: 0),
          style: AppTypography.h1.copyWith(
            color: AppColors.textPrimaryDark,
            fontFamily: 'JetBrains Mono',
            fontSize: 24,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(child: _buildDetailStat('Active Stocks', '${stockSummaries.length}')),
            Expanded(child: _buildDetailStat('Total Shares', '$totalShares')),
            Expanded(child: _buildDetailStat('Top Position', topHolding?.ticker ?? 'N/A')),
          ],
        ),
      ],
    );
  }

  Widget _buildRealizedPLBody() {
    final totalSalesCount = lots.fold(0, (sum, lot) => sum + lot.sales.length);
    final isProfit = summary.realizedPL >= 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppCurrencyFormatter.format(summary.realizedPL, showSign: true, decimalDigits: 2),
          style: AppTypography.h1.copyWith(
            color: isProfit ? AppColors.moneyGreen : AppColors.alertRed,
            fontFamily: 'JetBrains Mono',
            fontSize: 24,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(child: _buildDetailStat('Total Sales', '$totalSalesCount transactions')),
            Expanded(
              child: _buildDetailStat(
                'Performance', 
                isProfit ? 'Gain' : 'Loss',
                color: isProfit ? AppColors.moneyGreen : AppColors.alertRed,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFreeCashBody() {
    final totalVal = summary.portfolioValue > 0 ? summary.portfolioValue : 1.0;
    final liquidCash = summary.freeCash + summary.realizedPL;
    final cashPercent = (liquidCash / totalVal * 100).toStringAsFixed(1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppCurrencyFormatter.format(liquidCash, decimalDigits: 0),
          style: AppTypography.h1.copyWith(
            color: AppColors.textPrimaryDark,
            fontFamily: 'JetBrains Mono',
            fontSize: 24,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(child: _buildDetailStat('Cash Ratio', '$cashPercent% of portfolio')),
            Expanded(
              child: _buildDetailStat(
                'Includes Sales Profit',
                summary.realizedPL >= 0 ? '+${AppCurrencyFormatter.format(summary.realizedPL)}' : AppCurrencyFormatter.format(summary.realizedPL),
                color: summary.realizedPL >= 0 ? AppColors.moneyGreen : AppColors.alertRed,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOpenLotsBody() {
    final openLotsList = lots.where((l) => l.sharesRemaining > 0).toList();
    final dateFormat = DateFormat('MMM dd, yyyy');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${openLotsList.length} Active Purchase Lots',
          style: AppTypography.h2.copyWith(
            color: AppColors.textPrimaryDark,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (openLotsList.isEmpty)
          Text('No open lots found', style: AppTypography.body.copyWith(color: AppColors.neutral500))
        else
          Column(
            children: openLotsList.take(3).map((lot) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          lot.ticker,
                          style: AppTypography.body.copyWith(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          dateFormat.format(lot.buyDate),
                          style: AppTypography.caption.copyWith(color: AppColors.neutral500, fontSize: 11),
                        ),
                      ],
                    ),
                    Text(
                      '${lot.sharesRemaining} sh @ ${AppCurrencyFormatter.format(lot.buyPricePerShare, decimalDigits: 2)}',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondaryDark,
                        fontFamily: 'JetBrains Mono',
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildDetailStat(String label, String value, {Color? color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: AppTypography.caption.copyWith(
            color: AppColors.neutral500,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTypography.body.copyWith(
            color: color ?? AppColors.textPrimaryDark,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
