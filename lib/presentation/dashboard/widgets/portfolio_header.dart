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

  Widget _buildUserAvatar(String? photoUrl, String? displayName) {
    if (photoUrl != null && photoUrl.isNotEmpty) {
      return CircleAvatar(
        radius: 22,
        backgroundColor: AppColors.surfaceDark,
        backgroundImage: NetworkImage(photoUrl),
      );
    }

    final initial = (displayName != null && displayName.trim().isNotEmpty)
        ? displayName.trim().substring(0, 1).toUpperCase()
        : 'U';

    return CircleAvatar(
      radius: 22,
      backgroundColor: AppColors.brandIndigo,
      child: Text(
        initial,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).valueOrNull;
    final photoUrl = user?.photoURL;
    final displayName = user?.displayName;

    final formatCurrency = NumberFormat.simpleCurrency(name: 'PKR', decimalDigits: 0);
    final displayValue = formatCurrency
        .format(totalValue)
        .replaceAll('PKR', 'Rs ')
        .replaceAll('Rs  ', 'Rs ')
        .trim();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'TOTAL PORTFOLIO VALUE',
              style: AppTypography.caption.copyWith(
                color: AppColors.neutral500,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  displayValue,
                  style: AppTypography.display.copyWith(
                    color: AppColors.textPrimaryDark,
                    fontFamily: 'JetBrains Mono',
                    fontWeight: FontWeight.w700,
                    fontSize: 28,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                TrendChip(percentage: profitLossPercentage),
              ],
            ),
          ],
        ),
        _buildUserAvatar(photoUrl, displayName),
      ],
    );
  }
}
