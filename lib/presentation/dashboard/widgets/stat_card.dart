import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:stock_investment_tracker/core/theme/app_colors.dart';
import 'package:stock_investment_tracker/core/theme/app_typography.dart';
import 'package:stock_investment_tracker/core/theme/app_spacing.dart';
import 'package:flutter_animate/flutter_animate.dart';

class StatCard extends StatelessWidget {
  final String label;
  final num value;
  final bool isCurrency;
  final Color? valueColor;
  final int animationDelayMs;

  const StatCard({
    super.key,
    required this.label,
    required this.value,
    this.isCurrency = false,
    this.valueColor,
    this.animationDelayMs = 0,
  });

  @override
  Widget build(BuildContext context) {
    final formatCurrency = NumberFormat.simpleCurrency(name: 'PKR', decimalDigits: 0);
    final formatNumber = NumberFormat.decimalPattern();

    final displayValue = isCurrency 
      ? formatCurrency.format(value).replaceAll('PKR', 'Rs').trim()
      : formatNumber.format(value);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2D3748)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label.toUpperCase(),
            style: AppTypography.caption.copyWith(
              color: AppColors.neutral500,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            displayValue,
            style: AppTypography.h2.copyWith(
              color: valueColor ?? AppColors.textPrimaryDark,
              fontFamily: 'JetBrains Mono',
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms, delay: animationDelayMs.ms).slideY(begin: 0.1, end: 0, curve: Curves.easeOutCubic);
  }
}
