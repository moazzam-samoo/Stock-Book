import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:stock_investment_tracker/core/theme/app_colors.dart';
import 'package:stock_investment_tracker/core/theme/app_typography.dart';
import 'package:stock_investment_tracker/core/theme/app_spacing.dart';
import 'package:stock_investment_tracker/domain/entities/stock_summary.dart';
import 'package:stock_investment_tracker/domain/enums/lot_status.dart';
import 'package:stock_investment_tracker/presentation/common/badges.dart';
import 'package:stock_investment_tracker/presentation/common/ticker_avatar.dart';
import 'package:stock_investment_tracker/presentation/dashboard/widgets/sparkline_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';

class StockRow extends StatelessWidget {
  final StockSummary summary;
  final VoidCallback onTap;
  final int animationDelayMs;

  const StockRow({
    super.key,
    required this.summary,
    required this.onTap,
    this.animationDelayMs = 0,
  });

  TradeStatus _mapStatus(LotStatus status) {
    switch (status) {
      case LotStatus.open:
        return TradeStatus.open;
      case LotStatus.partiallySold:
        return TradeStatus.partial;
      case LotStatus.closed:
        return TradeStatus.closed;
    }
  }

  @override
  Widget build(BuildContext context) {
    final formatCurrency = NumberFormat.simpleCurrency(name: 'PKR', decimalDigits: 2);
    final formatNumber = NumberFormat.decimalPattern();
    final isPositive = summary.realizedPL >= 0;
    final color = isPositive ? AppColors.moneyGreen : AppColors.alertRed;
    
    final displayAvgPrice = formatCurrency.format(summary.avgBuyPrice).replaceAll('PKR', 'Rs').trim();
    final displayRealized = formatCurrency.format(summary.realizedPL.abs()).replaceAll('PKR', 'Rs').trim();
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md, horizontal: AppSpacing.sm),
        child: Row(
          children: [
            Hero(
              tag: 'avatar_${summary.ticker}',
              child: TickerAvatar(ticker: summary.ticker, size: 40),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        summary.ticker,
                        style: AppTypography.h3.copyWith(color: AppColors.textPrimaryDark),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      StatusBadge(status: _mapStatus(summary.status)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${formatNumber.format(summary.sharesHeld)} sh @ $displayAvgPrice',
                    style: AppTypography.caption.copyWith(color: AppColors.neutral500),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                SparklineChart(isPositive: isPositive, color: color),
                if (summary.realizedPL != 0) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${isPositive ? '+' : '-'}$displayRealized',
                    style: AppTypography.caption.copyWith(
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms, delay: animationDelayMs.ms).slideX(begin: 0.1, end: 0, curve: Curves.easeOutCubic);
  }
}
