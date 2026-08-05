import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stock_investment_tracker/core/utils/currency_formatter.dart';
import 'package:stock_investment_tracker/core/theme/app_colors.dart';
import 'package:stock_investment_tracker/core/theme/app_typography.dart';
import 'package:stock_investment_tracker/domain/entities/lot.dart';
import 'package:stock_investment_tracker/domain/enums/lot_status.dart';
import 'package:stock_investment_tracker/presentation/common/badges.dart';
import 'package:stock_investment_tracker/presentation/common/ticker_avatar.dart';
import 'package:stock_investment_tracker/presentation/dashboard/providers/dashboard_providers.dart';
import 'package:stock_investment_tracker/presentation/transactions/widgets/add_sell_bottom_sheet.dart';

class SelectLotBottomSheet extends ConsumerWidget {
  const SelectLotBottomSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.backgroundDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => const SelectLotBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lots = ref.watch(allLotsProvider).valueOrNull ?? [];
    final availableLots = lots.where((l) => l.status != LotStatus.closed).toList();
    final wholeFormat = NumberFormat('#,##0');
    final dateFormat = DateFormat('MMM d, y');

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.offBlack,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(width: 24), // balance for title centering
                Text('Add Sell', style: AppTypography.h2),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.neutral500),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Which lot are you selling from?',
              style: AppTypography.body.copyWith(color: AppColors.neutral500),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            if (availableLots.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32.0),
                  child: Text(
                    'No open lots available to sell.',
                    style: AppTypography.caption.copyWith(color: AppColors.neutral500),
                  ),
                ),
              )
            else
              SizedBox(
                height: 300,
                child: ListView.separated(
                  itemCount: availableLots.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final lot = availableLots[index];
                    return InkWell(
                      onTap: () {
                        Navigator.pop(context);
                        AddSellBottomSheet.show(context, lot);
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceDark,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.offBlack),
                        ),
                        child: Row(
                          children: [
                            TickerAvatar(ticker: lot.ticker, size: 40),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        '${lot.ticker} · ',
                                        style: AppTypography.body.copyWith(fontWeight: FontWeight.bold),
                                      ),
                                      Text(
                                        '${wholeFormat.format(lot.sharesRemaining)} left',
                                        style: AppTypography.body.copyWith(fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Bought ${dateFormat.format(lot.buyDate)} @ ${AppCurrencyFormatter.format(lot.buyPricePerShare)}',
                                    style: AppTypography.caption.copyWith(color: AppColors.neutral500),
                                  ),
                                ],
                              ),
                            ),
                            StatusBadge(status: lot.status),
                            const Icon(Icons.chevron_right, color: AppColors.neutral500),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
