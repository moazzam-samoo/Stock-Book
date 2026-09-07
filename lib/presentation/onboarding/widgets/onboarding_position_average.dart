import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Onboarding page 5 — multi-buy positions. Three "buy" chips appear one
/// at a time at staggered price levels, converge into a single average-cost
/// line, then a two-segment profit bar (realized / unrealized) builds up
/// beneath it. One controller drives the whole sequence via `Interval`s,
/// matching the timed-sequence feel of the other onboarding pages.
class OnboardingPositionAverage extends StatefulWidget {
  const OnboardingPositionAverage({super.key});

  @override
  State<OnboardingPositionAverage> createState() =>
      _OnboardingPositionAverageState();
}

class _OnboardingPositionAverageState extends State<OnboardingPositionAverage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  // Each buy chip's own 0..1 progress, staggered across the first 60% of
  // the timeline; the average-cost line and profit bar share the tail end.
  late final Animation<double> _chip1;
  late final Animation<double> _chip2;
  late final Animation<double> _chip3;
  late final Animation<double> _averageLine;
  late final Animation<double> _profitBar;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    Animation<double> interval(double start, double end) {
      return CurvedAnimation(
        parent: _controller,
        curve: Interval(start, end, curve: Curves.easeOutCubic),
      );
    }

    _chip1 = interval(0.0, 0.2);
    _chip2 = interval(0.15, 0.35);
    _chip3 = interval(0.3, 0.5);
    _averageLine = interval(0.5, 0.75);
    _profitBar = interval(0.75, 1.0);

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
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 130,
              child: CustomPaint(
                size: const Size(double.infinity, 130),
                painter: _BuyChipsPainter(
                  chip1: _chip1.value,
                  chip2: _chip2.value,
                  chip3: _chip3.value,
                  averageLine: _averageLine.value,
                ),
              ),
            ),
            const SizedBox(height: 28),
            _buildProfitBar(),
          ],
        );
      },
    );
  }

  Widget _buildProfitBar() {
    const realizedFraction = 0.4;
    final progress = _profitBar.value;
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            height: 16,
            width: 220,
            child: Row(
              children: [
                Expanded(
                  flex: (realizedFraction * 1000).round(),
                  child: Container(
                    color: AppColors.primary.withOpacity(
                      (progress / realizedFraction).clamp(0, 1),
                    ),
                  ),
                ),
                Expanded(
                  flex: ((1 - realizedFraction) * 1000).round(),
                  child: Container(
                    color: AppColors.chartViolet.withOpacity(
                      ((progress - realizedFraction) / (1 - realizedFraction))
                          .clamp(0, 1),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _legendDot(AppColors.primary, 'Realized'),
            const SizedBox(width: 16),
            _legendDot(AppColors.chartViolet, 'Unrealized'),
          ],
        ),
      ],
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: AppColors.textSecondaryLight,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _BuyChipsPainter extends CustomPainter {
  final double chip1;
  final double chip2;
  final double chip3;
  final double averageLine;

  _BuyChipsPainter({
    required this.chip1,
    required this.chip2,
    required this.chip3,
    required this.averageLine,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final chipY = [size.height * 0.75, size.height * 0.45, size.height * 0.15];
    final chipX = [size.width * 0.15, size.width * 0.5, size.width * 0.85];
    final progresses = [chip1, chip2, chip3];
    final avgY = size.height * 0.45;

    final chipPaint = Paint()..color = AppColors.chartIndigo;
    final linePaint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (var i = 0; i < 3; i++) {
      final p = progresses[i];
      if (p <= 0) continue;
      // Slide up from below into place while fading in.
      final settledY = chipY[i];
      final y = settledY + (1 - p) * 20;
      final opacity = p.clamp(0.0, 1.0);
      canvas.drawCircle(
        Offset(chipX[i], y),
        10,
        chipPaint..color = AppColors.chartIndigo.withOpacity(opacity),
      );
    }

    if (averageLine > 0) {
      final path = Path()
        ..moveTo(size.width * 0.05, avgY)
        ..lineTo(size.width * 0.05 + (size.width * 0.9) * averageLine, avgY);
      canvas.drawPath(path, linePaint..color = AppColors.primary.withOpacity(averageLine));
    }
  }

  @override
  bool shouldRepaint(covariant _BuyChipsPainter oldDelegate) {
    return oldDelegate.chip1 != chip1 ||
        oldDelegate.chip2 != chip2 ||
        oldDelegate.chip3 != chip3 ||
        oldDelegate.averageLine != averageLine;
  }
}
