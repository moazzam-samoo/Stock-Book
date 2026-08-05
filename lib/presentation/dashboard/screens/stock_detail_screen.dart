import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:stock_investment_tracker/core/theme/app_colors.dart';
import 'package:stock_investment_tracker/core/theme/app_spacing.dart';
import 'package:stock_investment_tracker/core/theme/app_typography.dart';
import 'package:stock_investment_tracker/domain/enums/lot_status.dart';
import 'package:stock_investment_tracker/presentation/common/badges.dart';
import 'package:stock_investment_tracker/presentation/common/ticker_avatar.dart';
import 'package:stock_investment_tracker/core/utils/currency_formatter.dart';
import 'package:stock_investment_tracker/presentation/dashboard/providers/dashboard_providers.dart';
import 'package:stock_investment_tracker/presentation/transactions/widgets/lot_card.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:stock_investment_tracker/presentation/common/custom_app_bar.dart';

import 'package:stock_investment_tracker/core/services/pdf_report_service.dart';

class StockDetailScreen extends ConsumerWidget {
  final String ticker;

  const StockDetailScreen({super.key, required this.ticker});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lotsAsyncValue = ref.watch(allLotsProvider);
    final stockSummaries = ref.watch(stockSummariesProvider);
    final summary = stockSummaries.where((s) => s.ticker == ticker).firstOrNull;
    final formatNumber = NumberFormat.decimalPattern();

    final primaryTextColor = isDark ? Colors.white : AppColors.textPrimaryLight;
    final containerBg = isDark ? const Color(0xFF13151B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF242731) : const Color(0xFFE2E8F0);
    
    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: Column(
        children: [
          CustomAppBar(
            title: ticker,
            showBackButton: true,
            onBackPressed: () => context.pop(),
            actions: [
              IconButton(
                icon: Icon(Icons.picture_as_pdf_outlined, color: primaryTextColor, size: 22),
                tooltip: 'Export $ticker PDF Report',
                onPressed: () async {
                  final allLots = ref.read(allLotsProvider).valueOrNull ?? [];
                  final stockLots = allLots.where((l) => l.ticker == ticker).toList();
                  final stockSummaries = ref.read(stockSummariesProvider);
                  final stockSummary = stockSummaries.where((s) => s.ticker == ticker).firstOrNull;
                  await PdfReportService.exportStockPdf(
                    ticker: ticker,
                    stockLots: stockLots,
                    summary: stockSummary,
                  );
                },
              ),
              const SizedBox(width: 8),
            ],
          ),
          Expanded(
            child: lotsAsyncValue.when(
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.brandIndigo)),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Error loading $ticker details', style: AppTypography.body.copyWith(color: AppColors.dangerRed)),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => ref.invalidate(allLotsProvider),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
              data: (lots) {
                final stockLots = lots.where((lot) => lot.ticker == ticker).toList();
                
                if (stockLots.isEmpty) {
                  return Center(
                    child: Text('No active lots for $ticker', style: AppTypography.body.copyWith(color: AppColors.neutral500)),
                  );
                }
                
                return CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                        child: Column(
                          children: [
                            Hero(
                              tag: 'avatar_$ticker',
                              child: TickerAvatar(ticker: ticker, size: 80),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              ticker,
                              style: AppTypography.h1.copyWith(
                                color: primaryTextColor,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (summary != null) ...[
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  StatusBadge(
                                    status: summary.status == LotStatus.open 
                                        ? TradeStatus.open 
                                        : summary.status == LotStatus.partiallySold 
                                            ? TradeStatus.partial 
                                            : TradeStatus.closed
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              Container(
                                padding: const EdgeInsets.all(AppSpacing.md),
                                decoration: BoxDecoration(
                                  color: containerBg,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: borderColor, width: 1.2),
                                  boxShadow: isDark ? null : [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 2))],
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  children: [
                                    _buildStatColumn('Shares', formatNumber.format(summary.sharesHeld), primaryTextColor),
                                    _buildStatColumn('Avg Price', AppCurrencyFormatter.format(summary.avgBuyPrice, decimalDigits: 2), primaryTextColor),
                                    _buildStatColumn(
                                      'Total P/L', 
                                      summary.realizedPL != 0 ? AppCurrencyFormatter.format(summary.realizedPL, decimalDigits: 2, showSign: true) : '-',
                                      primaryTextColor,
                                      color: summary.realizedPL >= 0 ? AppColors.moneyGreen : AppColors.alertRed,
                                    ),
                                  ],
                                ),
                              ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),
                            ],
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                Text(
                                  'Lots',
                                  style: AppTypography.h2.copyWith(
                                    color: primaryTextColor,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      sliver: AnimationLimiter(
                        child: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              return AnimationConfiguration.staggeredList(
                                position: index,
                                duration: const Duration(milliseconds: 375),
                                child: SlideAnimation(
                                  verticalOffset: 50.0,
                                  child: FadeInAnimation(
                                    child: Padding(
                                      padding: const EdgeInsets.only(bottom: 12.0),
                                      child: LotCard(
                                        lot: stockLots[index],
                                        showStockDetailNavigation: false,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                            childCount: stockLots.length,
                          ),
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
    );
  }

  Widget _buildStatColumn(String label, String value, Color defaultTextColor, {Color? color}) {
    return Column(
      children: [
        Text(
          label,
          style: AppTypography.caption.copyWith(color: AppColors.neutral500),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTypography.body.copyWith(
            fontWeight: FontWeight.bold,
            color: color ?? defaultTextColor,
          ),
        ),
      ],
    );
  }
}
