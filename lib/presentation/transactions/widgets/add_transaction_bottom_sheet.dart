import 'package:flutter/material.dart';
import 'package:stock_investment_tracker/core/theme/app_colors.dart';
import 'package:stock_investment_tracker/core/theme/app_typography.dart';
import 'package:stock_investment_tracker/presentation/transactions/widgets/add_buy_bottom_sheet.dart';
import 'package:stock_investment_tracker/presentation/transactions/widgets/select_lot_bottom_sheet.dart';

class AddTransactionBottomSheet extends StatelessWidget {
  const AddTransactionBottomSheet({super.key});

  static Future<void> show(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF13151B) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => const AddTransactionBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final grabHandleColor = isDark
        ? AppColors.offBlack
        : const Color(0xFFE2E8F0);
    final primaryTextColor = isDark ? Colors.white : AppColors.textPrimaryLight;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: grabHandleColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Add Transaction',
              style: AppTypography.h2.copyWith(color: primaryTextColor),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            _TransactionOption(
              icon: Icons.trending_up,
              title: 'Add Buy',
              subtitle: 'Log a new lot you purchased',
              onTap: () {
                Navigator.pop(context);
                AddBuyBottomSheet.show(context);
              },
            ),
            const SizedBox(height: 16),
            _TransactionOption(
              icon: Icons.trending_down,
              title: 'Add Sell',
              subtitle: 'Record a partial or full sale',
              onTap: () {
                Navigator.pop(context);
                SelectLotBottomSheet.show(context);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _TransactionOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _TransactionOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.offBlack : const Color(0xFFF5F5F5);
    final borderColor = isDark
        ? const Color(0xFF242731)
        : const Color(0xFFE2E8F0);
    final primaryTextColor = isDark ? Colors.white : AppColors.textPrimaryLight;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.brandIndigo.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.brandIndigo),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.h3.copyWith(color: primaryTextColor),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.neutral500,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.neutral500),
          ],
        ),
      ),
    );
  }
}
