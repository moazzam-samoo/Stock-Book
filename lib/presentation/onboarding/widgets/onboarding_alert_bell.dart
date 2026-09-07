import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Onboarding page 4 — price alerts. A hand-painted bell rings once on
/// entrance, then a small "target hit" notification card slides down and
/// fades in below it. Same `CustomPainter`-driven approach as the other
/// onboarding pages — no icon font, no external animation library.
class OnboardingAlertBell extends StatefulWidget {
  const OnboardingAlertBell({super.key});

  @override
  State<OnboardingAlertBell> createState() => _OnboardingAlertBellState();
}

class _OnboardingAlertBellState extends State<OnboardingAlertBell>
    with TickerProviderStateMixin {
  late final AnimationController _ringController;
  late final AnimationController _cardController;
  late final Animation<double> _ringAnimation;
  late final Animation<double> _cardAnimation;

  @override
  void initState() {
    super.initState();
    _ringController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _ringAnimation = CurvedAnimation(
      parent: _ringController,
      curve: Curves.elasticOut,
    );

    _cardController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _cardAnimation = CurvedAnimation(
      parent: _cardController,
      curve: Curves.easeOutCubic,
    );

    Future.delayed(const Duration(milliseconds: 400), () async {
      if (!mounted) return;
      await _ringController.forward();
      if (!mounted) return;
      _cardController.forward();
    });
  }

  @override
  void dispose() {
    _ringController.dispose();
    _cardController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _ringAnimation,
          builder: (context, child) {
            // elasticOut overshoots past 1.0 and oscillates back down to
            // rest at 1.0 on its own — (value - 1) turns that natural
            // oscillation into a swing that starts wide and settles at 0,
            // exactly the ringing-bell motion, with no extra easing math.
            final angle = (_ringAnimation.value - 1) * 0.5;
            return Transform.rotate(
              angle: angle,
              child: CustomPaint(
                size: const Size(90, 90),
                painter: _BellPainter(color: AppColors.warningYellow),
              ),
            );
          },
        ),
        const SizedBox(height: 28),
        AnimatedBuilder(
          animation: _cardAnimation,
          builder: (context, child) {
            return Opacity(
              opacity: _cardAnimation.value,
              child: Transform.translate(
                offset: Offset(0, 16 * (1 - _cardAnimation.value)),
                child: child,
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primary.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary,
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 14),
                ),
                const SizedBox(width: 10),
                Text(
                  'STPL hit your target',
                  style: TextStyle(
                    color: AppColors.textPrimaryLight,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _BellPainter extends CustomPainter {
  final Color color;

  _BellPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height / 2);
    final bodyPath = Path();

    // Simple rounded bell silhouette: a dome over a slightly flared base,
    // hand-drawn with cubic beziers rather than an icon glyph.
    final top = Offset(center.dx, center.dy - size.height * 0.32);
    final baseY = center.dy + size.height * 0.22;
    final leftBase = Offset(center.dx - size.width * 0.34, baseY);
    final rightBase = Offset(center.dx + size.width * 0.34, baseY);

    bodyPath.moveTo(top.dx, top.dy);
    bodyPath.cubicTo(
      top.dx - size.width * 0.32, top.dy + size.height * 0.02,
      leftBase.dx - size.width * 0.06, baseY - size.height * 0.28,
      leftBase.dx, leftBase.dy,
    );
    bodyPath.lineTo(rightBase.dx, rightBase.dy);
    bodyPath.cubicTo(
      rightBase.dx + size.width * 0.06, baseY - size.height * 0.28,
      top.dx + size.width * 0.32, top.dy + size.height * 0.02,
      top.dx, top.dy,
    );
    bodyPath.close();
    canvas.drawPath(bodyPath, paint);

    // Clapper.
    canvas.drawCircle(
      Offset(center.dx, baseY + size.height * 0.08),
      size.width * 0.06,
      paint,
    );

    // Crown knob.
    canvas.drawCircle(
      Offset(top.dx, top.dy - size.height * 0.05),
      size.width * 0.045,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _BellPainter oldDelegate) => false;
}
