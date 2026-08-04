import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:stock_investment_tracker/core/theme/app_colors.dart';
import 'package:stock_investment_tracker/core/theme/app_typography.dart';
import 'package:stock_investment_tracker/core/theme/app_spacing.dart';
import 'package:stock_investment_tracker/core/utils/currency_formatter.dart';
import 'package:flutter_animate/flutter_animate.dart';

class StatCard extends StatelessWidget {
  final String label;
  final num value;
  final bool isCurrency;
  final Color? valueColor;
  final int animationDelayMs;
  final VoidCallback? onTap;
  final bool isSelected;

  const StatCard({
    super.key,
    required this.label,
    required this.value,
    this.isCurrency = false,
    this.valueColor,
    this.animationDelayMs = 0,
    this.onTap,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final formatNumber = NumberFormat.decimalPattern();

    final displayValue = isCurrency 
      ? AppCurrencyFormatter.format(value, decimalDigits: 0)
      : formatNumber.format(value);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1E2620) : AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.moneyGreen : const Color(0xFF242731),
            width: isSelected ? 1.8 : 1.2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    label.toUpperCase(),
                    style: AppTypography.caption.copyWith(
                      color: isSelected ? AppColors.moneyGreen : AppColors.neutral500,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isSelected)
                  const Icon(
                    Icons.info_outline,
                    size: 14,
                    color: AppColors.moneyGreen,
                  ),
              ],
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
      ),
    ).animate().fadeIn(duration: 400.ms, delay: animationDelayMs.ms).slideY(begin: 0.1, end: 0, curve: Curves.easeOutCubic);
  }
}
