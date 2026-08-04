import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

class TickerAvatar extends StatelessWidget {
  final String ticker;
  final double size;

  const TickerAvatar({
    super.key,
    required this.ticker,
    this.size = 48.0,
  });

  static const List<Color> _palette = [
    Color(0xFF00C853), // Vibrant Green (BNL)
    Color(0xFF3B82F6), // Vibrant Blue (STPL)
    Color(0xFF8B5CF6), // Purple
    Color(0xFFF97316), // Orange
    Color(0xFF14B8A6), // Teal
    Color(0xFFEC4899), // Pink
    Color(0xFF6366F1), // Indigo
    Color(0xFFEAB308), // Amber
    Color(0xFF06B6D4), // Cyan
  ];

  Color _getColorForTicker(String symbol) {
    if (symbol.isEmpty) return _palette[0];
    int hash = 0;
    for (int i = 0; i < symbol.length; i++) {
      hash = symbol.codeUnitAt(i) + ((hash << 5) - hash);
    }
    return _palette[hash.abs() % _palette.length];
  }

  @override
  Widget build(BuildContext context) {
    final displayChars = ticker.isNotEmpty 
        ? ticker.toUpperCase().substring(0, ticker.length > 2 ? 2 : ticker.length)
        : '?';
        
    final bgColors = _getColorForTicker(ticker);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bgColors,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        displayChars,
        style: AppTypography.body.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: size * 0.38,
        ),
      ),
    );
  }
}
