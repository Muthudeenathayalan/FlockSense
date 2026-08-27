import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flock_sense/core/theme/app_design.dart';
import 'package:flock_sense/features/batches/data/batch_service.dart';
import 'package:flock_sense/features/batches/domain/batch_model.dart';
import 'package:flock_sense/features/farms/domain/farm_model.dart';

/// 3-card operational summary strip for a specific farm.
class FarmOperationalSummary extends StatelessWidget {
  const FarmOperationalSummary({super.key, required this.farm});

  final FarmModel farm;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<BatchModel>>(
      stream: BatchService.watchBatches(farm.id),
      builder: (context, snapshot) {
        final batches = snapshot.data ?? [];
        final activeBatches = batches
            .where((b) => b.status.toLowerCase() == 'active')
            .toList();
        final totalLiveBirds = activeBatches.fold<int>(
          0,
          (sum, b) =>
              sum + (b.currentBirds > 0 ? b.currentBirds : b.totalBirds),
        );

        return Row(
          children: [
            // Total Live Birds
            Expanded(
              child: AppDesign.miniStatCard(
                icon: Icons.flutter_dash_rounded,
                iconColor: const Color(0xFF0284C7),
                value: totalLiveBirds > 0
                    ? NumberFormat('#,###').format(totalLiveBirds)
                    : '0',
                label: 'Birds',
              ),
            ),
            const SizedBox(width: 8),
            // Active Batches
            Expanded(
              child: AppDesign.miniStatCard(
                icon: Icons.grid_view_rounded,
                iconColor: const Color(0xFF16A34A),
                value: activeBatches.length.toString(),
                label: 'Active Batches',
              ),
            ),
            const SizedBox(width: 8),
            // Status
            Expanded(
              child: AppDesign.miniStatCard(
                icon: farm.isActive
                    ? Icons.check_circle_rounded
                    : Icons.pause_circle_rounded,
                iconColor: farm.isActive
                    ? const Color(0xFF16A34A)
                    : const Color(0xFF64748B),
                value: farm.isActive ? 'Active' : 'Inactive',
                label: 'Status',
              ),
            ),
          ],
        );
      },
    );
  }
}
