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
import 'package:stock_investment_tracker/core/utils/currency_formatter.dart';
import 'package:stock_investment_tracker/core/utils/stock_color_utils.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stock_investment_tracker/presentation/settings/providers/settings_provider.dart';

class StockRow extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final formatCurrency = NumberFormat.simpleCurrency(name: 'PKR', decimalDigits: 2);
    final formatNumber = NumberFormat.decimalPattern();
    final isPositive = summary.realizedPL >= 0;
    final plColor = isPositive ? AppColors.moneyGreen : AppColors.alertRed;
    
    final settings = ref.watch(settingsProvider).valueOrNull;
    final customColor = settings?.stockColors[summary.ticker.toUpperCase().trim()];
    final sparklineColor = customColor != null 
        ? Color(customColor) 
        : StockColorUtils.getColorForTicker(summary.ticker);
    
    final displayAvgPrice = AppCurrencyFormatter.format(summary.avgBuyPrice, decimalDigits: 2);
    final displayRealized = AppCurrencyFormatter.format(summary.realizedPL, decimalDigits: 2, showSign: true);
    
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? Colors.white : AppColors.textPrimaryLight;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 12.0),
        child: Row(
          children: [
            Hero(
              tag: 'avatar_${summary.ticker}',
              child: TickerAvatar(ticker: summary.ticker, size: 42),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        summary.ticker,
                        style: AppTypography.h3.copyWith(
                          color: primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(width: 8),
                      StatusBadge(status: _mapStatus(summary.status)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${formatNumber.format(summary.sharesHeld)} sh  ·  avg $displayAvgPrice',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.neutral500,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    SparklineChart(isPositive: isPositive, color: sparklineColor),
                    const SizedBox(height: 4),
                    Text(
                      summary.realizedPL != 0 ? displayRealized : '-',
                      style: AppTypography.caption.copyWith(
                        color: summary.realizedPL != 0 ? plColor : AppColors.neutral500,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.chevron_right,
                  color: AppColors.neutral500,
                  size: 18,
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms, delay: animationDelayMs.ms).slideX(begin: 0.1, end: 0, curve: Curves.easeOutCubic);
  }
}
