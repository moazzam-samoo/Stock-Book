import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stock_investment_tracker/core/theme/app_colors.dart';
import 'package:stock_investment_tracker/core/theme/app_spacing.dart';
import 'package:stock_investment_tracker/core/theme/app_typography.dart';
import 'package:stock_investment_tracker/presentation/common/app_scaffold.dart';
import 'package:stock_investment_tracker/presentation/common/buttons.dart';
import 'package:stock_investment_tracker/presentation/dashboard/providers/dashboard_providers.dart';
import 'package:stock_investment_tracker/presentation/dashboard/widgets/allocation_donut_chart.dart';
import 'package:stock_investment_tracker/presentation/dashboard/widgets/dashboard_skeleton.dart';
import 'package:stock_investment_tracker/presentation/dashboard/widgets/portfolio_header.dart';
import 'package:stock_investment_tracker/presentation/dashboard/widgets/stat_card_grid.dart';
import 'package:stock_investment_tracker/presentation/dashboard/widgets/stock_row.dart';
import 'package:stock_investment_tracker/providers/push_notification_providers.dart';
import 'package:stock_investment_tracker/providers/repository_providers.dart';
import 'package:stock_investment_tracker/presentation/auth/providers/auth_providers.dart';
import 'package:stock_investment_tracker/data/migration/position_migration_runner.dart';
import 'package:stock_investment_tracker/presentation/common/empty_state_view.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:stock_investment_tracker/presentation/dashboard/widgets/metric_detail_card.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  DashboardMetricType? _selectedMetric;
  DateTime _lastSyncTime = DateTime.now();
  bool _isOffline = false;
  bool _isMigrating = true;
  String? _migrationError;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    _initConnectivity();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _runMigration();
    });
  }

  Future<void> _runMigration() async {
    try {
      final uid = ref.read(currentUserIdProvider);
      final dataSource = ref.read(firestoreDataSourceProvider);
      if (uid == null || dataSource == null) {
        if (mounted) {
          setState(() {
            _isMigrating = false;
          });
        }
        return;
      }
      final runner = PositionMigrationRunner(dataSource, uid);
      final outcome = await runner.runIfNeeded();
      
      if (mounted) {
        setState(() {
          if (outcome.success) {
            _isMigrating = false;
            // Initialize push notifications after successful migration
            ref.read(pushNotificationServiceProvider)?.initialize();
          } else {
            _migrationError = outcome.errorMessage ?? 'Migration failed due to an unknown error.';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _migrationError = e.toString();
        });
      }
    }
  }

  Future<void> _initConnectivity() async {
    final results = await Connectivity().checkConnectivity();
    _updateConnectivityStatus(results);

    _connectivitySubscription = Connectivity().onConnectivityChanged.listen(
      _updateConnectivityStatus,
    );
  }

  void _updateConnectivityStatus(List<ConnectivityResult> results) {
    final offline =
        results.contains(ConnectivityResult.none) || results.isEmpty;
    if (_isOffline != offline && mounted) {
      setState(() {
        _isOffline = offline;
      });
    }
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isMigrating && _migrationError == null) {
      return AppScaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: AppColors.brandIndigo),
              SizedBox(height: AppSpacing.lg),
              Text('Upgrading database schema...', style: AppTypography.body),
            ],
          ),
        ),
      );
    }
    
    if (_migrationError != null) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      final primaryTextColor = isDark ? Colors.white : AppColors.textPrimaryLight;
      return AppScaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: AppColors.alertRed, size: 48),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Database Upgrade Failed',
                  style: AppTypography.h2.copyWith(color: primaryTextColor),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  _migrationError!,
                  style: AppTypography.body.copyWith(color: AppColors.alertRed),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xl),
                PrimaryButton(
                  text: 'Retry',
                  onPressed: () {
                    setState(() {
                      _isMigrating = true;
                      _migrationError = null;
                    });
                    _runMigration();
                  },
                ),
              ],
            ),
          ),
        ),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? Colors.white : AppColors.textPrimaryLight;
    final cardBg = isDark ? AppColors.offBlack : Colors.white;
    final borderColor = isDark ? const Color(0xFF242731) : const Color(0xFFE2E8F0);
    final refreshBg = isDark ? AppColors.offBlack : Colors.white;

    final positionsAsyncValue = ref.watch(allPositionsProvider);
    final portfolioSummary = ref.watch(portfolioSummaryProvider);
    final stockSummaries = ref.watch(stockSummariesProvider);
    // "Your Stocks" lists what you currently hold. Tickers you've sold out of
    // stay in `stockSummaries` (the PDF report and metric drill-downs need
    // their booked profit) — they're just not part of this list.
    final heldStockSummaries =
        stockSummaries.where((s) => s.sharesHeld > 0).toList();
    final allocationData = ref.watch(allocationDataProvider);
    final withdrawals = ref.watch(allWithdrawalsProvider).valueOrNull ?? [];

    return AppScaffold(
      body: positionsAsyncValue.when(
        data: (positions) {
          return RefreshIndicator(
            onRefresh: () async {
              setState(() {
                _lastSyncTime = DateTime.now();
              });
              await Future.delayed(const Duration(milliseconds: 500));
            },
            color: AppColors.brandIndigo,
            backgroundColor: refreshBg,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.lg,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      PortfolioHeader(
                            totalValue: portfolioSummary.portfolioValue,
                            profitLossPercentage:
                                portfolioSummary.startingCapital > 0
                                ? ((portfolioSummary.portfolioValue -
                                              portfolioSummary
                                                  .startingCapital) /
                                          portfolioSummary.startingCapital) *
                                      100
                                : (portfolioSummary.currentlyInvested > 0
                                      ? (portfolioSummary.realizedPL /
                                                portfolioSummary
                                                    .currentlyInvested) *
                                            100
                                      : 0.0),
                            lastSyncTime: _lastSyncTime,
                            isOffline: _isOffline,
                          )
                          .animate()
                          .fadeIn(duration: 400.ms)
                          .slideY(begin: -0.1, end: 0),

                      const SizedBox(height: AppSpacing.xl),

                      StatCardGrid(
                        summary: portfolioSummary,
                        selectedMetric: _selectedMetric,
                        onSelectMetric: (metric) {
                          setState(() {
                            if (_selectedMetric == metric) {
                              _selectedMetric = null;
                            } else {
                              _selectedMetric = metric;
                            }
                          });
                        },
                      ),

                      if (_selectedMetric != null) ...[
                        const SizedBox(height: AppSpacing.md),
                        MetricDetailCard(
                          metricType: _selectedMetric!,
                          summary: portfolioSummary,
                          stockSummaries: stockSummaries,
                          positions: positions,
                          withdrawals: withdrawals,
                          onClose: () {
                            setState(() {
                              _selectedMetric = null;
                            });
                          },
                        ),
                      ],

                      const SizedBox(height: AppSpacing.xxl),

                      if (allocationData.isNotEmpty) ...[
                        AllocationDonutChart(
                          allocations: allocationData,
                          totalHoldings: portfolioSummary.currentlyInvested,
                        ),
                        const SizedBox(height: AppSpacing.xl),
                      ],

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Your Stocks',
                            style: AppTypography.h2.copyWith(
                              color: primaryTextColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => context.go('/transactions'),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 4.0,
                                horizontal: 8.0,
                              ),
                              child: Text(
                                'View all',
                                style: AppTypography.body.copyWith(
                                  color: primaryTextColor,
                                  fontWeight: FontWeight.bold,
                                  decoration: TextDecoration.underline,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      if (heldStockSummaries.isEmpty)
                        Column(
                          children: [
                            EmptyStateView(
                              icon: Icons.show_chart,
                              title: 'No stocks yet',
                              message:
                                  'Add your first stock purchase to track your portfolio.',
                              buttonLabel: 'Add your first stock',
                              onButtonPressed: () {
                                context.go('/transactions');
                              },
                            ),
                          ],
                        )
                      else
                        Container(
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: borderColor,
                              width: 1.2,
                            ),
                          ),
                          child: ListView.separated(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: heldStockSummaries.length,
                            separatorBuilder: (context, index) => Divider(
                              height: 1,
                              color: borderColor,
                              indent: 16,
                              endIndent: 16,
                            ),
                            itemBuilder: (context, index) {
                              final summary = heldStockSummaries[index];
                              return StockRow(
                                summary: summary,
                                animationDelayMs: index * 100,
                                onTap: () {
                                  context.push('/stock/${summary.ticker}');
                                },
                              );
                            },
                          ),
                        ),
                      const SizedBox(
                        height: 100,
                      ), // Bottom padding for floating navigation bar
                    ]),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Padding(
          padding: EdgeInsets.all(AppSpacing.md),
          child: DashboardSkeleton(),
        ),
        error: (error, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: AppColors.alertRed,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Something went wrong',
                  style: AppTypography.h3.copyWith(
                    color: primaryTextColor,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  error.toString(),
                  style: AppTypography.caption.copyWith(
                    color: AppColors.neutral500,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.lg),
                PrimaryButton(
                  label: 'Retry',
                  onPressed: () => ref.invalidate(allPositionsProvider),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
