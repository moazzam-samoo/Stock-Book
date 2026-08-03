import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:stock_investment_tracker/core/theme/app_colors.dart';
import 'package:stock_investment_tracker/core/theme/app_typography.dart';
import 'package:stock_investment_tracker/core/theme/app_spacing.dart';
import 'package:stock_investment_tracker/domain/entities/allocation_segment.dart';
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
    AppColors.moneyGreen,
    AppColors.brandIndigo,
    AppColors.warningYellow,
    AppColors.alertRed,
    const Color(0xFF9F7AEA), // Purple
    const Color(0xFFED8936), // Orange
    const Color(0xFF4FD1C5), // Teal
  ];

  @override
  Widget build(BuildContext context) {
    if (widget.allocations.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(
          child: Text(
            'No allocations yet',
            style: TextStyle(color: AppColors.neutral500),
          ),
        ),
      );
    }

    final formatCurrency = NumberFormat.simpleCurrency(name: 'PKR', decimalDigits: 0);
    final displayHoldings = formatCurrency.format(widget.totalHoldings).replaceAll('PKR', 'Rs').trim();

    return Column(
      children: [
        SizedBox(
          height: 200,
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
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    displayHoldings,
                    style: AppTypography.body.copyWith(
                      color: AppColors.textPrimaryDark,
                      fontFamily: 'JetBrains Mono',
                      fontWeight: FontWeight.w600,
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
                  sectionsSpace: 2,
                  centerSpaceRadius: 70,
                  sections: showingSections(),
                ),
              ).animate().scale(duration: 500.ms, curve: Curves.easeOutBack),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        // Legend
        Wrap(
          spacing: 16,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: List.generate(widget.allocations.length, (i) {
            final allocation = widget.allocations[i];
            final color = chartColors[i % chartColors.length];
            final isTouched = i == touchedIndex;
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${allocation.ticker} ${(allocation.percentage * 100).toStringAsFixed(0)}%',
                  style: AppTypography.caption.copyWith(
                    color: isTouched ? AppColors.textPrimaryDark : AppColors.neutral500,
                    fontWeight: isTouched ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            );
          }),
        ),
      ],
    );
  }

  List<PieChartSectionData> showingSections() {
    return List.generate(widget.allocations.length, (i) {
      final isTouched = i == touchedIndex;
      final radius = isTouched ? 30.0 : 25.0;
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
