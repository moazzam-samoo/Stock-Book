import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:stock_investment_tracker/core/theme/app_colors.dart';
import 'package:stock_investment_tracker/core/theme/app_typography.dart';
import 'package:stock_investment_tracker/core/theme/app_spacing.dart';
import 'package:stock_investment_tracker/presentation/common/badges.dart';
import 'package:stock_investment_tracker/presentation/auth/providers/auth_providers.dart';
import 'package:stock_investment_tracker/core/utils/currency_formatter.dart';

class PortfolioHeader extends ConsumerWidget {
  final double totalValue;
  final double profitLossPercentage;
  final DateTime? lastSyncTime;

  const PortfolioHeader({
    super.key,
    required this.totalValue,
    required this.profitLossPercentage,
    this.lastSyncTime,
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

    final displayValue = AppCurrencyFormatter.format(totalValue, decimalDigits: 0);

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
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildUserAvatar(photoUrl, displayName),
            if (lastSyncTime != null) ...[
              const SizedBox(height: 4),
              Text(
                'Last Sync: ${DateFormat('h:mm a').format(lastSyncTime!)}',
                style: AppTypography.caption.copyWith(
                  color: AppColors.neutral500,
                  fontSize: 10,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
