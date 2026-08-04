import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:stock_investment_tracker/core/theme/app_colors.dart';
import 'package:stock_investment_tracker/core/theme/app_typography.dart';
import 'package:stock_investment_tracker/domain/entities/user_settings.dart';
import 'package:stock_investment_tracker/presentation/auth/controllers/auth_controller.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:stock_investment_tracker/presentation/auth/providers/auth_providers.dart';
import 'package:stock_investment_tracker/presentation/common/app_scaffold.dart';
import 'package:stock_investment_tracker/presentation/common/buttons.dart';
import 'package:stock_investment_tracker/presentation/common/inputs.dart';
import 'package:stock_investment_tracker/presentation/settings/providers/settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppSemanticColors>() ?? AppSemanticColors.dark;
    final user = ref.watch(authStateProvider).valueOrNull;
    final settingsAsync = ref.watch(settingsProvider);

    return AppScaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            title: Text('Settings', style: AppTypography.h1.copyWith(color: Colors.white, fontSize: 32)),
            backgroundColor: AppColors.deepSpaceBlack,
            expandedHeight: 120,
            pinned: true,
          ),
          settingsAsync.when(
            data: (settings) => SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle(context, 'FAVORITE STOCKS'),
                    const SizedBox(height: 12),
                    _buildFavoriteStocks(context, colors, ref, settings),
                    const SizedBox(height: 32),
                    
                    _buildSectionTitle(context, 'PORTFOLIO'),
                    const SizedBox(height: 12),
                    _buildPortfolioPreferences(context, colors, ref, settings),
                    const SizedBox(height: 32),
                    
                    _buildSectionTitle(context, 'APPEARANCE'),
                    const SizedBox(height: 12),
                    _buildAppearancePreferences(context, colors, ref, settings),
                    const SizedBox(height: 32),
                    
                    _buildSectionTitle(context, 'ACCOUNT'),
                    const SizedBox(height: 12),
                    _buildAccountSection(context, user, colors, ref),
                    const SizedBox(height: 100), // Bottom padding for navbar
                  ].animate(interval: 50.ms).fade(duration: 400.ms).slideY(begin: 0.05, duration: 400.ms, curve: Curves.easeOutQuad),
                ),
              ),
            ),
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator(color: AppColors.brandIndigo)),
            ),
            error: (err, stack) => const SliverFillRemaining(
              child: Center(child: Text('Error loading settings')),
            ),
          ),
        ],
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

  Widget _buildAccountSection(
      BuildContext context, User? user, AppSemanticColors colors, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.offBlack,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.neutral500.withOpacity(0.1)),
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
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
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
          Divider(height: 1, color: AppColors.neutral500.withOpacity(0.1)),
          InkWell(
            onTap: () => _confirmLogout(context, ref),
            borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(16), bottomRight: Radius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.logout, color: AppColors.alertRed, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Log Out',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColors.alertRed,
                          fontWeight: FontWeight.bold,
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

  Widget _buildFavoriteStocks(BuildContext context, AppSemanticColors colors, WidgetRef ref, UserSettings settings) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.offBlack,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.neutral500.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 12,
            children: [
              ...((settings.favorites as List<String>).map((ticker) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.deepSpaceBlack,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.circle, size: 8, color: AppColors.moneyGreen),
                        const SizedBox(width: 4),
                        const Icon(Icons.star, size: 12, color: AppColors.warningYellow),
                        const SizedBox(width: 6),
                        Text(ticker, style: const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(width: 6),
                        InkWell(
                          onTap: () => ref.read(settingsControllerProvider.notifier).removeFavorite(ticker),
                          child: const Icon(Icons.close, size: 14, color: AppColors.neutral500),
                        ),
                      ],
                    ),
                  ).animate(key: ValueKey(ticker)).fade(duration: 200.ms).scale(duration: 200.ms, begin: const Offset(0.8, 0.8)))),
              InkWell(
                onTap: () => _showAddTickerDialog(context, ref),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.brandIndigo.withOpacity(0.2),
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
            'Favorites feed the ticker picker in every Add Buy and Add Sell form — type once, select forever after.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.neutral500, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildPortfolioPreferences(BuildContext context, AppSemanticColors colors, WidgetRef ref, UserSettings settings) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.offBlack,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.neutral500.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Starting Capital', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 2),
                      Text('Baseline for free cash', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.neutral500)),
                    ],
                  ),
                ),
                Container(
                  width: 140,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.deepSpaceBlack,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 12.0),
                        child: Text(settings.currency == 'PKR' ? 'Rs' : '\$', style: const TextStyle(color: AppColors.neutral500)),
                      ),
                      Expanded(
                        child: _StartingCapitalInput(settings: settings, ref: ref),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: AppColors.neutral500.withOpacity(0.1)),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Currency', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppColors.deepSpaceBlack,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: settings.currency,
                      icon: const Icon(Icons.keyboard_arrow_down, size: 16, color: AppColors.neutral500),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      dropdownColor: AppColors.deepSpaceBlack,
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
        ],
      ),
    );
  }

  Widget _buildAppearancePreferences(BuildContext context, AppSemanticColors colors, WidgetRef ref, UserSettings settings) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.offBlack,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.neutral500.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Theme', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 2),
              Text('Dark is the default', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.neutral500)),
            ],
          ),
          Container(
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.deepSpaceBlack,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildThemeToggle(context, ref, 'dark', Icons.dark_mode, 'Dark', settings.themeMode == 'dark'),
                _buildThemeToggle(context, ref, 'light', Icons.light_mode, 'Light', settings.themeMode == 'light'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeToggle(BuildContext context, WidgetRef ref, String mode, IconData icon, String label, bool isSelected) {
    return InkWell(
      onTap: () => ref.read(settingsControllerProvider.notifier).updateThemeMode(mode),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.brandIndigo : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: isSelected ? Colors.white : AppColors.neutral500),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(color: isSelected ? Colors.white : AppColors.neutral500, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  void _showAddTickerDialog(BuildContext context, WidgetRef ref) {
    String ticker = '';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Favorite Stock'),
        content: TextField(
          autofocus: true,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(
            hintText: 'e.g. SYS',
          ),
          onChanged: (val) => ticker = val,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (ticker.trim().isNotEmpty) {
                ref.read(settingsControllerProvider.notifier).addFavorite(ticker.trim().toUpperCase());
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
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
      ref.read(authControllerProvider.notifier).signOut();
    }
  }
}

class _StartingCapitalInput extends StatefulWidget {
  final UserSettings settings;
  final WidgetRef ref;

  const _StartingCapitalInput({required this.settings, required this.ref});

  @override
  State<_StartingCapitalInput> createState() => _StartingCapitalInputState();
}

class _StartingCapitalInputState extends State<_StartingCapitalInput> {
  late TextEditingController _controller;
  bool _isDirty = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.settings.startingCapital.toString());
  }

  @override
  void didUpdateWidget(_StartingCapitalInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.settings.startingCapital != widget.settings.startingCapital && !_isDirty) {
      _controller.text = widget.settings.startingCapital.toString();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    final parsed = double.tryParse(_controller.text) ?? 0.0;
    if (parsed > 0) {
      widget.ref.read(settingsControllerProvider.notifier).updateStartingCapital(parsed);
      setState(() => _isDirty = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _controller,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 12),
              isDense: true,
            ),
            onChanged: (_) {
              if (!_isDirty) setState(() => _isDirty = true);
            },
            onSubmitted: (_) => _save(),
          ),
        ),
        if (_isDirty)
          IconButton(
            icon: const Icon(Icons.check_circle, color: AppColors.moneyGreen, size: 20),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: _save,
          )
        else
          const SizedBox(width: 20), // Placeholder to keep alignment
        const SizedBox(width: 8),
      ],
    );
  }
}
