import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stock_investment_tracker/core/theme/app_colors.dart';
import 'package:stock_investment_tracker/presentation/transactions/providers/transactions_providers.dart';
import 'package:stock_investment_tracker/presentation/transactions/widgets/lot_card.dart';
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
    final lots = ref.watch(filteredLotsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

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
              IconButton(
                icon: Icon(Icons.picture_as_pdf_outlined, color: iconColor, size: 22),
                tooltip: 'Export Portfolio PDF Report',
                onPressed: () async {
                  HapticFeedback.lightImpact();
                  final allLots = ref.read(allLotsProvider).valueOrNull ?? [];
                  final summary = ref.read(portfolioSummaryProvider);
                  final stockSummaries = ref.read(stockSummariesProvider);
                  await PdfReportService.exportOverallPortfolioPdf(
                    lots: allLots,
                    summary: summary,
                    stockSummaries: stockSummaries,
                  );
                },
              ),
              IconButton(
                icon: Icon(_showSearch ? Icons.close : Icons.search, color: iconColor, size: 22),
                onPressed: () {
                  setState(() {
                    _showSearch = !_showSearch;
                  });
                },
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: Icon(Icons.tune_rounded, color: iconColor, size: 22),
                onPressed: () {
                  // Toggle filter chip row focus or reset
                },
              ),
              const SizedBox(width: 8),
            ],
          ),
          if (_showSearch) const TransactionSearchBar(),
          const FilterChipRow(),
          Expanded(
            child: lots.isEmpty
                ? const EmptyStateView(
                    icon: Icons.receipt_long_outlined,
                    title: 'No transactions found',
                    message: 'Add your first stock purchase to get started.',
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 110),
                    itemCount: lots.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        child: LotCard(lot: lots[index]),
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
          backgroundColor: const Color(0xFF584BF6),
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
