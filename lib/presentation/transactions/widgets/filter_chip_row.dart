import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stock_investment_tracker/core/theme/app_colors.dart';
import 'package:stock_investment_tracker/presentation/transactions/providers/transactions_providers.dart';

class FilterChipRow extends ConsumerWidget {
  const FilterChipRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final chipBg = isDark ? AppColors.offBlack : const Color(0xFFF5F5F5);
    final unselectedLabel = isDark ? Colors.white : AppColors.textPrimaryLight;

    final currentFilter = ref.watch(statusFilterProvider);
    final filters = ['Open', 'Partial', 'Closed', 'All'];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: filters.map((filter) {
          final isSelected = currentFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(filter),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  ref.read(statusFilterProvider.notifier).updateFilter(filter);
                }
              },
              backgroundColor: chipBg,
              selectedColor: AppColors.brandIndigo.withOpacity(0.2),
              labelStyle: TextStyle(
                color: isSelected ? AppColors.brandIndigo : unselectedLabel,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected ? AppColors.brandIndigo : Colors.transparent,
                ),
              ),
              showCheckmark: false,
            ),
          );
        }).toList(),
      ),
    );
  }
}
