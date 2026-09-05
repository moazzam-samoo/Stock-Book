import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:stock_investment_tracker/core/utils/currency_formatter.dart';
import 'package:stock_investment_tracker/core/theme/app_colors.dart';
import 'package:stock_investment_tracker/core/theme/app_typography.dart';
import 'package:stock_investment_tracker/domain/calculator/position_calculator.dart';
import 'package:stock_investment_tracker/domain/entities/position.dart';
import 'package:stock_investment_tracker/domain/entities/position_sale.dart';
import 'package:stock_investment_tracker/domain/enums/position_status.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:stock_investment_tracker/presentation/transactions/widgets/edit_sale_bottom_sheet.dart';
import 'package:stock_investment_tracker/providers/repository_providers.dart';

/// One positionSale inside a position's positionSale history, shown as a bordered card with the
/// profit that positionSale booked. Swipe left to edit or delete it.
class PositionSaleRow extends ConsumerWidget {
  final PositionSale positionSale;
  final Position position;

  /// Set on the per-buy slices a closed cycle is split into: the sale shown
  /// there may be part of a larger real sale, so editing or deleting it from
  /// that card would write back nonsense.
  final bool readOnly;

  const PositionSaleRow({
    super.key,
    required this.positionSale,
    required this.position,
    this.readOnly = false,
  });

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Delete PositionSale?'),
        content: const Text(
          'This will permanently delete this positionSale and recalculate the position remaining shares.',
        ),
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
      final repo = ref.read(positionRepositoryProvider);
      if (repo != null) {
        final updatedSales = position.sales.where((s) => s.id != positionSale.id).toList();
        final updatedPosition = position.copyWith(sales: updatedSales);
        // Deleting a sale can un-close or un-partial a position — status is
        // stored, not derived, so it has to be restamped here or a position
        // stays stuck as PARTIAL after its only sale is removed.
        final newStatus = PositionCalculator.computeStatus(updatedPosition);
        await repo.updatePosition(updatedPosition.copyWith(
          status: newStatus,
          closedAt: newStatus == PositionStatus.closed ? position.closedAt : null,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final wholeFormat = NumberFormat('#,##0');
    final dateFormat = DateFormat('MMM d, y');

    final primaryTextColor = isDark ? Colors.white : AppColors.textPrimaryLight;
    final rowBg = isDark ? const Color(0xFF1A1D27) : const Color(0xFFF8FAFC);
    final borderColor =
        isDark ? const Color(0xFF242731) : const Color(0xFFE2E8F0);

    // Profit booked by this individual sale, against the cost basis frozen at
    // the moment it was sold — never the position's current avg cost, which
    // later buys may have since moved. See PHASE-03A for why.
    final costBasisAtSale = positionSale.costBasisAtSale ?? 0.0;
    final positionSaleProfit = positionSale.realizedPL;
    final profitPercent = costBasisAtSale == 0
        ? 0.0
        : (positionSale.pricePerShare - costBasisAtSale) / costBasisAtSale * 100;
    final isProfit = positionSaleProfit >= 0;
    final plColor = isProfit
        ? (isDark ? AppColors.moneyGreen : AppColors.moneyGreenOnLight)
        : AppColors.alertRed;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Slidable(
          key: ValueKey(positionSale.id),
          enabled: !readOnly,
          endActionPane: readOnly
              ? null
              : ActionPane(
                  motion: const ScrollMotion(),
                  extentRatio: 0.5,
                  children: [
                    SlidableAction(
                      onPressed: (ctx) {
                        HapticFeedback.lightImpact();
                        EditSaleBottomSheet.show(ctx, position, positionSale);
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Line 1: what was sold, and when
                Row(
                  children: [
                    Container(
                      margin: const EdgeInsets.only(right: 10),
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF97316),
                        shape: BoxShape.circle,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'Sold ${wholeFormat.format(positionSale.shares)} @ ${AppCurrencyFormatter.format(positionSale.pricePerShare)}',
                        style: AppTypography.body.copyWith(
                          color: primaryTextColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Text(
                      dateFormat.format(positionSale.date),
                      style: AppTypography.caption.copyWith(
                        color: AppColors.neutral500,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Cost basis ${AppCurrencyFormatter.format(costBasisAtSale)}',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.neutral500,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 8),
                Divider(color: borderColor, height: 1),
                const SizedBox(height: 8),

                // Line 2: money in, and the profit this positionSale booked
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Received ',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.neutral500,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          AppCurrencyFormatter.format(positionSale.amountReceived),
                          style: AppTypography.body.copyWith(
                            color: isDark ? AppColors.moneyGreen : AppColors.moneyGreenOnLight,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: plColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: plColor.withOpacity(0.25)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isProfit
                                ? Icons.arrow_upward
                                : Icons.arrow_downward,
                            size: 12,
                            color: plColor,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '${isProfit ? "+" : "-"}${AppCurrencyFormatter.format(positionSaleProfit.abs())}',
                            style: AppTypography.caption.copyWith(
                              color: plColor,
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '(${isProfit ? "+" : ""}${profitPercent.toStringAsFixed(1)}%)',
                            style: AppTypography.caption.copyWith(
                              color: plColor.withOpacity(0.8),
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
