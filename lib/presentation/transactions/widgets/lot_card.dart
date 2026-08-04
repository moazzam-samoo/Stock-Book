import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
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

class LotCard extends ConsumerStatefulWidget {
  final Lot lot;

  const LotCard({super.key, required this.lot});

  @override
  ConsumerState<LotCard> createState() => _LotCardState();
}

class _LotCardState extends ConsumerState<LotCard> {
  bool _isExpanded = false;

  void _toggleExpand() {
    HapticFeedback.lightImpact();
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final NumberFormat currencyFormat = NumberFormat('#,##0.00');
    final NumberFormat wholeFormat = NumberFormat('#,##0');
    final DateFormat dateFormat = DateFormat('MMM d');

    final cardBg = isDark ? const Color(0xFF13151B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF242731) : const Color(0xFFE2E8F0);
    final primaryTextColor = isDark ? Colors.white : AppColors.textPrimaryLight;
    final pillBg = isDark ? const Color(0xFF1E222D) : const Color(0xFFF1F5F9);

    return GestureDetector(
      onTap: _toggleExpand,
      behavior: HitTestBehavior.opaque,
      child: Slidable(
        key: ValueKey(widget.lot.id),
        endActionPane: ActionPane(
          motion: const ScrollMotion(),
          extentRatio: 0.25,
          children: [
            SlidableAction(
              onPressed: (context) async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Delete Lot?'),
                    content: const Text('This will permanently delete this lot and all its sales. This action cannot be undone.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Delete', style: TextStyle(color: AppColors.dangerRed)),
                      ),
                    ],
                  ),
                );
                
                if (confirm == true) {
                  HapticFeedback.mediumImpact();
                  final results = await Connectivity().checkConnectivity();
                  final isOffline = results.contains(ConnectivityResult.none) || results.isEmpty;
                  
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
                        backgroundColor: isOffline ? AppColors.warningYellow : AppColors.moneyGreen,
                      ),
                    );
                  }
                }
              },
              backgroundColor: AppColors.dangerRed,
              foregroundColor: Colors.white,
              icon: Icons.delete,
              label: 'Delete',
            ),
          ],
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.all(16),
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
                  TickerAvatar(ticker: widget.lot.ticker, size: 40),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              '${widget.lot.ticker} · ',
                              style: AppTypography.body.copyWith(
                                fontWeight: FontWeight.w800,
                                color: primaryTextColor,
                                fontSize: 16,
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
                          'Bought ${dateFormat.format(widget.lot.buyDate)} @ Rs ${currencyFormat.format(widget.lot.buyPricePerShare)}',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.neutral500,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: AppColors.neutral500,
                    size: 20,
                  ),
                ],
              ),
              
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
                      style: AppTypography.caption.copyWith(color: AppColors.neutral500, fontStyle: FontStyle.italic),
                    ),
                  )
                else
                  ...widget.lot.sales!.map((sale) => SaleEventRow(sale: sale, lotId: widget.lot.id!)).toList(),
                
                const SizedBox(height: 16),
                // Remaining shares pill container (Matches Transtions.png)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                        backgroundColor: isDark ? const Color(0xFF1D1E38) : const Color(0xFFEEF2FF),
                        foregroundColor: const Color(0xFF635BFF),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.south_west_rounded, size: 18, color: Color(0xFF635BFF)),
                      label: const Text(
                        'Add Sale from this lot',
                        style: TextStyle(
                          color: Color(0xFF635BFF),
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
      ),
    );
  }
}
