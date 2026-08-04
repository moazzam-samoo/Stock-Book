import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
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
  bool _isExpanded = false;

  final List<Color> chartColors = [
    const Color(0xFF00C853), // Vibrant Green (BNL)
    const Color(0xFF3B82F6), // Vibrant Blue (STPL)
    const Color(0xFF8B5CF6), // Purple
    const Color(0xFFF97316), // Orange
    const Color(0xFF14B8A6), // Teal
    const Color(0xFFEC4899), // Pink
    const Color(0xFFEAB308), // Yellow
    const Color(0xFF06B6D4), // Cyan
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

    final hasMore = widget.allocations.length > 4;
    final visibleCount = _isExpanded
        ? widget.allocations.length
        : (hasMore ? 4 : widget.allocations.length);

    final displayHoldings = AppCurrencyFormatter.format(widget.totalHoldings, decimalDigits: 0);

    // Determine center label & value based on selection
    final bool isSelected = touchedIndex >= 0 && touchedIndex < widget.allocations.length;
    final String centerLabel = isSelected ? widget.allocations[touchedIndex].ticker : 'HOLDINGS';
    final String centerValue = isSelected
        ? AppCurrencyFormatter.format(widget.allocations[touchedIndex].amount, decimalDigits: 0)
        : displayHoldings;

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
              GestureDetector(
                onTap: () {
                  setState(() {
                    touchedIndex = -1;
                  });
                },
                child: Text(
                  isSelected ? 'reset selection' : 'tap to highlight',
                  style: AppTypography.caption.copyWith(
                    color: isSelected ? AppColors.moneyGreen : AppColors.neutral500,
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
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
                          centerLabel,
                          style: AppTypography.caption.copyWith(
                            color: isSelected ? AppColors.moneyGreen : AppColors.neutral500,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          centerValue,
                          style: AppTypography.body.copyWith(
                            color: AppColors.textPrimaryDark,
                            fontFamily: 'JetBrains Mono',
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                        if (isSelected) ...[
                          const SizedBox(height: 2),
                          Text(
                            '${widget.allocations[touchedIndex].percentage.toStringAsFixed(0)}%',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.moneyGreen,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ],
                    ),
                    // Pie Chart
                    PieChart(
                      PieChartData(
                        pieTouchData: PieTouchData(
                          touchCallback: (FlTouchEvent event, pieTouchResponse) {
                            if (!event.isInterestedForInteractions ||
                                pieTouchResponse == null ||
                                pieTouchResponse.touchedSection == null) {
                              return;
                            }
                            final index = pieTouchResponse.touchedSection!.touchedSectionIndex;
                            if (index >= 0 && index < widget.allocations.length) {
                              setState(() {
                                touchedIndex = (touchedIndex == index) ? -1 : index;
                              });
                            }
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
              const SizedBox(width: 20),
              // Right: Legend
              Expanded(
                child: AnimatedSize(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(visibleCount, (i) {
                      final allocation = widget.allocations[i];
                      final color = chartColors[i % chartColors.length];
                      final isTouched = i == touchedIndex;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3.0),
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              touchedIndex = (touchedIndex == i) ? -1 : i;
                            });
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 6.0),
                            decoration: BoxDecoration(
                              color: isTouched ? const Color(0xFF1E2620) : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isTouched ? AppColors.moneyGreen : Colors.transparent,
                                width: 1,
                              ),
                            ),
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
                                const SizedBox(width: 8),
                                Text(
                                  allocation.ticker,
                                  style: AppTypography.body.copyWith(
                                    color: isTouched ? AppColors.moneyGreen : AppColors.textPrimaryDark,
                                    fontWeight: isTouched ? FontWeight.w800 : FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  '${allocation.percentage.toStringAsFixed(0)}%',
                                  style: AppTypography.body.copyWith(
                                    color: isTouched ? AppColors.moneyGreen : AppColors.neutral400,
                                    fontWeight: isTouched ? FontWeight.w800 : FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ],
          ),
          if (hasMore) ...[
            const SizedBox(height: 12),
            Center(
              child: InkWell(
                onTap: () {
                  setState(() {
                    _isExpanded = !_isExpanded;
                  });
                },
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _isExpanded ? 'Show Less' : 'Show All (${widget.allocations.length})',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.brandIndigo,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                        color: AppColors.brandIndigo,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<PieChartSectionData> showingSections() {
    return List.generate(widget.allocations.length, (i) {
      final isTouched = i == touchedIndex;
      final radius = isTouched ? 24.0 : 18.0;
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
