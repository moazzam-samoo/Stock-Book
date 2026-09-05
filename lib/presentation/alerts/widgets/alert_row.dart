import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';
import 'package:stock_investment_tracker/core/theme/app_colors.dart';
import 'package:stock_investment_tracker/core/theme/app_typography.dart';
import 'package:stock_investment_tracker/core/utils/currency_formatter.dart';
import 'package:stock_investment_tracker/domain/entities/price_alert.dart';
import 'package:stock_investment_tracker/presentation/alerts/providers/alerts_providers.dart';
import 'package:stock_investment_tracker/presentation/common/ticker_avatar.dart';
import 'package:stock_investment_tracker/presentation/alerts/widgets/add_alert_bottom_sheet.dart';

class AlertRow extends ConsumerWidget {
  final PriceAlert alert;

  const AlertRow({super.key, required this.alert});

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Delete Alert?'),
        content: Text('Remove alert for ${alert.ticker}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: AppColors.dangerRed),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      HapticFeedback.mediumImpact();
      await ref.read(alertsControllerProvider.notifier).deleteAlert(alert.id);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? Colors.white : AppColors.textPrimaryLight;
    final rowBg = isDark ? const Color(0xFF1A1D27) : const Color(0xFFF8FAFC);
    final borderColor = isDark ? const Color(0xFF242731) : const Color(0xFFE2E8F0);
    final dateFormat = DateFormat('MMM d');

    final threshold = alertThreshold(alert.targetPrice, alert.tolerancePercent);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Slidable(
          key: ValueKey(alert.id),
          endActionPane: ActionPane(
            motion: const ScrollMotion(),
            extentRatio: 0.5,
            children: [
              SlidableAction(
                onPressed: (ctx) {
                  HapticFeedback.lightImpact();
                  AddAlertBottomSheet.show(ctx, existing: alert);
                },
                backgroundColor: const Color(0xFF584BF6),
                foregroundColor: Colors.white,
                icon: Icons.edit_outlined,
                label: 'Edit',
              ),
              SlidableAction(
                onPressed: (ctx) => _confirmDelete(ctx, ref),
                backgroundColor: AppColors.dangerRed,
                foregroundColor: Colors.white,
                icon: Icons.delete_outline,
                label: 'Delete',
              ),
            ],
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: rowBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor, width: 1.2),
            ),
            child: Row(
              children: [
                TickerAvatar(ticker: alert.ticker, size: 40),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            alert.ticker,
                            style: AppTypography.body.copyWith(
                              color: primaryTextColor,
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            AppCurrencyFormatter.format(alert.targetPrice),
                            style: AppTypography.body.copyWith(
                              color: primaryTextColor,
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: alert.isActive
                                  ? (isDark ? AppColors.chartGreen.withOpacity(0.15) : AppColors.moneyGreenOnLight.withOpacity(0.15))
                                  : AppColors.neutral500.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              // Alerts aren't one-shot: a fired alert stays
                              // ACTIVE so it can keep notifying on a further
                              // move (see PriceAlert.lastAlertPrice) —
                              // "TRIGGERED" would now be a permanent, wrong
                              // label the moment it first fired.
                              alert.isActive ? 'ACTIVE' : 'PAUSED',
                              style: AppTypography.caption.copyWith(
                                color: alert.isActive
                                    ? (isDark ? AppColors.chartGreen : AppColors.moneyGreenOnLight)
                                    : AppColors.neutral500,
                                fontWeight: FontWeight.w700,
                                fontSize: 10,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          if (alert.alertSent) ...[
                            const SizedBox(width: 6),
                            Icon(
                              Icons.notifications_active,
                              size: 14,
                              color: isDark ? AppColors.chartGreen : AppColors.moneyGreenOnLight,
                            ),
                          ],
                          const SizedBox(width: 8),
                          Text(
                            '≤ ${AppCurrencyFormatter.format(threshold)}',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.neutral500,
                              fontSize: 12,
                            ),
                          ),
                          if (alert.lastAlertPrice != null) ...[
                            const SizedBox(width: 8),
                            Text(
                              // Shows the price the alert actually last fired
                              // at — the useful number when it can fire
                              // repeatedly, not just whether it ever did.
                              '· last: ${AppCurrencyFormatter.format(alert.lastAlertPrice!)}',
                              style: AppTypography.caption.copyWith(
                                color: AppColors.neutral500,
                                fontSize: 12,
                              ),
                            ),
                          ] else if (alert.alertSentAt != null) ...[
                            const SizedBox(width: 8),
                            Text(
                              '· ${dateFormat.format(alert.alertSentAt!)}',
                              style: AppTypography.caption.copyWith(
                                color: AppColors.neutral500,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.swipe_left_rounded,
                  size: 16,
                  color: AppColors.neutral500,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
