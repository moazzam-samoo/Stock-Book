import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:stock_investment_tracker/core/theme/app_colors.dart';
import 'package:stock_investment_tracker/core/theme/app_typography.dart';
import 'package:stock_investment_tracker/domain/entities/lot.dart';
import 'package:stock_investment_tracker/presentation/common/buttons.dart';
import 'package:stock_investment_tracker/presentation/common/date_picker_field.dart';
import 'package:stock_investment_tracker/presentation/common/inputs.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:stock_investment_tracker/presentation/transactions/providers/add_sell_controller.dart';

class AddSellBottomSheet extends ConsumerStatefulWidget {
  final Lot lot;

  const AddSellBottomSheet({super.key, required this.lot});

  static Future<void> show(BuildContext context, Lot lot) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.backgroundDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
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
  double get _profitLoss => (_sellPrice - widget.lot.buyPricePerShare) * _sharesSold;
  double get _profitLossPercent {
    if (widget.lot.buyPricePerShare == 0) return 0;
    return (_sellPrice - widget.lot.buyPricePerShare) / widget.lot.buyPricePerShare * 100;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _sellDate == null) {
      return;
    }

    if (_sharesSold > widget.lot.sharesRemaining) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cannot sell more than available (${widget.lot.sharesRemaining})'),
          backgroundColor: AppColors.dangerRed,
        ),
      );
      return;
    }

    final results = await Connectivity().checkConnectivity();
    final isOffline = results.contains(ConnectivityResult.none) || results.isEmpty;

    await ref.read(addSellControllerProvider.notifier).submit(
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
          backgroundColor: isOffline ? AppColors.warningYellow : AppColors.moneyGreen,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat('#,##0.00');
    final asyncState = ref.watch(addSellControllerProvider);
    final isProfit = _profitLoss >= 0;
    final plColor = isProfit ? AppColors.moneyGreen : AppColors.dangerRed;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
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
                    color: AppColors.offBlack,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 24),
                  Text('Add Sell', style: AppTypography.h2),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.neutral500),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceDark,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.lot.ticker,
                      style: AppTypography.h3,
                    ),
                    Text(
                      'Max: ${currencyFormat.format(widget.lot.sharesRemaining)}',
                      style: AppTypography.caption.copyWith(color: AppColors.neutral500),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
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
                        if (parsed > widget.lot.sharesRemaining) return 'Max: ${widget.lot.sharesRemaining}';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: NumericInput(
                      label: 'Sell Price / Share',
                      onChanged: (val) {
                        setState(() {
                          _sellPrice = double.tryParse(val) ?? 0.0;
                        });
                      },
                      validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Amount Received',
                        style: AppTypography.caption.copyWith(color: AppColors.neutral500),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Rs ${currencyFormat.format(_amountReceived)}',
                        style: AppTypography.h2.copyWith(color: Colors.white),
                      ),
                    ],
                  ),
                  if (_sharesSold > 0 && _sellPrice > 0)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          isProfit ? 'Profit' : 'Loss',
                          style: AppTypography.caption.copyWith(color: AppColors.neutral500),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              isProfit ? Icons.arrow_upward : Icons.arrow_downward,
                              color: plColor,
                              size: 16,
                            ),
                            Text(
                              'Rs ${currencyFormat.format(_profitLoss.abs())} (${_profitLossPercent.toStringAsFixed(1)}%)',
                              style: AppTypography.body.copyWith(
                                color: plColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 32),
              PrimaryButton(
                text: 'Save Sell',
                onPressed: _submit,
                isLoading: asyncState.isLoading,
              ),
              if (asyncState.hasError) ...[
                const SizedBox(height: 8),
                Text(
                  'Error saving lot: ${asyncState.error}',
                  style: TextStyle(color: AppColors.dangerRed),
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
