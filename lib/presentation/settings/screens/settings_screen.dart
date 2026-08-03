import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:stock_investment_tracker/core/theme/app_colors.dart';
import 'package:stock_investment_tracker/domain/entities/user_settings.dart';
import 'package:stock_investment_tracker/presentation/auth/controllers/auth_controller.dart';
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
    final currentUid = ref.watch(currentUserIdProvider);
    final settingsAsync = ref.watch(settingsProvider);

    return AppScaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            title: const Text('Settings'),
            floating: true,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          ),
          settingsAsync.when(
            data: (settings) => SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle(context, 'Account'),
                    const SizedBox(height: 16),
                    _buildAccountSection(context, currentUid, colors, ref),
                    const SizedBox(height: 32),
                    
                    _buildSectionTitle(context, 'Portfolio Preferences'),
                    const SizedBox(height: 16),
                    _buildPortfolioPreferences(context, colors, ref, settings),
                    const SizedBox(height: 32),
                    
                    _buildSectionTitle(context, 'App Appearance'),
                    const SizedBox(height: 16),
                    _buildAppearancePreferences(context, colors, ref, settings),
                  ].animate(interval: 50.ms).fade(duration: 400.ms).slideY(begin: 0.05, duration: 400.ms, curve: Curves.easeOutQuad),
                ),
              ),
            ),
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
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
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
    );
  }

  Widget _buildAccountSection(
      BuildContext context, String? uid, AppSemanticColors colors, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: colors.success,
                child: const Icon(Icons.person, color: Colors.white),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      uid ?? 'Guest User',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      uid != null ? 'Logged In' : 'Not signed in',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).textTheme.bodySmall?.color,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: SecondaryButton(
              onPressed: () => _confirmLogout(context, ref),
              label: 'Sign Out',
              icon: Icons.logout,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPortfolioPreferences(BuildContext context, AppSemanticColors colors, WidgetRef ref, UserSettings settings) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Starting Capital'),
          const SizedBox(height: 8),
          NumericInput(
            hint: settings.startingCapital.toString(),
            initialValue: settings.startingCapital.toString(),
            onChanged: (val) {
              final parsed = double.tryParse(val) ?? 0.0;
              if (parsed > 0) {
                ref.read(settingsControllerProvider.notifier).updateStartingCapital(parsed);
              }
            },
          ),
          const SizedBox(height: 16),
          const Text('Currency'),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: settings.currency,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            items: const [
              DropdownMenuItem(value: 'PKR', child: Text('PKR - Pakistani Rupee')),
              DropdownMenuItem(value: 'USD', child: Text('USD - US Dollar')),
            ],
            onChanged: (val) {
              if (val != null) {
                ref.read(settingsControllerProvider.notifier).updateCurrency(val);
              }
            },
          ),
          const SizedBox(height: 16),
          const Text('Favorite Stocks'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ...((settings.favorites as List<String>).map((ticker) => Chip(
                    label: Text(ticker),
                    onDeleted: () {
                      ref.read(settingsControllerProvider.notifier).removeFavorite(ticker);
                    },
                  ).animate(key: ValueKey(ticker)).fade(duration: 200.ms).scale(duration: 200.ms, begin: const Offset(0.8, 0.8)))),
              ActionChip(
                label: const Text('Add Ticker'),
                avatar: const Icon(Icons.add, size: 16),
                onPressed: () {
                  _showAddTickerDialog(context, ref);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAppearancePreferences(BuildContext context, AppSemanticColors colors, WidgetRef ref, UserSettings settings) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Theme'),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'dark', label: Text('Dark'), icon: Icon(Icons.dark_mode, size: 16)),
              ButtonSegment(value: 'light', label: Text('Light'), icon: Icon(Icons.light_mode, size: 16)),
            ],
            selected: {settings.themeMode as String},
            onSelectionChanged: (set) {
              if (set.isNotEmpty) {
                ref.read(settingsControllerProvider.notifier).updateThemeMode(set.first);
              }
            },
          ),
        ],
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
      ref.read(mockAuthNotifierProvider.notifier).state = false;
      ref.read(authControllerProvider.notifier).signOut();
    }
  }
}
