import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import 'dart:ui';

class OnboardingLineChart extends StatefulWidget {
  const OnboardingLineChart({super.key});

  @override
  State<OnboardingLineChart> createState() => _OnboardingLineChartState();
}

class _OnboardingLineChartState extends State<OnboardingLineChart> with TickerProviderStateMixin {
  late final AnimationController _drawController;
  late final AnimationController _pulseController;
  late final Animation<double> _drawAnimation;

  @override
  void initState() {
    super.initState();
    _drawController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    
    _drawAnimation = CurvedAnimation(
      parent: _drawController,
      curve: Curves.easeOutCubic,
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _drawController.forward();
    });
  }

  @override
  void dispose() {
    _drawController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_drawAnimation, _pulseController]),
      builder: (context, child) {
        return CustomPaint(
          size: const Size(double.infinity, 240),
          painter: _LineChartPainter(
            drawProgress: _drawAnimation.value,
            pulseProgress: _pulseController.value,
          ),
        );
      },
    );
  }
}

class _LineChartPainter extends CustomPainter {
  final double drawProgress;
  final double pulseProgress;

  _LineChartPainter({required this.drawProgress, required this.pulseProgress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    
    final points = [
      Offset(0, size.height * 0.8),
      Offset(size.width * 0.2, size.height * 0.6),
      Offset(size.width * 0.4, size.height * 0.7),
      Offset(size.width * 0.6, size.height * 0.4),
      Offset(size.width * 0.8, size.height * 0.5),
      Offset(size.width, size.height * 0.2),
    ];
    
    path.moveTo(points.first.dx, points.first.dy);
    
    for (int i = 1; i < points.length; i++) {
      final p0 = points[i - 1];
      final p1 = points[i];
      final midPoint = Offset((p0.dx + p1.dx) / 2, (p0.dy + p1.dy) / 2);
      
      path.quadraticBezierTo(p0.dx, p0.dy, midPoint.dx, midPoint.dy);
      
      if (i == points.length - 1) {
        path.lineTo(p1.dx, p1.dy);
      }
    }
    
    final metrics = path.computeMetrics().toList();
    if (metrics.isEmpty) return;
    
    final metric = metrics.first;
    final extractPath = metric.extractPath(0.0, metric.length * drawProgress);

    if (drawProgress > 0.05) {
      final fillPath = Path.from(extractPath)
        ..lineTo(extractPath.getBounds().right, size.height)
        ..lineTo(0, size.height)
        ..close();
        
      final fillPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.primary.withOpacity(0.3),
            AppColors.primary.withOpacity(0.0),
          ],
        ).createShader(Rect.fromLTRB(0, 0, size.width, size.height));
        
      canvas.drawPath(fillPath, fillPaint);
    }

    canvas.drawPath(extractPath, paint);
    
    if (drawProgress > 0) {
      final tangent = metric.getTangentForOffset(metric.length * drawProgress);
      if (tangent != null) {
        final position = tangent.position;
        
        final pulsePaint = Paint()
          ..color = AppColors.primary.withOpacity(0.3 + 0.3 * pulseProgress)
          ..style = PaintingStyle.fill;
          
        canvas.drawCircle(position, 8 + 6 * pulseProgress, pulsePaint);
        
        final dotPaint = Paint()
          ..color = AppColors.primary
          ..style = PaintingStyle.fill;
          
        canvas.drawCircle(position, 6, dotPaint);
        
        final innerDotPaint = Paint()
          ..color = Colors.white
          ..style = PaintingStyle.fill;
          
        canvas.drawCircle(position, 3, innerDotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) {
    return oldDelegate.drawProgress != drawProgress || 
           oldDelegate.pulseProgress != pulseProgress;
  }
}
