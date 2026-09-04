import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:stock_investment_tracker/core/theme/app_colors.dart';
import 'package:stock_investment_tracker/core/theme/app_spacing.dart';
import 'package:stock_investment_tracker/core/theme/app_typography.dart';
import 'package:stock_investment_tracker/domain/calculator/position_calculator.dart';
import 'package:stock_investment_tracker/domain/enums/lot_status.dart';
import 'package:stock_investment_tracker/domain/enums/position_status.dart';
import 'package:stock_investment_tracker/presentation/common/badges.dart';
import 'package:stock_investment_tracker/presentation/common/ticker_avatar.dart';
import 'package:stock_investment_tracker/core/utils/currency_formatter.dart';
import 'package:stock_investment_tracker/presentation/dashboard/providers/dashboard_providers.dart';
import 'package:stock_investment_tracker/providers/market_prices_providers.dart';
import 'package:stock_investment_tracker/presentation/transactions/widgets/position_card.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:stock_investment_tracker/presentation/common/custom_app_bar.dart';

import 'package:stock_investment_tracker/core/services/pdf_report_service.dart';

class StockDetailScreen extends ConsumerWidget {
  final String ticker;

  const StockDetailScreen({super.key, required this.ticker});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final positionsAsyncValue = ref.watch(allPositionsProvider);
    final stockSummaries = ref.watch(stockSummariesProvider);
    final summary = stockSummaries.where((s) => s.ticker == ticker).firstOrNull;
    final formatNumber = NumberFormat.decimalPattern();

    final marketPriceAsync = ref.watch(watchMarketPriceProvider(ticker));
    final livePriceModel = marketPriceAsync.valueOrNull;
    final livePrice = livePriceModel?.price;
    final isPriceStale = livePriceModel != null && DateTime.now().difference(livePriceModel.updatedAt).inHours >= 1;

    final primaryTextColor = isDark ? Colors.white : AppColors.textPrimaryLight;
    final containerBg = isDark ? const Color(0xFF13151B) : Colors.white;
    final borderColor = isDark
        ? const Color(0xFF242731)
        : const Color(0xFFE2E8F0);

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      body: Column(
        children: [
          CustomAppBar(
            title: ticker,
            showBackButton: true,
            onBackPressed: () => context.pop(),
            actions: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () async {
                    HapticFeedback.lightImpact();
                    final allPositions = ref.read(allPositionsProvider).valueOrNull ?? [];
                    // Every cycle of this ticker, not just the newest — a
                    // per-stock report that drops a closed cycle's sales is
                    // missing exactly the history it exists to record.
                    final tickerPositions = allPositions
                        .where((p) => p.ticker == ticker)
                        .toList();
                    final stockSummaries = ref.read(stockSummariesProvider);
                    final stockSummary = stockSummaries
                        .where((s) => s.ticker == ticker)
                        .firstOrNull;
                    if (tickerPositions.isNotEmpty) {
                      await PdfReportService.exportStockPdf(
                        ticker: ticker,
                        positions: tickerPositions,
                        summary: stockSummary,
                      );
                    }
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
              const SizedBox(width: 12),
            ],
          ),
          Expanded(
            child: positionsAsyncValue.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.brandIndigo),
              ),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Error loading $ticker details',
                      style: AppTypography.body.copyWith(
                        color: AppColors.dangerRed,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => ref.invalidate(allPositionsProvider),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
              data: (positions) {
                // Every holding cycle for this ticker, each its own card:
                // what you still hold first, then closed cycles newest-first.
                final stockPositions = positions
                    .where((p) => p.ticker == ticker)
                    .toList()
                  ..sort((a, b) {
                    final aClosed = a.status == PositionStatus.closed;
                    final bClosed = b.status == PositionStatus.closed;
                    if (aClosed != bClosed) return aClosed ? 1 : -1;
                    return b.openedAt.compareTo(a.openedAt);
                  });

                if (stockPositions.isEmpty) {
                  return Center(
                    child: Text(
                      'No active position for $ticker',
                      style: AppTypography.body.copyWith(
                        color: AppColors.neutral500,
                      ),
                    ),
                  );
                }

                final refreshBg = isDark ? const Color(0xFF13151B) : Colors.white;
                return RefreshIndicator(
                  color: AppColors.brandIndigo,
                  backgroundColor: refreshBg,
                  onRefresh: () async {
                    ref.invalidate(watchMarketPriceProvider(ticker));
                    await Future.delayed(const Duration(milliseconds: 500));
                  },
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24.0,
                          vertical: 12.0,
                        ),
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
                                        : summary.status ==
                                              LotStatus.partiallySold
                                        ? TradeStatus.partial
                                        : TradeStatus.closed,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              // Live Price
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  Text(
                                    livePrice != null ? AppCurrencyFormatter.format(livePrice) : '—',
                                    style: AppTypography.h1.copyWith(
                                      color: (livePriceModel == null || isPriceStale)
                                          ? (isDark ? Colors.white54 : Colors.black38)
                                          : primaryTextColor,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 32,
                                    ),
                                  ),
                                  if (livePriceModel != null && isPriceStale) ...[
                                    const SizedBox(width: 8),
                                    Text(
                                      '(Stale)',
                                      style: TextStyle(
                                        color: AppColors.alertRed,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              if (livePrice != null) ...[
                                Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: Text(
                                    'Current Market Price',
                                    style: AppTypography.caption.copyWith(
                                      color: isDark ? Colors.white54 : Colors.black54,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                if (livePriceModel != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2.0),
                                    child: Text(
                                      'As of ${DateFormat('h:mm a').format(livePriceModel.updatedAt)}',
                                      style: TextStyle(
                                        color: isDark ? Colors.white54 : Colors.black54,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                const SizedBox(height: 16),
                                Builder(builder: (context) {
                                  // Unrealized P/L across every cycle still
                                  // held for this ticker — a closed cycle
                                  // always contributes 0 (PositionCalculator
                                  // guards on sharesHeld == 0), so summing
                                  // over all of stockPositions is safe.
                                  final totalUnrealizedPL = stockPositions.fold<double>(
                                    0.0,
                                    (sum, p) => sum + PositionCalculator.unrealizedPL(p, livePrice),
                                  );
                                  final isUnrealizedProfit = totalUnrealizedPL >= 0;
                                  final unrealizedColor = isUnrealizedProfit
                                      ? (isDark ? AppColors.moneyGreen : AppColors.moneyGreenOnLight)
                                      : AppColors.alertRed;
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 4.0),
                                    child: Text(
                                      '${isUnrealizedProfit ? "+" : "-"}${AppCurrencyFormatter.format(totalUnrealizedPL.abs())} Unrealized',
                                      style: AppTypography.body.copyWith(
                                        color: unrealizedColor,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15,
                                      ),
                                    ),
                                  );
                                }),
                              ],
                              const SizedBox(height: 24),
                              Container(
                                    padding: const EdgeInsets.all(
                                      AppSpacing.md,
                                    ),
                                    decoration: BoxDecoration(
                                      color: containerBg,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: borderColor,
                                        width: 1.2,
                                      ),
                                      boxShadow: isDark
                                          ? null
                                          : [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(
                                                  0.04,
                                                ),
                                                blurRadius: 10,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                    ),
                                    child: Column(
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceAround,
                                          children: [
                                            _buildStatColumn(
                                              'Shares',
                                              formatNumber.format(
                                                summary.sharesHeld,
                                              ),
                                              primaryTextColor,
                                            ),
                                            _buildStatColumn(
                                              'Avg Price',
                                              AppCurrencyFormatter.format(
                                                summary.avgBuyPrice,
                                                decimalDigits: 2,
                                              ),
                                              primaryTextColor,
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 16),
                                        Divider(color: borderColor, height: 1),
                                        const SizedBox(height: 16),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceAround,
                                          children: [
                                            _buildStatColumn(
                                              'Total Invested',
                                              AppCurrencyFormatter.format(
                                                summary.amountInvestedOpen,
                                                decimalDigits: 2,
                                              ),
                                              primaryTextColor,
                                            ),
                                            _buildStatColumn(
                                              'Total P/L',
                                              summary.realizedPL != 0
                                                  ? AppCurrencyFormatter.format(
                                                      summary.realizedPL,
                                                      decimalDigits: 2,
                                                      showSign: true,
                                                    )
                                                  : '-',
                                              primaryTextColor,
                                              color: summary.realizedPL >= 0
                                                  ? (isDark ? AppColors.moneyGreen : AppColors.moneyGreenOnLight)
                                                  : AppColors.alertRed,
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  )
                                  .animate()
                                  .fadeIn(duration: 400.ms)
                                  .slideY(begin: 0.1, end: 0),
                            ],
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                Text(
                                  stockPositions.length == 1
                                      ? 'Position'
                                      : 'Positions',
                                  style: AppTypography.h2.copyWith(
                                    color: primaryTextColor,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            // A closed cycle becomes one card per buy; what's
                            // still held stays pooled as a single averaged card.
                            ...stockPositions.expand(
                              (position) => PositionCalculator.splitByBuy(position).map(
                                (card) => PositionCard(
                                  position: card,
                                  showStockDetailNavigation: false,
                                  writePosition:
                                      identical(card, position) ? null : position,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    ),
  );
  }

  Widget _buildStatColumn(
    String label,
    String value,
    Color defaultTextColor, {
    Color? color,
  }) {
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
