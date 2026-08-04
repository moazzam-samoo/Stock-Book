import 'package:flutter/material.dart';
import 'package:stock_investment_tracker/core/theme/app_typography.dart';
import 'package:stock_investment_tracker/core/utils/stock_color_utils.dart';

class TickerAvatar extends StatelessWidget {
  final String ticker;
  final double size;

  const TickerAvatar({
    super.key,
    required this.ticker,
    this.size = 48.0,
  });

  @override
  Widget build(BuildContext context) {
    final displayChars = ticker.isNotEmpty 
        ? ticker.toUpperCase().substring(0, ticker.length > 2 ? 2 : ticker.length)
        : '?';
        
    final bgColors = StockColorUtils.getColorForTicker(ticker);

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
