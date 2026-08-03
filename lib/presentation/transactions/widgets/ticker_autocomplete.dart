import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stock_investment_tracker/core/theme/app_colors.dart';
import 'package:stock_investment_tracker/core/theme/app_typography.dart';
import 'package:stock_investment_tracker/presentation/common/ticker_avatar.dart';
import 'package:stock_investment_tracker/presentation/settings/providers/settings_provider.dart';

class TickerAutocomplete extends ConsumerWidget {
  final ValueChanged<String> onSelected;

  const TickerAutocomplete({super.key, required this.onSelected});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider).valueOrNull;
    final favorites = settings?.favorites ?? [];

    return Autocomplete<String>(
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text.isEmpty) {
          return const Iterable<String>.empty();
        }
        return favorites.where((String option) {
          return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
        });
      },
      onSelected: onSelected,
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        return TextField(
          controller: controller,
          focusNode: focusNode,
          textCapitalization: TextCapitalization.characters,
          style: AppTypography.body.copyWith(color: Colors.white),
          decoration: InputDecoration(
            labelText: 'Stock Ticker',
            hintText: 'e.g. STPL',
            hintStyle: TextStyle(color: AppColors.neutral500),
            labelStyle: TextStyle(color: AppColors.neutral500),
            enabledBorder: UnderlineInputBorder(
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
            color: AppColors.surfaceDark,
            elevation: 4.0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(color: AppColors.offBlack),
            ),
            child: SizedBox(
              width: MediaQuery.of(context).size.width - 48,
              height: 200,
              child: ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: options.length,
                itemBuilder: (BuildContext context, int index) {
                  final String option = options.elementAt(index);
                  return ListTile(
                    leading: TickerAvatar(ticker: option, size: 32),
                    title: Text(option, style: const TextStyle(color: Colors.white)),
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
