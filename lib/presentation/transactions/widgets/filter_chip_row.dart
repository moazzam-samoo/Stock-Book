import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stock_investment_tracker/core/theme/app_colors.dart';
import 'package:stock_investment_tracker/domain/entities/position.dart';
import 'package:stock_investment_tracker/domain/enums/position_status.dart';
import 'package:stock_investment_tracker/presentation/dashboard/providers/dashboard_providers.dart';
import 'package:stock_investment_tracker/presentation/transactions/providers/transactions_providers.dart';

class FilterChipRow extends ConsumerWidget {
  const FilterChipRow({super.key});

  int _countFor(String filter, List<Position> positions) {
    switch (filter.toLowerCase()) {
      case 'open':
        return positions.where((p) => p.status != PositionStatus.closed).length;
      case 'partial':
        return positions.where((p) => p.status == PositionStatus.partiallySold).length;
      case 'closed':
        return positions.where((p) => p.status == PositionStatus.closed).length;
      case 'all':
      default:
        return positions.length;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final chipBg = isDark ? AppColors.offBlack : const Color(0xFFF5F5F5);
    final unselectedLabel = isDark ? Colors.white70 : AppColors.textPrimaryLight;
    final selectedFill = isDark
        ? const Color(0xFF2D6A4F)
        : const Color(0xFF86EFAC);

    final currentFilter = ref.watch(statusFilterProvider);
    final allPositions = ref.watch(allPositionsProvider).valueOrNull ?? [];
    final filters = ['Open', 'Partial', 'Closed', 'All'];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: filters.map((filter) {
          final isSelected = currentFilter == filter;
          final count = _countFor(filter, allPositions);
          final labelColor = isSelected
              ? (isDark ? Colors.white : const Color(0xFF14532D))
              : unselectedLabel;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(filter),
                ],
              ),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  ref.read(statusFilterProvider.notifier).updateFilter(filter);
                }
              },
              backgroundColor: chipBg,
              selectedColor: selectedFill,
              elevation: isSelected ? 2 : 0,
              shadowColor: selectedFill.withOpacity(0.3),
              labelStyle: TextStyle(
                color: labelColor,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected ? selectedFill.withOpacity(0.6) : Colors.transparent,
                  width: 1.5,
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
