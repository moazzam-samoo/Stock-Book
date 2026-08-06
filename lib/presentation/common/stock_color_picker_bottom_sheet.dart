import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stock_investment_tracker/core/theme/app_colors.dart';
import 'package:stock_investment_tracker/core/utils/stock_color_utils.dart';
import 'package:stock_investment_tracker/presentation/settings/providers/settings_provider.dart';

class StockColorPickerBottomSheet extends ConsumerWidget {
  final String ticker;

  const StockColorPickerBottomSheet({super.key, required this.ticker});

  static Future<void> show(BuildContext context, String ticker) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StockColorPickerBottomSheet(ticker: ticker),
    );
  }

  static const List<Color> _presetColors = [
    Color(0xFF00E676), // Green
    Color(0xFF10B981), // Emerald
    Color(0xFF00B8D4), // Cyan
    Color(0xFF2979FF), // Blue
    Color(0xFF6366F1), // Indigo
    Color(0xFFD500F9), // Purple
    Color(0xFFFF4081), // Pink
    Color(0xFFFF1744), // Red
    Color(0xFFFF9100), // Orange
    Color(0xFFFFD600), // Amber
    Color(0xFF84CC16), // Lime
    Color(0xFF14B8A6), // Teal
    Color(0xFF3B82F6), // Sky Blue
    Color(0xFF8B5CF6), // Deep Purple
    Color(0xFFEC4899), // Rose
    Color(0xFFF43F5E), // Crimson
    Color(0xFFEAB308), // Gold
    Color(0xFF64748B), // Slate Grey
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF13151B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF242731) : const Color(0xFFE2E8F0);
    final textColor = isDark ? Colors.white : AppColors.textPrimaryLight;

    final settings = ref.watch(settingsProvider).valueOrNull;
    final currentColorValue = settings?.stockColors[ticker.toUpperCase().trim()];
    final defaultColor = StockColorUtils.getColorForTicker(ticker);

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: borderColor),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: currentColorValue != null ? Color(currentColorValue) : defaultColor,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      ticker.substring(0, ticker.length > 2 ? 2 : ticker.length),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Pick Color for $ticker',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Choose a custom avatar color for $ticker across all screens.',
            style: const TextStyle(fontSize: 13, color: AppColors.neutral500),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 14,
            runSpacing: 14,
            children: [
              ..._presetColors.map((color) {
                final isSelected = currentColorValue == color.value;
                return GestureDetector(
                  onTap: () async {
                    final cleanTicker = ticker.toUpperCase().trim();
                    Navigator.pop(context);
                    await ref.read(settingsControllerProvider.notifier).updateStockColor(cleanTicker, color.value);
                    ref.invalidate(settingsProvider);
                  },
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(color: Colors.white, width: 3)
                          : Border.all(color: Colors.black.withOpacity(0.15), width: 1),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: color.withOpacity(0.6),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              )
                            ]
                          : null,
                    ),
                    child: isSelected
                        ? const Icon(Icons.check_rounded, color: Colors.white, size: 22)
                        : null,
                  ),
                );
              }),
            ],
          ),
          const SizedBox(height: 24),
          if (currentColorValue != null) ...[
            SizedBox(
              width: double.infinity,
              height: 44,
              child: OutlinedButton.icon(
                onPressed: () async {
                  await ref.read(settingsControllerProvider.notifier).updateStockColor(ticker.toUpperCase().trim(), 0);
                  if (context.mounted) Navigator.pop(context);
                },
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: borderColor),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Reset to Default Auto Color', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}
