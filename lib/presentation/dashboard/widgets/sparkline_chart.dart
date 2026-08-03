import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math';

class SparklineChart extends StatelessWidget {
  final bool isPositive;
  final Color color;

  const SparklineChart({
    super.key,
    required this.isPositive,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    // Generate a simple deterministic sparkline that trends up or down
    final random = Random(color.value);
    final spots = <FlSpot>[];
    
    double currentY = 5.0;
    for (int i = 0; i <= 6; i++) {
      spots.add(FlSpot(i.toDouble(), currentY));
      double change = (random.nextDouble() * 2) - 0.5;
      if (isPositive) {
        change += 0.5;
      } else {
        change -= 0.5;
      }
      currentY += change;
    }

    final minY = spots.map((e) => e.y).reduce(min);
    final maxY = spots.map((e) => e.y).reduce(max);

    return SizedBox(
      width: 40,
      height: 24,
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: 6,
          minY: minY - 1,
          maxY: maxY + 1,
          lineTouchData: const LineTouchData(enabled: false),
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: color,
              barWidth: 1.5,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: color.withOpacity(0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
