import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import 'package:stock_investment_tracker/domain/enums/lot_status.dart';

enum TradeStatus { open, partial, closed }

class StatusBadge extends StatelessWidget {
  final dynamic status;

  const StatusBadge({
    super.key,
    required this.status,
  });

  TradeStatus get _tradeStatus {
    if (status is TradeStatus) return status as TradeStatus;
    if (status is LotStatus) {
      switch (status as LotStatus) {
        case LotStatus.open:
          return TradeStatus.open;
        case LotStatus.partiallySold:
          return TradeStatus.partial;
        case LotStatus.closed:
          return TradeStatus.closed;
      }
    }
    return TradeStatus.open;
  }

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor;
    String label;

    switch (_tradeStatus) {
      case TradeStatus.open:
        bgColor = AppColors.moneyGreen.withOpacity(0.2);
        textColor = AppColors.moneyGreen;
        label = 'OPEN';
        break;
      case TradeStatus.partial:
        bgColor = AppColors.warningYellow.withOpacity(0.2);
        textColor = AppColors.warningYellow;
        label = 'PARTIAL';
        break;
      case TradeStatus.closed:
        bgColor = AppColors.alertRed.withOpacity(0.2);
        textColor = AppColors.alertRed;
        label = 'CLOSED';
        break;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
        child: Text(
          label,
          key: ValueKey(label),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: textColor,
                fontWeight: FontWeight.bold,
              ),
        ),
      ),
    );
  }
}

class TrendChip extends StatelessWidget {
  final double percentage;

  const TrendChip({
    super.key,
    required this.percentage,
  });

  @override
  Widget build(BuildContext context) {
    final isPositive = percentage >= 0;
    final color = isPositive ? AppColors.moneyGreen : AppColors.alertRed;
    final icon = isPositive ? Icons.arrow_upward : Icons.arrow_downward;
    final prefix = isPositive ? '+' : '';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
            child: Icon(icon, key: ValueKey(icon), color: color, size: 12),
          ),
          const SizedBox(width: 4),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
            child: Text(
              '$prefix${percentage.toStringAsFixed(2)}%',
              key: ValueKey(percentage),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
