import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';
import 'package:stock_investment_tracker/core/theme/app_colors.dart';
import 'package:stock_investment_tracker/core/theme/app_typography.dart';
import 'package:stock_investment_tracker/core/utils/currency_formatter.dart';
import 'package:stock_investment_tracker/domain/entities/withdrawal.dart';
import 'package:stock_investment_tracker/presentation/settings/providers/withdrawal_provider.dart';
import 'package:stock_investment_tracker/presentation/settings/widgets/withdrawal_bottom_sheet.dart';

class WithdrawalRow extends ConsumerWidget {
  final Withdrawal withdrawal;

  const WithdrawalRow({super.key, required this.withdrawal});

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Delete Withdrawal?'),
        content: Text(
          'This will add ${AppCurrencyFormatter.format(withdrawal.amount)} back to your available profit.',
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
      await ref
          .read(withdrawalControllerProvider.notifier)
          .deleteWithdrawal(withdrawal.id);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
          key: ValueKey(withdrawal.id),
          endActionPane: ActionPane(
            motion: const ScrollMotion(),
            extentRatio: 0.5,
            children: [
              SlidableAction(
                onPressed: (ctx) {
                  HapticFeedback.lightImpact();
                  WithdrawalBottomSheet.show(ctx, existing: withdrawal);
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
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: AppColors.warningYellow.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.north_east_rounded,
                    size: 14,
                    color: AppColors.warningYellow,
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppCurrencyFormatter.format(withdrawal.amount),
                        style: AppTypography.body.copyWith(
                          color: primaryTextColor,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        withdrawal.note.isEmpty
                            ? dateFormat.format(withdrawal.date)
                            : '${dateFormat.format(withdrawal.date)} · ${withdrawal.note}',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.neutral500,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
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
