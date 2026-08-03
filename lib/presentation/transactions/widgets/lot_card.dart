import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:stock_investment_tracker/core/theme/app_colors.dart';
import 'package:stock_investment_tracker/core/theme/app_typography.dart';
import 'package:stock_investment_tracker/domain/entities/lot.dart';
import 'package:stock_investment_tracker/domain/enums/lot_status.dart';
import 'package:stock_investment_tracker/presentation/common/status_badge.dart';
import 'package:stock_investment_tracker/presentation/common/ticker_avatar.dart';
import 'package:stock_investment_tracker/presentation/transactions/widgets/sale_event_row.dart';

class LotCard extends StatefulWidget {
  final Lot lot;

  const LotCard({super.key, required this.lot});

  @override
  State<LotCard> createState() => _LotCardState();
}

class _LotCardState extends State<LotCard> {
  bool _isExpanded = false;

  void _toggleExpand() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    final NumberFormat currencyFormat = NumberFormat('#,##0.00');
    final DateFormat dateFormat = DateFormat('MMM d, y');

    return GestureDetector(
      onTap: _toggleExpand,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.offBlack),
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
                            style: AppTypography.body.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '${currencyFormat.format(widget.lot.sharesPurchased)} sh',
                            style: AppTypography.body.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Bought ${dateFormat.format(widget.lot.buyDate)} @ Rs ${currencyFormat.format(widget.lot.buyPricePerShare)}',
                        style: AppTypography.caption.copyWith(color: AppColors.neutral500),
                      ),
                    ],
                  ),
                ),
                StatusBadge(status: widget.lot.status),
                const SizedBox(width: 8),
                Icon(
                  _isExpanded ? Icons.expand_less : Icons.expand_more,
                  color: AppColors.neutral500,
                ),
              ],
            ),
            
            // Expanded content
            if (_isExpanded) ...[
              const SizedBox(height: 16),
              const Divider(color: AppColors.offBlack, height: 1),
              const SizedBox(height: 16),
              Text(
                'SALE HISTORY',
                style: AppTypography.caption.copyWith(
                  color: AppColors.neutral500,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              if (widget.lot.sales == null || widget.lot.sales!.isEmpty)
                Text(
                  'No sales recorded yet.',
                  style: AppTypography.caption.copyWith(color: AppColors.neutral500, fontStyle: FontStyle.italic),
                )
              else
                ...widget.lot.sales!.map((sale) => SaleEventRow(sale: sale)).toList(),
              
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Remaining', style: AppTypography.body),
                  Text(
                    '${currencyFormat.format(widget.lot.sharesRemaining)} shares',
                    style: AppTypography.body.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              
              if (widget.lot.status != LotStatus.closed) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      // TODO: Navigate to Add Sale with this lot pre-selected
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.brandIndigo,
                      side: const BorderSide(color: AppColors.brandIndigo),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Add Sale from this lot'),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
