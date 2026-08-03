import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

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
        
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.offBlack,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.darkGray),
      ),
      alignment: Alignment.center,
      child: Text(
        displayChars,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: AppColors.textPrimaryDark,
            ),
      ),
    );
  }
}
