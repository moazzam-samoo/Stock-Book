import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Onboarding page 3 — live PSX prices. A price number ticks from a base
/// value up to a "live" value while a faint sparkline draws in beneath it,
/// and a small pulsing "LIVE" dot loops for as long as the page is visible.
/// Same structure as [OnboardingLineChart]/[OnboardingDonutChart]: a
/// `CustomPainter` doing all the drawing, no external animation library.
class OnboardingLivePrice extends StatefulWidget {
  const OnboardingLivePrice({super.key});

  @override
  State<OnboardingLivePrice> createState() => _OnboardingLivePriceState();
}

class _OnboardingLivePriceState extends State<OnboardingLivePrice>
    with TickerProviderStateMixin {
  late final AnimationController _priceController;
  late final AnimationController _pulseController;
  late final Animation<double> _priceAnimation;

  static const double _basePrice = 8.48;
  static const double _livePrice = 8.63;

  @override
  void initState() {
    super.initState();
    _priceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _priceAnimation = CurvedAnimation(
      parent: _priceController,
      curve: Curves.easeOutCubic,
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _priceController.forward();
    });
  }

  @override
  void dispose() {
    _priceController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_priceAnimation, _pulseController]),
      builder: (context, child) {
        final currentPrice =
            _basePrice + (_livePrice - _basePrice) * _priceAnimation.value;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 8 + 3 * _pulseController.value,
                  height: 8 + 3 * _pulseController.value,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary.withOpacity(
                      0.5 + 0.5 * _pulseController.value,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'LIVE',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Rs ${currentPrice.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 44,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimaryLight,
                fontFamily: 'JetBrains Mono',
              ),
            ),
            const SizedBox(height: 24),
            CustomPaint(
              size: const Size(double.infinity, 100),
              painter: _SparklinePainter(drawProgress: _priceAnimation.value),
            ),
          ],
        );
      },
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final double drawProgress;

  _SparklinePainter({required this.drawProgress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary.withOpacity(0.7)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final points = [
      Offset(0, size.height * 0.7),
      Offset(size.width * 0.25, size.height * 0.55),
      Offset(size.width * 0.5, size.height * 0.65),
      Offset(size.width * 0.75, size.height * 0.35),
      Offset(size.width, size.height * 0.15),
    ];

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }

    final metrics = path.computeMetrics().toList();
    if (metrics.isEmpty) return;
    final metric = metrics.first;
    final extractPath = metric.extractPath(0.0, metric.length * drawProgress);

    canvas.drawPath(extractPath, paint);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) {
    return oldDelegate.drawProgress != drawProgress;
  }
}
