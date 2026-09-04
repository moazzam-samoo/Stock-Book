import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stock_investment_tracker/core/utils/currency_formatter.dart';
import 'package:stock_investment_tracker/core/theme/app_colors.dart';
import 'package:stock_investment_tracker/core/theme/app_typography.dart';
import 'package:stock_investment_tracker/domain/calculator/position_calculator.dart';
import 'package:stock_investment_tracker/domain/entities/position.dart';
import 'package:stock_investment_tracker/domain/entities/position_buy.dart';
import 'package:stock_investment_tracker/domain/enums/position_status.dart';
import 'package:stock_investment_tracker/presentation/common/date_picker_field.dart';
import 'package:stock_investment_tracker/presentation/common/inputs.dart';
import 'package:stock_investment_tracker/presentation/transactions/widgets/ticker_autocomplete.dart';
import 'package:stock_investment_tracker/providers/repository_providers.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class EditBuyBottomSheet extends ConsumerStatefulWidget {
  final Position position;
  final PositionBuy buy;

  const EditBuyBottomSheet({
    super.key,
    required this.position,
    required this.buy,
  });

  static Future<void> show(BuildContext context, Position position, PositionBuy buy) {
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
        child: EditBuyBottomSheet(position: position, buy: buy),
      ),
    );
  }

  @override
  ConsumerState<EditBuyBottomSheet> createState() => _EditBuyBottomSheetState();
}

class _EditBuyBottomSheetState extends ConsumerState<EditBuyBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _tickerController;
  final _tickerFocusNode = FocusNode();
  late String _ticker;
  late DateTime? _buyDate;
  late double _sharesPurchased;
  late double _buyPrice;
  late double? _targetPrice;
  bool _isSaving = false;

  double get _amountInvested => _sharesPurchased * _buyPrice;

  @override
  void initState() {
    super.initState();
    _ticker = widget.position.ticker;
    _tickerController = TextEditingController(text: widget.position.ticker);
    _buyDate = widget.buy.date;
    _sharesPurchased = widget.buy.shares.toDouble();
    _buyPrice = widget.buy.pricePerShare;
    _targetPrice = widget.position.targetPrice;
  }

  @override
  void dispose() {
    _tickerController.dispose();
    _tickerFocusNode.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() ||
        _ticker.isEmpty ||
        _buyDate == null) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final results = await Connectivity().checkConnectivity();
      final isOffline =
          results.contains(ConnectivityResult.none) || results.isEmpty;

      final updatedBuy = widget.buy.copyWith(
        date: _buyDate!,
        shares: _sharesPurchased.toInt(),
        pricePerShare: _buyPrice,
      );

      final updatedBuys = widget.position.buys.map((b) => b.id == updatedBuy.id ? updatedBuy : b).toList();

      final updatedPosition = widget.position.copyWith(
        ticker: _ticker.toUpperCase(),
        targetPrice: _targetPrice,
        buys: updatedBuys,
      );

      // Editing a buy's share count changes sharesHeld, which can close or
      // reopen the position — `status` is stored, not derived, so it has to be
      // restamped here or it goes stale (AGENTS.md §14).
      final newStatus = PositionCalculator.computeStatus(updatedPosition);
      final positionToSave = updatedPosition.copyWith(
        status: newStatus,
        closedAt: newStatus == PositionStatus.closed
            ? (widget.position.closedAt ?? _buyDate)
            : null,
      );

      final repo = ref.read(positionRepositoryProvider);
      if (repo != null) {
        await repo.updatePosition(positionToSave);
      }

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isOffline
                ? "You're offline. Buy changes saved locally."
                : 'Buy updated successfully!',
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
          content: Text('Failed to update buy: $e'),
          backgroundColor: AppColors.dangerRed,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? Colors.white : AppColors.textPrimaryLight;
    final boxBorderColor = isDark
        ? const Color(0xFF242731)
        : const Color(0xFFE2E8F0);
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
                      'Edit Buy',
                      style: AppTypography.h2.copyWith(
                        color: primaryTextColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(width: 40),
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
                        initialValue: widget.buy.shares.toString(),
                        onChanged: (val) {
                          setState(() {
                            _sharesPurchased = double.tryParse(val) ?? 0.0;
                          });
                        },
                        validator: (val) =>
                            val == null || val.isEmpty ? 'Required' : null,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: NumericInput(
                        label: 'Buy Price / Share',
                        initialValue: widget.buy.pricePerShare.toString(),
                        onChanged: (val) {
                          setState(() {
                            _buyPrice = double.tryParse(val) ?? 0.0;
                          });
                        },
                        validator: (val) =>
                            val == null || val.isEmpty ? 'Required' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                NumericInput(
                  label: 'Target Selling Price / Share (Optional)',
                  initialValue: widget.position.targetPrice?.toString() ?? '',
                  onChanged: (val) {
                    setState(() {
                      _targetPrice = double.tryParse(val);
                    });
                  },
                ),
                const SizedBox(height: 12),
                Text(
                  'Changing this buy shifts the average cost for shares still held. Sales already recorded keep the cost basis they were booked at — this never rewrites past profit.',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.neutral500,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 12),
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
                      Text(
                        'Amount Invested',
                        style: AppTypography.body.copyWith(
                          color: AppColors.neutral500,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        _amountInvested > 0
                            ? AppCurrencyFormatter.format(_amountInvested)
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
                            'Update Buy',
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
