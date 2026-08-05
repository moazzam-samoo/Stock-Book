import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stock_investment_tracker/core/utils/currency_formatter.dart';
import 'package:stock_investment_tracker/core/theme/app_colors.dart';
import 'package:stock_investment_tracker/core/theme/app_typography.dart';
import 'package:stock_investment_tracker/domain/entities/lot.dart';
import 'package:stock_investment_tracker/presentation/common/badges.dart';
import 'package:stock_investment_tracker/presentation/common/date_picker_field.dart';
import 'package:stock_investment_tracker/presentation/common/inputs.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:stock_investment_tracker/presentation/transactions/providers/add_sell_controller.dart';

class AddSellBottomSheet extends ConsumerStatefulWidget {
  final Lot lot;

  const AddSellBottomSheet({super.key, required this.lot});

  static Future<void> show(BuildContext context, Lot lot) {
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
        child: AddSellBottomSheet(lot: lot),
      ),
    );
  }

  @override
  ConsumerState<AddSellBottomSheet> createState() => _AddSellBottomSheetState();
}

class _AddSellBottomSheetState extends ConsumerState<AddSellBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  DateTime? _sellDate = DateTime.now();
  double _sharesSold = 0.0;
  double _sellPrice = 0.0;

  double get _amountReceived => _sharesSold * _sellPrice;
  double get _profitLoss =>
      (_sellPrice - widget.lot.buyPricePerShare) * _sharesSold;
  double get _profitLossPercent {
    if (widget.lot.buyPricePerShare == 0) return 0;
    return (_sellPrice - widget.lot.buyPricePerShare) /
        widget.lot.buyPricePerShare *
        100;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _sellDate == null) {
      return;
    }

    if (_sharesSold > widget.lot.sharesRemaining) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Cannot sell more than available (${widget.lot.sharesRemaining})',
          ),
          backgroundColor: AppColors.dangerRed,
        ),
      );
      return;
    }

    final results = await Connectivity().checkConnectivity();
    final isOffline =
        results.contains(ConnectivityResult.none) || results.isEmpty;

    await ref
        .read(addSellControllerProvider.notifier)
        .submit(
          lot: widget.lot,
          sellDate: _sellDate!,
          sharesSold: _sharesSold,
          sellPricePerShare: _sellPrice,
        );

    if (!mounted) return;
    if (!ref.read(addSellControllerProvider).hasError) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isOffline
                ? "You're offline. Your sale was saved locally and will sync when online."
                : 'Sold ${_sharesSold.toInt()} shares of ${widget.lot.ticker} successfully!',
          ),
          backgroundColor: isOffline
              ? AppColors.warningYellow
              : AppColors.moneyGreen,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final wholeFormat = NumberFormat('#,##0');
    final dateFormat = DateFormat('MMM d, y');
    final asyncState = ref.watch(addSellControllerProvider);
    final isProfit = _profitLoss >= 0;
    final plColor = isProfit ? AppColors.moneyGreen : AppColors.alertRed;

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
                      'Add Sell',
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
                // Selected Lot Banner (Matches Add Sale form LOT.png)
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
                              'Remaining: ${wholeFormat.format(widget.lot.sharesRemaining)} shares',
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
                  onDateSelected: (date) {
                    setState(() {
                      _sellDate = date;
                    });
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: NumericInput(
                        label: 'Shares Sold',
                        onChanged: (val) {
                          setState(() {
                            _sharesSold = double.tryParse(val) ?? 0.0;
                          });
                        },
                        validator: (val) {
                          if (val == null || val.isEmpty) return 'Required';
                          final parsed = double.tryParse(val) ?? 0.0;
                          if (parsed > widget.lot.sharesRemaining)
                            return 'Max: ${widget.lot.sharesRemaining}';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: NumericInput(
                        label: 'Sell Price / Share',
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
                // Amount Received Box (Matches Add Sale form LOT.png)
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
                              isProfit ? 'Estimated Profit' : 'Estimated Loss',
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
                    onPressed: asyncState.isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF584BF6),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: asyncState.isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : const Text(
                            'Save Sale',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                  ),
                ),
                if (asyncState.hasError) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Error saving sale: ${asyncState.error}',
                    style: const TextStyle(color: AppColors.dangerRed),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
