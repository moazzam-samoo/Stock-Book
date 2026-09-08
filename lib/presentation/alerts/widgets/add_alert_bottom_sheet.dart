import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stock_investment_tracker/core/theme/app_colors.dart';
import 'package:stock_investment_tracker/core/theme/app_typography.dart';
import 'package:stock_investment_tracker/core/utils/currency_formatter.dart';
import 'package:stock_investment_tracker/domain/entities/price_alert.dart';
import 'package:stock_investment_tracker/presentation/alerts/providers/alerts_providers.dart';
import 'package:stock_investment_tracker/presentation/common/inputs.dart';
import 'package:stock_investment_tracker/presentation/transactions/widgets/ticker_autocomplete.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class AddAlertBottomSheet extends ConsumerStatefulWidget {
  final PriceAlert? existing;

  const AddAlertBottomSheet({
    super.key,
    this.existing,
  });

  static Future<void> show(BuildContext context, {PriceAlert? existing}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF13151B) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: AddAlertBottomSheet(existing: existing),
      ),
    );
  }

  @override
  ConsumerState<AddAlertBottomSheet> createState() => _AddAlertBottomSheetState();
}

class _AddAlertBottomSheetState extends ConsumerState<AddAlertBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _tickerController;
  final _tickerFocusNode = FocusNode();
  
  String? _ticker;
  double? _targetPrice;
  double _tolerancePercent = 1.0;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _ticker = widget.existing?.ticker;
    _targetPrice = widget.existing?.targetPrice;
    _tolerancePercent = widget.existing?.tolerancePercent ?? 1.0;

    _tickerController = TextEditingController(text: _ticker);
  }

  @override
  void dispose() {
    _tickerController.dispose();
    _tickerFocusNode.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    // TickerAutocomplete isn't a FormField, so it can't participate in the
    // Form's own validate()/save() — its requiredness is checked here instead.
    if (_ticker == null || _ticker!.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a stock ticker')),
      );
      return;
    }
    _formKey.currentState!.save();

    final connectivityResult = await Connectivity().checkConnectivity();
    final isOffline = connectivityResult.contains(ConnectivityResult.none);
    if (isOffline && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "You're offline, alert will sync when connected.",
            style: AppTypography.body.copyWith(
              color: Colors.black,
              fontWeight: FontWeight.w600,
            ),
          ),
          backgroundColor: AppColors.warningYellow,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }

    setState(() {
      _isSaving = true;
    });

    final notifier = ref.read(alertsControllerProvider.notifier);

    if (widget.existing != null) {
      final updated = widget.existing!.copyWith(
        ticker: _ticker,
        targetPrice: _targetPrice,
        tolerancePercent: _tolerancePercent,
      );
      await notifier.updateAlert(updated);
    } else {
      await notifier.addAlert(
        ticker: _ticker!,
        targetPrice: _targetPrice!,
        tolerancePercent: _tolerancePercent,
      );
    }

    if (mounted) {
      Navigator.pop(context);
      if (!isOffline) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.existing != null ? 'Alert updated successfully' : 'Alert created successfully',
              style: AppTypography.body.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            backgroundColor: AppColors.moneyGreenOnLight,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? Colors.white : AppColors.textPrimaryLight;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF242731) : const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF584BF6).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.notifications_active_outlined,
                    color: Color(0xFF584BF6),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  widget.existing != null ? 'Edit Price Alert' : 'New Price Alert',
                  style: AppTypography.h3.copyWith(
                    color: primaryTextColor,
                    fontSize: 20,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            TickerAutocomplete(
              controller: _tickerController,
              focusNode: _tickerFocusNode,
              // No unfocus() here: TickerAutocomplete's onSelected fires on
              // every keystroke (not just a genuine tap on a suggestion), so
              // an unfocus() call here was dismissing the keyboard after
              // every single typed character.
              onSelected: (val) {
                setState(() {
                  _ticker = val.trim().toUpperCase();
                });
              },
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: NumericInput(
                    label: 'Target Price (Rs)',
                    initialValue: _targetPrice?.toString(),
                    onChanged: (val) {
                      setState(() {
                        _targetPrice = double.tryParse(val);
                      });
                    },
                    validator: (val) {
                      final parsed = double.tryParse(val ?? '');
                      return parsed == null || parsed <= 0 ? 'Invalid' : null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: NumericInput(
                    label: 'Tolerance (%)',
                    initialValue: _tolerancePercent.toString(),
                    onChanged: (val) {
                      setState(() {
                        _tolerancePercent = double.tryParse(val) ?? 0.0;
                      });
                    },
                    validator: (val) {
                      final parsed = double.tryParse(val ?? '');
                      return parsed == null || parsed < 0 ? 'Invalid' : null;
                    },
                  ),
                ),
              ],
            ),
            if (_targetPrice != null && _targetPrice! > 0) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1A1D27) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? const Color(0xFF242731) : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      size: 16,
                      color: AppColors.neutral500,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Notify me when price drops to or below ${AppCurrencyFormatter.format(alertThreshold(_targetPrice!, _tolerancePercent))}',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.neutral500,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isSaving ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF584BF6),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      widget.existing != null ? 'Save Changes' : 'Create Alert',
                      style: AppTypography.body.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
