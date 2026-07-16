import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flock_sense/features/farms/presentation/providers/farm_providers.dart';
import 'package:flock_sense/features/dashboard/domain/entities/dashboard_metrics.dart';

/// Derives dashboard metrics from the live farm stream.
/// Previously referenced flock.openingCount and flock.targetFcr which
/// do not exist — replaced with safe farm-based aggregation.
final dashboardMetricsProvider = Provider.autoDispose<DashboardMetrics>((ref) {
  final farmsAsync = ref.watch(farmListProvider);
  return farmsAsync.when(
    data: (farms) => DashboardMetrics(
      totalFarms: farms.length,
      activeFarms: farms.where((f) => f.status == 'active').length,
      totalCapacity: farms.fold(0, (sum, f) => sum + (f.capacity ?? 0)),
    ),
    loading: () =>
        const DashboardMetrics(totalFarms: 0, activeFarms: 0, totalCapacity: 0),
    error: (_, __) =>
        const DashboardMetrics(totalFarms: 0, activeFarms: 0, totalCapacity: 0),
  );
});
