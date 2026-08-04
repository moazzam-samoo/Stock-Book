import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:stock_investment_tracker/core/theme/app_colors.dart';
import 'package:stock_investment_tracker/core/theme/app_typography.dart';
import 'package:stock_investment_tracker/core/theme/app_spacing.dart';
import 'package:stock_investment_tracker/presentation/common/badges.dart';
import 'package:stock_investment_tracker/presentation/auth/providers/auth_providers.dart';

class PortfolioHeader extends ConsumerWidget {
  final double totalValue;
  final double profitLossPercentage;

  const PortfolioHeader({
    super.key,
    required this.totalValue,
    required this.profitLossPercentage,
  });

  String _getGreeting(String? userName) {
    final hour = DateTime.now().hour;
    String greeting;
    if (hour < 12) {
      greeting = 'Good morning';
    } else if (hour < 17) {
      greeting = 'Good afternoon';
    } else {
      greeting = 'Good evening';
    }

    if (userName != null && userName.trim().isNotEmpty) {
      final firstName = userName.trim().split(' ').first;
      return '$greeting $firstName';
    }
    return greeting;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).valueOrNull;
    final userName = user?.displayName;

    final formatCurrency = NumberFormat.simpleCurrency(name: 'PKR', decimalDigits: 0);
    final displayValue = formatCurrency.format(totalValue).replaceAll('PKR', 'Rs').trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _getGreeting(userName),
          style: AppTypography.body.copyWith(
            color: AppColors.neutral400,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'TOTAL PORTFOLIO VALUE',
          style: AppTypography.caption.copyWith(
            color: AppColors.neutral500,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.8,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 2),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              displayValue,
              style: AppTypography.display.copyWith(
                color: AppColors.textPrimaryDark,
                fontFamily: 'JetBrains Mono',
                fontWeight: FontWeight.w700,
                fontSize: 32,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            TrendChip(percentage: profitLossPercentage),
          ],
        ),
      ],
    );
  }
}
