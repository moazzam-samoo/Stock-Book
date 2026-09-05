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
import 'package:stock_investment_tracker/data/data_sources/remote/firestore_data_source.dart';
import 'package:stock_investment_tracker/presentation/dashboard/providers/dashboard_providers.dart';
import 'package:stock_investment_tracker/providers/market_prices_providers.dart';
import 'package:stock_investment_tracker/presentation/dashboard/providers/market_status_providers.dart';
import 'package:stock_investment_tracker/presentation/transactions/widgets/position_card.dart';
import 'package:stock_investment_tracker/providers/ticker_providers.dart';
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
    // Replaces the old time-since-last-fetch "(Stale)" marker: whether the
    // market itself is open right now, via the same rule the Dashboard clock
    // and position_card.dart use — null means "don't know", never guessed.
    final isMarketOpen = currentlyOpen(ref.watch(watchMarketStatusProvider).valueOrNull);
    // Legacy positions created before ticker normalization existed can still
    // carry a dirty stored ticker (e.g. a trailing space — the exact "BNL "
    // vs "BNL" bug fixed earlier for price lookups). The PSX reference list
    // is always clean, so normalize both sides here rather than assuming the
    // route param matches it exactly.
    final normalizedTicker = FirestoreDataSource.normalizeTicker(ticker);
    final companyName = ref
        .watch(allTickersProvider)
        .valueOrNull
        ?.where((t) => FirestoreDataSource.normalizeTicker(t.symbol) == normalizedTicker)
        .firstOrNull
        ?.name;

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
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // Left: avatar + ticker name, with the full
                                // company name as a subtitle underneath.
                                Expanded(
                                  child: Row(
                                    children: [
                                      Hero(
                                        tag: 'avatar_$ticker',
                                        child: TickerAvatar(ticker: ticker, size: 48),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              ticker,
                                              style: AppTypography.h1.copyWith(
                                                color: primaryTextColor,
                                                fontWeight: FontWeight.w800,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            if (companyName != null && companyName.isNotEmpty)
                                              Padding(
                                                padding: const EdgeInsets.only(top: 2.0),
                                                child: Text(
                                                  companyName,
                                                  style: AppTypography.caption.copyWith(
                                                    color: isDark ? Colors.white54 : Colors.black54,
                                                    fontSize: 12,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Right: just the status tag — the market
                                // data card lives full-width below now.
                                if (summary != null) ...[
                                  const SizedBox(width: 12),
                                  StatusBadge(
                                    status: summary.status == LotStatus.open
                                        ? TradeStatus.open
                                        : summary.status ==
                                              LotStatus.partiallySold
                                        ? TradeStatus.partial
                                        : TradeStatus.closed,
                                  ),
                                ],
                              ],
                            ),
                            if (summary != null) ...[
                              const SizedBox(height: 16),
                              // Price card: price + open/closed status +
                              // unrealized P/L all grouped into one bordered
                              // box, matching the stats box below instead of
                              // floating loose on the bare background.
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 20,
                                  horizontal: 16,
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
                                            color: Colors.black.withOpacity(0.04),
                                            blurRadius: 10,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.baseline,
                                      textBaseline: TextBaseline.alphabetic,
                                      children: [
                                        Text(
                                          livePrice != null ? AppCurrencyFormatter.format(livePrice) : '—',
                                          style: AppTypography.h1.copyWith(
                                            color: livePriceModel == null
                                                ? (isDark ? Colors.white54 : Colors.black38)
                                                : primaryTextColor,
                                            fontWeight: FontWeight.w800,
                                            fontSize: 32,
                                          ),
                                        ),
                                        if (isMarketOpen == true && livePrice != null) ...[
                                          const SizedBox(width: 8),
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Container(
                                                width: 7,
                                                height: 7,
                                                decoration: const BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: Color(0xFF00FF7F),
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                'Live',
                                                style: TextStyle(
                                                  color: const Color(0xFF00FF7F),
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                        if (isMarketOpen == false && livePrice != null) ...[
                                          const SizedBox(width: 8),
                                          Text(
                                            'at Closed',
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
                                          // Market closed: this price is a known
                                          // closing price, not a live one — say so
                                          // rather than implying it's still moving.
                                          isMarketOpen == false ? 'Closing Price' : 'Current Market Price',
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
                                        return Text(
                                          '${isUnrealizedProfit ? "+" : "-"}${AppCurrencyFormatter.format(totalUnrealizedPL.abs())} Unrealized',
                                          style: AppTypography.body.copyWith(
                                            color: unrealizedColor,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 15,
                                          ),
                                        );
                                      }),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
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
