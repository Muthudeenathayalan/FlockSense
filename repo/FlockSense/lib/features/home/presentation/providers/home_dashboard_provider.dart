import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flock_sense/features/auth/presentation/providers/auth_provider.dart';
import 'package:flock_sense/features/batches/domain/batch_model.dart';
import 'package:flock_sense/features/farms/domain/farm_model.dart';
import 'package:flock_sense/features/farms/presentation/providers/farm_providers.dart';

String _formatTodayRecordDate() {
  final now = DateTime.now();
  return '${now.year.toString().padLeft(4, '0')}-'
      '${now.month.toString().padLeft(2, '0')}-'
      '${now.day.toString().padLeft(2, '0')}';
}

final activeFarmIdProvider = StreamProvider.autoDispose<String?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (user) {
      if (user == null) return Stream<String?>.value(null);
      return FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots()
          .map((snapshot) => snapshot.data()?['activeFarmId'] as String?);
    },
    loading: () => Stream<String?>.value(null),
    error: (_, __) => Stream<String?>.value(null),
  );
});

final allUserBatchesProvider = StreamProvider.autoDispose<List<BatchModel>>((
  ref,
) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (user) {
      if (user == null) return Stream<List<BatchModel>>.empty();
      return FirebaseFirestore.instance
          .collectionGroup('batches')
          .where('ownerId', isEqualTo: user.uid)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map((doc) => BatchModel.fromJson(doc.data()))
                .toList(),
          );
    },
    loading: () => Stream<List<BatchModel>>.empty(),
    error: (_, __) => Stream<List<BatchModel>>.empty(),
  );
});

final todayMortalityProvider = StreamProvider.autoDispose<int>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (user) {
      if (user == null) return Stream<int>.value(0);
      final todayId = _formatTodayRecordDate();
      return FirebaseFirestore.instance
          .collectionGroup('dailyRecords')
          .where('ownerId', isEqualTo: user.uid)
          .where('recordDate', isEqualTo: todayId)
          .snapshots()
          .map((snapshot) {
            var total = 0;
            for (final doc in snapshot.docs) {
              final mortality = doc.data()['mortalityCount'];
              if (mortality is int) {
                total += mortality;
              } else if (mortality is double) {
                total += mortality.toInt();
              } else if (mortality is String) {
                total += int.tryParse(mortality) ?? 0;
              }
            }
            return total;
          });
    },
    loading: () => Stream<int>.value(0),
    error: (_, __) => Stream<int>.value(0),
  );
});

class HomeDashboardData {
  const HomeDashboardData({
    required this.farms,
    required this.activeFarm,
    required this.activeBatchCount,
    required this.liveBirds,
    required this.todayMortality,
  });

  final List<FarmModel> farms;
  final FarmModel? activeFarm;
  final int activeBatchCount;
  final int liveBirds;
  final int todayMortality;

  static const empty = HomeDashboardData(
    farms: <FarmModel>[],
    activeFarm: null,
    activeBatchCount: 0,
    liveBirds: 0,
    todayMortality: 0,
  );
}

final homeDashboardDataProvider =
    Provider.autoDispose<AsyncValue<HomeDashboardData>>((ref) {
      final farmsValue = ref.watch(farmListProvider);
      final activeFarmIdValue = ref.watch(activeFarmIdProvider);
      final batchesValue = ref.watch(allUserBatchesProvider);
      final mortalityValue = ref.watch(todayMortalityProvider);

      if (farmsValue.isLoading ||
          activeFarmIdValue.isLoading ||
          batchesValue.isLoading ||
          mortalityValue.isLoading) {
        return AsyncValue<HomeDashboardData>.loading();
      }

      if (farmsValue.hasError) {
        return AsyncValue<HomeDashboardData>.error(
          farmsValue.error!,
          farmsValue.stackTrace ?? StackTrace.current,
        );
      }
      if (activeFarmIdValue.hasError) {
        return AsyncValue<HomeDashboardData>.error(
          activeFarmIdValue.error!,
          activeFarmIdValue.stackTrace ?? StackTrace.current,
        );
      }
      if (batchesValue.hasError) {
        return AsyncValue<HomeDashboardData>.error(
          batchesValue.error!,
          batchesValue.stackTrace ?? StackTrace.current,
        );
      }
      if (mortalityValue.hasError) {
        return AsyncValue<HomeDashboardData>.error(
          mortalityValue.error!,
          mortalityValue.stackTrace ?? StackTrace.current,
        );
      }

      final farms = farmsValue.value ?? <FarmModel>[];
      final activeFarmId = activeFarmIdValue.value;
      FarmModel? activeFarm;
      if (activeFarmId != null) {
        for (final farm in farms) {
          if (farm.id == activeFarmId) {
            activeFarm = farm;
            break;
          }
        }
      }
      final batches = batchesValue.value ?? <BatchModel>[];
      final activeBatchCount = batches
          .where((batch) => batch.status == 'active')
          .length;
      final liveBirds = batches
          .where((batch) => batch.status == 'active')
          .fold<int>(0, (sum, batch) => sum + batch.currentBirds);
      final todayMortality = mortalityValue.value ?? 0;

      return AsyncValue.data(
        HomeDashboardData(
          farms: farms,
          activeFarm: activeFarm,
          activeBatchCount: activeBatchCount,
          liveBirds: liveBirds,
          todayMortality: todayMortality,
        ),
      );
    });
