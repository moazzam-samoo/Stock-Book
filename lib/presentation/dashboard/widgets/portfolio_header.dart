import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:stock_investment_tracker/core/theme/app_colors.dart';
import 'package:stock_investment_tracker/core/theme/app_typography.dart';
import 'package:stock_investment_tracker/core/theme/app_spacing.dart';
import 'package:stock_investment_tracker/presentation/common/badges.dart';

class PortfolioHeader extends StatelessWidget {
  final double totalValue;
  final double profitLossPercentage;

  const PortfolioHeader({
    super.key,
    required this.totalValue,
    required this.profitLossPercentage,
  });

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good morning 👋';
    } else if (hour < 17) {
      return 'Good afternoon 👋';
    } else {
      return 'Good evening 👋';
    }
  }

  @override
  Widget build(BuildContext context) {
    final formatCurrency = NumberFormat.simpleCurrency(name: 'PKR', decimalDigits: 0);
    final displayValue = formatCurrency.format(totalValue).replaceAll('PKR', 'Rs').trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _getGreeting(),
          style: AppTypography.caption.copyWith(color: AppColors.neutral500),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'TOTAL PORTFOLIO VALUE',
          style: AppTypography.caption.copyWith(
            color: AppColors.neutral500,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              displayValue,
              style: AppTypography.display.copyWith(
                color: AppColors.textPrimaryDark,
                fontFamily: 'JetBrains Mono',
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Padding(
              padding: const EdgeInsets.only(bottom: 6.0),
              child: TrendChip(percentage: profitLossPercentage),
            ),
          ],
        ),
      ],
    );
  }
}
