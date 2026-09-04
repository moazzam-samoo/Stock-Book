import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stock_investment_tracker/core/theme/app_colors.dart';
import 'package:stock_investment_tracker/domain/calculator/position_calculator.dart';
import 'package:stock_investment_tracker/domain/entities/position.dart';
import 'package:stock_investment_tracker/presentation/transactions/providers/transactions_providers.dart';
import 'package:stock_investment_tracker/presentation/transactions/widgets/position_card.dart';
import 'package:stock_investment_tracker/presentation/transactions/widgets/transaction_search_bar.dart';
import 'package:stock_investment_tracker/presentation/transactions/widgets/filter_chip_row.dart';
import 'package:stock_investment_tracker/presentation/transactions/widgets/add_transaction_bottom_sheet.dart';
import 'package:stock_investment_tracker/presentation/common/empty_state_view.dart';
import 'package:stock_investment_tracker/core/services/pdf_report_service.dart';
import 'package:stock_investment_tracker/presentation/dashboard/providers/dashboard_providers.dart';
import 'package:stock_investment_tracker/presentation/common/app_scaffold.dart';
import 'package:stock_investment_tracker/presentation/common/custom_app_bar.dart';

import 'package:go_router/go_router.dart';

class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  bool _showSearch = false;

  @override
  Widget build(BuildContext context) {
    final filteredPositions = ref.watch(filteredPositionsProvider);
    // A closed cycle shows as one card per buy — each card knows the real
    // position behind it so edit/delete still land on the right document.
    final cards = <({Position display, Position? writeTarget})>[];
    for (final position in filteredPositions) {
      for (final slice in PositionCalculator.splitByBuy(position)) {
        cards.add((
          display: slice,
          writeTarget: identical(slice, position) ? null : position,
        ));
      }
    }
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = isDark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF64748B);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          context.go('/');
        }
      },
      child: AppScaffold(
        body: Column(
          children: [
            CustomAppBar(
              title: 'Transactions',
              actions: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () async {
                      HapticFeedback.lightImpact();
                      // The overall report covers the whole portfolio — it must
                      // not depend on which filter chip happens to be selected
                      // (the default one now hides closed positions).
                      final positions =
                          ref.read(allPositionsProvider).valueOrNull ?? [];
                      final summary = ref.read(portfolioSummaryProvider);
                      final stockSummaries = ref.read(stockSummariesProvider);
                      final withdrawals =
                          ref.read(allWithdrawalsProvider).valueOrNull ?? [];
                      await PdfReportService.exportOverallPortfolioPdf(
                        positions: positions,
                        summary: summary,
                        stockSummaries: stockSummaries,
                        withdrawals: withdrawals,
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF10233A)
                            : const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.chartBlue.withOpacity(0.25),
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.picture_as_pdf_outlined,
                            size: 16,
                            color: AppColors.chartBlue,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Export PDF',
                            style: TextStyle(
                              color: AppColors.chartBlue,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(
                    _showSearch ? Icons.close : Icons.search,
                    color: iconColor,
                    size: 22,
                  ),
                  onPressed: () {
                    setState(() {
                      _showSearch = !_showSearch;
                    });
                  },
                ),
                const SizedBox(width: 12),
              ],
            ),
            if (_showSearch) const TransactionSearchBar(),
            const FilterChipRow(),
            Expanded(
              child: cards.isEmpty
                  ? const EmptyStateView(
                      icon: Icons.receipt_long_outlined,
                      title: 'No transactions found',
                      message: 'Add your first stock purchase to get started.',
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.only(bottom: 110),
                      itemCount: cards.length,
                      itemBuilder: (context, index) {
                        final card = cards[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 6,
                          ),
                          child: PositionCard(
                            position: card.display,
                            writePosition: card.writeTarget,
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
        floatingActionButton: Padding(
          padding: const EdgeInsets.only(bottom: 96.0),
          child: FloatingActionButton(
            shape: const CircleBorder(),
            backgroundColor: isDark
                ? AppColors.moneyGreen.withOpacity(0.7)
                : AppColors.moneyGreenOnLight.withOpacity(0.85),
            elevation: 4,
            onPressed: () {
              HapticFeedback.lightImpact();
              AddTransactionBottomSheet.show(context);
            },
            child: const Icon(Icons.add, color: Colors.white, size: 28),
          ),
        ),
      ),
    );
  }
}
