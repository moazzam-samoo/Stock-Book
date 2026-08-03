import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class StockTickerRain extends StatefulWidget {
  const StockTickerRain({super.key});

  @override
  State<StockTickerRain> createState() => _StockTickerRainState();
}

class _StockTickerRainState extends State<StockTickerRain> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final List<_TickerDrop> _drops = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    _initDrops();
  }

  void _initDrops() {
    final texts = ['AAPL', 'GOOGL', 'MSFT', 'TSLA', '+2.3%', '↗', '↘', '-1.5%', 'AMZN', 'META', '+5.1%', '-0.8%'];
    for (int i = 0; i < 30; i++) {
      _drops.add(
        _TickerDrop(
          text: texts[_random.nextInt(texts.length)],
          x: _random.nextDouble(),
          y: _random.nextDouble(),
          speed: 0.2 + _random.nextDouble() * 0.4,
          opacity: 0.05 + _random.nextDouble() * 0.1,
          size: 14 + _random.nextDouble() * 10,
        ),
      );
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
          painter: _RainPainter(
            drops: _drops,
            progress: _controller.value,
          ),
        );
      },
    );
  }
}

class _TickerDrop {
  final String text;
  final double x;
  double y;
  final double speed;
  final double opacity;
  final double size;

  _TickerDrop({
    required this.text,
    required this.x,
    required this.y,
    required this.speed,
    required this.opacity,
    required this.size,
  });
}

class _RainPainter extends CustomPainter {
  final List<_TickerDrop> drops;
  final double progress;

  _RainPainter({required this.drops, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (var drop in drops) {
      double currentY = (drop.y + progress * drop.speed * 10) % 1.2 - 0.1;
      
      final textPainter = TextPainter(
        text: TextSpan(
          text: drop.text,
          style: TextStyle(
            color: drop.text.contains('-') || drop.text == '↘' 
                ? AppColors.danger.withOpacity(drop.opacity)
                : drop.text.contains('+') || drop.text == '↗'
                    ? AppColors.success.withOpacity(drop.opacity)
                    : AppColors.textSecondary.withOpacity(drop.opacity),
            fontSize: drop.size,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(drop.x * size.width, currentY * size.height),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RainPainter oldDelegate) {
    return true;
  }
}
