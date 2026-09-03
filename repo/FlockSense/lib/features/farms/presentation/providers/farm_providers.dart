import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flock_sense/features/auth/presentation/providers/auth_provider.dart';
import 'package:flock_sense/features/batches/data/batch_service.dart';
import 'package:flock_sense/features/batches/domain/batch_model.dart';
import 'package:flock_sense/features/farms/data/farm_service.dart';
import 'package:flock_sense/features/farms/domain/farm_model.dart';
import 'package:flock_sense/features/sheds/data/shed_service.dart';
import 'package:flock_sense/features/sheds/domain/shed_model.dart';

/// Real-time list of the signed-in user's farms from Firestore.
final farmListProvider = StreamProvider.autoDispose<List<FarmModel>>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (user) {
      if (user == null) return Stream.value(<FarmModel>[]);
      return FarmService.watchFarms(user.uid);
    },
    loading: () => Stream.value(<FarmModel>[]),
    error: (_, __) => Stream.value(<FarmModel>[]),
  );
});

/// Real-time stream of all batches owned by the user.
final allUserBatchesProvider = StreamProvider.autoDispose<List<BatchModel>>((
  ref,
) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (user) {
      if (user == null) return Stream.value(<BatchModel>[]);
      return BatchService.watchAllUserBatches(user.uid);
    },
    loading: () => Stream.value(<BatchModel>[]),
    error: (_, __) => Stream.value(<BatchModel>[]),
  );
});

/// Real-time stream of all sheds owned by the user.
final allUserShedsProvider = StreamProvider.autoDispose<List<ShedModel>>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (user) {
      if (user == null) return Stream.value(<ShedModel>[]);
      return ShedService.watchAllUserSheds(user.uid);
    },
    loading: () => Stream.value(<ShedModel>[]),
    error: (_, __) => Stream.value(<ShedModel>[]),
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

/// Pure helper for computing dashboard stats from lists of farms, batches, and sheds.
FarmDashboardStats calculateFarmDashboardStats({
  required List<FarmModel> farms,
  required List<BatchModel> batches,
  required List<ShedModel> sheds,
}) {
  final activeBatchesList = batches
      .where((b) => b.status.toLowerCase() == 'active')
      .toList();
  final activeBatchesCount = activeBatchesList.length;
  final currentBirdPopulation = activeBatchesList.fold<int>(
    0,
    (sum, b) => sum + (b.currentBirds > 0 ? b.currentBirds : b.totalBirds),
  );

  final shedCapacitySum = sheds.fold<int>(
    0,
    (sum, s) => sum + s.physicalCapacity,
  );
  final farmCapacitySum = farms.fold<int>(
    0,
    (sum, f) => sum + (f.capacity ?? 0),
  );
  final totalShedCapacity = shedCapacitySum > 0
      ? shedCapacitySum
      : farmCapacitySum;

  return FarmDashboardStats(
    totalFarms: farms.length,
    totalShedCapacity: totalShedCapacity,
    currentBirds: currentBirdPopulation,
    activeBatches: activeBatchesCount,
  );
}

final farmDashboardStatsProvider = Provider.autoDispose<FarmDashboardStats>((
  ref,
) {
  final farms = ref.watch(farmListProvider).value ?? <FarmModel>[];
  final batches = ref.watch(allUserBatchesProvider).value ?? <BatchModel>[];
  final sheds = ref.watch(allUserShedsProvider).value ?? <ShedModel>[];

  return calculateFarmDashboardStats(
    farms: farms,
    batches: batches,
    sheds: sheds,
  );
});
