import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:stock_investment_tracker/core/theme/app_colors.dart';
import 'package:stock_investment_tracker/core/theme/app_typography.dart';
import 'package:stock_investment_tracker/domain/entities/sale.dart';

class SaleEventRow extends StatelessWidget {
  final Sale sale;

  const SaleEventRow({super.key, required this.sale});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat('#,##0.00');
    final dateFormat = DateFormat('MMM d, y');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6, right: 12),
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: AppColors.moneyGreen,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sold ${currencyFormat.format(sale.sharesSold)} @ Rs ${currencyFormat.format(sale.sellPricePerShare)}',
                  style: AppTypography.body,
                ),
                const SizedBox(height: 2),
                Text(
                  dateFormat.format(sale.sellDate),
                  style: AppTypography.caption.copyWith(color: AppColors.neutral500),
                ),
              ],
            ),
          ),
          Text(
            '+ Rs ${currencyFormat.format(sale.amountReceived)}',
            style: AppTypography.body.copyWith(
              color: AppColors.moneyGreen,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
