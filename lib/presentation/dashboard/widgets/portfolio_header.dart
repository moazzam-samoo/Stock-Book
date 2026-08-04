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
  final bool isOffline;

  const PortfolioHeader({
    super.key,
    required this.totalValue,
    required this.profitLossPercentage,
    this.lastSyncTime,
    this.isOffline = false,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
                color: isDark ? AppColors.neutral500 : const Color(0xFF64748B),
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
                    color: isDark ? Colors.white : AppColors.textPrimaryLight,
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
              const SizedBox(height: 6),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isOffline ? AppColors.alertRed : const Color(0xFF00FF7F),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    isOffline
                        ? 'Offline (${DateFormat('h:mm a').format(lastSyncTime!)})'
                        : 'Last Sync: ${DateFormat('h:mm a').format(lastSyncTime!)}',
                    style: AppTypography.caption.copyWith(
                      color: isOffline ? AppColors.alertRed : AppColors.neutral500,
                      fontSize: 10,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ],
    );
  }
}
