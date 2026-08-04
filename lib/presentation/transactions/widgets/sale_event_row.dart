import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:stock_investment_tracker/core/theme/app_colors.dart';
import 'package:stock_investment_tracker/core/theme/app_typography.dart';
import 'package:stock_investment_tracker/domain/entities/sale.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:stock_investment_tracker/providers/repository_providers.dart';

class SaleEventRow extends ConsumerWidget {
  final Sale sale;
  final String lotId;

  const SaleEventRow({super.key, required this.sale, required this.lotId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currencyFormat = NumberFormat('#,##0.00');
    final wholeFormat = NumberFormat('#,##0');
    final dateFormat = DateFormat('MMM d');

    final primaryTextColor = isDark ? Colors.white : AppColors.textPrimaryLight;

    return Slidable(
      key: ValueKey(sale.id),
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        extentRatio: 0.25,
        children: [
          SlidableAction(
            onPressed: (context) async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Delete Sale?'),
                  content: const Text(
                    'This will permanently delete this sale and recalculate the lot remaining shares.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
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
                    .read(saleRepositoryProvider)!
                    .deleteSale(lotId, sale.id);
              }
            },
            backgroundColor: AppColors.dangerRed,
            foregroundColor: Colors.white,
            icon: Icons.delete,
            label: 'Delete',
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 4.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              margin: const EdgeInsets.only(right: 10),
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Color(0xFFF97316), // Orange dot matching Transtions.png
                shape: BoxShape.circle,
              ),
            ),
            Expanded(
              child: Row(
                children: [
                  Text(
                    'Sold ${wholeFormat.format(sale.sharesSold)} @ ${currencyFormat.format(sale.sellPricePerShare)}',
                    style: AppTypography.body.copyWith(
                      color: primaryTextColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              dateFormat.format(sale.sellDate),
              style: AppTypography.caption.copyWith(
                color: AppColors.neutral500,
                fontSize: 12,
              ),
            ),
            const SizedBox(width: 16),
            Text(
              'Rs ${currencyFormat.format(sale.amountReceived)}',
              style: AppTypography.body.copyWith(
                color: AppColors.moneyGreen,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
