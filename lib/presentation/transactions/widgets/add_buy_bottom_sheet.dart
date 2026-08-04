import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:stock_investment_tracker/core/theme/app_colors.dart';
import 'package:stock_investment_tracker/core/theme/app_typography.dart';
import 'package:stock_investment_tracker/presentation/common/date_picker_field.dart';
import 'package:stock_investment_tracker/presentation/common/inputs.dart';
import 'package:stock_investment_tracker/presentation/transactions/providers/add_buy_controller.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:stock_investment_tracker/presentation/transactions/widgets/ticker_autocomplete.dart';

class AddBuyBottomSheet extends ConsumerStatefulWidget {
  const AddBuyBottomSheet({super.key});

  static Future<void> show(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF13151B) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
  final _tickerController = TextEditingController();
  final _tickerFocusNode = FocusNode();
  String _ticker = '';
  DateTime? _buyDate = DateTime.now();
  double _sharesPurchased = 0.0;
  double _buyPrice = 0.0;

  double get _amountInvested => _sharesPurchased * _buyPrice;

  @override
  void dispose() {
    _tickerController.dispose();
    _tickerFocusNode.dispose();
    super.dispose();
  }


  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _ticker.isEmpty || _buyDate == null) {
      return;
    }
    
    final results = await Connectivity().checkConnectivity();
    final isOffline = results.contains(ConnectivityResult.none) || results.isEmpty;

    await ref.read(addBuyControllerProvider.notifier).submit(
      ticker: _ticker,
      buyDate: _buyDate!,
      sharesPurchased: _sharesPurchased,
      buyPricePerShare: _buyPrice,
    );

    if (!mounted) return;
    if (!ref.read(addBuyControllerProvider).hasError) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isOffline
                ? "You're offline. Your purchase was saved locally and will sync when online."
                : 'Bought ${_sharesPurchased.toInt()} shares of $_ticker successfully!',
          ),
          backgroundColor: isOffline ? AppColors.warningYellow : AppColors.moneyGreen,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currencyFormat = NumberFormat('#,##0.00');
    final asyncState = ref.watch(addBuyControllerProvider);

    final primaryTextColor = isDark ? Colors.white : AppColors.textPrimaryLight;
    final boxBorderColor = isDark ? const Color(0xFF242731) : const Color(0xFFE2E8F0);
    final boxBgColor = isDark ? const Color(0xFF1A1D27) : const Color(0xFFF8FAFC);

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
                      color: isDark ? const Color(0xFF333A4A) : const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: Icon(Icons.close, color: AppColors.neutral500, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Text(
                      'Add Buy',
                      style: AppTypography.h2.copyWith(
                        color: primaryTextColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(width: 40), // Balance close button
                  ],
                ),
                const SizedBox(height: 20),
                TickerAutocomplete(
                  controller: _tickerController,
                  focusNode: _tickerFocusNode,
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
                    const SizedBox(width: 14),
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
                const SizedBox(height: 20),
                // Amount Invested Box (Matches Add Buy.png)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    color: boxBgColor,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: boxBorderColor, width: 1.2),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Amount Invested',
                        style: AppTypography.body.copyWith(
                          color: AppColors.neutral500,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        _amountInvested > 0 ? 'Rs ${currencyFormat.format(_amountInvested)}' : 'Rs —',
                        style: AppTypography.h2.copyWith(
                          color: primaryTextColor,
                          fontFamily: 'JetBrains Mono',
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                        ),
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
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: asyncState.isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                          )
                        : const Text(
                            'Save Buy',
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
                    'Error saving lot: ${asyncState.error}',
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
