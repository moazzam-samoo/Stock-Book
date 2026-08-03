import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import 'dart:math';

class OnboardingDonutChart extends StatefulWidget {
  const OnboardingDonutChart({super.key});

  @override
  State<OnboardingDonutChart> createState() => _OnboardingDonutChartState();
}

class _OnboardingDonutChartState extends State<OnboardingDonutChart> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: const Size(200, 200),
          painter: _DonutChartPainter(progress: _controller.value),
        );
      },
    );
  }
}

class _DonutChartPainter extends CustomPainter {
  final double progress;

  _DonutChartPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width / 2, size.height / 2) - 20;
    
    final segments = [
      {'color': AppColors.chartGreen, 'sweep': 0.45},
      {'color': AppColors.chartBlue, 'sweep': 0.25},
      {'color': AppColors.chartOrange, 'sweep': 0.20},
      {'color': AppColors.chartPurple, 'sweep': 0.10},
    ];

    double startAngle = -pi / 2;
    
    for (int i = 0; i < segments.length; i++) {
      final sweep = segments[i]['sweep'] as double;
      final color = segments[i]['color'] as Color;
      
      double segmentStartProgress = i * (1.0 / segments.length);
      double segmentEndProgress = (i + 1) * (1.0 / segments.length);
      
      double segmentProgress = 0.0;
      if (progress >= segmentEndProgress) {
        segmentProgress = 1.0;
      } else if (progress > segmentStartProgress) {
        segmentProgress = (progress - segmentStartProgress) / (segmentEndProgress - segmentStartProgress);
        segmentProgress = Curves.easeOutCubic.transform(segmentProgress);
      }
      
      if (segmentProgress > 0) {
        final paint = Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 24
          ..strokeCap = StrokeCap.round;
          
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: radius),
          startAngle,
          (sweep * 2 * pi) * segmentProgress,
          false,
          paint,
        );
      }
      
      startAngle += sweep * 2 * pi;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
