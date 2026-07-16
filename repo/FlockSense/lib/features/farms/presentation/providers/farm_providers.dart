import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flock_sense/features/auth/presentation/providers/auth_provider.dart';
import 'package:flock_sense/features/farms/data/farm_service.dart';
import 'package:flock_sense/features/farms/domain/farm_model.dart';

/// Real-time list of the signed-in user's farms from Firestore.
final farmListProvider = StreamProvider.autoDispose<List<FarmModel>>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (user) {
      if (user == null) return const Stream<List<FarmModel>>.empty();
      return FarmService.watchFarms(user.uid);
    },
    loading: () => const Stream<List<FarmModel>>.empty(),
    error: (_, __) => const Stream<List<FarmModel>>.empty(),
  );
});

/// Aggregate stats derived from farmListProvider — powers the Home dashboard.
class FarmDashboardStats {
  final int totalFarms;
  final int totalShedCapacity;
  final int currentBirds;
  final int activeBatches;
  const FarmDashboardStats({
    required this.totalFarms,
    required this.totalShedCapacity,
    required this.currentBirds,
    required this.activeBatches,
  });
  static const empty = FarmDashboardStats(
    totalFarms: 0,
    totalShedCapacity: 0,
    currentBirds: 0,
    activeBatches: 0,
  );
}

final farmDashboardStatsProvider = Provider.autoDispose<FarmDashboardStats>((
  ref,
) {
  final farmsAsync = ref.watch(farmListProvider);
  return farmsAsync.when(
    data: (farms) => FarmDashboardStats(
      totalFarms: farms.length,
      totalShedCapacity: 0, // TODO: Sum from all sheds across farms
      currentBirds: 0, // TODO: Sum from active batches
      activeBatches: 0, // TODO: Count active batches
    ),
    loading: () => FarmDashboardStats.empty,
    error: (_, __) => FarmDashboardStats.empty,
  );
});
