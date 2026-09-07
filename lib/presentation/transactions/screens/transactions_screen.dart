import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
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
import 'package:stock_investment_tracker/providers/market_prices_providers.dart';
import 'package:stock_investment_tracker/providers/workflow_trigger_providers.dart';
import 'package:stock_investment_tracker/core/services/workflow_trigger_service.dart';
import 'package:stock_investment_tracker/presentation/common/app_scaffold.dart';
import 'package:stock_investment_tracker/presentation/common/custom_app_bar.dart';

import 'package:go_router/go_router.dart';

/// Pull-to-refresh does two things, and the distinction matters:
///
///  1. Re-reads Firestore, so whatever the backend last wrote shows
///     immediately. This always happens.
///  2. If a GitHub token is saved (Settings), also asks the backend to run
///     *now* rather than waiting for its 5-minute schedule — which matters
///     most outside market hours, on weekends, or right after adding a
///     holding.
///
/// The run takes about a minute, so prices don't update the instant the
/// spinner stops. The Firestore stream picks them up on its own when the
/// backend writes; the snackbar sets that expectation rather than leaving it
/// looking broken.
Future<void> _refreshPrices(BuildContext context, WidgetRef ref) async {
  ref.invalidate(watchMarketPriceProvider);

  final result = await ref.read(triggerWorkflowProvider)();
  if (!context.mounted) return;

  // A missing token is the normal state for anyone who hasn't set one up —
  // the local refresh above still happened, so don't nag about it.
  if (result.outcome == WorkflowTriggerOutcome.noToken) return;

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(result.message),
      backgroundColor: result.isSuccess ? AppColors.moneyGreenOnLight : AppColors.dangerRed,
      behavior: SnackBarBehavior.floating,
    ),
  );
}

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
    // Reversed so newest buy appears on top.
    final cards = <({Position display, Position? writeTarget})>[];
    for (final position in filteredPositions) {
      final splits = PositionCalculator.splitByBuy(position);
      for (final slice in splits.reversed) {
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
              subtitle: 'Track your investments',
              icon: FontAwesomeIcons.chartLine.data,
              iconBadgeColor: isDark ? AppColors.moneyGreen : AppColors.moneyGreenOnLight,
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
                InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () {
                    HapticFeedback.lightImpact();
                    setState(() {
                      _showSearch = !_showSearch;
                      if (!_showSearch) {
                        // Closing the search bar used to leave its last
                        // query in place forever (the bar itself is a
                        // separate widget with its own disposed state, but
                        // searchQueryProvider is a persistent provider) —
                        // every other position stayed hidden until the app
                        // restarted, reading as "stocks don't come back".
                        ref.read(searchQueryProvider.notifier).updateQuery('');
                      }
                    });
                  },
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDark ? const Color(0xFF13151B) : Colors.white,
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF242731)
                            : const Color(0xFFE2E8F0),
                        width: 1.2,
                      ),
                    ),
                    child: Icon(
                      _showSearch ? Icons.close : Icons.search,
                      color: iconColor,
                      size: 20,
                    ),
                  ),
                ),
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
                  : RefreshIndicator(
                      color: AppColors.brandIndigo,
                      backgroundColor: isDark ? AppColors.offBlack : Colors.white,
                      onRefresh: () => _refreshPrices(context, ref),
                      child: ListView.builder(
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
                              key: ValueKey(card.display.id),
                              position: card.display,
                              writePosition: card.writeTarget,
                            ),
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
        floatingActionButton: Padding(
          padding: const EdgeInsets.only(bottom: 114.0),
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
