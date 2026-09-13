import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flock_sense/core/theme/app_colors.dart';
import 'package:flock_sense/core/theme/app_design.dart';
import 'package:flock_sense/features/batches/data/batch_service.dart';
import 'package:flock_sense/features/batches/domain/batch_model.dart';
import 'package:flock_sense/features/farms/domain/farm_model.dart';

/// 3-card operational summary strip matching Image 1:
/// Total Birds (green), Capacity (amber/gold), and Farm Type (blue).
class FarmOperationalSummary extends StatelessWidget {
  const FarmOperationalSummary({
    super.key,
    required this.farm,
    this.batches,
  });

  final FarmModel farm;
  final List<BatchModel>? batches;

  @override
  Widget build(BuildContext context) {
    if (batches != null) {
      return _buildRow(batches!);
    }

    return StreamBuilder<List<BatchModel>>(
      stream: BatchService.watchBatches(farm.id),
      builder: (context, snapshot) {
        final bList = snapshot.data ?? [];
        return _buildRow(bList);
      },
    );
  }

  Widget _buildRow(List<BatchModel> batches) {
    final activeBatches = batches
        .where((b) => b.status.toLowerCase() == 'active')
        .toList();
    final totalBirds = activeBatches.fold<int>(
      0,
      (sum, b) => sum + (b.totalBirds > 0 ? b.totalBirds : b.currentBirds),
    );

    // Calculate capacity
    String capacityText = '-';
    if (farm.capacity != null && farm.capacity! > 0) {
      capacityText = NumberFormat('#,###').format(farm.capacity);
    } else if (farm.totalSqFt > 0) {
      capacityText = NumberFormat('#,###').format((farm.totalSqFt / 1.2).round());
    } else if (farm.lengthFt > 0 && farm.widthFt > 0) {
      capacityText = NumberFormat('#,###').format(((farm.lengthFt * farm.widthFt) / 1.2).round());
    }

    // Type text
    final typeText = farm.farmType.trim().isNotEmpty
        ? farm.farmType.trim()
        : (farm.flockType.trim().isNotEmpty ? farm.flockType.trim() : '-');

    return Row(
      children: [
        // 1. Total Birds (Green)
        Expanded(
          child: AppDesign.miniStatCard(
            icon: Icons.pets_rounded,
            iconColor: AppColors.primary,
            value: totalBirds > 0 ? NumberFormat('#,###').format(totalBirds) : (batches.isNotEmpty ? '0' : '-'),
            label: 'Total Birds',
          ),
        ),
        const SizedBox(width: 10),
        // 2. Capacity (Amber)
        Expanded(
          child: AppDesign.miniStatCard(
            icon: Icons.scale_outlined,
            iconColor: AppColors.gold,
            value: capacityText,
            label: 'Capacity',
          ),
        ),
        const SizedBox(width: 10),
        // 3. Farm Type (Blue)
        Expanded(
          child: AppDesign.miniStatCard(
            icon: Icons.business_outlined,
            iconColor: AppColors.ocean,
            value: typeText,
            label: 'Farm Type',
          ),
        ),
      ],
    );
  }
}

