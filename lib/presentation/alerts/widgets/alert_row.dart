import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:stock_investment_tracker/core/theme/app_colors.dart';
import 'package:stock_investment_tracker/core/theme/app_typography.dart';
import 'package:stock_investment_tracker/core/utils/currency_formatter.dart';
import 'package:stock_investment_tracker/data/data_sources/remote/firestore_data_source.dart';
import 'package:stock_investment_tracker/domain/entities/price_alert.dart';
import 'package:stock_investment_tracker/presentation/alerts/providers/alerts_providers.dart';
import 'package:stock_investment_tracker/presentation/alerts/widgets/add_alert_bottom_sheet.dart';
import 'package:stock_investment_tracker/presentation/common/ticker_avatar.dart';
import 'package:stock_investment_tracker/providers/market_prices_providers.dart';
import 'package:stock_investment_tracker/providers/ticker_providers.dart';
import 'package:stock_investment_tracker/presentation/dashboard/providers/market_status_providers.dart';

class AlertRow extends ConsumerWidget {
  const AlertRow({required this.alert, super.key});

  final PriceAlert alert;

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
    final secondaryTextColor = isDark ? Colors.white54 : Colors.black54;
    final cardBg = isDark ? const Color(0xFF13151B) : Colors.white;
    final borderColor = isDark
        ? const Color(0xFF242731)
        : const Color(0xFFE2E8F0);
    final greenColor = isDark
        ? AppColors.moneyGreen
        : AppColors.moneyGreenOnLight;

    final threshold = alertThreshold(alert.targetPrice, alert.tolerancePercent);

    // Live market price & previous close for percentage change
    final marketPriceAsync = ref.watch(watchMarketPriceProvider(alert.ticker));
    final marketPrice = marketPriceAsync.valueOrNull;
    final livePrice = marketPrice?.price;
    final previousClose = marketPrice?.previousClose;
    final isMarketOpen = currentlyOpen(
      ref.watch(watchMarketStatusProvider).valueOrNull,
    );
    final changePercent =
        (livePrice != null && previousClose != null && previousClose > 0)
        ? ((livePrice - previousClose) / previousClose) * 100
        : null;

    // Full company name lookup
    final normalizedTicker = FirestoreDataSource.normalizeTicker(alert.ticker);
    final companyName = ref
        .watch(allTickersProvider)
        .valueOrNull
        ?.where(
          (t) =>
              FirestoreDataSource.normalizeTicker(t.symbol) == normalizedTicker,
        )
        .firstOrNull
        ?.name;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
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
          child: InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              AddAlertBottomSheet.show(context, existing: alert);
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark
                      ? (alert.isActive ? const Color(0xFF1E3A2B) : borderColor)
                      : (alert.isActive
                            ? const Color(0xFFA7F3D0)
                            : borderColor),
                  width: 1.2,
                ),
                boxShadow: [
                  if (!isDark)
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Top Header: Avatar + Expanded column (Row 1: Ticker & Price, Row 2: Company Name, Row 3: Status & Bell)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TickerAvatar(ticker: alert.ticker, size: 48),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Row 1: Ticker and Live Price Pill
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    alert.ticker,
                                    style: AppTypography.h3.copyWith(
                                      fontWeight: FontWeight.w800,
                                      color: primaryTextColor,
                                      fontSize: 18,
                                      height: 0.6,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: greenColor.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: greenColor.withValues(alpha: 0.25),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        livePrice != null
                                            ? AppCurrencyFormatter.format(
                                                livePrice,
                                              )
                                            : '—',
                                        style: TextStyle(
                                          color: greenColor,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 13,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Icon(
                                        Icons.arrow_outward_rounded,
                                        size: 13,
                                        color: greenColor,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            // Row 2: Share full company name (clean spacing, no overlap, room to wrap)
                            if (companyName != null &&
                                companyName.isNotEmpty) ...[
                              Text(
                                companyName,
                                style: AppTypography.caption.copyWith(
                                  color: secondaryTextColor,
                                  fontSize: 11,
                                  height: 0,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],

                            const SizedBox(height: 8),

                            // Row 3: Status pill on left, Bell icon on right
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: alert.isActive
                                        ? greenColor.withValues(alpha: 0.12)
                                        : AppColors.neutral500.withValues(
                                            alpha: 0.12,
                                          ),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: alert.isActive
                                          ? greenColor.withValues(alpha: 0.3)
                                          : AppColors.neutral500.withValues(
                                              alpha: 0.3,
                                            ),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 6,
                                        height: 6,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: alert.isActive
                                              ? greenColor
                                              : AppColors.neutral500,
                                        ),
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        alert.isActive ? 'ACTIVE' : 'PAUSED',
                                        style: TextStyle(
                                          color: alert.isActive
                                              ? greenColor
                                              : AppColors.neutral500,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 10,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  alert.alertSent
                                      ? Icons.notifications_active
                                      : Icons.notifications_none_rounded,
                                  size: 20,
                                  color: alert.alertSent
                                      ? greenColor
                                      : AppColors.neutral500,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),
                  Divider(color: borderColor, height: 1),
                  const SizedBox(height: 14),

                  // 2. Middle Metrics Row: Target Price | Current Price | Change %
                  Row(
                    children: [
                      // Column 1: Target Price
                      Expanded(
                        flex: 4,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.track_changes_outlined,
                                  size: 13,
                                  color: secondaryTextColor,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  'Target Price',
                                  style: AppTypography.caption.copyWith(
                                    color: secondaryTextColor,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                '≤ ${AppCurrencyFormatter.format(threshold)}',
                                style: AppTypography.body.copyWith(
                                  color: primaryTextColor,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Vertical Divider
                      Container(width: 1, height: 32, color: borderColor),
                      const SizedBox(width: 12),

                      // Column 2: Current Price
                      Expanded(
                        flex: 4,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  FontAwesomeIcons.arrowTrendUp.data,
                                  size: 12,
                                  color: secondaryTextColor,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  'Current Price',
                                  style: AppTypography.caption.copyWith(
                                    color: secondaryTextColor,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text.rich(
                                TextSpan(
                                  children: [
                                    TextSpan(
                                      text: livePrice != null
                                          ? AppCurrencyFormatter.format(
                                              livePrice,
                                            )
                                          : '—',
                                      style: AppTypography.body.copyWith(
                                        color: livePrice == null
                                            ? secondaryTextColor
                                            : isMarketOpen == true
                                            ? greenColor
                                            : primaryTextColor,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 15,
                                      ),
                                    ),
                                    if (marketPrice != null)
                                      TextSpan(
                                        text:
                                            ' As of ${DateFormat('h:mm a').format(marketPrice.updatedAt)}',
                                        style: TextStyle(
                                          color: secondaryTextColor,
                                          fontWeight: FontWeight.w500,
                                          fontSize: 10,
                                        ),
                                      ),
                                  ],
                                ),
                                maxLines: 1,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Vertical Divider
                      Container(width: 1, height: 32, color: borderColor),
                      const SizedBox(width: 8),

                      // Column 3: Change % pill
                      Expanded(
                        flex: 3,
                        child: Center(
                          child: changePercent != null
                              ? Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        (changePercent >= 0
                                                ? greenColor
                                                : AppColors.alertRed)
                                            .withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color:
                                          (changePercent >= 0
                                                  ? greenColor
                                                  : AppColors.alertRed)
                                              .withOpacity(0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        changePercent >= 0
                                            ? Icons.arrow_outward_rounded
                                            : Icons.south_east_rounded,
                                        size: 12,
                                        color: changePercent >= 0
                                            ? greenColor
                                            : AppColors.alertRed,
                                      ),
                                      const SizedBox(width: 3),
                                      Text(
                                        '${changePercent >= 0 ? "+" : ""}${changePercent.toStringAsFixed(2)}%',
                                        style: TextStyle(
                                          color: changePercent >= 0
                                              ? greenColor
                                              : AppColors.alertRed,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.neutral500.withOpacity(
                                      0.1,
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Text(
                                    '—',
                                    style: TextStyle(
                                      color: AppColors.neutral500,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // 3. Bottom Status Banner: Green checkmark + Alert Active + Details + Chevron
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: alert.isActive
                          ? (isDark
                                ? const Color(0xFF0F261C)
                                : const Color(0xFFECFDF5))
                          : (isDark
                                ? const Color(0xFF1A1D27)
                                : const Color(0xFFF1F5F9)),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: alert.isActive
                            ? greenColor.withOpacity(0.2)
                            : borderColor,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: alert.isActive
                                ? greenColor
                                : AppColors.neutral500,
                          ),
                          child: Icon(
                            alert.isActive
                                ? Icons.check_rounded
                                : Icons.pause_rounded,
                            color: isDark
                                ? const Color(0xFF0F261C)
                                : Colors.white,
                            size: 15,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                alert.isActive
                                    ? 'Alert Active'
                                    : 'Alert Paused',
                                style: TextStyle(
                                  color: alert.isActive
                                      ? greenColor
                                      : secondaryTextColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                alert.isActive
                                    ? 'Will notify you when price hits ${AppCurrencyFormatter.format(threshold)} or lower.'
                                    : 'Alert is currently paused.',
                                style: AppTypography.caption.copyWith(
                                  color: secondaryTextColor,
                                  fontSize: 11,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 18,
                          color: secondaryTextColor,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
