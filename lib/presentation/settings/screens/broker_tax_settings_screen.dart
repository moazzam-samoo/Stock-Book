import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stock_investment_tracker/core/theme/app_colors.dart';
import 'package:stock_investment_tracker/core/theme/app_typography.dart';
import 'package:stock_investment_tracker/domain/entities/admin_tax_rates.dart';
import 'package:stock_investment_tracker/domain/entities/tax_settings.dart';
import 'package:stock_investment_tracker/presentation/common/custom_app_bar.dart';
import 'package:stock_investment_tracker/presentation/common/inputs.dart';
import 'package:stock_investment_tracker/presentation/settings/providers/settings_provider.dart';

/// Dedicated screen for configuring broker fee and tax rates.
/// Pushed outside the bottom navigation shell with [CustomAppBar].
class BrokerTaxSettingsScreen extends ConsumerStatefulWidget {
  const BrokerTaxSettingsScreen({super.key});

  @override
  ConsumerState<BrokerTaxSettingsScreen> createState() =>
      _BrokerTaxSettingsScreenState();
}

class _BrokerTaxSettingsScreenState
    extends ConsumerState<BrokerTaxSettingsScreen> {
  late final TextEditingController _cdcController;
  late final TextEditingController _psxLagaController;
  late final TextEditingController _secpLagaController;
  late final TextEditingController _nccplController;
  late final TextEditingController _commissionController;
  late final TextEditingController _sstController;
  late final TextEditingController _otherChargesController;
  late final TextEditingController _cgtController;

  bool _isSaving = false;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _cdcController = TextEditingController();
    _psxLagaController = TextEditingController();
    _secpLagaController = TextEditingController();
    _nccplController = TextEditingController();
    _commissionController = TextEditingController();
    _sstController = TextEditingController();
    _otherChargesController = TextEditingController();
    _cgtController = TextEditingController();
  }

  void _populateFields([AdminTaxRates? adminFallback]) {
    final settings = ref.read(settingsProvider).valueOrNull;
    final userTax = settings?.taxSettings ?? const TaxSettings();
    final admin = adminFallback ??
        ref.read(adminTaxRatesProvider).valueOrNull ??
        AdminTaxRates.psxDefaults;

    String formatPercent(double? userVal, double adminVal) {
      final val = userVal != null ? userVal * 100 : adminVal * 100;
      return _formatNumber(val);
    }

    String formatRs(double? userVal, double adminVal) {
      final val = userVal ?? adminVal;
      return _formatNumber(val);
    }

    _cdcController.text = formatRs(userTax.cdcPerShare, admin.cdcPerShare);
    _psxLagaController.text =
        formatPercent(userTax.psxLagaRate, admin.psxLagaRate);
    _secpLagaController.text =
        formatPercent(userTax.secpLagaRate, admin.secpLagaRate);
    _nccplController.text = formatPercent(userTax.nccplRate, admin.nccplRate);
    _commissionController.text =
        formatPercent(userTax.commissionRate, admin.commissionRate);
    _sstController.text = formatPercent(userTax.sstRate, admin.sstRate);
    _otherChargesController.text =
        formatRs(userTax.otherCharges, admin.otherCharges);
    _cgtController.text = formatPercent(userTax.cgtRate, admin.cgtRate);
  }

  String _formatNumber(double val) {
    if (val == 0.0) return '0.0';
    final str = val.toStringAsFixed(6);
    return str.replaceAll(RegExp(r'0*$'), '').replaceAll(RegExp(r'\.$'), '');
  }

  @override
  void dispose() {
    _cdcController.dispose();
    _psxLagaController.dispose();
    _secpLagaController.dispose();
    _nccplController.dispose();
    _commissionController.dispose();
    _sstController.dispose();
    _otherChargesController.dispose();
    _cgtController.dispose();
    super.dispose();
  }

  Future<void> _resetToAdminDefaults() async {
    await HapticFeedback.lightImpact();
    final admin = ref.read(adminTaxRatesProvider).valueOrNull ??
        AdminTaxRates.psxDefaults;

    setState(() {
      _populateFields(admin);
    });

    try {
      final currentTax =
          ref.read(settingsProvider).valueOrNull?.taxSettings ??
              const TaxSettings();
      final updated = currentTax.copyWith(
        clearOverrides: true,
        taxEnabled: currentTax.taxEnabled,
      );

      await ref
          .read(settingsControllerProvider.notifier)
          .updateTaxSettings(updated);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reset to Firebase Admin default rates'),
          backgroundColor: AppColors.moneyGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to reset rates: $e'),
          backgroundColor: AppColors.dangerRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _saveChanges() async {
    if (_isSaving) return;
    await HapticFeedback.lightImpact();
    setState(() => _isSaving = true);

    try {
      double? parsePercent(String text) {
        final val = double.tryParse(text.trim());
        if (val == null) return null;
        return val / 100.0;
      }

      double? parseRs(String text) {
        return double.tryParse(text.trim());
      }

      final currentTax =
          ref.read(settingsProvider).valueOrNull?.taxSettings ??
              const TaxSettings();

      final updated = TaxSettings(
        taxEnabled: currentTax.taxEnabled,
        cdcPerShare: parseRs(_cdcController.text),
        psxLagaRate: parsePercent(_psxLagaController.text),
        secpLagaRate: parsePercent(_secpLagaController.text),
        nccplRate: parsePercent(_nccplController.text),
        commissionRate: parsePercent(_commissionController.text),
        sstRate: parsePercent(_sstController.text),
        otherCharges: parseRs(_otherChargesController.text),
        cgtRate: parsePercent(_cgtController.text),
      );

      await ref
          .read(settingsControllerProvider.notifier)
          .updateTaxSettings(updated);

      if (!mounted) return;
      final results = await Connectivity().checkConnectivity();
      if (!mounted) return;
      final isOffline =
          results.contains(ConnectivityResult.none) || results.isEmpty;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isOffline
                ? "You're offline. Rates saved locally and will sync when online."
                : 'Broker charges and tax rates saved successfully',
          ),
          backgroundColor:
              isOffline ? AppColors.warningYellow : AppColors.moneyGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );

      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save tax rates: $e'),
          backgroundColor: AppColors.dangerRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF13151B) : Colors.white;
    final borderColor =
        isDark ? const Color(0xFF242731) : const Color(0xFFE2E8F0);
    final primaryTextColor = isDark ? Colors.white : AppColors.textPrimaryLight;

    final settings = ref.watch(settingsProvider).valueOrNull;
    final userTax = settings?.taxSettings ?? const TaxSettings();

    // Populate controllers once data is ready
    if (!_initialized && settings != null) {
      _populateFields();
      _initialized = true;
    }

    final adminRatesAsync = ref.watch(adminTaxRatesProvider);
    final admin = adminRatesAsync.valueOrNull ?? AdminTaxRates.psxDefaults;
    final hasCustomOverrides = userTax.hasCustomOverrides;

    return Scaffold(
      body: Column(
        children: [
          const CustomAppBar(
            title: 'Broker Rates & Taxes',
            showBackButton: true,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 16.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Guidance Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1A1D27)
                          : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: borderColor),
                    ),
                    child: Text(
                      'Configure your broker charges and tax rates below. These rates are automatically applied to calculate net profit on your trades. If you leave values as default, official PSX rates maintained by admin will apply.',
                      style: AppTypography.caption.copyWith(
                        color: isDark
                            ? const Color(0xFFB3B3B3)
                            : const Color(0xFF64748B),
                        height: 1.45,
                        fontSize: 12.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Admin status banner
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 11,
                    ),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: hasCustomOverrides
                            ? AppColors.brandIndigo.withOpacity(0.4)
                            : (isDark
                                ? AppColors.moneyGreen.withOpacity(0.35)
                                : AppColors.moneyGreenOnLight
                                    .withOpacity(0.35)),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          hasCustomOverrides
                              ? Icons.tune_rounded
                              : Icons.cloud_done_rounded,
                          size: 18,
                          color: hasCustomOverrides
                              ? AppColors.brandIndigo
                              : (isDark
                                  ? AppColors.moneyGreen
                                  : AppColors.moneyGreenOnLight),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            hasCustomOverrides
                                ? 'Custom Broker Rates Active (overriding admin defaults)'
                                : 'Synced with Firebase Admin PSX rates',
                            style: AppTypography.caption.copyWith(
                              color: primaryTextColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 12.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 22),
                  _buildSubSectionTitle(context, 'PER-SHARE CHARGES (RS)'),
                  const SizedBox(height: 8),
                  NumericInput(
                    label: 'CDC Fee (Rs per share)',
                    hint: 'Admin default: ${_formatNumber(admin.cdcPerShare)}',
                    controller: _cdcController,
                  ),

                  const SizedBox(height: 20),
                  _buildSubSectionTitle(
                    context,
                    'TRADE VALUE CHARGES & LEVIES (%)',
                  ),
                  const SizedBox(height: 8),
                  NumericInput(
                    label: 'PSX Laga (%)',
                    hint:
                        'Admin default: ${_formatNumber(admin.psxLagaRate * 100)}%',
                    controller: _psxLagaController,
                  ),
                  const SizedBox(height: 12),
                  NumericInput(
                    label: 'SECP Laga (%)',
                    hint:
                        'Admin default: ${_formatNumber(admin.secpLagaRate * 100)}%',
                    controller: _secpLagaController,
                  ),
                  const SizedBox(height: 12),
                  NumericInput(
                    label: 'NCCPL Charge (%)',
                    hint:
                        'Admin default: ${_formatNumber(admin.nccplRate * 100)}%',
                    controller: _nccplController,
                  ),
                  const SizedBox(height: 12),
                  NumericInput(
                    label: 'Broker Commission (%)',
                    hint:
                        'Admin default: ${_formatNumber(admin.commissionRate * 100)}%',
                    controller: _commissionController,
                  ),

                  const SizedBox(height: 20),
                  _buildSubSectionTitle(context, 'TAXES & OTHER FEES'),
                  const SizedBox(height: 8),
                  NumericInput(
                    label: 'SST on Commission (%)',
                    hint:
                        'Admin default: ${_formatNumber(admin.sstRate * 100)}%',
                    controller: _sstController,
                  ),
                  const SizedBox(height: 12),
                  NumericInput(
                    label: 'Other Fixed Fees (Rs)',
                    hint:
                        'Admin default: ${_formatNumber(admin.otherCharges)}',
                    controller: _otherChargesController,
                  ),
                  const SizedBox(height: 12),
                  NumericInput(
                    label: 'Capital Gains Tax (CGT %)',
                    hint:
                        'Admin default: ${_formatNumber(admin.cgtRate * 100)}%',
                    controller: _cgtController,
                  ),
                  const SizedBox(height: 6),
                  Padding(
                    padding: const EdgeInsets.only(left: 4.0),
                    child: Text(
                      'ℹ CGT only deducts when net trade profit is greater than Rs 0.',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.neutral500,
                        fontSize: 11.5,
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isSaving ? null : _resetToAdminDefaults,
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: borderColor),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          icon: const Icon(Icons.refresh_rounded, size: 18),
                          label: Text(
                            'Reset to Admin',
                            style: AppTypography.caption.copyWith(
                              color: primaryTextColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isSaving ? null : _saveChanges,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDark
                                ? AppColors.moneyGreen
                                : AppColors.moneyGreenOnLight,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            elevation: 0,
                          ),
                          icon: _isSaving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.check_rounded, size: 18),
                          label: Text(
                            _isSaving ? 'Saving...' : 'Save Rates',
                            style: AppTypography.caption.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: AppColors.neutral500,
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.1,
          ),
    );
  }
}
