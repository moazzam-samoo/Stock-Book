import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:stock_investment_tracker/core/theme/app_colors.dart';
import 'package:stock_investment_tracker/core/theme/app_typography.dart';
import 'package:stock_investment_tracker/core/theme/app_spacing.dart';
import 'package:stock_investment_tracker/domain/entities/allocation_segment.dart';
import 'package:stock_investment_tracker/core/utils/currency_formatter.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AllocationDonutChart extends StatefulWidget {
  final List<AllocationSegment> allocations;
  final double totalHoldings;

  const AllocationDonutChart({
    super.key,
    required this.allocations,
    required this.totalHoldings,
  });

  @override
  State<AllocationDonutChart> createState() => _AllocationDonutChartState();
}

class _AllocationDonutChartState extends State<AllocationDonutChart> {
  int touchedIndex = -1;

  final List<Color> chartColors = [
    const Color(0xFF00C853), // Vibrant Green (BNL)
    const Color(0xFF3B82F6), // Vibrant Blue (STPL)
    const Color(0xFF8B5CF6), // Purple
    const Color(0xFFF97316), // Orange
    const Color(0xFF14B8A6), // Teal
    const Color(0xFFEC4899), // Pink
  ];

  @override
  Widget build(BuildContext context) {
    if (widget.allocations.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF242731), width: 1.2),
        ),
        child: const Center(
          child: Text(
            'No allocations yet',
            style: TextStyle(color: AppColors.neutral500),
          ),
        ),
      );
    }

    final displayHoldings = AppCurrencyFormatter.format(widget.totalHoldings, decimalDigits: 0);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF242731), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Allocation',
                style: AppTypography.h3.copyWith(
                  color: AppColors.textPrimaryDark,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              Text(
                'tap to highlight',
                style: AppTypography.caption.copyWith(
                  color: AppColors.neutral500,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              // Left: Donut Chart
              SizedBox(
                width: 140,
                height: 140,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Center Text
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'HOLDINGS',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.neutral500,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          displayHoldings,
                          style: AppTypography.body.copyWith(
                            color: AppColors.textPrimaryDark,
                            fontFamily: 'JetBrains Mono',
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    // Pie Chart
                    PieChart(
                      PieChartData(
                        pieTouchData: PieTouchData(
                          touchCallback: (FlTouchEvent event, pieTouchResponse) {
                            setState(() {
                              if (!event.isInterestedForInteractions ||
                                  pieTouchResponse == null ||
                                  pieTouchResponse.touchedSection == null) {
                                touchedIndex = -1;
                                return;
                              }
                              touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                            });
                          },
                        ),
                        borderData: FlBorderData(show: false),
                        sectionsSpace: 3,
                        centerSpaceRadius: 45,
                        sections: showingSections(),
                      ),
                    ).animate().scale(duration: 500.ms, curve: Curves.easeOutBack),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              // Right: Legend
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(widget.allocations.length, (i) {
                    final allocation = widget.allocations[i];
                    final color = chartColors[i % chartColors.length];
                    final isTouched = i == touchedIndex;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6.0),
                      child: Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: color,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            allocation.ticker,
                            style: AppTypography.body.copyWith(
                              color: AppColors.textPrimaryDark,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${allocation.percentage.toStringAsFixed(0)}%',
                            style: AppTypography.body.copyWith(
                              color: isTouched ? AppColors.moneyGreen : AppColors.neutral400,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<PieChartSectionData> showingSections() {
    return List.generate(widget.allocations.length, (i) {
      final isTouched = i == touchedIndex;
      final radius = isTouched ? 22.0 : 18.0;
      final allocation = widget.allocations[i];
      final color = chartColors[i % chartColors.length];

      return PieChartSectionData(
        color: color,
        value: allocation.percentage,
        title: '',
        radius: radius,
        badgeWidget: null,
      );
    });
  }
}
