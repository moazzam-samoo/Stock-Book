import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stock_investment_tracker/core/utils/currency_formatter.dart';
import 'package:stock_investment_tracker/core/theme/app_colors.dart';
import 'package:stock_investment_tracker/core/theme/app_typography.dart';
import 'package:stock_investment_tracker/domain/entities/lot.dart';
import 'package:stock_investment_tracker/domain/entities/sale.dart';
import 'package:stock_investment_tracker/presentation/common/badges.dart';
import 'package:stock_investment_tracker/presentation/common/date_picker_field.dart';
import 'package:stock_investment_tracker/presentation/common/inputs.dart';
import 'package:stock_investment_tracker/providers/repository_providers.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Edits an existing sale within a lot.
///
/// The lot's remaining shares, status and realized P/L are all derived from the
/// sales array on read, so writing the corrected sale is enough — no derived
/// field needs patching here.
class EditSaleBottomSheet extends ConsumerStatefulWidget {
  final Lot lot;
  final Sale sale;

  const EditSaleBottomSheet({super.key, required this.lot, required this.sale});

  static Future<void> show(BuildContext context, Lot lot, Sale sale) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF13151B) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: EditSaleBottomSheet(lot: lot, sale: sale),
      ),
    );
  }

  @override
  ConsumerState<EditSaleBottomSheet> createState() =>
      _EditSaleBottomSheetState();
}

class _EditSaleBottomSheetState extends ConsumerState<EditSaleBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  late DateTime? _sellDate;
  late double _sharesSold;
  late double _sellPrice;
  bool _isSaving = false;

  /// Shares available to this sale = whole lot minus everything sold in the
  /// *other* sales, so growing this sale is allowed up to the real ceiling.
  int get _maxShares {
    final soldElsewhere = widget.lot.sales
        .where((s) => s.id != widget.sale.id)
        .fold(0, (sum, s) => sum + s.sharesSold);
    return widget.lot.sharesPurchased - soldElsewhere;
  }

  double get _amountReceived => _sharesSold * _sellPrice;
  double get _profitLoss =>
      (_sellPrice - widget.lot.buyPricePerShare) * _sharesSold;

  @override
  void initState() {
    super.initState();
    _sellDate = widget.sale.sellDate;
    _sharesSold = widget.sale.sharesSold.toDouble();
    _sellPrice = widget.sale.sellPricePerShare;
  }

  Future<void> _submit() async {
    // Bail out synchronously on re-entry so a fast double-tap can't fire this
    // twice before the rebuild disables the button — see WithdrawalBottomSheet
    // for the failure mode this avoids (double Navigator.pop crash).
    if (_isSaving) return;
    if (!_formKey.currentState!.validate() || _sellDate == null) return;

    if (_sharesSold > _maxShares) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cannot sell more than available ($_maxShares)'),
          backgroundColor: AppColors.dangerRed,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final results = await Connectivity().checkConnectivity();
      final isOffline =
          results.contains(ConnectivityResult.none) || results.isEmpty;

      final updatedSale = Sale(
        id: widget.sale.id,
        sellDate: _sellDate!,
        sharesSold: _sharesSold.toInt(),
        sellPricePerShare: _sellPrice,
        amountReceived: _amountReceived,
      );

      final repo = ref.read(saleRepositoryProvider);
      if (repo != null) {
        await repo.updateSale(widget.lot.id, updatedSale);
      }

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isOffline
                ? "You're offline. Sale changes saved locally and will sync when online."
                : 'Sale updated successfully!',
          ),
          backgroundColor: isOffline
              ? AppColors.warningYellow
              : AppColors.moneyGreen,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update sale: $e'),
          backgroundColor: AppColors.dangerRed,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final wholeFormat = NumberFormat('#,##0');
    final dateFormat = DateFormat('MMM d, y');
    final isProfit = _profitLoss >= 0;
    final plColor = isProfit
        ? (isDark ? AppColors.moneyGreen : AppColors.moneyGreenOnLight)
        : AppColors.alertRed;

    final primaryTextColor = isDark ? Colors.white : AppColors.textPrimaryLight;
    final boxBorderColor = isDark
        ? const Color(0xFF242731)
        : const Color(0xFFE2E8F0);
    final bannerBgColor = isDark
        ? const Color(0xFF1E2235)
        : const Color(0xFFEEF2FF);
    final boxBgColor = isDark
        ? const Color(0xFF1A1D27)
        : const Color(0xFFF8FAFC);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF333A4A)
                          : const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: AppColors.neutral500,
                        size: 20,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Text(
                      'Edit Sale',
                      style: AppTypography.h2.copyWith(
                        color: primaryTextColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(width: 40),
                  ],
                ),
                const SizedBox(height: 16),

                // Parent lot banner
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: bannerBgColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF584BF6).withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${widget.lot.ticker} · Bought ${dateFormat.format(widget.lot.buyDate)}',
                              style: AppTypography.body.copyWith(
                                color: primaryTextColor,
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Buy price ${AppCurrencyFormatter.format(widget.lot.buyPricePerShare)} · max ${wholeFormat.format(_maxShares)} sh',
                              style: AppTypography.caption.copyWith(
                                color: AppColors.neutral500,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      StatusBadge(status: widget.lot.status),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                DatePickerField(
                  label: 'Sell Date',
                  initialDate: _sellDate,
                  onDateSelected: (date) => setState(() => _sellDate = date),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: NumericInput(
                        label: 'Shares Sold',
                        initialValue: widget.sale.sharesSold.toString(),
                        onChanged: (val) {
                          setState(() {
                            _sharesSold = double.tryParse(val) ?? 0.0;
                          });
                        },
                        validator: (val) {
                          if (val == null || val.isEmpty) return 'Required';
                          final parsed = double.tryParse(val) ?? 0.0;
                          if (parsed <= 0) return 'Must be > 0';
                          if (parsed > _maxShares) return 'Max: $_maxShares';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: NumericInput(
                        label: 'Sell Price / Share',
                        initialValue: widget.sale.sellPricePerShare.toString(),
                        onChanged: (val) {
                          setState(() {
                            _sellPrice = double.tryParse(val) ?? 0.0;
                          });
                        },
                        validator: (val) =>
                            val == null || val.isEmpty ? 'Required' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: boxBgColor,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: boxBorderColor, width: 1.2),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Amount Received',
                            style: AppTypography.body.copyWith(
                              color: AppColors.neutral500,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _amountReceived > 0
                                ? AppCurrencyFormatter.format(_amountReceived)
                                : 'Rs —',
                            style: AppTypography.h2.copyWith(
                              color: primaryTextColor,
                              fontFamily: 'JetBrains Mono',
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                      if (_sharesSold > 0 && _sellPrice > 0)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              isProfit ? 'Realized Profit' : 'Realized Loss',
                              style: AppTypography.caption.copyWith(
                                color: AppColors.neutral500,
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  isProfit
                                      ? Icons.arrow_upward
                                      : Icons.arrow_downward,
                                  color: plColor,
                                  size: 14,
                                ),
                                Text(
                                  AppCurrencyFormatter.format(
                                    _profitLoss.abs(),
                                  ),
                                  style: AppTypography.body.copyWith(
                                    color: plColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF584BF6),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : const Text(
                            'Update Sale',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
