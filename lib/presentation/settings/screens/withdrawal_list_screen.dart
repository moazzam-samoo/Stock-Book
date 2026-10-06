import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:stock_investment_tracker/core/services/pdf_report_service.dart';
import 'package:stock_investment_tracker/core/theme/app_colors.dart';
import 'package:stock_investment_tracker/core/theme/app_typography.dart';
import 'package:stock_investment_tracker/core/utils/currency_formatter.dart';
import 'package:stock_investment_tracker/presentation/common/custom_app_bar.dart';
import 'package:stock_investment_tracker/presentation/dashboard/providers/dashboard_providers.dart';
import 'package:stock_investment_tracker/presentation/settings/providers/settings_provider.dart';
import 'package:stock_investment_tracker/presentation/settings/widgets/withdrawal_bottom_sheet.dart';
import 'package:stock_investment_tracker/presentation/settings/widgets/withdrawal_row.dart';

class WithdrawalListScreen extends ConsumerWidget {
  const WithdrawalListScreen({super.key});

  Future<void> _exportPdf(BuildContext context, WidgetRef ref) async {
    final withdrawals = ref.read(allWithdrawalsProvider).valueOrNull ?? [];
    if (withdrawals.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No withdrawals to export.')),
      );
      return;
    }
    final summary = ref.read(portfolioSummaryProvider);
    await PdfReportService.exportWithdrawalsPdf(
      withdrawals: withdrawals,
      totalWithdrawn: summary.totalWithdrawn,
      grossRealizedPL: summary.grossRealizedPL,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? Colors.white : AppColors.textPrimaryLight;
    final cardBg = isDark ? const Color(0xFF13151B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF242731) : const Color(0xFFE2E8F0);
    final scaffoldBg = isDark ? const Color(0xFF0D0F14) : const Color(0xFFF5F5F5);
    final accentGreen = isDark ? AppColors.moneyGreen : AppColors.moneyGreenOnLight;

    final withdrawalsAsync = ref.watch(allWithdrawalsProvider);
    final summary = ref.watch(portfolioSummaryProvider);

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomAppBar(
              title: 'Profit Withdrawals',
              titleFontSize: 20,
              showBackButton: true,
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: InkWell(
                    onTap: () => _exportPdf(context, ref),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1A1D27) : const Color(0xFFF0FAF5),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: borderColor),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.picture_as_pdf_rounded,
                            size: 15,
                            color: accentGreen,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'Export PDF',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: accentGreen,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            Expanded(
              child: withdrawalsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
                data: (withdrawals) {
                  return CustomScrollView(
                    slivers: [
                      // Summary card
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: cardBg,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: borderColor),
                              boxShadow: isDark
                                  ? null
                                  : [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 12,
                                        offset: const Offset(0, 2),
                                      )
                                    ],
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Total Withdrawn',
                                        style: AppTypography.caption.copyWith(
                                          color: AppColors.neutral500,
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        AppCurrencyFormatter.format(summary.totalWithdrawn),
                                        style: TextStyle(
                                          fontFamily: 'JetBrains Mono',
                                          color: summary.totalWithdrawn > 0
                                              ? AppColors.warningYellow
                                              : primaryTextColor,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 22,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      'Gross Realized P/L',
                                      style: AppTypography.caption.copyWith(
                                        color: AppColors.neutral500,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      AppCurrencyFormatter.format(summary.grossRealizedPL),
                                      style: TextStyle(
                                        color: summary.grossRealizedPL >= 0
                                            ? accentGreen
                                            : AppColors.dangerRed,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${withdrawals.length} withdrawal${withdrawals.length == 1 ? '' : 's'}',
                                      style: AppTypography.caption.copyWith(
                                        color: AppColors.neutral500,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ).animate().fadeIn(duration: 300.ms),
                        ),
                      ),

                      if (withdrawals.isEmpty)
                        SliverFillRemaining(
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.north_east_rounded,
                                  size: 48,
                                  color: AppColors.neutral500.withOpacity(0.4),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No withdrawals yet',
                                  style: AppTypography.body.copyWith(
                                    color: primaryTextColor,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Record profits you\'ve taken out',
                                  style: AppTypography.caption.copyWith(
                                    color: AppColors.neutral500,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final w = withdrawals[index];
                                return WithdrawalRow(withdrawal: w)
                                    .animate()
                                    .fadeIn(
                                      duration: 250.ms,
                                      delay: Duration(milliseconds: index * 40),
                                    )
                                    .slideY(begin: 0.08, end: 0);
                              },
                              childCount: withdrawals.length,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => WithdrawalBottomSheet.show(context),
        backgroundColor: AppColors.warningYellow,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Add Withdrawal',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
