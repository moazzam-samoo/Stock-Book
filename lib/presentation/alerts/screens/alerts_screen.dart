import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:stock_investment_tracker/core/theme/app_colors.dart';
import 'package:stock_investment_tracker/presentation/alerts/providers/alerts_providers.dart';
import 'package:stock_investment_tracker/presentation/alerts/widgets/add_alert_bottom_sheet.dart';
import 'package:stock_investment_tracker/presentation/alerts/widgets/alert_row.dart';
import 'package:stock_investment_tracker/presentation/common/app_scaffold.dart';
import 'package:stock_investment_tracker/presentation/common/custom_app_bar.dart';
import 'package:stock_investment_tracker/presentation/common/empty_state_view.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

class AlertsScreen extends ConsumerWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alertsAsync = ref.watch(allAlertsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          context.go('/');
        }
      },
      child: AppScaffold(
        // Matches Transactions' own add button exactly — same shape, color,
        // position — rather than an app-bar icon, so "add" looks and behaves
        // identically everywhere in the app.
        floatingActionButton: Padding(
          padding: const EdgeInsets.only(bottom: 114.0),
          child: FloatingActionButton(
            shape: const CircleBorder(),
            backgroundColor: isDark
                ? AppColors.moneyGreen.withOpacity(0.7)
                : AppColors.moneyGreenOnLight.withOpacity(0.85),
            elevation: 4,
            onPressed: () {
              HapticFeedback.lightImpact();
              AddAlertBottomSheet.show(context);
            },
            child: const Icon(Icons.add, color: Colors.white, size: 28),
          ),
        ),
        body: Column(
          children: [
            CustomAppBar(
              title: 'Buy Alerts',
              subtitle: 'Notified when a target price hits',
              icon: FontAwesomeIcons.bell.data,
              iconBadgeColor: const Color(0xFF584BF6),
            ),
            Expanded(
              child: alertsAsync.when(
                data: (alerts) {
                  if (alerts.isEmpty) {
                    return const EmptyStateView(
                      icon: Icons.notifications_none_rounded,
                      title: 'No Active Alerts',
                      message: 'Set target prices for stocks you want to buy, and get notified when they drop.',
                    );
                  }

                  return AnimationLimiter(
                    child: ListView.builder(
                      padding: const EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 120),
                      itemCount: alerts.length,
                      itemBuilder: (context, index) {
                        return AnimationConfiguration.staggeredList(
                          position: index,
                          duration: const Duration(milliseconds: 375),
                          child: SlideAnimation(
                            verticalOffset: 50.0,
                            child: FadeInAnimation(
                              child: AlertRow(alert: alerts[index]),
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(color: Color(0xFF584BF6)),
                ),
                error: (error, stack) => Center(
                  child: Text('Error loading alerts', style: TextStyle(color: AppColors.dangerRed)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
