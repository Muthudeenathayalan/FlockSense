import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flock_sense/core/theme/app_colors.dart';
import 'package:flock_sense/features/batches/domain/batch_model.dart';
import 'package:flock_sense/features/farms/domain/farm_model.dart';
import 'package:flock_sense/features/performance/domain/growth_analytics_model.dart';
import 'package:flock_sense/features/performance/presentation/providers/growth_analytics_providers.dart';

class AnalyticsFilterBar extends ConsumerWidget {
  const AnalyticsFilterBar({
    super.key,
    required this.farms,
    required this.batches,
    this.activeFarm,
    this.activeBatch,
  });

  final List<FarmModel> farms;
  final List<BatchModel> batches;
  final FarmModel? activeFarm;
  final BatchModel? activeBatch;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filterState = ref.watch(growthAnalyticsFilterProvider);
    final notifier = ref.read(growthAnalyticsFilterProvider.notifier);

    final rawFarmId = filterState.selectedFarmId ?? activeFarm?.id;
    final selectedFarmId = farms.any((f) => f.id == rawFarmId)
        ? rawFarmId
        : null;

    final rawBatchId = filterState.selectedBatchId ?? activeBatch?.id;
    final selectedBatchId = batches.any((b) => b.id == rawBatchId)
        ? rawBatchId
        : null;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Farm Selector Dropdown
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSoft,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.border.withValues(alpha: 0.8),
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String?>(
                      value: selectedFarmId,
                      hint: const Text(
                        'All Farms',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      isExpanded: true,
                      icon: const Icon(
                        Icons.arrow_drop_down_rounded,
                        color: AppColors.primary,
                      ),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text(
                            'All Farms',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        ...farms.map(
                          (f) => DropdownMenuItem<String?>(
                            value: f.id,
                            child: Text(
                              f.farmName,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                      onChanged: (val) => notifier.selectFarm(val),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Batch Selector Dropdown
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSoft,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.border.withValues(alpha: 0.8),
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String?>(
                      value: selectedBatchId,
                      hint: const Text(
                        'Entire Batch',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      isExpanded: true,
                      icon: const Icon(
                        Icons.arrow_drop_down_rounded,
                        color: AppColors.primary,
                      ),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text(
                            'Entire Batch',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        ...batches.map(
                          (b) => DropdownMenuItem<String?>(
                            value: b.id,
                            child: Text(
                              b.batchName,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                      onChanged: (val) => notifier.selectBatch(val),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Date Range Pill Chips Horizontal Scroll
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: AnalyticsDateRange.values.map((range) {
                final selected = filterState.dateRange == range;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(
                      _rangeLabel(range),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: selected
                            ? FontWeight.w800
                            : FontWeight.w600,
                      ),
                    ),
                    selected: selected,
                    onSelected: (_) => notifier.selectDateRange(range),
                    selectedColor: AppColors.primary,
                    backgroundColor: AppColors.surfaceSoft,
                    elevation: selected ? 2 : 0,
                    labelStyle: TextStyle(
                      color: selected ? Colors.white : AppColors.textSecondary,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  String _rangeLabel(AnalyticsDateRange range) {
    switch (range) {
      case AnalyticsDateRange.today:
        return 'Today';
      case AnalyticsDateRange.last7Days:
        return 'Last 7 Days';
      case AnalyticsDateRange.last30Days:
        return 'Last 30 Days';
      case AnalyticsDateRange.entireBatch:
        return 'Entire Batch';
    }
  }
}
