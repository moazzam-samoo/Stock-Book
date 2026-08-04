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
      ? formatCurrency.format(value).replaceAll('PKR', 'Rs ').replaceAll('Rs  ', 'Rs ').trim()
      : formatNumber.format(value);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF242731), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label.toUpperCase(),
            style: AppTypography.caption.copyWith(
              color: AppColors.neutral500,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
              fontSize: 11,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Text(
            displayValue,
            style: AppTypography.h2.copyWith(
              color: valueColor ?? AppColors.textPrimaryDark,
              fontFamily: 'JetBrains Mono',
              fontWeight: FontWeight.w700,
              fontSize: 20,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms, delay: animationDelayMs.ms).slideY(begin: 0.1, end: 0, curve: Curves.easeOutCubic);
  }
}
