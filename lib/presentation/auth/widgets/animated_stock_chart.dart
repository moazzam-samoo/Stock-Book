import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import 'dart:math';

class AnimatedStockChart extends StatefulWidget {
  const AnimatedStockChart({super.key});

  @override
  State<AnimatedStockChart> createState() => _AnimatedStockChartState();
}

class _AnimatedStockChartState extends State<AnimatedStockChart> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final List<Offset> _points = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
    
    _generatePoints();
  }
  
  void _generatePoints() {
    final random = Random(42);
    double y = 0.5;
    for (int i = 0; i <= 20; i++) {
      _points.add(Offset(i / 20, y));
      y += (random.nextDouble() - 0.45) * 0.3;
      y = y.clamp(0.2, 0.8);
    }
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
          size: Size.infinite,
          painter: _ChartPainter(
            points: _points,
            progress: _controller.value,
          ),
        );
      },
    );
  }
}

class _ChartPainter extends CustomPainter {
  final List<Offset> points;
  final double progress;

  _ChartPainter({required this.points, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final paint = Paint()
      ..color = AppColors.chartGreen.withOpacity(0.15)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    
    final scaledPoints = points.map((p) => Offset(p.dx * size.width, p.dy * size.height)).toList();
    
    path.moveTo(scaledPoints.first.dx, scaledPoints.first.dy);
    
    for (int i = 1; i < scaledPoints.length; i++) {
      path.lineTo(scaledPoints[i].dx, scaledPoints[i].dy);
    }
    
    final metrics = path.computeMetrics().toList();
    if (metrics.isEmpty) return;
    
    final metric = metrics.first;
    
    // Animate the line drawing in, then fading out or looping
    // we use a simple reveal
    double end = metric.length * progress;
    final extractPath = metric.extractPath(0.0, end);

    canvas.drawPath(extractPath, paint);
  }

  @override
  bool shouldRepaint(covariant _ChartPainter oldDelegate) {
    return true;
  }
}
