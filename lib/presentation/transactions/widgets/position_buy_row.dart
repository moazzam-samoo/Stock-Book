import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';
import 'package:stock_investment_tracker/core/theme/app_colors.dart';
import 'package:stock_investment_tracker/core/theme/app_typography.dart';
import 'package:stock_investment_tracker/core/utils/currency_formatter.dart';
import 'package:stock_investment_tracker/domain/calculator/position_calculator.dart';
import 'package:stock_investment_tracker/domain/entities/position.dart';
import 'package:stock_investment_tracker/domain/entities/position_buy.dart';
import 'package:stock_investment_tracker/presentation/transactions/widgets/edit_buy_bottom_sheet.dart';
import 'package:stock_investment_tracker/providers/repository_providers.dart';

/// One buy inside a position's purchase history — the individual-lot detail
/// that keeping every buy visible (rather than collapsing to just the blended
/// average) is what makes the merge model safe rather than lossy.
class PositionBuyRow extends ConsumerWidget {
  final PositionBuy buy;
  final Position position;

  const PositionBuyRow({super.key, required this.buy, required this.position});

  int get _sharesSoldElsewhere =>
      position.buys.fold<int>(0, (sum, b) => sum + b.shares) -
      PositionCalculator.sharesHeld(position);

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    // Deleting a buy can't be allowed to leave recorded sales exceeding what
    // remains bought — that would make sharesHeld negative and desync every
    // downstream figure derived from this position.
    final sharesAfterDelete =
        position.buys.fold<int>(0, (sum, b) => sum + b.shares) - buy.shares;
    if (sharesAfterDelete < _sharesSoldElsewhere) {
      showDialog<void>(
        context: context,
        builder: (dialogCtx) => AlertDialog(
          title: const Text('Cannot Delete Buy'),
          content: const Text(
            'Deleting this buy would leave fewer shares purchased than already sold. Delete or edit the related sale first.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Delete Buy?'),
        content: const Text(
          'This will permanently remove this buy from the position.',
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
        final updatedBuys = position.buys.where((b) => b.id != buy.id).toList();
        final updatedPosition = position.copyWith(buys: updatedBuys);
        final newStatus = PositionCalculator.computeStatus(updatedPosition);
        await repo.updatePosition(updatedPosition.copyWith(status: newStatus));
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

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Slidable(
          key: ValueKey(buy.id),
          endActionPane: ActionPane(
            motion: const ScrollMotion(),
            extentRatio: 0.5,
            children: [
              SlidableAction(
                onPressed: (ctx) {
                  HapticFeedback.lightImpact();
                  EditBuyBottomSheet.show(ctx, position, buy);
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
                Container(
                  margin: const EdgeInsets.only(right: 10),
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFF10B981),
                    shape: BoxShape.circle,
                  ),
                ),
                Expanded(
                  child: Text(
                    'Bought ${wholeFormat.format(buy.shares)} @ ${AppCurrencyFormatter.format(buy.pricePerShare)}',
                    style: AppTypography.body.copyWith(
                      color: primaryTextColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
                Text(
                  dateFormat.format(buy.date),
                  style: AppTypography.caption.copyWith(
                    color: AppColors.neutral500,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
