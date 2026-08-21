import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flock_sense/features/auth/presentation/providers/auth_provider.dart';
import 'package:flock_sense/features/batches/domain/batch_model.dart';
import 'package:flock_sense/features/farms/domain/farm_model.dart';
import 'package:flock_sense/features/farms/presentation/providers/farm_providers.dart';

import 'package:flock_sense/features/daily_records/domain/daily_record_model.dart';

String _formatTodayRecordDate() {
  final now = DateTime.now();
  return '${now.year.toString().padLeft(4, '0')}-'
      '${now.month.toString().padLeft(2, '0')}-'
      '${now.day.toString().padLeft(2, '0')}';
}

final latestDgRecordProvider = StreamProvider.autoDispose<DailyRecordModel?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (user) {
      if (user == null) return Stream<DailyRecordModel?>.value(null);
      return FirebaseFirestore.instance
          .collectionGroup('dailyRecords')
          .where('ownerId', isEqualTo: user.uid)
          .snapshots()
          .map((snap) {
            for (final doc in snap.docs) {
              final data = doc.data();
              if (data['dgLevelLiters'] != null) {
                return DailyRecordModel.fromJson(data);
              }
            }
            return null;
          }).handleError((_) => null);
    },
    loading: () => Stream<DailyRecordModel?>.value(null),
    error: (err, stack) => Stream<DailyRecordModel?>.value(null),
  );
});

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
    error: (err, stack) => Stream<String?>.value(null),
  );
});

final allUserBatchesProvider = StreamProvider.autoDispose<List<BatchModel>>((
  ref,
) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (user) {
      if (user == null) return Stream.value(<BatchModel>[]);
      return FirebaseFirestore.instance
          .collectionGroup('batches')
          .where('ownerId', isEqualTo: user.uid)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map((doc) => BatchModel.fromJson(doc.data()))
                .toList(),
          )
          .handleError((_) => <BatchModel>[]);
    },
    loading: () => Stream.value(<BatchModel>[]),
    error: (err, stack) => Stream.value(<BatchModel>[]),
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
          })
          .handleError((_) => 0);
    },
    loading: () => Stream<int>.value(0),
    error: (err, stack) => Stream<int>.value(0),
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

      final farms = farmsValue.value ?? <FarmModel>[];
      final activeFarmId = activeFarmIdValue.value;
      final batches = batchesValue.value ?? <BatchModel>[];
      final todayMortality = mortalityValue.value ?? 0;

      FarmModel? activeFarm;
      if (activeFarmId != null) {
        for (final farm in farms) {
          if (farm.id == activeFarmId) {
            activeFarm = farm;
            break;
          }
        }
      }
      if (activeFarm == null && farms.isNotEmpty) {
        activeFarm = farms.first;
      }

      final activeBatchCount = batches
          .where((batch) => batch.status == 'active')
          .length;
      final liveBirds = batches
          .where((batch) => batch.status == 'active')
          .fold<int>(0, (total, batch) => total + batch.currentBirds);

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
