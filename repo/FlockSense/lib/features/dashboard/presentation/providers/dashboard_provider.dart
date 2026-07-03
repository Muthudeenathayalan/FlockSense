import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flock_sense/features/dashboard/domain/entities/dashboard_metrics.dart';
import 'package:flock_sense/features/flock/presentation/providers/flock_provider.dart';

final dashboardMetricsProvider = Provider.autoDispose<DashboardMetrics>((ref) {
  final flocksAsync = ref.watch(flockListProvider);

  return flocksAsync.when(
    data: (flocks) {
      final totalBirds = flocks.fold<int>(0, (sum, flock) => sum + flock.openingCount);
      final targetFcrs = flocks.map((flock) => flock.targetFcr).whereType<double>().toList();
      final averageTargetFcr = targetFcrs.isEmpty ? 0.0 : targetFcrs.reduce((a, b) => a + b) / targetFcrs.length;
      return DashboardMetrics(
        totalFlocks: flocks.length,
        totalBirds: totalBirds,
        averageTargetFcr: averageTargetFcr,
        totalMortality: 0,
        totalFeedKg: 0.0,
        revenue: 0.0,
        expenses: 0.0,
        profitLoss: 0.0,
        pendingVaccinations: 0,
      );
    },
    loading: () => DashboardMetrics.empty,
    error: (error, _) => DashboardMetrics.empty,
  );
});
