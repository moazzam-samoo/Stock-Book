import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:stock_investment_tracker/core/utils/currency_formatter.dart';
import 'package:stock_investment_tracker/data/data_sources/remote/firestore_data_source.dart';
import 'package:stock_investment_tracker/providers/ticker_providers.dart';
import 'package:stock_investment_tracker/core/theme/app_colors.dart';
import 'package:stock_investment_tracker/core/theme/app_typography.dart';
import 'package:stock_investment_tracker/presentation/dashboard/widgets/sparkline_chart.dart';
import 'package:stock_investment_tracker/domain/entities/position.dart';
import 'package:stock_investment_tracker/domain/entities/position_buy.dart';
import 'package:stock_investment_tracker/domain/calculator/position_calculator.dart';
import 'package:stock_investment_tracker/domain/enums/position_status.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stock_investment_tracker/providers/repository_providers.dart';
import 'package:stock_investment_tracker/presentation/common/badges.dart';
import 'package:stock_investment_tracker/presentation/common/ticker_avatar.dart';
import 'package:stock_investment_tracker/presentation/transactions/widgets/position_sale_row.dart';
import 'package:stock_investment_tracker/presentation/transactions/widgets/position_buy_row.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:stock_investment_tracker/presentation/transactions/widgets/add_sell_bottom_sheet.dart';
import 'package:stock_investment_tracker/presentation/transactions/widgets/edit_buy_bottom_sheet.dart';
import 'package:stock_investment_tracker/providers/market_prices_providers.dart';
import 'package:stock_investment_tracker/presentation/dashboard/providers/market_status_providers.dart';
import 'package:stock_investment_tracker/presentation/settings/providers/settings_provider.dart';
import 'package:stock_investment_tracker/domain/entities/pin_result.dart';

import 'package:stock_investment_tracker/core/services/pdf_report_service.dart';

class PositionCard extends ConsumerStatefulWidget {
  final Position position;
  final bool showStockDetailNavigation;

  /// Where writes (delete, edit-buy) should land, when that isn't [position]
  /// itself.
  ///
  /// A closed cycle is displayed as one card per buy — those slices come from
  /// [PositionCalculator.splitByBuy] and carry synthetic ids plus sales that
  /// may be partial allocations, so they must never be written back. Passing
  /// the real position here keeps delete/edit working while the card renders
  /// the slice, and puts the sale rows into read-only mode.
  final Position? writePosition;

  const PositionCard({
    super.key,
    required this.position,
    this.showStockDetailNavigation = true,
    this.writePosition,
  });

  @override
  ConsumerState<PositionCard> createState() => _PositionCardState();
}

class _PositionCardState extends ConsumerState<PositionCard> {
  bool _isExpanded = false;
  Offset? _tapDownPosition;

  /// The real, persisted position behind this card.
  Position get _writeTarget => widget.writePosition ?? widget.position;

  /// True when this card is one buy's slice of a split closed cycle, rather
  /// than a position in its own right.
  bool get _isSlice => widget.writePosition != null;

  void _toggleExpand() {
    HapticFeedback.lightImpact();
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  Future<void> _handlePinTap(BuildContext context) async {
    HapticFeedback.lightImpact();
    final controller = ref.read(settingsControllerProvider.notifier);
    final result = await controller.togglePin(widget.position.ticker);
    if (!context.mounted || result != PinResult.limitReached) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Free plan allows 5 pinned stocks — unlock unlimited in Settings'),
        action: SnackBarAction(
          label: 'Settings',
          onPressed: () => context.push('/settings'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final NumberFormat wholeFormat = NumberFormat('#,##0');
    final DateFormat dateFormat = DateFormat('MMM d, y');

    final cardBg = isDark ? const Color(0xFF13151B) : Colors.white;
    final borderColor = isDark
        ? const Color(0xFF242731)
        : const Color(0xFFE2E8F0);
    final primaryTextColor = isDark ? Colors.white : AppColors.textPrimaryLight;
    final pillBg = isDark ? const Color(0xFF1E222D) : const Color(0xFFF1F5F9);

    final pinnedTickers = ref.watch(settingsProvider).valueOrNull?.pinnedTickers ?? const <String>[];
    final isPinned = pinnedTickers.contains(widget.position.ticker.toUpperCase());

    final isProfit = PositionCalculator.realizedPL(widget.position) >= 0;
    final plColor = isProfit
        ? (isDark ? AppColors.moneyGreen : AppColors.moneyGreenOnLight)
        : AppColors.alertRed;
    final soldShares =
        (widget.position.buys.fold<int>(0, (sum, b) => sum + b.shares)) -
        PositionCalculator.sharesHeld(widget.position);
    final holdingDaysText = PositionCalculator.holdingDays(widget.position) == 1
        ? '1 day'
        : '${PositionCalculator.holdingDays(widget.position)} days';

    // A closed cycle holds nothing, so avgCost/amountInvested correctly return
    // 0 — useless on a card whose whole job is to record what happened. Show
    // what the cycle actually cost instead.
    final isClosed = widget.position.status == PositionStatus.closed;
    final costPerShare = isClosed
        ? PositionCalculator.historicalAvgCost(widget.position)
        : PositionCalculator.avgCost(widget.position);
    final investedAmount = isClosed
        ? PositionCalculator.totalCapitalDeployed(widget.position)
        : PositionCalculator.amountInvested(widget.position);
    final totalReceived = isClosed
        ? (widget.position.sales.isNotEmpty
              ? widget.position.sales.fold(
                  0.0,
                  (sum, s) => sum + s.amountReceived,
                )
              : investedAmount + PositionCalculator.realizedPL(widget.position))
        : 0.0;

    final marketPriceAsync = !isClosed
        ? ref.watch(watchMarketPriceProvider(widget.position.ticker))
        : null;
    final livePriceModel = marketPriceAsync?.valueOrNull;
    final livePrice = livePriceModel?.price;
    // Replaces the old time-since-last-fetch "(Stale)" marker: whether the
    // *market itself* is open right now is more useful than how long ago the
    // price was fetched, and it's the same currentlyOpen() rule the
    // Dashboard clock already uses — null means "don't know", never guessed.
    final isMarketOpen = currentlyOpen(
      ref.watch(watchMarketStatusProvider).valueOrNull,
    );

    final normalizedTicker = FirestoreDataSource.normalizeTicker(
      widget.position.ticker,
    );
    final companyName = ref
        .watch(allTickersProvider)
        .valueOrNull
        ?.where(
          (t) =>
              FirestoreDataSource.normalizeTicker(t.symbol) == normalizedTicker,
        )
        .firstOrNull
        ?.name;

    return GestureDetector(
      onTapDown: (details) => _tapDownPosition = details.globalPosition,
      onTap: _toggleExpand,
      onLongPress: () => _showContextMenu(context),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.only(bottom: 12),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _isExpanded ? AppColors.brandIndigo : borderColor,
            width: 1.2,
          ),
          boxShadow: isDark
              ? (_isExpanded
                    ? [
                        BoxShadow(
                          color: AppColors.brandIndigo.withOpacity(0.3),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ]
                    : null)
              : [
                  BoxShadow(
                    color: _isExpanded
                        ? AppColors.brandIndigo.withOpacity(0.4)
                        : Colors.black.withOpacity(0.04),
                    blurRadius: _isExpanded ? 16 : 10,
                    spreadRadius: _isExpanded ? 2 : 0,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: widget.showStockDetailNavigation
                      ? () => context.push('/stock/${widget.position.ticker}')
                      : null,
                  child: TickerAvatar(ticker: widget.position.ticker, size: 42),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: GestureDetector(
                    onTap: widget.showStockDetailNavigation
                        ? () => context.push('/stock/${widget.position.ticker}')
                        : null,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 8,
                          children: [
                            Text(
                              widget.position.ticker,
                              style: AppTypography.body.copyWith(
                                fontWeight: FontWeight.w800,
                                color: primaryTextColor,
                                fontSize: 17,
                              ),
                            ),
                            StatusBadge(status: widget.position.status),
                          ],
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
                        // For open/partial positions: Bought date lives in the header.
                        // Closed positions show Bought date in Row 1 below.
                        if (!isClosed)
                          Padding(
                            padding: const EdgeInsets.only(top: 2.0),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.calendar_today_outlined,
                                  size: 11,
                                  color: isDark
                                      ? Colors.white54
                                      : Colors.black54,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Bought ${dateFormat.format(widget.position.openedAt)}',
                                  style: AppTypography.caption.copyWith(
                                    color: isDark
                                        ? Colors.white54
                                        : Colors.black54,
                                    fontSize: 11,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => _handlePinTap(context),
                  child: Container(
                    width: 32,
                    height: 32,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isPinned ? AppColors.moneyGreen.withOpacity(0.15) : pillBg,
                      border: Border.all(
                        color: isPinned ? AppColors.moneyGreen : borderColor,
                      ),
                    ),
                    child: Icon(
                      isPinned ? Icons.push_pin_rounded : Icons.push_pin_outlined,
                      color: isPinned ? AppColors.moneyGreen : AppColors.neutral500,
                      size: 16,
                    ),
                  ),
                ),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: pillBg,
                    border: Border.all(color: borderColor),
                  ),
                  child: Icon(
                    _isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: AppColors.neutral500,
                    size: 18,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Divider(color: borderColor, height: 1),
            const SizedBox(height: 14),

            // Row 1:
            // For closed cards: Bought / Sold / Avg. Price (3 columns)
            // For open cards: Quantity / Avg. Price / Live Price (3 columns)
            Row(
              children: [
                if (isClosed) ...[
                  Expanded(
                    child: _GridDetail(
                      icon: Icons.calendar_today_outlined,
                      label: 'Bought',
                      value: dateFormat.format(widget.position.openedAt),
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: _GridDetail(
                    icon: FontAwesomeIcons.coins.data,
                    label: isClosed ? 'Sold' : 'Quantity',
                    value:
                        '${wholeFormat.format(widget.position.buys.fold<int>(0, (sum, b) => sum + b.shares))} sh',
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _GridDetail(
                    icon: Icons.local_offer_outlined,
                    label: 'Avg. Price',
                    value: AppCurrencyFormatter.format(costPerShare),
                    isDark: isDark,
                  ),
                ),
                if (!isClosed) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: _GridDetail(
                      icon: Icons.show_chart_outlined,
                      label: 'Live Price',
                      value: livePrice != null
                          ? AppCurrencyFormatter.format(livePrice)
                          : '—',
                      valueColor: livePriceModel == null
                          ? (isDark ? Colors.white54 : Colors.black38)
                          : isMarketOpen == true
                          ? (isDark ? AppColors.moneyGreen : AppColors.moneyGreenOnLight)
                          : null,
                      caption: livePriceModel != null
                          ? 'As of ${DateFormat('h:mm a').format(livePriceModel.updatedAt)}'
                          : null,
                      isDark: isDark,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 14),

            // For open positions: Total Invested & Live Price / Unrealized container,
            // followed by Holding Period & Target Price row.
            // For closed positions: Total Cost and Holding Period in the same row
            // to eliminate redundant whitespace.
            if (!isClosed) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color:
                      (isDark
                              ? AppColors.moneyGreen
                              : AppColors.moneyGreenOnLight)
                          .withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color:
                        (isDark
                                ? AppColors.moneyGreen
                                : AppColors.moneyGreenOnLight)
                            .withOpacity(0.25),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                FontAwesomeIcons.arrowTrendUp.data,
                                size: 13,
                                color: isDark
                                    ? AppColors.moneyGreen
                                    : AppColors.moneyGreenOnLight,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Total Invested',
                                style: AppTypography.caption.copyWith(
                                  color: isDark
                                      ? Colors.white70
                                      : Colors.black54,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              AppCurrencyFormatter.format(investedAmount),
                              style: AppTypography.body.copyWith(
                                color: primaryTextColor,
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(width: 1, height: 40, color: borderColor),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Unrealized',
                                style: AppTypography.caption.copyWith(
                                  color: isDark
                                      ? Colors.white70
                                      : Colors.black54,
                                  fontSize: 12,
                                ),
                              ),
                              if (isMarketOpen == true &&
                                  livePrice != null) ...[
                                const SizedBox(width: 5),
                                Container(
                                  width: 5,
                                  height: 5,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Color(0xFF00FF7F),
                                  ),
                                ),
                              ],
                              if (isMarketOpen == false &&
                                  livePrice != null) ...[
                                const SizedBox(width: 4),
                                Text(
                                  '(Closed)',
                                  style: TextStyle(
                                    color: AppColors.alertRed,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: livePrice != null
                                ? Text.rich(
                                    TextSpan(
                                      children: [
                                        TextSpan(
                                          text:
                                              '${PositionCalculator.unrealizedPL(widget.position, livePrice) >= 0 ? "+" : ""}${AppCurrencyFormatter.format(PositionCalculator.unrealizedPL(widget.position, livePrice).abs())} ',
                                          style: AppTypography.body.copyWith(
                                            color:
                                                PositionCalculator.unrealizedPL(
                                                      widget.position,
                                                      livePrice,
                                                    ) >=
                                                    0
                                                ? (isDark
                                                      ? AppColors.moneyGreen
                                                      : AppColors
                                                            .moneyGreenOnLight)
                                                : AppColors.alertRed,
                                            fontWeight: FontWeight.w800,
                                            fontSize: 16,
                                          ),
                                        ),
                                        TextSpan(
                                          text:
                                              '(${PositionCalculator.unrealizedPLPercent(widget.position, livePrice) >= 0 ? "+" : ""}${PositionCalculator.unrealizedPLPercent(widget.position, livePrice).toStringAsFixed(2)}%)',
                                          style: AppTypography.body.copyWith(
                                            color:
                                                PositionCalculator.unrealizedPL(
                                                      widget.position,
                                                      livePrice,
                                                    ) >=
                                                    0
                                                ? (isDark
                                                      ? AppColors.moneyGreen
                                                      : AppColors
                                                            .moneyGreenOnLight)
                                                : AppColors.alertRed,
                                            fontWeight: FontWeight.w600,
                                            // Smaller than the amount — this
                                            // is the secondary figure.
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : Text(
                                    '—',
                                    style: AppTypography.body.copyWith(
                                      color: isDark
                                          ? Colors.white54
                                          : Colors.black38,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 16,
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Holding Period / Target Price (+ bell)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.position.targetPrice != null &&
                      widget.position.targetPrice! > 0) ...[
                    // Two columns to split — Holding Period only stretches
                    // full-width via Expanded when there's a second column to
                    // share the row with.
                    Expanded(
                      child: _GridDetail(
                        icon: Icons.access_time_outlined,
                        label: 'Holding Period',
                        value: holdingDaysText,
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _GridDetail(
                        icon: Icons.track_changes_outlined,
                        iconColor: const Color.fromARGB(255, 16, 205, 234),
                        label: 'Target Price',
                        value: AppCurrencyFormatter.format(
                          widget.position.targetPrice!,
                        ),
                        secondaryValue:
                            '(${((widget.position.targetPrice! - PositionCalculator.avgCost(widget.position)) / PositionCalculator.avgCost(widget.position) * 100) >= 0 ? "+" : ""}${((widget.position.targetPrice! - PositionCalculator.avgCost(widget.position)) / PositionCalculator.avgCost(widget.position) * 100).toStringAsFixed(1)}% Est.)',
                        valueColor: const Color.fromARGB(255, 16, 205, 234),
                        isDark: isDark,
                      ),
                    ),
                    // Always shown once a target exists — dim/outline means
                    // "armed, watching for this price"; solid green means
                    // "already notified you at least once".
                    Padding(
                      padding: const EdgeInsets.only(top: 2.0),
                      child: Icon(
                        widget.position.targetAlertSent
                            ? Icons.notifications_active
                            : Icons.notifications_none_rounded,
                        size: 18,
                        color: widget.position.targetAlertSent
                            ? (isDark
                                  ? AppColors.moneyGreen
                                  : AppColors.moneyGreenOnLight)
                            : AppColors.neutral500,
                      ),
                    ),
                  ] else
                    Expanded(
                      child: _GridDetail(
                        icon: Icons.access_time_outlined,
                        label: 'Holding Period',
                        value: holdingDaysText,
                        isDark: isDark,
                      ),
                    ),
                ],
              ),
            ] else ...[
              // Closed cycle: Total Invested (money invested), Total Cost (money got with profit), and Holding Period
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _GridDetail(
                      icon: FontAwesomeIcons.arrowTrendUp.data,
                      label: 'Total Invested',
                      value: AppCurrencyFormatter.format(investedAmount),
                      isDark: isDark,
                    ),
                  ),
                  Expanded(
                    child: _GridDetail(
                      icon: Icons.account_balance_wallet_outlined,
                      label: 'Total Cost',
                      value: AppCurrencyFormatter.format(totalReceived),
                      valueColor: const Color.fromARGB(255, 16, 205, 234),
                      isDark: isDark,
                    ),
                  ),
                  Expanded(
                    child: _GridDetail(
                      icon: Icons.access_time_outlined,
                      label: 'Holding Period',
                      value: holdingDaysText,
                      isDark: isDark,
                    ),
                  ),
                ],
              ),
            ],

            // Realized P/L banner — shown once anything has been sold, so a
            // partially-sold position surfaces the profit it has already booked.
            if (widget.position.status == PositionStatus.closed ||
                widget.position.status == PositionStatus.partiallySold) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: plColor.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: plColor.withOpacity(0.12)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                isProfit
                                    ? Icons.arrow_upward
                                    : Icons.arrow_downward,
                                size: 16,
                                color: plColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                isProfit ? 'Realized Profit' : 'Realized Loss',
                                style: AppTypography.caption.copyWith(
                                  color: plColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${wholeFormat.format(soldShares)} of ${wholeFormat.format((widget.position.buys.fold<int>(0, (sum, b) => sum + b.shares)))} shares sold',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.neutral500,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SparklineChart(
                      isPositive: isProfit,
                      color: plColor,
                      seed: widget.position.id.hashCode,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${isProfit ? "+" : "-"}${AppCurrencyFormatter.format(PositionCalculator.realizedPL(widget.position).abs())}',
                      style: AppTypography.body.copyWith(
                        color: plColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Expanded content
            if (_isExpanded) ...[
              const SizedBox(height: 16),
              Divider(color: borderColor, height: 1),
              const SizedBox(height: 16),
              Text(
                'BUY HISTORY',
                style: AppTypography.caption.copyWith(
                  color: AppColors.neutral500,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 12),
              ...widget.position.buys.map(
                (buy) => PositionBuyRow(buy: buy, position: widget.position),
              ),

              const SizedBox(height: 16),
              Text(
                'SALE HISTORY',
                style: AppTypography.caption.copyWith(
                  color: AppColors.neutral500,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 12),
              if (widget.position.sales.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Text(
                    'No sales recorded yet.',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.neutral500,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                )
              else
                ...widget.position.sales.map(
                  (sale) => PositionSaleRow(
                    positionSale: sale,
                    position: _writeTarget,
                    // A slice's sale rows can be partial allocations of a real
                    // sale, so they're a record to read, not a row to edit.
                    readOnly: _isSlice,
                  ),
                ),

              // Remaining shares pill — pointless on a closed cycle, where it
              // would always read 0.
              if (!isClosed) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: pillBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Remaining',
                        style: AppTypography.body.copyWith(
                          color: AppColors.neutral500,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        '${wholeFormat.format(PositionCalculator.sharesHeld(widget.position))} shares',
                        style: AppTypography.body.copyWith(
                          fontWeight: FontWeight.w800,
                          color: primaryTextColor,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              if (widget.position.status != PositionStatus.closed) ...[
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      AddSellBottomSheet.show(context, widget.position);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark
                          ? const Color(0xFF132B1A)
                          : const Color(0xFFECFDF5),
                      foregroundColor: isDark
                          ? AppColors.moneyGreen
                          : AppColors.moneyGreenOnLight,
                      elevation: 0,
                      side: BorderSide(color: borderColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: Icon(
                      Icons.south_west_rounded,
                      size: 18,
                      color: isDark
                          ? AppColors.moneyGreen
                          : AppColors.moneyGreenOnLight,
                    ),
                    label: Text(
                      'Add Sale from this position',
                      style: TextStyle(
                        color: isDark
                            ? AppColors.moneyGreen
                            : AppColors.moneyGreenOnLight,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 46,
                      child: ElevatedButton.icon(
                        onPressed: () =>
                            PdfReportService.exportPositionPdf(widget.position),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDark
                              ? const Color(0xFF10233A)
                              : const Color(0xFFEFF6FF),
                          foregroundColor: AppColors.chartBlue,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          side: BorderSide(color: borderColor),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(
                          Icons.picture_as_pdf_outlined,
                          size: 16,
                          color: AppColors.chartBlue,
                        ),
                        label: const Text(
                          'PDF Report',
                          style: TextStyle(
                            color: AppColors.chartBlue,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ),
                  if (widget.showStockDetailNavigation) ...[
                    const SizedBox(width: 10),
                    Expanded(
                      child: SizedBox(
                        height: 46,
                        child: OutlinedButton.icon(
                          onPressed: () =>
                              context.push('/stock/${widget.position.ticker}'),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: borderColor),
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            foregroundColor: primaryTextColor,
                          ),
                          icon: Icon(
                            Icons.analytics_outlined,
                            size: 16,
                            color: primaryTextColor,
                          ),
                          label: Text(
                            'Stock Details',
                            style: TextStyle(
                              color: primaryTextColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showContextMenu(BuildContext context) async {
    HapticFeedback.mediumImpact();
    if (_tapDownPosition == null) return;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF13151B) : Colors.white;
    final primaryTextColor = isDark ? Colors.white : AppColors.textPrimaryLight;

    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;

    final result = await showMenu<String>(
      context: context,
      position: RelativeRect.fromRect(
        _tapDownPosition! & const Size(40, 40),
        Offset.zero & overlay.size,
      ),
      color: cardBg,
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      items: [
        PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              const Icon(
                Icons.edit_outlined,
                color: Color(0xFF584BF6),
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                'Edit Position',
                style: TextStyle(
                  color: primaryTextColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'pdf',
          child: Row(
            children: [
              const Icon(
                Icons.picture_as_pdf_outlined,
                color: Color(0xFF2563EB),
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                'Export Position PDF',
                style: TextStyle(
                  color: primaryTextColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              const Icon(
                Icons.delete_outline,
                color: AppColors.alertRed,
                size: 20,
              ),
              const SizedBox(width: 12),
              const Text(
                'Delete Position',
                style: TextStyle(
                  color: AppColors.alertRed,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );

    if (result == 'edit' && context.mounted) {
      if (widget.position.buys.length == 1) {
        // The common case — one buy, nothing to disambiguate.
        EditBuyBottomSheet.show(
          context,
          _writeTarget,
          widget.position.buys.first,
        );
      } else {
        // Multiple buys: ask which one, rather than silently doing nothing
        // (this used to only expand the card, and only if it wasn't already
        // expanded — a no-op the second time you tapped Edit).
        _pickBuyToEdit(context);
      }
    } else if (result == 'pdf') {
      PdfReportService.exportPositionPdf(widget.position);
    } else if (result == 'delete' && context.mounted) {
      _confirmDelete(context);
    }
  }

  Future<void> _pickBuyToEdit(BuildContext context) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF13151B) : Colors.white;
    final borderColor = isDark
        ? const Color(0xFF242731)
        : const Color(0xFFE2E8F0);
    final primaryTextColor = isDark ? Colors.white : AppColors.textPrimaryLight;
    final wholeFormat = NumberFormat('#,##0');
    final dateFormat = DateFormat('MMM d, y');

    final selected = await showModalBottomSheet<PositionBuy>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Which buy do you want to edit?',
                style: AppTypography.h3.copyWith(color: primaryTextColor),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ...widget.position.buys.map(
                (buy) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: InkWell(
                    onTap: () => Navigator.pop(sheetContext, buy),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: borderColor),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${wholeFormat.format(buy.shares)} sh @ ${AppCurrencyFormatter.format(buy.pricePerShare)}',
                            style: AppTypography.body.copyWith(
                              color: primaryTextColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            dateFormat.format(buy.date),
                            style: AppTypography.caption.copyWith(
                              color: AppColors.neutral500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (selected != null && context.mounted) {
      EditBuyBottomSheet.show(context, _writeTarget, selected);
    }
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Delete Position?'),
        content: Text(
          _isSlice
              // The card shows one buy, but the record behind it is the whole
              // cycle — say so rather than deleting more than was asked for.
              ? 'This deletes the entire ${_writeTarget.ticker} position — every buy and sale in this closed cycle, not just this one. This action cannot be undone.'
              : 'This will permanently delete this position and all its sales. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: AppColors.alertRed),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      HapticFeedback.mediumImpact();
      final results = await Connectivity().checkConnectivity();
      final isOffline =
          results.contains(ConnectivityResult.none) || results.isEmpty;

      final repo = ref.read(positionRepositoryProvider);
      if (repo != null) {
        await repo.deletePosition(_writeTarget.id);
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isOffline
                  ? "You're offline. Position deleted locally and will sync when online."
                  : 'Position deleted successfully',
            ),
            backgroundColor: isOffline
                ? AppColors.warningYellow
                : AppColors.moneyGreen,
          ),
        );
      }
    }
  }
}

/// One block of the new icon-above-label, value-below grid layout — Bought /
/// Quantity / Avg. Price and Holding Period / Target Price all use this.
class _GridDetail extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String label;
  final String value;
  final Color? valueColor;
  final bool isDark;

  /// A secondary figure rendered smaller right after [value] — e.g. the
  /// "(+19.1% Est.)" part of a target price, which shouldn't compete with
  /// the primary number for visual weight.
  final String? secondaryValue;

  /// A small line below [value] — e.g. "As of 3:42 PM" for Live Price.
  final String? caption;

  const _GridDetail({
    required this.icon,
    this.iconColor,
    required this.label,
    required this.value,
    this.valueColor,
    required this.isDark,
    this.secondaryValue,
    this.caption,
  });

  @override
  Widget build(BuildContext context) {
    final labelColor = isDark ? Colors.white70 : Colors.black54;
    final defaultValueColor = isDark
        ? Colors.white
        : AppColors.textPrimaryLight;
    final resolvedValueColor = valueColor ?? defaultValueColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 13, color: iconColor ?? labelColor),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                style: AppTypography.caption.copyWith(
                  color: labelColor,
                  fontSize: 11,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: caption == null && secondaryValue == null
                      ? value
                      : '$value ',
                  style: AppTypography.body.copyWith(
                    color: resolvedValueColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                if (secondaryValue != null)
                  TextSpan(
                    text: caption == null ? secondaryValue : '$secondaryValue ',
                    style: AppTypography.body.copyWith(
                      color: resolvedValueColor,
                      fontWeight: FontWeight.w500,
                      fontSize: 11,
                    ),
                  ),
                // Same row as the value — e.g. Live Price's "As of h:mm a",
                // not a second stacked line.
                if (caption != null)
                  TextSpan(
                    text: caption,
                    style: TextStyle(
                      color: isDark ? Colors.white38 : Colors.black38,
                      fontSize: 10,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
              ],
            ),
            maxLines: 1,
          ),
        ),
      ],
    );
  }
}
