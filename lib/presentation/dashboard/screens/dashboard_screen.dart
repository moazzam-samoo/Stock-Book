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
import 'package:stock_investment_tracker/presentation/common/empty_state_view.dart';
import 'package:flutter_animate/flutter_animate.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lotsAsyncValue = ref.watch(allLotsProvider);
    final portfolioSummary = ref.watch(portfolioSummaryProvider);
    final stockSummaries = ref.watch(stockSummariesProvider);
    final allocationData = ref.watch(allocationDataProvider);

    return AppScaffold(
      body: lotsAsyncValue.when(
        data: (lots) {
          return RefreshIndicator(
            onRefresh: () async {
              // Usually invalidating the provider re-fetches the stream
              // But since it's a StreamProvider from Firestore, it updates automatically.
              // We can simulate a slight delay for the UI feedback.
              await Future.delayed(const Duration(milliseconds: 500));
            },
            color: AppColors.brandIndigo,
            backgroundColor: AppColors.surfaceDark,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.lg),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      PortfolioHeader(
                        totalValue: portfolioSummary.currentlyInvested + portfolioSummary.realizedPL + portfolioSummary.freeCash,
                        profitLossPercentage: portfolioSummary.currentlyInvested > 0 
                            ? (portfolioSummary.realizedPL / portfolioSummary.currentlyInvested) * 100 
                            : 0.0,
                      ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1, end: 0),
                      
                      const SizedBox(height: AppSpacing.xl),
                      
                      StatCardGrid(summary: portfolioSummary),
                      
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
                              color: AppColors.textPrimaryDark,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => context.go('/transactions'),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                              child: Text(
                                'View all',
                                style: AppTypography.body.copyWith(
                                  color: const Color(0xFF4361EE),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      
                      if (stockSummaries.isEmpty)
                        EmptyStateView(
                          icon: Icons.show_chart,
                          title: 'No stocks yet',
                          message: 'Add your first stock purchase to track your portfolio.',
                          buttonLabel: 'Add your first stock',
                          onButtonPressed: () {
                            context.go('/transactions');
                          },
                        )
                      else
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.surfaceDark,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFF242731), width: 1.2),
                          ),
                          child: ListView.separated(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: stockSummaries.length,
                            separatorBuilder: (context, index) => const Divider(
                              height: 1,
                              color: Color(0xFF242731),
                              indent: 16,
                              endIndent: 16,
                            ),
                            itemBuilder: (context, index) {
                              final summary = stockSummaries[index];
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
                      const SizedBox(height: 100), // Bottom padding for floating navigation bar
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
                const Icon(Icons.error_outline, size: 64, color: AppColors.alertRed),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Something went wrong',
                  style: AppTypography.h3.copyWith(color: AppColors.textPrimaryDark),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  error.toString(),
                  style: AppTypography.caption.copyWith(color: AppColors.neutral500),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.lg),
                PrimaryButton(
                  label: 'Retry',
                  onPressed: () => ref.invalidate(allLotsProvider),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
