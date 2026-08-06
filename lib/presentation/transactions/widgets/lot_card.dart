import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:stock_investment_tracker/core/utils/currency_formatter.dart';
import 'package:stock_investment_tracker/core/theme/app_colors.dart';
import 'package:stock_investment_tracker/core/theme/app_colors.dart';
import 'package:stock_investment_tracker/core/theme/app_typography.dart';
import 'package:stock_investment_tracker/domain/entities/lot.dart';
import 'package:stock_investment_tracker/domain/enums/lot_status.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:stock_investment_tracker/providers/repository_providers.dart';
import 'package:stock_investment_tracker/presentation/common/badges.dart';
import 'package:stock_investment_tracker/presentation/common/ticker_avatar.dart';
import 'package:stock_investment_tracker/presentation/transactions/widgets/sale_event_row.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:stock_investment_tracker/presentation/transactions/widgets/add_sell_bottom_sheet.dart';
import 'package:stock_investment_tracker/presentation/transactions/widgets/edit_lot_bottom_sheet.dart';
import 'package:stock_investment_tracker/core/services/pdf_report_service.dart';
import 'package:stock_investment_tracker/presentation/common/animated_pdf_button.dart';

class LotCard extends ConsumerStatefulWidget {
  final Lot lot;
  final bool showStockDetailNavigation;

  const LotCard({
    super.key,
    required this.lot,
    this.showStockDetailNavigation = true,
  });

  @override
  ConsumerState<LotCard> createState() => _LotCardState();
}

class _LotCardState extends ConsumerState<LotCard> {
  bool _isExpanded = false;
  Offset? _tapDownPosition;

  void _toggleExpand() {
    HapticFeedback.lightImpact();
    setState(() {
      _isExpanded = !_isExpanded;
    });
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

    final isProfit = widget.lot.realizedProfitLoss >= 0;
    final plColor = isProfit ? AppColors.moneyGreen : AppColors.alertRed;
    final holdingDaysText = widget.lot.holdingDays == 1
        ? '1 day hold'
        : '${widget.lot.holdingDays} days';

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
          border: Border.all(color: borderColor, width: 1.2),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              children: [
                GestureDetector(
                  onTap: widget.showStockDetailNavigation
                      ? () => context.push('/stock/${widget.lot.ticker}')
                      : null,
                  child: TickerAvatar(ticker: widget.lot.ticker, size: 42),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          GestureDetector(
                            onTap: widget.showStockDetailNavigation
                                ? () => context.push(
                                    '/stock/${widget.lot.ticker}',
                                  )
                                : null,
                            child: Text(
                              '${widget.lot.ticker} · ',
                              style: AppTypography.body.copyWith(
                                fontWeight: FontWeight.w800,
                                color: primaryTextColor,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          Text(
                            '${wholeFormat.format(widget.lot.sharesPurchased)} sh',
                            style: AppTypography.body.copyWith(
                              fontWeight: FontWeight.w800,
                              color: primaryTextColor,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(width: 8),
                          StatusBadge(status: widget.lot.status),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Bought ${dateFormat.format(widget.lot.buyDate)} @ ${AppCurrencyFormatter.format(widget.lot.buyPricePerShare)}',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.neutral500,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        'Holding Period : ${holdingDaysText}',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.chartBlue,
                          fontSize: 13,
                        ),
                      ),
                      if (widget.lot.targetPrice != null &&
                          widget.lot.targetPrice! > 0) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Target: ${AppCurrencyFormatter.format(widget.lot.targetPrice!)} (${((widget.lot.targetPrice! - widget.lot.buyPricePerShare) / widget.lot.buyPricePerShare * 100) >= 0 ? "+" : ""}${((widget.lot.targetPrice! - widget.lot.buyPricePerShare) / widget.lot.buyPricePerShare * 100).toStringAsFixed(1)}% Est.)',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.moneyGreen.withOpacity(0.8),
                            fontWeight: FontWeight.normal,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(
                  _isExpanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: AppColors.neutral500,
                  size: 22,
                ),
              ],
            ),

            // Closed Profit Banner (Summary row when closed)
            if (widget.lot.status == LotStatus.closed) ...[
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
                    Row(
                      children: [
                        Icon(
                          isProfit ? Icons.arrow_upward : Icons.arrow_downward,
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
                    Text(
                      '${isProfit ? "+" : "-"}${AppCurrencyFormatter.format(widget.lot.realizedProfitLoss.abs())}',
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
                'SALE HISTORY',
                style: AppTypography.caption.copyWith(
                  color: AppColors.neutral500,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 12),
              if (widget.lot.sales == null || widget.lot.sales!.isEmpty)
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
                ...widget.lot.sales!
                    .map(
                      (sale) => SaleEventRow(sale: sale, lotId: widget.lot.id!),
                    )
                    .toList(),

              const SizedBox(height: 16),
              // Remaining shares pill container
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
                      '${wholeFormat.format(widget.lot.sharesRemaining)} shares',
                      style: AppTypography.body.copyWith(
                        fontWeight: FontWeight.w800,
                        color: primaryTextColor,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),

              if (widget.lot.status != LotStatus.closed) ...[
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      AddSellBottomSheet.show(context, widget.lot);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark
                          ? const Color(0xFF132B1A)
                          : const Color(0xFFECFDF5),
                      foregroundColor: AppColors.moneyGreen,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(
                      Icons.south_west_rounded,
                      size: 18,
                      color: AppColors.moneyGreen,
                    ),
                    label: const Text(
                      'Add Sale from this lot',
                      style: TextStyle(
                        color: AppColors.moneyGreen,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 12),
              AnimatedPdfButton(
                isCompact: false,
                label: 'Download Lot PDF Report',
                onPressed: () => PdfReportService.exportLotPdf(widget.lot),
              ),
              if (widget.showStockDetailNavigation) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        context.push('/stock/${widget.lot.ticker}'),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: borderColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      foregroundColor: primaryTextColor,
                    ),
                    icon: Icon(
                      Icons.analytics_outlined,
                      size: 18,
                      color: primaryTextColor,
                    ),
                    label: Text(
                      'View Full Stock Details',
                      style: TextStyle(
                        color: primaryTextColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
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
                'Edit Lot',
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
                'Export Lot PDF',
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
                'Delete Lot',
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
      EditLotBottomSheet.show(context, widget.lot);
    } else if (result == 'pdf') {
      PdfReportService.exportLotPdf(widget.lot);
    } else if (result == 'delete' && context.mounted) {
      _confirmDelete(context);
    }
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Delete Lot?'),
        content: const Text(
          'This will permanently delete this lot and all its sales. This action cannot be undone.',
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

      final repo = ref.read(lotRepositoryProvider);
      if (repo != null) {
        await repo.deleteLot(widget.lot.id);
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isOffline
                  ? "You're offline. Lot deleted locally and will sync when online."
                  : 'Lot deleted successfully',
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
