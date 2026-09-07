import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:stock_investment_tracker/core/theme/app_colors.dart';
import 'package:stock_investment_tracker/core/theme/app_typography.dart';
import 'package:stock_investment_tracker/domain/calculator/position_calculator.dart';
import 'package:stock_investment_tracker/domain/entities/position.dart';
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
import 'package:stock_investment_tracker/presentation/dashboard/widgets/sparkline_chart.dart';

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
    final isMarketOpen = currentlyOpen(
      ref.watch(watchMarketStatusProvider).valueOrNull,
    );
    final normalizedTicker = FirestoreDataSource.normalizeTicker(ticker);
    final companyName = ref
        .watch(allTickersProvider)
        .valueOrNull
        ?.where(
          (t) =>
              FirestoreDataSource.normalizeTicker(t.symbol) == normalizedTicker,
        )
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
            title: 'Stock Details',

            showBackButton: true,
            onBackPressed: () => context.pop(),
            actions: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () async {
                    HapticFeedback.lightImpact();
                    final allPositions =
                        ref.read(allPositionsProvider).valueOrNull ?? [];
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
                final stockPositions =
                    positions.where((p) => p.ticker == ticker).toList()
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

                final openPositions = stockPositions
                    .where((p) => p.status != PositionStatus.closed)
                    .toList();
                final closedPositions = stockPositions
                    .where((p) => p.status == PositionStatus.closed)
                    .toList();

                final openCards =
                    <({Position display, Position? writeTarget})>[];
                for (final position in openPositions) {
                  final splits = PositionCalculator.splitByBuy(position);
                  for (final slice in splits) {
                    openCards.add((
                      display: slice,
                      writeTarget: identical(slice, position) ? null : position,
                    ));
                  }
                }
                openCards.sort(
                  (a, b) => b.display.openedAt.compareTo(a.display.openedAt),
                );

                final closedCards =
                    <({Position display, Position? writeTarget})>[];
                for (final position in closedPositions) {
                  final splits = PositionCalculator.splitByBuy(position);
                  for (final slice in splits) {
                    closedCards.add((
                      display: slice,
                      writeTarget: identical(slice, position) ? null : position,
                    ));
                  }
                }
                // Sort by latest date on top: newer buy on top, tie-break by closedAt
                closedCards.sort((a, b) {
                  final dateComp = b.display.openedAt.compareTo(
                    a.display.openedAt,
                  );
                  if (dateComp != 0) return dateComp;
                  final closedA = a.display.closedAt ?? a.display.openedAt;
                  final closedB = b.display.closedAt ?? b.display.openedAt;
                  return closedB.compareTo(closedA);
                });

                final refreshBg = isDark
                    ? const Color(0xFF13151B)
                    : Colors.white;
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
                                  Expanded(
                                    child: Row(
                                      children: [
                                        Hero(
                                          tag: 'avatar_$ticker',
                                          child: TickerAvatar(
                                            ticker: ticker,
                                            size: 48,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                ticker,
                                                style: AppTypography.h1
                                                    .copyWith(
                                                      color: primaryTextColor,
                                                      fontWeight:
                                                          FontWeight.w800,
                                                      fontSize: 22,
                                                    ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              if (companyName != null &&
                                                  companyName.isNotEmpty)
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                        top: 2.0,
                                                      ),
                                                  child: Text(
                                                    companyName,
                                                    style: AppTypography.caption
                                                        .copyWith(
                                                          color: isDark
                                                              ? Colors.white54
                                                              : Colors.black54,
                                                          fontSize: 12,
                                                        ),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (openPositions.isNotEmpty ||
                                      closedPositions.isNotEmpty) ...[
                                    const SizedBox(width: 12),
                                    _buildStatusTag(
                                      openPositions.isEmpty
                                          ? TradeStatus.closed
                                          : openPositions.any(
                                                (p) => p.sales.isNotEmpty,
                                              )
                                              ? TradeStatus.partial
                                              : TradeStatus.open,
                                      isDark,
                                    ),
                                  ],
                                ],
                              ),
                              if (summary != null) ...[
                                const SizedBox(height: 24),
                                Container(
                                  width: double.infinity,
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.all(16.0),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment.start,
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .baseline,
                                                    textBaseline:
                                                        TextBaseline.alphabetic,
                                                    children: [
                                                      Text(
                                                        livePrice != null
                                                            ? AppCurrencyFormatter.format(
                                                                livePrice,
                                                              )
                                                            : '—',
                                                        style: AppTypography.h1.copyWith(
                                                          color:
                                                              livePriceModel ==
                                                                  null
                                                              ? (isDark
                                                                    ? Colors
                                                                          .white54
                                                                    : Colors
                                                                          .black38)
                                                              : isMarketOpen == true
                                                              ? (isDark
                                                                    ? AppColors
                                                                          .moneyGreen
                                                                    : AppColors
                                                                          .moneyGreenOnLight)
                                                              : primaryTextColor,
                                                          fontWeight:
                                                              FontWeight.w800,
                                                          fontSize: 30,
                                                        ),
                                                      ),
                                                      if (isMarketOpen ==
                                                              true &&
                                                          livePrice !=
                                                              null) ...[
                                                        const SizedBox(
                                                          width: 8,
                                                        ),
                                                        Row(
                                                          mainAxisSize:
                                                              MainAxisSize.min,
                                                          children: [
                                                            Container(
                                                              width: 7,
                                                              height: 7,
                                                              decoration:
                                                                  const BoxDecoration(
                                                                    shape: BoxShape
                                                                        .circle,
                                                                    color: Color(
                                                                      0xFF00FF7F,
                                                                    ),
                                                                  ),
                                                            ),
                                                            const SizedBox(
                                                              width: 4,
                                                            ),
                                                            const Text(
                                                              'Live',
                                                              style: TextStyle(
                                                                color: Color(
                                                                  0xFF00FF7F,
                                                                ),
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                fontSize: 12,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ],
                                                      if (isMarketOpen ==
                                                              false &&
                                                          livePrice !=
                                                              null) ...[
                                                        const SizedBox(
                                                          width: 8,
                                                        ),
                                                        const Text(
                                                          'at Closed',
                                                          style: TextStyle(
                                                            color: AppColors
                                                                .alertRed,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            fontSize: 12,
                                                          ),
                                                        ),
                                                      ],
                                                    ],
                                                  ),
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                          top: 4.0,
                                                        ),
                                                    child: Text(
                                                      isMarketOpen == false
                                                          ? 'Closing Price'
                                                          : 'Current Market Price',
                                                      style: AppTypography
                                                          .caption
                                                          .copyWith(
                                                            color: isDark
                                                                ? Colors.white54
                                                                : Colors
                                                                      .black54,
                                                            fontSize: 12,
                                                          ),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 12),
                                                  Builder(
                                                    builder: (context) {
                                                      final totalUnrealizedPL =
                                                          stockPositions.fold<
                                                            double
                                                          >(
                                                            0.0,
                                                            (sum, p) =>
                                                                sum +
                                                                PositionCalculator.unrealizedPL(
                                                                  p,
                                                                  livePrice,
                                                                ),
                                                          );
                                                      final isUnrealizedProfit =
                                                          totalUnrealizedPL >=
                                                          0;
                                                      final unrealizedColor =
                                                          isUnrealizedProfit
                                                          ? (isDark
                                                                ? AppColors
                                                                      .moneyGreen
                                                                : AppColors
                                                                      .moneyGreenOnLight)
                                                          : AppColors.alertRed;

                                                      final amountInvested =
                                                          summary
                                                              .amountInvestedOpen;
                                                      final plPercentage =
                                                          amountInvested > 0
                                                          ? (totalUnrealizedPL /
                                                                    amountInvested) *
                                                                100
                                                          : 0.0;

                                                      return Text(
                                                        '${isUnrealizedProfit ? "+" : "-"}${AppCurrencyFormatter.format(totalUnrealizedPL.abs())} (${isUnrealizedProfit ? "+" : ""}${plPercentage.toStringAsFixed(2)}%)',
                                                        style: AppTypography
                                                            .body
                                                            .copyWith(
                                                              color:
                                                                  unrealizedColor,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w700,
                                                              fontSize: 15,
                                                            ),
                                                      );
                                                    },
                                                  ),
                                                  const SizedBox(height: 8),
                                                  if (livePriceModel != null)
                                                    Row(
                                                      children: [
                                                        Icon(
                                                          Icons.access_time,
                                                          size: 12,
                                                          color: isDark
                                                              ? Colors.white54
                                                              : Colors.black54,
                                                        ),
                                                        const SizedBox(
                                                          width: 4,
                                                        ),
                                                        Text(
                                                          'As of ${DateFormat('h:mm a').format(livePriceModel.updatedAt)}',
                                                          style: TextStyle(
                                                            color: isDark
                                                                ? Colors.white54
                                                                : Colors
                                                                      .black54,
                                                            fontSize: 11,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                ],
                                              ),
                                            ),
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.end,
                                              children: [
                                                Builder(
                                                  builder: (context) {
                                                    if (livePriceModel !=
                                                            null &&
                                                        livePriceModel
                                                                .previousClose >
                                                            0) {
                                                      final change =
                                                          livePriceModel.price -
                                                          livePriceModel
                                                              .previousClose;
                                                      final changePercentage =
                                                          (change /
                                                              livePriceModel
                                                                  .previousClose) *
                                                          100;
                                                      final isPositive =
                                                          changePercentage >= 0;
                                                      final color = isPositive
                                                          ? AppColors.moneyGreen
                                                          : AppColors.alertRed;
                                                      return Container(
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                              horizontal: 8,
                                                              vertical: 4,
                                                            ),
                                                        decoration: BoxDecoration(
                                                          color: color
                                                              .withOpacity(
                                                                0.15,
                                                              ),
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                12,
                                                              ),
                                                        ),
                                                        child: Row(
                                                          mainAxisSize:
                                                              MainAxisSize.min,
                                                          children: [
                                                            Icon(
                                                              isPositive
                                                                  ? Icons
                                                                        .arrow_outward
                                                                  : Icons
                                                                        .arrow_downward,
                                                              size: 12,
                                                              color: color,
                                                            ),
                                                            const SizedBox(
                                                              width: 4,
                                                            ),
                                                            Text(
                                                              '${isPositive ? "+" : ""}${changePercentage.toStringAsFixed(2)}%',
                                                              style: TextStyle(
                                                                color: color,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                fontSize: 12,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      );
                                                    }
                                                    return const SizedBox.shrink();
                                                  },
                                                ),
                                                const SizedBox(height: 16),
                                                Builder(
                                                  builder: (context) {
                                                    bool isPositive = true;
                                                    if (livePriceModel !=
                                                            null &&
                                                        livePriceModel
                                                                .previousClose >
                                                            0) {
                                                      isPositive =
                                                          livePriceModel
                                                              .price >=
                                                          livePriceModel
                                                              .previousClose;
                                                    }
                                                    return SizedBox(
                                                      width: 100,
                                                      height: 40,
                                                      child: SparklineChart(
                                                        isPositive: isPositive,
                                                        color: isPositive
                                                            ? AppColors
                                                                  .moneyGreen
                                                            : AppColors
                                                                  .alertRed,
                                                        width: 100,
                                                        height: 40,
                                                      ),
                                                    );
                                                  },
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        margin: const EdgeInsets.only(
                                          left: 12.0,
                                          right: 12.0,
                                          bottom: 12.0,
                                        ),
                                        padding: const EdgeInsets.all(16.0),
                                        decoration: BoxDecoration(
                                          color: isDark
                                              ? const Color(0xFF1A1D27)
                                              : const Color(0xFFF8FAFC),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          border: Border.all(
                                            color: borderColor,
                                            width: 1,
                                          ),
                                        ),
                                        child: Column(
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: _buildMetricTile(
                                                    icon: Icons.trending_up,
                                                    title: 'Shares',
                                                    value: formatNumber.format(
                                                      summary.sharesHeld,
                                                    ),
                                                    valueColor:
                                                        primaryTextColor,
                                                    isDark: isDark,
                                                  ),
                                                ),
                                                Expanded(
                                                  child: _buildMetricTile(
                                                    icon: Icons
                                                        .local_offer_outlined,
                                                    title: 'Avg. Price',
                                                    value:
                                                        AppCurrencyFormatter.format(
                                                          summary.avgBuyPrice,
                                                          decimalDigits: 2,
                                                        ),
                                                    valueColor:
                                                        primaryTextColor,
                                                    isDark: isDark,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 16),
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: _buildMetricTile(
                                                    icon: Icons
                                                        .account_balance_wallet_outlined,
                                                    title: 'Total Invested',
                                                    value:
                                                        AppCurrencyFormatter.format(
                                                          summary
                                                              .amountInvestedOpen,
                                                          decimalDigits: 2,
                                                        ),
                                                    valueColor:
                                                        primaryTextColor,
                                                    isDark: isDark,
                                                  ),
                                                ),
                                                Expanded(
                                                  child: _buildMetricTile(
                                                    icon:
                                                        Icons.savings_outlined,
                                                    title: 'Total P/L',
                                                    value:
                                                        summary.realizedPL != 0
                                                        ? AppCurrencyFormatter.format(
                                                            summary.realizedPL,
                                                            decimalDigits: 2,
                                                            showSign: true,
                                                          )
                                                        : '-',
                                                    valueColor:
                                                        summary.realizedPL >= 0
                                                        ? (isDark
                                                              ? AppColors
                                                                    .moneyGreen
                                                              : AppColors
                                                                    .moneyGreenOnLight)
                                                        : AppColors.alertRed,
                                                    isDark: isDark,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),
                              ],

                              const SizedBox(height: 32),

                              _buildSectionHeader(
                                icon: Icons.business_center_outlined,
                                title: 'Open Positions',
                                badgeText:
                                    '${openCards.length} ${openCards.length == 1 ? 'Open Position' : 'Open Positions'}',
                                badgeDotColor: isDark
                                    ? AppColors.moneyGreen
                                    : AppColors.moneyGreenOnLight,
                                isDark: isDark,
                                primaryTextColor: primaryTextColor,
                              ),
                              const SizedBox(height: 16),
                              if (openCards.isEmpty)
                                Center(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 24.0,
                                    ),
                                    child: Text(
                                      'No open positions',
                                      style: AppTypography.body.copyWith(
                                        color: AppColors.neutral500,
                                      ),
                                    ),
                                  ),
                                )
                              else
                                ...openCards.map(
                                  (card) => PositionCard(
                                    position: card.display,
                                    showStockDetailNavigation: false,
                                    writePosition: card.writeTarget,
                                  ),
                                ),

                              const SizedBox(height: 32),

                              if (closedCards.isNotEmpty) ...[
                                _buildSectionHeader(
                                  icon: Icons.check_circle_outline_rounded,
                                  title: 'Closed Positions',
                                  badgeText: '${closedCards.length} Closed',
                                  badgeDotColor: AppColors.alertRed,
                                  isDark: isDark,
                                  primaryTextColor: primaryTextColor,
                                ),
                                const SizedBox(height: 16),
                                ...closedCards.map(
                                  (card) => PositionCard(
                                    position: card.display,
                                    showStockDetailNavigation: false,
                                    writePosition: card.writeTarget,
                                  ),
                                ),
                              ],

                              const SizedBox(height: 48),
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

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required String badgeText,
    required bool isDark,
    required Color primaryTextColor,
    Color? badgeDotColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(
              icon,
              color: primaryTextColor,
              size: 22,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: AppTypography.h2.copyWith(
                color: primaryTextColor,
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF242731) : const Color(0xFFE2E8F0),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (badgeDotColor != null) ...[
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: badgeDotColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
              ],
              Text(
                badgeText,
                style: AppTypography.caption.copyWith(
                  color: isDark ? Colors.white70 : Colors.black87,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusTag(TradeStatus tradeStatus, bool isDark) {
    final positiveColor = isDark
        ? AppColors.moneyGreen
        : AppColors.moneyGreenOnLight;
    final Color bgColor;
    final Color borderColor;
    final Color textColor;
    final IconData icon;
    final String label;

    switch (tradeStatus) {
      case TradeStatus.open:
        bgColor = isDark ? const Color(0xFF10281D) : const Color(0xFFDCFCE7);
        borderColor = positiveColor.withValues(alpha: isDark ? 0.6 : 0.7);
        textColor = positiveColor;
        icon = Icons.lock_open_rounded;
        label = 'OPEN';
        break;
      case TradeStatus.partial:
        bgColor = isDark ? const Color(0xFF2E2415) : const Color(0xFFFEF3C7);
        borderColor = AppColors.warningYellow.withValues(
          alpha: isDark ? 0.6 : 0.7,
        );
        textColor = AppColors.warningYellow;
        icon = Icons.pie_chart_rounded;
        label = 'PARTIAL';
        break;
      case TradeStatus.closed:
        bgColor = isDark ? const Color(0xFF2D1518) : const Color(0xFFFEE2E2);
        borderColor = AppColors.alertRed.withValues(alpha: isDark ? 0.6 : 0.7);
        textColor = AppColors.alertRed;
        icon = Icons.check_circle_outline_rounded;
        label = 'CLOSED';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: borderColor,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 13,
            color: textColor,
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w800,
              fontSize: 11,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required IconData icon,
    required String title,
    required String value,
    required Color valueColor,
    required bool isDark,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF242731) : const Color(0xFFE2E8F0),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 14,
            color: isDark ? Colors.white70 : Colors.black87,
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: AppTypography.caption.copyWith(
                color: isDark ? Colors.white54 : Colors.black54,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: AppTypography.body.copyWith(
                fontWeight: FontWeight.bold,
                color: valueColor,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
