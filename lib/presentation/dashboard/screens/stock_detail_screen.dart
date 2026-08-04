import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:stock_investment_tracker/core/theme/app_colors.dart';
import 'package:stock_investment_tracker/core/theme/app_spacing.dart';
import 'package:stock_investment_tracker/core/theme/app_typography.dart';
import 'package:stock_investment_tracker/domain/enums/lot_status.dart';
import 'package:stock_investment_tracker/presentation/common/badges.dart';
import 'package:stock_investment_tracker/presentation/common/ticker_avatar.dart';
import 'package:stock_investment_tracker/core/utils/currency_formatter.dart';
import 'package:stock_investment_tracker/presentation/dashboard/providers/dashboard_providers.dart';
import 'package:stock_investment_tracker/presentation/transactions/widgets/lot_card.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

class StockDetailScreen extends ConsumerWidget {
  final String ticker;

  const StockDetailScreen({super.key, required this.ticker});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lotsAsyncValue = ref.watch(allLotsProvider);
    final stockSummaries = ref.watch(stockSummariesProvider);
    final summary = stockSummaries.where((s) => s.ticker == ticker).firstOrNull;
    final formatCurrency = NumberFormat.simpleCurrency(name: 'PKR', decimalDigits: 2);
    final formatNumber = NumberFormat.decimalPattern();
    
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Text(ticker, style: AppTypography.h3),
        centerTitle: true,
      ),
      body: lotsAsyncValue.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.brandIndigo)),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error loading $ticker details', style: AppTypography.body.copyWith(color: AppColors.dangerRed)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(allLotsProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (lots) {
          final stockLots = lots.where((lot) => lot.ticker == ticker).toList();
          
          if (stockLots.isEmpty) {
            return Center(
              child: Text('No active lots for $ticker', style: AppTypography.body.copyWith(color: AppColors.neutral500)),
            );
          }
          
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      Hero(
                        tag: 'avatar_$ticker',
                        child: TickerAvatar(ticker: ticker, size: 80),
                      ),
                      const SizedBox(height: 16),
                      Text(ticker, style: AppTypography.h1),
                      const SizedBox(height: 8),
                      if (summary != null) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            StatusBadge(
                              status: summary.status == LotStatus.open 
                                  ? TradeStatus.open 
                                  : summary.status == LotStatus.partiallySold 
                                      ? TradeStatus.partial 
                                      : TradeStatus.closed
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceDark,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.offBlack),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildStatColumn('Shares', formatNumber.format(summary.sharesHeld)),
                              _buildStatColumn('Avg Price', AppCurrencyFormatter.format(summary.avgBuyPrice, decimalDigits: 2)),
                              _buildStatColumn(
                                'Total P/L', 
                                summary.realizedPL != 0 ? AppCurrencyFormatter.format(summary.realizedPL, decimalDigits: 2, showSign: true) : '-',
                                color: summary.realizedPL >= 0 ? AppColors.moneyGreen : AppColors.alertRed,
                              ),
                            ],
                          ),
                        ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),
                      ],
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Text('Lots', style: AppTypography.h2.copyWith(color: AppColors.textPrimaryDark)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                sliver: AnimationLimiter(
                  child: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        return AnimationConfiguration.staggeredList(
                          position: index,
                          duration: const Duration(milliseconds: 375),
                          child: SlideAnimation(
                            verticalOffset: 50.0,
                            child: FadeInAnimation(
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 12.0),
                                child: LotCard(lot: stockLots[index]),
                              ),
                            ),
                          ),
                        );
                      },
                      childCount: stockLots.length,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, {Color? color}) {
    return Column(
      children: [
        Text(
          label,
          style: AppTypography.caption.copyWith(color: AppColors.neutral500),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTypography.body.copyWith(
            fontWeight: FontWeight.bold,
            color: color ?? AppColors.textPrimaryDark,
          ),
        ),
      ],
    );
  }
}
