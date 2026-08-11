import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stock_investment_tracker/core/theme/app_colors.dart';
import 'package:stock_investment_tracker/core/theme/app_typography.dart';
import 'package:stock_investment_tracker/core/utils/currency_formatter.dart';
import 'package:stock_investment_tracker/domain/entities/withdrawal.dart';
import 'package:stock_investment_tracker/presentation/common/date_picker_field.dart';
import 'package:stock_investment_tracker/presentation/common/inputs.dart';
import 'package:stock_investment_tracker/presentation/dashboard/providers/dashboard_providers.dart';
import 'package:stock_investment_tracker/presentation/settings/providers/withdrawal_provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Add or edit a profit withdrawal. Pass [existing] to edit.
class WithdrawalBottomSheet extends ConsumerStatefulWidget {
  final Withdrawal? existing;

  const WithdrawalBottomSheet({super.key, this.existing});

  static Future<void> show(BuildContext context, {Withdrawal? existing}) {
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
        child: WithdrawalBottomSheet(existing: existing),
      ),
    );
  }

  @override
  ConsumerState<WithdrawalBottomSheet> createState() =>
      _WithdrawalBottomSheetState();
}

class _WithdrawalBottomSheetState
    extends ConsumerState<WithdrawalBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  late DateTime? _date;
  late double _amount;
  late String _note;
  bool _isSaving = false;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    _date = widget.existing?.date ?? DateTime.now();
    _amount = widget.existing?.amount ?? 0.0;
    _note = widget.existing?.note ?? '';
  }

  Future<void> _submit() async {
    // Bail out synchronously if a submission is already in flight. This guards
    // against a fast double-tap firing _submit() twice before the rebuild that
    // disables the button lands — without it, the second call still runs to
    // completion and calls Navigator.pop on an already-popped route, throwing
    // "Bad state: Future already completed" and leaving an error banner.
    if (_isSaving) return;
    if (!_formKey.currentState!.validate() || _date == null) return;
    if (_amount <= 0) return;

    setState(() => _isSaving = true);

    try {
      final results = await Connectivity().checkConnectivity();
      final isOffline =
          results.contains(ConnectivityResult.none) || results.isEmpty;

      final controller = ref.read(withdrawalControllerProvider.notifier);
      if (_isEditing) {
        await controller.updateWithdrawal(
          widget.existing!.copyWith(
            amount: _amount,
            date: _date!,
            note: _note.trim(),
          ),
        );
      } else {
        await controller.addWithdrawal(
          amount: _amount,
          date: _date!,
          note: _note,
        );
      }

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isOffline
                ? "You're offline. Withdrawal saved locally and will sync when online."
                : _isEditing
                    ? 'Withdrawal updated successfully'
                    : 'Withdrew ${AppCurrencyFormatter.format(_amount)} from profit',
          ),
          backgroundColor:
              isOffline ? AppColors.warningYellow : AppColors.moneyGreen,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save withdrawal: $e'),
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
    final summary = ref.watch(portfolioSummaryProvider);

    final primaryTextColor = isDark ? Colors.white : AppColors.textPrimaryLight;
    final boxBorderColor =
        isDark ? const Color(0xFF242731) : const Color(0xFFE2E8F0);
    final boxBgColor =
        isDark ? const Color(0xFF1A1D27) : const Color(0xFFF8FAFC);

    // Available profit excludes the row being edited, so editing 3,000 -> 4,000
    // is measured against the pot as it would be without this withdrawal.
    final availableNow = _isEditing
        ? summary.realizedPL + widget.existing!.amount
        : summary.realizedPL;
    final remainingAfter = availableNow - _amount;
    final isOverdrawn = _amount > 0 && remainingAfter < 0;

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
                      _isEditing ? 'Edit Withdrawal' : 'Withdraw Profit',
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

                // Available profit banner
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1E2235)
                        : const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF584BF6).withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Available Profit',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.neutral500,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            AppCurrencyFormatter.format(availableNow),
                            style: AppTypography.body.copyWith(
                              color: availableNow >= 0
                                  ? AppColors.moneyGreen
                                  : AppColors.alertRed,
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Already Withdrawn',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.neutral500,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            AppCurrencyFormatter.format(summary.totalWithdrawn),
                            style: AppTypography.body.copyWith(
                              color: primaryTextColor,
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                DatePickerField(
                  label: 'Withdrawal Date',
                  initialDate: _date,
                  onDateSelected: (date) => setState(() => _date = date),
                ),
                const SizedBox(height: 16),
                NumericInput(
                  label: 'Amount Withdrawn',
                  initialValue: _isEditing
                      ? widget.existing!.amount.toString()
                      : null,
                  onChanged: (val) {
                    setState(() => _amount = double.tryParse(val) ?? 0.0);
                  },
                  validator: (val) {
                    if (val == null || val.isEmpty) return 'Required';
                    final parsed = double.tryParse(val) ?? 0.0;
                    if (parsed <= 0) return 'Must be greater than 0';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Note (Optional)',
                  hint: 'e.g. Bills, Personal',
                  initialValue: _isEditing ? widget.existing!.note : null,
                  onChanged: (val) => _note = val,
                ),
                const SizedBox(height: 20),

                // Impact preview
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
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Profit Left After This',
                            style: AppTypography.body.copyWith(
                              color: AppColors.neutral500,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            _amount > 0
                                ? AppCurrencyFormatter.format(remainingAfter)
                                : 'Rs —',
                            style: AppTypography.h2.copyWith(
                              color: isOverdrawn
                                  ? AppColors.warningYellow
                                  : primaryTextColor,
                              fontFamily: 'JetBrains Mono',
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                      if (isOverdrawn) ...[
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Icon(
                              Icons.warning_amber_rounded,
                              color: AppColors.warningYellow,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'This is more than your realized profit — it will show as a negative P/L.',
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.warningYellow,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
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
                        : Text(
                            _isEditing
                                ? 'Update Withdrawal'
                                : 'Save Withdrawal',
                            style: const TextStyle(
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
