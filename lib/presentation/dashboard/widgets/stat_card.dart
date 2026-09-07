import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:stock_investment_tracker/core/theme/app_colors.dart';
import 'package:stock_investment_tracker/core/theme/app_typography.dart';
import 'package:stock_investment_tracker/core/utils/currency_formatter.dart';
import 'package:stock_investment_tracker/presentation/dashboard/widgets/sparkline_chart.dart';
import 'package:stock_investment_tracker/presentation/dashboard/widgets/wave_decoration.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// The decorative element anchored to the bottom of a [StatCard]. Each
/// dashboard metric gets whichever reads best for what it actually means,
/// not one style forced onto all six.
enum StatCardDecoration {
  /// A large, faint version of the card's own icon in the bottom-right
  /// corner — the default for anything without a more specific shape.
  ghostIcon,

  /// A small trending line (reuses [SparklineChart]) — for a metric that's
  /// actually a trend, like Realized P/L.
  sparkline,

  /// A wave silhouette along the bottom edge — for Total Liquid Capital,
  /// where "liquid" has an obvious visual pun.
  wave,
}

class StatCard extends StatelessWidget {
  final String label;
  final num value;
  final bool isCurrency;
  final Color? valueColor;
  final int animationDelayMs;
  final VoidCallback? onTap;
  final bool isSelected;

  /// Optional footnote under the value, e.g. "Rs 5,000 withdrawn".
  final String? tag;
  final Color? tagColor;

  /// Icon badge (top-left) and this card's own accent color — the same
  /// color tints the icon badge and bottom decoration only, never the card
  /// shell itself.
  final IconData? icon;
  final Color accentColor;
  final StatCardDecoration decoration;

  /// For [StatCardDecoration.ghostIcon] only — a different glyph than the
  /// badge's own [icon] for the bottom-right watermark (e.g. a wallet badge
  /// but a stacked-coins ghost). Defaults to [icon] when not given.
  final IconData? ghostIcon;

  /// Only used by [StatCardDecoration.sparkline] — whether the trend line
  /// should read as climbing or falling.
  final bool sparklineIsPositive;

  const StatCard({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    required this.accentColor,
    this.isCurrency = false,
    this.valueColor,
    this.animationDelayMs = 0,
    this.onTap,
    this.isSelected = false,
    this.tag,
    this.tagColor,
    this.decoration = StatCardDecoration.ghostIcon,
    this.sparklineIsPositive = true,
    this.ghostIcon,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final formatNumber = NumberFormat.decimalPattern();

    final displayValue = isCurrency
        ? AppCurrencyFormatter.format(value, decimalDigits: 0)
        : formatNumber.format(value);

    final baseCardBg = isDark ? const Color(0xFF13151B) : Colors.white;

    final selectedAccent = isDark ? AppColors.moneyGreen : AppColors.moneyGreenOnLight;

    // Plain, neutral card shell — only the icon badge and the bottom
    // decoration carry the metric's accent color. Tinting the whole card
    // background/border in that color too read as "everything is green",
    // not "the icon is green".
    final borderColor = isSelected
        ? selectedAccent
        : (isDark ? const Color(0xFF242731) : const Color(0xFFE2E8F0));

    final labelColor = isDark ? AppColors.neutral500 : const Color(0xFF64748B);

    final defaultValColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;

    return InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: baseCardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: borderColor,
                width: isSelected ? 1.8 : 1.2,
              ),
              boxShadow: isDark
                  ? null
                  : [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                children: [
                  Positioned.fill(child: _buildDecoration(context)),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 16.0,
                      horizontal: 16.0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (icon != null) ...[
                          Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                accentColor,
                                Color.lerp(accentColor, Colors.black, 0.28)!,
                              ],
                            ),
                          ),
                          child: Icon(icon, color: Colors.white, size: 18),
                        ),
                        const SizedBox(height: 10),
                        ],
                        Text(
                          label.toUpperCase(),
                          style: AppTypography.caption.copyWith(
                            color: labelColor,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                            fontSize: 9,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          displayValue,
                          style: AppTypography.h2.copyWith(
                            color: valueColor ?? defaultValColor,
                            fontFamily: 'JetBrains Mono',
                            fontWeight: FontWeight.w700,
                            fontSize: 20,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (tag != null) ...[
                          const SizedBox(height: 5),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: (tagColor ?? AppColors.warningYellow).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.north_east_rounded,
                                  size: 10,
                                  color: tagColor ?? AppColors.warningYellow,
                                ),
                                const SizedBox(width: 3),
                                Flexible(
                                  child: Text(
                                    tag!,
                                    style: AppTypography.caption.copyWith(
                                      color: tagColor ?? AppColors.warningYellow,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 9,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        )
        .animate()
        .fadeIn(duration: 400.ms, delay: animationDelayMs.ms)
        .slideY(begin: 0.1, end: 0, curve: Curves.easeOutCubic);
  }

  Widget _buildDecoration(BuildContext context) {
    switch (decoration) {
      case StatCardDecoration.sparkline:
        return Align(
          alignment: Alignment.bottomRight,
          child: Padding(
            padding: const EdgeInsets.only(right: 8, bottom: 8),
            child: Opacity(
              opacity: 0.7,
              child: SparklineChart(
                isPositive: sparklineIsPositive,
                color: accentColor,
                seed: label.hashCode,
              ),
            ),
          ),
        );
      case StatCardDecoration.wave:
        return WaveDecoration(color: accentColor.withOpacity(0.22));
      case StatCardDecoration.ghostIcon:
        return Align(
          alignment: Alignment.bottomRight,
          child: Padding(
            padding: const EdgeInsets.only(right: 4, bottom: 4),
            child: Icon(
              ghostIcon ?? icon,
              size: 36,
              color: accentColor.withOpacity(0.22),
            ),
          ),
        );
    }
  }
}
