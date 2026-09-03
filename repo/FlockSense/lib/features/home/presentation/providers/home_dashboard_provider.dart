import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flock_sense/features/auth/presentation/providers/auth_provider.dart';
import 'package:flock_sense/features/batches/data/batch_service.dart';
import 'package:flock_sense/features/batches/domain/batch_model.dart';
import 'package:flock_sense/features/farms/domain/farm_model.dart';
import 'package:flock_sense/features/farms/presentation/providers/farm_providers.dart';
import 'package:flock_sense/features/daily_records/data/daily_record_service.dart';
import 'package:flock_sense/features/daily_records/domain/daily_record_model.dart';

export 'package:flock_sense/features/farms/presentation/providers/farm_providers.dart'
    show allUserBatchesProvider;

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
    error: (err, stack) => Stream<String?>.value(null),
  );
});

final recentDailyRecordsProvider =
    StreamProvider.autoDispose<List<DailyRecordModel>>((ref) {
      final authState = ref.watch(authStateProvider);
      return authState.when(
        data: (user) {
          if (user == null) return Stream.value(<DailyRecordModel>[]);
          return DailyRecordService.watchAllUserDailyRecords(user.uid);
        },
        loading: () => Stream.value(<DailyRecordModel>[]),
        error: (_, __) => Stream.value(<DailyRecordModel>[]),
      );
    });

final todayMortalityProvider = StreamProvider.autoDispose<int>((ref) async* {
  final records = ref.watch(recentDailyRecordsProvider).value ?? const [];
  final now = DateTime.now();
  var total = 0;
  for (final doc in records) {
    if (doc.recordDate.year == now.year &&
        doc.recordDate.month == now.month &&
        doc.recordDate.day == now.day) {
      total += doc.mortalityCount.toInt();
    }
  }
  yield total;
});

final latestDgRecordProvider =
    StreamProvider.autoDispose<DailyRecordModel?>((ref) async* {
      final records = ref.watch(recentDailyRecordsProvider).value ?? const [];
      DailyRecordModel? found;
      for (final doc in records) {
        if (doc.dgLevelLiters != null) {
          found = doc;
          break;
        }
      }
      yield found;
    });

class HomeDashboardData {
  const HomeDashboardData({
    required this.farms,
    required this.activeFarm,
    required this.activeBatchCount,
    required this.liveBirds,
    required this.todayMortality,
    this.recentRecords = const <DailyRecordModel>[],
  });

  final List<FarmModel> farms;
  final FarmModel? activeFarm;
  final int activeBatchCount;
  final int liveBirds;
  final int todayMortality;
  final List<DailyRecordModel> recentRecords;

  static const empty = HomeDashboardData(
    farms: <FarmModel>[],
    activeFarm: null,
    activeBatchCount: 0,
    liveBirds: 0,
    todayMortality: 0,
    recentRecords: <DailyRecordModel>[],
  );
}

final homeDashboardDataProvider =
    Provider.autoDispose<AsyncValue<HomeDashboardData>>((ref) {
      final farmsValue = ref.watch(farmListProvider);
      final activeFarmIdValue = ref.watch(activeFarmIdProvider);
      final batchesValue = ref.watch(allUserBatchesProvider);
      final mortalityValue = ref.watch(todayMortalityProvider);
      final recordsValue = ref.watch(recentDailyRecordsProvider);

      final farms = farmsValue.value ?? <FarmModel>[];
      final activeFarmId = activeFarmIdValue.value;
      final batches = batchesValue.value ?? <BatchModel>[];
      final todayMortality = mortalityValue.value ?? 0;
      final recentRecords = recordsValue.value ?? <DailyRecordModel>[];

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
          .where((batch) => batch.isActive)
          .length;
      final liveBirds = batches
          .where((batch) => batch.isActive)
          .fold<int>(0, (total, batch) => total + batch.currentBirds);

      return AsyncValue.data(
        HomeDashboardData(
          farms: farms,
          activeFarm: activeFarm,
          activeBatchCount: activeBatchCount,
          liveBirds: liveBirds,
          todayMortality: todayMortality,
          recentRecords: recentRecords,
        ),
      );
    });
