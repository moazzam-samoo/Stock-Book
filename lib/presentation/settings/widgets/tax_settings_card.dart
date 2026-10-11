import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:stock_investment_tracker/core/theme/app_colors.dart';
import 'package:stock_investment_tracker/core/theme/app_typography.dart';
import 'package:stock_investment_tracker/domain/entities/user_settings.dart';
import 'package:stock_investment_tracker/presentation/settings/providers/settings_provider.dart';

/// Compact Broker Charges & Taxes card on [SettingsScreen].
/// Features a master On/Off switch, and when enabled, presents a sleek
/// navigation button to open [BrokerTaxSettingsScreen].
class TaxSettingsCard extends ConsumerStatefulWidget {
  final UserSettings settings;
  final bool isDark;

  const TaxSettingsCard({
    super.key,
    required this.settings,
    required this.isDark,
  });

  @override
  ConsumerState<TaxSettingsCard> createState() => _TaxSettingsCardState();
}

class _TaxSettingsCardState extends ConsumerState<TaxSettingsCard> {
  late bool _taxEnabled;

  @override
  void initState() {
    super.initState();
    _taxEnabled = widget.settings.taxSettings.taxEnabled;
  }

  @override
  void didUpdateWidget(covariant TaxSettingsCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.settings.taxSettings.taxEnabled !=
        widget.settings.taxSettings.taxEnabled) {
      _taxEnabled = widget.settings.taxSettings.taxEnabled;
    }
  }

  Future<void> _toggleMasterSwitch(bool value) async {
    await HapticFeedback.lightImpact();
    setState(() => _taxEnabled = value);

    final current = widget.settings.taxSettings;
    final updated = current.copyWith(taxEnabled: value);

    try {
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
            value
                ? 'Broker charges and taxes enabled'
                : 'Broker charges and taxes disabled',
          ),
          backgroundColor: isOffline
              ? AppColors.warningYellow
              : (value
                  ? AppColors.moneyGreen
                  : (widget.isDark
                      ? const Color(0xFF242731)
                      : AppColors.neutral500)),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update tax settings: $e'),
          backgroundColor: AppColors.dangerRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final cardBg = isDark ? const Color(0xFF13151B) : Colors.white;
    final borderColor =
        isDark ? const Color(0xFF242731) : const Color(0xFFE2E8F0);
    final primaryTextColor = isDark ? Colors.white : AppColors.textPrimaryLight;

    final taxSettings = widget.settings.taxSettings;
    final hasCustomOverrides = taxSettings.hasCustomOverrides;

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                )
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Master switch row
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: _taxEnabled
                        ? (isDark
                            ? AppColors.moneyGreen.withOpacity(0.15)
                            : AppColors.moneyGreenOnLight.withOpacity(0.12))
                        : (isDark
                            ? Colors.white.withOpacity(0.05)
                            : Colors.black.withOpacity(0.04)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Icon(
                      FontAwesomeIcons.receipt.data,
                      size: 17,
                      color: _taxEnabled
                          ? (isDark
                              ? AppColors.moneyGreen
                              : AppColors.moneyGreenOnLight)
                          : AppColors.neutral500,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Apply Broker Charges & Taxes',
                        style: AppTypography.body.copyWith(
                          color: primaryTextColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Deducts PSX fees & taxes from realized profit',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.neutral500,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch.adaptive(
                  value: _taxEnabled,
                  onChanged: _toggleMasterSwitch,
                  activeColor: isDark
                      ? AppColors.moneyGreen
                      : AppColors.moneyGreenOnLight,
                ),
              ],
            ),
          ),

          // Navigation button revealed when enabled
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Column(
              children: [
                Divider(color: borderColor, height: 1),
                InkWell(
                  onTap: () async {
                    await HapticFeedback.lightImpact();
                    if (context.mounted) {
                      await context.push('/tax-settings');
                    }
                  },
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 14.0,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF1E222D)
                                : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.tune_rounded,
                            size: 16,
                            color: isDark
                                ? Colors.white70
                                : const Color(0xFF4A5568),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Configure Rates & Taxes',
                                style: AppTypography.body.copyWith(
                                  color: primaryTextColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                hasCustomOverrides
                                    ? 'Custom broker rates active'
                                    : 'Using admin PSX defaults',
                                style: AppTypography.caption.copyWith(
                                  color: hasCustomOverrides
                                      ? AppColors.brandIndigo
                                      : AppColors.neutral500,
                                  fontSize: 11.5,
                                  fontWeight: hasCustomOverrides
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 13,
                          color: AppColors.neutral500,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            crossFadeState: _taxEnabled
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 220),
          ),
        ],
      ),
    );
  }
}
