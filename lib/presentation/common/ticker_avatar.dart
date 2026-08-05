import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stock_investment_tracker/core/theme/app_typography.dart';
import 'package:stock_investment_tracker/core/utils/stock_color_utils.dart';
import 'package:stock_investment_tracker/presentation/settings/providers/settings_provider.dart';
import 'package:stock_investment_tracker/presentation/common/stock_color_picker_bottom_sheet.dart';

class TickerAvatar extends ConsumerWidget {
  final String ticker;
  final double size;

  const TickerAvatar({
    super.key,
    required this.ticker,
    this.size = 48.0,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final displayChars = ticker.isNotEmpty
        ? ticker.toUpperCase().substring(0, ticker.length > 2 ? 2 : ticker.length)
        : '?';

    final settings = ref.watch(settingsProvider).valueOrNull;
    final customColorValue = settings?.stockColors[ticker.toUpperCase().trim()];

    final Color bgColor = customColorValue != null
        ? Color(customColorValue)
        : StockColorUtils.getColorForTicker(ticker);

    // Calculate background luminance for smart contrast
    final bool isLightBg = bgColor.computeLuminance() > 0.45;
    final Color textColor = isLightBg ? const Color(0xFF0F172A) : Colors.white;

    return GestureDetector(
      onLongPress: () {
        StockColorPickerBottomSheet.show(context, ticker);
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: bgColor,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: bgColor.withOpacity(0.35),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          displayChars,
          style: AppTypography.body.copyWith(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: size * 0.38,
            shadows: [
              Shadow(
                color: isLightBg
                    ? Colors.white.withOpacity(0.6)
                    : Colors.black.withOpacity(0.6),
                blurRadius: 2,
                offset: const Offset(0.5, 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
