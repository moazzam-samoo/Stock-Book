import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import 'package:stock_investment_tracker/domain/enums/lot_status.dart';
import 'package:stock_investment_tracker/domain/enums/position_status.dart';

enum TradeStatus { open, partial, closed }

class StatusBadge extends StatelessWidget {
  /// Deliberately `dynamic`: three different enums flow in here
  /// ([TradeStatus], [LotStatus], [PositionStatus]). That flexibility is also
  /// how `PositionStatus` once went completely unhandled without a compile
  /// error — every position rendered as OPEN, including fully-sold ones. Hence
  /// the assert on the fallback below: add a branch, never rely on the default.
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
    if (status is PositionStatus) {
      switch (status as PositionStatus) {
        case PositionStatus.open:
          return TradeStatus.open;
        case PositionStatus.partiallySold:
          return TradeStatus.partial;
        case PositionStatus.closed:
          return TradeStatus.closed;
      }
    }
    assert(
      false,
      'StatusBadge got an unhandled status type: ${status.runtimeType}. '
      'Add a branch for it — falling through to OPEN mislabels real data.',
    );
    return TradeStatus.open;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final positiveColor = isDark ? AppColors.moneyGreen : AppColors.moneyGreenOnLight;

    Color bgColor;
    Color textColor;
    String label;

    switch (_tradeStatus) {
      case TradeStatus.open:
        bgColor = positiveColor.withOpacity(0.2);
        textColor = positiveColor;
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isPositive = percentage >= 0;
    final color = isPositive
        ? (isDark ? AppColors.moneyGreen : AppColors.moneyGreenOnLight)
        : AppColors.alertRed;
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
