import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:stock_investment_tracker/core/theme/app_colors.dart';
import 'package:stock_investment_tracker/core/theme/app_typography.dart';
import 'package:stock_investment_tracker/presentation/common/buttons.dart';
import 'package:stock_investment_tracker/presentation/common/date_picker_field.dart';
import 'package:stock_investment_tracker/presentation/common/inputs.dart';
import 'package:stock_investment_tracker/presentation/transactions/providers/add_buy_controller.dart';
import 'package:stock_investment_tracker/presentation/transactions/widgets/ticker_autocomplete.dart';

class AddBuyBottomSheet extends ConsumerStatefulWidget {
  const AddBuyBottomSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.backgroundDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: const AddBuyBottomSheet(),
      ),
    );
  }

  @override
  ConsumerState<AddBuyBottomSheet> createState() => _AddBuyBottomSheetState();
}

class _AddBuyBottomSheetState extends ConsumerState<AddBuyBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  String _ticker = '';
  DateTime? _buyDate = DateTime.now();
  double _sharesPurchased = 0.0;
  double _buyPrice = 0.0;

  double get _amountInvested => _sharesPurchased * _buyPrice;

  void _submit() {
    if (!_formKey.currentState!.validate() || _ticker.isEmpty || _buyDate == null) {
      // Show snackbar or error for missing fields
      return;
    }
    
    ref.read(addBuyControllerProvider.notifier).submit(
      ticker: _ticker,
      buyDate: _buyDate!,
      sharesPurchased: _sharesPurchased,
      buyPricePerShare: _buyPrice,
    ).then((_) {
      if (!mounted) return;
      if (!ref.read(addBuyControllerProvider).hasError) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Bought $_sharesPurchased shares of $_ticker successfully!'),
            backgroundColor: AppColors.moneyGreen,
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat('#,##0.00');
    final asyncState = ref.watch(addBuyControllerProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
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
                  const SizedBox(width: 24), // balance for title centering
                  Text('Add Buy', style: AppTypography.h2),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.neutral500),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              TickerAutocomplete(
                onSelected: (val) {
                  setState(() {
                    _ticker = val;
                  });
                },
              ),
              const SizedBox(height: 16),
              DatePickerField(
                label: 'Buy Date',
                initialDate: _buyDate,
                onDateSelected: (date) {
                  setState(() {
                    _buyDate = date;
                  });
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: NumericInput(
                      label: 'Shares Purchased',
                      onChanged: (val) {
                        setState(() {
                          _sharesPurchased = double.tryParse(val) ?? 0.0;
                        });
                      },
                      validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: NumericInput(
                      label: 'Buy Price / Share',
                      onChanged: (val) {
                        setState(() {
                          _buyPrice = double.tryParse(val) ?? 0.0;
                        });
                      },
                      validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'Amount Invested',
                style: AppTypography.caption.copyWith(color: AppColors.neutral500),
              ),
              const SizedBox(height: 4),
              Text(
                'Rs ${currencyFormat.format(_amountInvested)}',
                style: AppTypography.h2.copyWith(color: Colors.white),
              ),
              const SizedBox(height: 32),
              PrimaryButton(
                text: 'Save Buy',
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
    );
  }
}
