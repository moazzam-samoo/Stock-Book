import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stock_investment_tracker/core/theme/app_colors.dart';
import 'package:stock_investment_tracker/core/theme/app_typography.dart';
import 'package:stock_investment_tracker/presentation/common/ticker_avatar.dart';
import 'package:stock_investment_tracker/presentation/settings/providers/settings_provider.dart';
import 'package:stock_investment_tracker/providers/ticker_providers.dart';

class TickerAutocomplete extends ConsumerWidget {
  final ValueChanged<String> onSelected;
  final TextEditingController controller;
  final FocusNode focusNode;

  const TickerAutocomplete({
    super.key, 
    required this.onSelected,
    required this.controller,
    required this.focusNode,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? Colors.white : AppColors.textPrimaryLight;
    final dropdownBg = isDark ? AppColors.offBlack : Colors.white;
    final dropdownBorder = isDark ? const Color(0xFF242731) : const Color(0xFFE2E8F0);

    final settings = ref.watch(settingsProvider).valueOrNull;
    final favorites = settings?.favorites ?? [];
    final allTickers = ref.watch(allTickersProvider).valueOrNull ?? [];

    return RawAutocomplete<String>(
      textEditingController: controller,
      focusNode: focusNode,
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text.isEmpty) {
          return const Iterable<String>.empty();
        }
        
        final query = textEditingValue.text.toLowerCase();
        
        if (allTickers.isEmpty) {
          return favorites.where((String option) {
            return option.toLowerCase().contains(query);
          });
        }
        
        final matches = allTickers.where((t) {
          return t.symbol.toLowerCase().contains(query) || 
                 t.name.toLowerCase().contains(query);
        }).map((t) => t.symbol).toList();
        
        matches.sort((a, b) {
          final aFav = favorites.contains(a);
          final bFav = favorites.contains(b);
          if (aFav && !bFav) return -1;
          if (!aFav && bFav) return 1;
          return a.compareTo(b);
        });
        
        return matches;
      },
      onSelected: onSelected,
      fieldViewBuilder: (context, textController, focusNode, onFieldSubmitted) {
        return TextField(
          controller: textController,
          focusNode: focusNode,
          textCapitalization: TextCapitalization.characters,
          style: AppTypography.body.copyWith(color: primaryTextColor),
          decoration: InputDecoration(
            labelText: 'Stock Ticker',
            hintText: 'e.g. STPL',
            hintStyle: TextStyle(color: AppColors.neutral500),
            labelStyle: TextStyle(color: AppColors.neutral500),
            enabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.offBlack),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.brandIndigo),
            ),
          ),
          onChanged: (val) {
            onSelected(val.toUpperCase());
          },
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            color: dropdownBg,
            elevation: 4.0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(color: dropdownBorder),
            ),
            child: SizedBox(
              width: MediaQuery.of(context).size.width - 48,
              height: 200,
              child: ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: options.length,
                itemBuilder: (BuildContext context, int index) {
                  final String option = options.elementAt(index);
                  
                  // Look up company name
                  String? companyName;
                  if (allTickers.isNotEmpty) {
                    try {
                      final ticker = allTickers.firstWhere((t) => t.symbol == option);
                      companyName = ticker.name;
                    } catch (_) {}
                  }

                  return ListTile(
                    leading: TickerAvatar(ticker: option, size: 32),
                    title: Text(option, style: TextStyle(color: primaryTextColor)),
                    subtitle: companyName != null 
                        ? Text(
                            companyName, 
                            style: AppTypography.caption.copyWith(color: AppColors.neutral400),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ) 
                        : null,
                    onTap: () {
                      onSelected(option);
                    },
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
