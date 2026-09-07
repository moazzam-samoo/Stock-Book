import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:stock_investment_tracker/core/services/data_export_service.dart';
import 'package:stock_investment_tracker/core/theme/app_colors.dart';
import 'package:stock_investment_tracker/core/theme/app_typography.dart';
import 'package:stock_investment_tracker/providers/workflow_trigger_providers.dart';
import 'package:stock_investment_tracker/core/utils/currency_formatter.dart';
import 'package:stock_investment_tracker/core/utils/stock_color_utils.dart';
import 'package:stock_investment_tracker/domain/entities/user_settings.dart';
import 'package:stock_investment_tracker/presentation/auth/controllers/auth_controller.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:stock_investment_tracker/presentation/auth/providers/auth_providers.dart';
import 'package:stock_investment_tracker/presentation/common/app_scaffold.dart';
import 'package:stock_investment_tracker/presentation/common/custom_app_bar.dart';
import 'package:stock_investment_tracker/presentation/common/stock_color_picker_bottom_sheet.dart';
import 'package:stock_investment_tracker/presentation/dashboard/providers/dashboard_providers.dart';
import 'package:stock_investment_tracker/presentation/settings/providers/settings_provider.dart';
import 'package:stock_investment_tracker/presentation/settings/widgets/withdrawal_bottom_sheet.dart';
import 'package:stock_investment_tracker/presentation/settings/widgets/withdrawal_row.dart';
import 'package:stock_investment_tracker/presentation/transactions/widgets/ticker_autocomplete.dart';
import 'package:stock_investment_tracker/providers/package_info_providers.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppSemanticColors>() ?? AppSemanticColors.dark;
    final user = ref.watch(authStateProvider).valueOrNull;
    final settingsAsync = ref.watch(settingsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          context.go('/');
        }
      },
      child: AppScaffold(
        body: Column(
          children: [
            CustomAppBar(
              title: 'Settings',
              subtitle: 'App preferences & account',
              icon: FontAwesomeIcons.gear.data,
              iconBadgeColor: isDark ? AppColors.moneyGreen : AppColors.moneyGreenOnLight,
            ),
            Expanded(
              child: settingsAsync.when(
                data: (settings) => SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle(context, 'FAVORITE STOCKS'),
                      const SizedBox(height: 12),
                      _buildFavoriteStocks(context, colors, ref, settings, isDark),
                      const SizedBox(height: 28),

                      _buildSectionTitle(context, 'PORTFOLIO'),
                      const SizedBox(height: 12),
                      _buildPortfolioPreferences(context, colors, ref, settings, isDark),
                      const SizedBox(height: 28),

                      _buildSectionTitle(context, 'PROFIT WITHDRAWALS'),
                      const SizedBox(height: 12),
                      _buildWithdrawalsSection(context, ref, isDark),
                      const SizedBox(height: 28),

                      _buildSectionTitle(context, 'PRICE REFRESH'),
                      const SizedBox(height: 12),
                      _buildPriceRefreshSection(context, ref, isDark),
                      const SizedBox(height: 28),

                      _buildSectionTitle(context, 'ABOUT US'),
                      const SizedBox(height: 12),
                      _buildCompanyOwnersNavCard(context, isDark),
                      const SizedBox(height: 12),
                      _buildVersionLabel(ref, isDark),
                      const SizedBox(height: 28),

                      _buildSectionTitle(context, 'ACCOUNT'),
                      const SizedBox(height: 12),
                      _buildAccountSection(context, user, colors, ref, isDark),
                      const SizedBox(height: 100), // Bottom padding for navbar
                    ].animate(interval: 50.ms).fade(duration: 400.ms).slideY(begin: 0.05, duration: 400.ms, curve: Curves.easeOutQuad),
                  ),
                ),
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.brandIndigo),
                ),
                error: (err, stack) => const Center(
                  child: Text('Error loading settings'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.neutral500,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
      ),
    );
  }

  Widget _buildFavoriteStocks(BuildContext context, AppSemanticColors colors, WidgetRef ref, UserSettings settings, bool isDark) {
    final cardBg = isDark ? const Color(0xFF13151B) : Colors.white;
    final chipBg = isDark ? const Color(0xFF1E222D) : const Color(0xFFF1F5F9);
    final borderColor = isDark ? const Color(0xFF242731) : const Color(0xFFE2E8F0);
    final primaryTextColor = isDark ? Colors.white : AppColors.textPrimaryLight;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: isDark ? null : [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 12,
            children: [
              ...(settings.favorites.map((ticker) {
                final customColorVal = settings.stockColors[ticker.toUpperCase().trim()];
                final avatarColor = customColorVal != null ? Color(customColorVal) : StockColorUtils.getColorForTicker(ticker);

                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: chipBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: () => StockColorPickerBottomSheet.show(context, ticker),
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: avatarColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white.withOpacity(0.4), width: 1),
                          ),
                          child: const Icon(Icons.palette_outlined, size: 10, color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(ticker, style: TextStyle(fontWeight: FontWeight.bold, color: primaryTextColor)),
                      const SizedBox(width: 6),
                      InkWell(
                        onTap: () async {
                          await ref.read(settingsControllerProvider.notifier).removeFavorite(ticker);
                          ref.invalidate(settingsProvider);
                        },
                        child: const Icon(Icons.close, size: 14, color: AppColors.neutral500),
                      ),
                    ],
                  ),
                ).animate(key: ValueKey(ticker)).fade(duration: 200.ms).scale(duration: 200.ms, begin: const Offset(0.8, 0.8));
              })),
              InkWell(
                onTap: () => _showAddTickerDialog(context),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.brandIndigo.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.add, size: 16, color: AppColors.brandIndigo),
                      const SizedBox(width: 4),
                      Text('Add', style: TextStyle(color: AppColors.brandIndigo, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Tap the color dot on any stock chip (or long-press any avatar) to customize its display color.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.neutral500, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildPortfolioPreferences(BuildContext context, AppSemanticColors colors, WidgetRef ref, UserSettings settings, bool isDark) {
    final cardBg = isDark ? const Color(0xFF13151B) : Colors.white;
    final inputBg = isDark ? const Color(0xFF1E222D) : const Color(0xFFF1F5F9);
    final borderColor = isDark ? const Color(0xFF242731) : const Color(0xFFE2E8F0);
    final primaryTextColor = isDark ? Colors.white : AppColors.textPrimaryLight;

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: isDark ? null : [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isSmallScreen = constraints.maxWidth < 360;
                
                final labelWidget = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Starting Capital', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: primaryTextColor)),
                    const SizedBox(height: 2),
                    Text('Baseline for free cash', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.neutral500)),
                  ],
                );
                
                final inputWidget = Container(
                  decoration: BoxDecoration(
                    color: inputBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 48,
                        padding: const EdgeInsets.only(left: 12.0),
                        alignment: Alignment.centerLeft,
                        child: Text(settings.currency == 'PKR' ? 'Rs' : '\$', style: const TextStyle(color: AppColors.neutral500)),
                      ),
                      Expanded(
                        child: _StartingCapitalInput(settings: settings, ref: ref, isDark: isDark),
                      ),
                    ],
                  ),
                );

                if (isSmallScreen) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      labelWidget,
                      const SizedBox(height: 12),
                      inputWidget,
                    ],
                  );
                }

                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: labelWidget),
                    const SizedBox(width: 16),
                    Flexible(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minWidth: 120, maxWidth: 220),
                        child: inputWidget,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          Divider(height: 1, color: borderColor),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Currency', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: primaryTextColor)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: inputBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: settings.currency,
                      icon: const Icon(Icons.keyboard_arrow_down, size: 16, color: AppColors.neutral500),
                      style: TextStyle(color: primaryTextColor, fontWeight: FontWeight.bold),
                      dropdownColor: inputBg,
                      items: const [
                        DropdownMenuItem(value: 'PKR', child: Text('PKR')),
                        DropdownMenuItem(value: 'USD', child: Text('USD')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          ref.read(settingsControllerProvider.notifier).updateCurrency(val);
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: borderColor),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Theme', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: primaryTextColor)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: inputBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: settings.themeMode,
                      icon: const Icon(Icons.keyboard_arrow_down, size: 16, color: AppColors.neutral500),
                      style: TextStyle(color: primaryTextColor, fontWeight: FontWeight.bold),
                      dropdownColor: inputBg,
                      items: const [
                        DropdownMenuItem(value: 'dark', child: Text('Dark')),
                        DropdownMenuItem(value: 'light', child: Text('Light')),
                        DropdownMenuItem(value: 'system', child: Text('System')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          ref.read(settingsControllerProvider.notifier).updateThemeMode(val);
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWithdrawalsSection(BuildContext context, WidgetRef ref, bool isDark) {
    final cardBg = isDark ? const Color(0xFF13151B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF242731) : const Color(0xFFE2E8F0);
    final primaryTextColor = isDark ? Colors.white : AppColors.textPrimaryLight;

    final withdrawals = ref.watch(allWithdrawalsProvider).valueOrNull ?? [];
    final summary = ref.watch(portfolioSummaryProvider);

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: isDark ? null : [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: total withdrawn + remaining profit
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Total Withdrawn', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: primaryTextColor)),
                      const SizedBox(height: 2),
                      Text(
                        withdrawals.isEmpty
                            ? 'No withdrawals yet'
                            : '${withdrawals.length} withdrawal${withdrawals.length == 1 ? '' : 's'} · ${AppCurrencyFormatter.format(summary.grossRealizedPL)} profit earned',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.neutral500),
                      ),
                    ],
                  ),
                ),
                Text(
                  AppCurrencyFormatter.format(summary.totalWithdrawn),
                  style: TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    color: summary.totalWithdrawn > 0 ? AppColors.warningYellow : primaryTextColor,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: borderColor),

          if (withdrawals.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
              child: Column(
                children: withdrawals.map((w) => WithdrawalRow(withdrawal: w)).toList(),
              ),
            ),

          Padding(
            padding: EdgeInsets.fromLTRB(16, withdrawals.isEmpty ? 16 : 6, 16, 16),
            child: SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton.icon(
                onPressed: () => WithdrawalBottomSheet.show(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? const Color(0xFF2A2416) : const Color(0xFFFEF9E7),
                  foregroundColor: AppColors.warningYellow,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.north_east_rounded, size: 18, color: AppColors.warningYellow),
                label: const Text(
                  'Add Withdrawal',
                  style: TextStyle(color: AppColors.warningYellow, fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Lets the user supply their own GitHub token so pull-to-refresh can ask
  /// the backend to run immediately instead of waiting for its 5-minute
  /// schedule (which is also idle outside market hours and at weekends).
  ///
  /// The token is stored only in the device keystore — it is never committed
  /// and never built into the app, which is the whole reason it's entered
  /// here rather than shipped as a constant.
  Widget _buildPriceRefreshSection(BuildContext context, WidgetRef ref, bool isDark) {
    final cardBg = isDark ? const Color(0xFF13151B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF242731) : const Color(0xFFE2E8F0);
    final primaryTextColor = isDark ? Colors.white : AppColors.textPrimaryLight;
    final hasTokenAsync = ref.watch(hasGithubTokenProvider);
    final hasToken = hasTokenAsync.valueOrNull ?? false;

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: isDark
            ? null
            : [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  hasToken ? Icons.cloud_done_outlined : Icons.cloud_off_outlined,
                  size: 20,
                  color: hasToken
                      ? (isDark ? AppColors.chartGreen : AppColors.moneyGreenOnLight)
                      : AppColors.neutral500,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    hasToken ? 'On-demand refresh enabled' : 'On-demand refresh off',
                    style: AppTypography.body.copyWith(
                      color: primaryTextColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              hasToken
                  ? 'Pull down on Transactions to fetch prices right away. Prices also refresh automatically every 5 minutes while the market is open.'
                  : 'Prices refresh automatically every 5 minutes while the market is open. Add a GitHub token to also refresh on demand by pulling down on Transactions.',
              style: AppTypography.caption.copyWith(color: AppColors.neutral500, fontSize: 13),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showGithubTokenDialog(context, ref),
                    icon: const Icon(Icons.key_outlined, size: 18),
                    label: Text(hasToken ? 'Replace token' : 'Add token'),
                  ),
                ),
                if (hasToken) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final messenger = ScaffoldMessenger.of(context);
                        final result = await ref.read(triggerWorkflowProvider)();
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(result.message),
                            backgroundColor:
                                result.isSuccess ? AppColors.moneyGreenOnLight : AppColors.dangerRed,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      icon: const Icon(Icons.play_arrow_outlined, size: 18),
                      label: const Text('Test'),
                    ),
                  ),
                ],
              ],
            ),
            if (hasToken)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () async {
                    await ref.read(secureTokenStorageProvider).deleteGithubToken();
                    ref.invalidate(hasGithubTokenProvider);
                  },
                  child: const Text('Remove token', style: TextStyle(color: AppColors.dangerRed)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showGithubTokenDialog(BuildContext context, WidgetRef ref) {
    var token = '';
    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('GitHub token'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Create a fine-grained token on GitHub with access to only the '
              'Stock-Book repository, and only the "Actions" permission set to '
              'read and write. Paste it below.\n\n'
              'It is stored encrypted on this device only — never uploaded, and '
              'never included in the app itself.',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              autofocus: true,
              obscureText: true,
              decoration: const InputDecoration(
                hintText: 'github_pat_...',
                border: OutlineInputBorder(),
              ),
              onChanged: (val) => token = val,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final trimmed = token.trim();
              if (trimmed.isEmpty) return;
              Navigator.pop(dialogCtx);
              await ref.read(secureTokenStorageProvider).writeGithubToken(trimmed);
              ref.invalidate(hasGithubTokenProvider);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _buildCompanyOwnersNavCard(BuildContext context, bool isDark) {
    final cardBg = isDark ? const Color(0xFF13151B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF242731) : const Color(0xFFE2E8F0);
    final primaryTextColor = isDark ? Colors.white : AppColors.textPrimaryLight;

    return InkWell(
      onTap: () => context.push('/company'),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
          boxShadow: isDark ? null : [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 2))],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                'assets/icon/android-chrome-192x192.png',
                width: 44,
                height: 44,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.brandIndigo,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.business_rounded, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Company & Owners',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: primaryTextColor),
                  ),
                  const Text(
                    'Coding District, the team behind Stock Book',
                    style: TextStyle(fontSize: 11, color: AppColors.neutral500),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: AppColors.neutral500),
          ],
        ),
      ),
    );
  }

  Widget _buildVersionLabel(WidgetRef ref, bool isDark) {
    final packageInfo = ref.watch(packageInfoProvider);
    return Center(
      child: Text(
        packageInfo.when(
          data: (info) => 'Version ${info.version} (${info.buildNumber})',
          loading: () => '',
          error: (_, __) => '',
        ),
        style: TextStyle(
          fontSize: 11,
          color: isDark ? AppColors.neutral500 : AppColors.textSecondaryLight,
        ),
      ),
    );
  }

  Widget _buildAccountSection(
      BuildContext context, User? user, AppSemanticColors colors, WidgetRef ref, bool isDark) {
    final cardBg = isDark ? const Color(0xFF13151B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF242731) : const Color(0xFFE2E8F0);
    final primaryTextColor = isDark ? Colors.white : AppColors.textPrimaryLight;

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: isDark ? null : [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                user?.photoURL != null
                    ? CircleAvatar(
                        radius: 24,
                        backgroundImage: NetworkImage(user!.photoURL!),
                      )
                    : CircleAvatar(
                        radius: 24,
                        backgroundColor: AppColors.brandIndigo,
                        child: Text(
                          user?.email?.isNotEmpty == true ? user!.email![0].toUpperCase() : 'U',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                      ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.email ?? 'Guest User',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: primaryTextColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Synced across all devices',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.neutral500),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: borderColor),
          InkWell(
            onTap: () => _exportData(context, ref),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.file_download_outlined, color: AppColors.brandIndigo, size: 20),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Export data (JSON)',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: primaryTextColor,
                            fontWeight: FontWeight.bold,
                          ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Divider(height: 1, color: borderColor),
          InkWell(
            onTap: () => _confirmLogout(context, ref),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.logout, color: AppColors.alertRed, size: 20),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Log Out',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppColors.alertRed,
                            fontWeight: FontWeight.bold,
                          ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Divider(height: 1, color: borderColor),
          InkWell(
            onTap: () => _confirmDeleteAccount(context, ref),
            borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(16), bottomRight: Radius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.delete_forever_outlined, color: AppColors.alertRed, size: 20),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Delete Account',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppColors.alertRed,
                            fontWeight: FontWeight.bold,
                          ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddTickerDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const _AddFavoriteDialog(),
    );
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.alertRed),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (result == true) {
      await ref.read(authControllerProvider.notifier).signOut();
    }
  }

  Future<void> _confirmDeleteAccount(BuildContext context, WidgetRef ref) async {
    final firstConfirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account?'),
        content: const Text(
          'This permanently deletes your account and everything in it — every position, '
          'price alert, and withdrawal record. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.alertRed),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
    if (firstConfirm != true || !context.mounted) return;

    final typedConfirm = await showDialog<bool>(
      context: context,
      builder: (context) => const _DeleteAccountTypeToConfirmDialog(),
    );
    if (typedConfirm != true || !context.mounted) return;

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    unawaited(showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    ));

    try {
      await ref.read(authControllerProvider.notifier).deleteAccount();
      final error = ref.read(authControllerProvider).error;
      if (context.mounted) Navigator.pop(context); // close the spinner
      if (error != null) {
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('Could not delete account: $error')),
        );
      }
      // On success the auth state stream emits null and the router
      // redirects to sign-in on its own — no manual navigation needed here.
    } catch (e) {
      if (context.mounted) Navigator.pop(context);
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Could not delete account: $e')),
      );
    }
  }

  Future<void> _exportData(BuildContext context, WidgetRef ref) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    
    try {
      final lots = ref.read(allLotsProvider).valueOrNull ?? [];
      final withdrawals = ref.read(allWithdrawalsProvider).valueOrNull ?? [];
      final settings = ref.read(settingsProvider).valueOrNull;
      
      if (settings == null) {
        throw Exception("Settings not loaded.");
      }

      final jsonString = await DataExportService.buildExportJson(
        lots: lots,
        withdrawals: withdrawals,
        settings: settings,
      );

      final date = DateTime.now().toIso8601String().split('T').first;
      final filename = 'stock-book-backup-$date.json';

      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile.fromData(
              utf8.encode(jsonString),
              mimeType: 'application/json',
              name: filename,
            ),
          ],
          fileNameOverrides: [filename],
        ),
      );

      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('Export successful.'),
          backgroundColor: AppColors.moneyGreen,
        ),
      );
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Export failed: $e'),
          backgroundColor: AppColors.alertRed,
        ),
      );
    }
  }
}

class _AddFavoriteDialog extends ConsumerStatefulWidget {
  const _AddFavoriteDialog();

  @override
  ConsumerState<_AddFavoriteDialog> createState() => _AddFavoriteDialogState();
}

class _AddFavoriteDialogState extends ConsumerState<_AddFavoriteDialog> {
  final _tickerController = TextEditingController();
  final _tickerFocusNode = FocusNode();
  String _ticker = '';

  @override
  void dispose() {
    _tickerController.dispose();
    _tickerFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Favorite Stock'),
      // Same search-by-symbol-or-company-name mechanism as Add Buy/Add
      // Alert, instead of a plain text field with no suggestions — this
      // is the only way a user finds a stock's real ticker without
      // already knowing it.
      content: TickerAutocomplete(
        controller: _tickerController,
        focusNode: _tickerFocusNode,
        onSelected: (val) {
          setState(() {
            _ticker = val.trim().toUpperCase();
          });
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () async {
            final cleanTicker = _ticker.trim().toUpperCase();
            if (cleanTicker.isNotEmpty) {
              Navigator.pop(context);
              await ref.read(settingsControllerProvider.notifier).addFavorite(cleanTicker);
              ref.invalidate(settingsProvider);
            }
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}

class _StartingCapitalInput extends StatefulWidget {
  final UserSettings settings;
  final WidgetRef ref;
  final bool isDark;

  const _StartingCapitalInput({required this.settings, required this.ref, required this.isDark});

  @override
  State<_StartingCapitalInput> createState() => _StartingCapitalInputState();
}

class _StartingCapitalInputState extends State<_StartingCapitalInput> {
  late TextEditingController _controller;
  bool _isDirty = false;
  String? _errorText;
  final _formatter = NumberFormat('#,##0');

  String _formatValue(num value) {
    if (value == 0) return '0';
    return _formatter.format(value);
  }

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _formatValue(widget.settings.startingCapital));
  }

  @override
  void didUpdateWidget(_StartingCapitalInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.settings.startingCapital != widget.settings.startingCapital && !_isDirty) {
      _controller.text = _formatValue(widget.settings.startingCapital);
      _errorText = null;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    final raw = _controller.text.replaceAll(',', '').trim();
    final parsed = double.tryParse(raw);
    
    if (parsed == null || parsed < 0) {
      setState(() {
        _errorText = 'Invalid amount';
      });
      return;
    }

    setState(() {
      _errorText = null;
      _isDirty = false;
    });

    widget.ref.read(settingsControllerProvider.notifier).updateStartingCapital(parsed);
    widget.ref.invalidate(settingsProvider);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Starting capital updated successfully'),
        backgroundColor: AppColors.moneyGreen,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textColor = widget.isDark ? Colors.white : AppColors.textPrimaryLight;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 48,
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
                  keyboardType: const TextInputType.numberWithOptions(decimal: false),
                  inputFormatters: [
                    ThousandsSeparatorInputFormatter(),
                  ],
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12),
                    isDense: true,
                  ),
                  onChanged: (_) {
                    if (!_isDirty) setState(() => _isDirty = true);
                    if (_errorText != null) setState(() => _errorText = null);
                  },
                  onSubmitted: (_) => _save(),
                ),
              ),
              SizedBox(
                width: 40,
                child: _isDirty
                    ? IconButton(
                        icon: const Icon(Icons.check_circle, color: AppColors.moneyGreen, size: 20),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: _save,
                      )
                    : const SizedBox(),
              ),
            ],
          ),
        ),
        if (_errorText != null)
          Padding(
            padding: const EdgeInsets.only(left: 12.0, bottom: 4.0),
            child: Text(
              _errorText!,
              style: const TextStyle(color: AppColors.alertRed, fontSize: 11),
            ),
          ),
      ],
    );
  }
}

class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  static const int _maxDigits = 12;

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    // Only allow digits and commas
    final validCharacters = RegExp(r'^[0-9,]*$');
    if (!validCharacters.hasMatch(newValue.text)) {
      return oldValue;
    }

    String rawNewValue = newValue.text.replaceAll(',', '');
    if (rawNewValue.length > _maxDigits) {
      rawNewValue = rawNewValue.substring(0, _maxDigits);
    }

    final intValue = int.tryParse(rawNewValue);
    if (intValue == null) {
      return oldValue;
    }

    final formatter = NumberFormat('#,##0');
    final newString = formatter.format(intValue);

    int rawCursorPosition = 0;
    for (int i = 0; i < newValue.selection.end; i++) {
      if (i < newValue.text.length && newValue.text[i] != ',') {
        rawCursorPosition++;
      }
    }
    
    int newCursorPosition = 0;
    int rawCount = 0;
    for (int i = 0; i < newString.length; i++) {
      if (rawCount == rawCursorPosition) {
        newCursorPosition = i;
        break;
      }
      if (newString[i] != ',') {
        rawCount++;
      }
    }
    if (rawCount == rawCursorPosition) {
        newCursorPosition = newString.length;
    }

    return TextEditingValue(
      text: newString,
      selection: TextSelection.collapsed(offset: newCursorPosition),
    );
  }
}

/// Second, harder confirmation step for account deletion — typing the exact
/// word beats a second tap-through dialog, since a destructive action this
/// permanent deserves more friction than the same "yes/no" pattern used for
/// merely signing out.
class _DeleteAccountTypeToConfirmDialog extends StatefulWidget {
  const _DeleteAccountTypeToConfirmDialog();

  @override
  State<_DeleteAccountTypeToConfirmDialog> createState() =>
      _DeleteAccountTypeToConfirmDialogState();
}

class _DeleteAccountTypeToConfirmDialogState
    extends State<_DeleteAccountTypeToConfirmDialog> {
  static const _confirmWord = 'DELETE';
  final _controller = TextEditingController();
  bool _isMatch = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Are you absolutely sure?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Type $_confirmWord to permanently delete your account.'),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            autofocus: true,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(border: OutlineInputBorder()),
            onChanged: (value) => setState(() {
              _isMatch = value.trim() == _confirmWord;
            }),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _isMatch ? () => Navigator.pop(context, true) : null,
          style: TextButton.styleFrom(foregroundColor: AppColors.alertRed),
          child: const Text('Delete Permanently'),
        ),
      ],
    );
  }
}
