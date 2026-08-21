import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flock_sense/core/models/sync_status.dart';
import 'package:flock_sense/features/auth/presentation/providers/auth_provider.dart';
import 'package:flock_sense/features/daily_records/data/daily_record_service.dart';
import 'package:flock_sense/features/daily_records/domain/daily_record_model.dart';
import 'package:flock_sense/features/home/presentation/providers/home_dashboard_provider.dart';

class DailyRecordFarmNotifier extends Notifier<String?> {
  @override
  String? build() => null;
  void selectFarm(String? farmId) => state = farmId;
}

final dailyRecordFarmIdProvider =
    NotifierProvider<DailyRecordFarmNotifier, String?>(DailyRecordFarmNotifier.new);

class DailyRecordBatchNotifier extends Notifier<String?> {
  @override
  String? build() => null;
  void selectBatch(String? batchId) => state = batchId;
}

final dailyRecordBatchIdProvider =
    NotifierProvider<DailyRecordBatchNotifier, String?>(DailyRecordBatchNotifier.new);

class DailyRecordDateNotifier extends Notifier<DateTime> {
  @override
  DateTime build() => DateTime.now();
  void setDate(DateTime date) => state = date;
}

final dailyRecordDateProvider =
    NotifierProvider<DailyRecordDateNotifier, DateTime>(DailyRecordDateNotifier.new);

class DailyRecordSearchNotifier extends Notifier<String> {
  @override
  String build() => '';
  void setQuery(String query) => state = query;
}

final dailyRecordSearchQueryProvider =
    NotifierProvider<DailyRecordSearchNotifier, String>(DailyRecordSearchNotifier.new);

class DailyRecordFilterNotifier extends Notifier<String> {
  @override
  String build() => 'All';
  void setFilter(String filter) => state = filter;
}

final dailyRecordFilterCategoryProvider =
    NotifierProvider<DailyRecordFilterNotifier, String>(DailyRecordFilterNotifier.new);

class DailyRecordSortNotifier extends Notifier<String> {
  @override
  String build() => 'Newest';
  void setSort(String sort) => state = sort;
}

final dailyRecordSortOrderProvider =
    NotifierProvider<DailyRecordSortNotifier, String>(DailyRecordSortNotifier.new);

final dailyRecordsStreamProvider = StreamProvider.autoDispose<List<DailyRecordModel>>((ref) {
  final authState = ref.watch(authStateProvider);
  final activeFarmId = ref.watch(activeFarmIdProvider).asData?.value;
  final selectedFarmId = ref.watch(dailyRecordFarmIdProvider) ?? activeFarmId;
  final selectedBatchId = ref.watch(dailyRecordBatchIdProvider);

  final user = authState.asData?.value;
  final uid = user?.uid ?? 'local_user';

  if (selectedFarmId != null &&
      selectedFarmId.isNotEmpty &&
      selectedBatchId != null &&
      selectedBatchId.isNotEmpty) {
    return DailyRecordService.watchDailyRecords(
      farmId: selectedFarmId,
      batchId: selectedBatchId,
    );
  }

  return DailyRecordService.watchAllUserDailyRecords(uid);
});

final dailyRecordSyncStatusProvider = StreamProvider.autoDispose<SyncStatus>((ref) {
  final authState = ref.watch(authStateProvider);
  final activeFarmId = ref.watch(activeFarmIdProvider).asData?.value;
  final selectedFarmId = ref.watch(dailyRecordFarmIdProvider) ?? activeFarmId;
  final selectedBatchId = ref.watch(dailyRecordBatchIdProvider);

  final user = authState.asData?.value;
  if (user == null || selectedFarmId == null || selectedBatchId == null) {
    return Stream.value(SyncStatus.synced);
  }
  return DailyRecordService.watchSyncStatus(
    farmId: selectedFarmId,
    batchId: selectedBatchId,
  );
});

final filteredDailyRecordsProvider = Provider.autoDispose<List<DailyRecordModel>>((ref) {
  final records = ref.watch(dailyRecordsStreamProvider).value ?? [];
  final query = ref.watch(dailyRecordSearchQueryProvider).toLowerCase().trim();
  final filter = ref.watch(dailyRecordFilterCategoryProvider);
  final sort = ref.watch(dailyRecordSortOrderProvider);

  var list = records.where((r) {
    // 1. Search Query Filter (Date, Medicine, Feed, Vaccine)
    final dateStr =
        '${r.recordDate.year}-${r.recordDate.month.toString().padLeft(2, '0')}-${r.recordDate.day.toString().padLeft(2, '0')}';
    final matchesQuery = query.isEmpty ||
        dateStr.contains(query) ||
        (r.medicineName?.toLowerCase().contains(query) ?? false) ||
        (r.feedType?.toLowerCase().contains(query) ?? false) ||
        (r.vaccineName?.toLowerCase().contains(query) ?? false) ||
        (r.notes?.toLowerCase().contains(query) ?? false);

    if (!matchesQuery) return false;

    // 2. Category Filter (All, Feed, Water, Mortality, Medicine, Vaccination, Weight, Environment)
    switch (filter) {
      case 'Feed':
        return r.feedConsumedKg > 0 || (r.feedType != null && r.feedType!.isNotEmpty);
      case 'Water':
        return r.waterConsumedLiters > 0 || (r.waterSource != null && r.waterSource!.isNotEmpty);
      case 'Mortality':
        return r.mortalityCount > 0 || (r.mortalityCause != null && r.mortalityCause!.isNotEmpty);
      case 'Medicine':
        return r.medicineGiven || (r.medicineName != null && r.medicineName!.isNotEmpty);
      case 'Vaccination':
        return r.vaccineGiven || (r.vaccineName != null && r.vaccineName!.isNotEmpty);
      case 'Weight':
        return r.avgWeightGrams > 0;
      case 'Environment':
        return r.temperature != null || r.humidity != null || r.weather != null;
      case 'All':
      default:
        return true;
    }
  }).toList();

  // 3. Sorting (Newest vs Oldest)
  if (sort == 'Oldest') {
    list.sort((a, b) => a.recordDate.compareTo(b.recordDate));
  } else {
    list.sort((a, b) => b.recordDate.compareTo(a.recordDate));
  }

  return list;
});

class DailyRecordStats {
  final double feedUsedToday;
  final double waterUsedToday;
  final int currentBirds;
  final int todaysMortality;
  final double averageWeight;
  final String medicineUsedToday;
  final String upcomingVaccination;

  const DailyRecordStats({
    required this.feedUsedToday,
    required this.waterUsedToday,
    required this.currentBirds,
    required this.todaysMortality,
    required this.averageWeight,
    required this.medicineUsedToday,
    required this.upcomingVaccination,
  });

  static const empty = DailyRecordStats(
    feedUsedToday: 0.0,
    waterUsedToday: 0.0,
    currentBirds: 0,
    todaysMortality: 0,
    averageWeight: 0.0,
    medicineUsedToday: 'None',
    upcomingVaccination: 'None Scheduled',
  );
}

final dailyRecordsStatsProvider = Provider.autoDispose<DailyRecordStats>((ref) {
  final records = ref.watch(dailyRecordsStreamProvider).value ?? [];
  if (records.isEmpty) return DailyRecordStats.empty;

  final now = DateTime.now();
  final todayStart = DateTime(now.year, now.month, now.day);

  double todayFeed = 0.0;
  double todayWater = 0.0;
  int todayMortality = 0;
  double latestWeight = 0.0;
  int currentBirds = 0;
  final medicines = <String>[];
  String upcomingVaccine = 'None Scheduled';

  for (final r in records) {
    final isToday = r.recordDate.year == todayStart.year &&
        r.recordDate.month == todayStart.month &&
        r.recordDate.day == todayStart.day;

    if (isToday) {
      todayFeed += r.feedConsumedKg;
      todayWater += r.waterConsumedLiters;
      todayMortality += r.mortalityCount;
      if (r.medicineGiven && r.medicineName != null && r.medicineName!.isNotEmpty) {
        medicines.add(r.medicineName!);
      }
    }

    if (latestWeight == 0.0 && r.avgWeightGrams > 0) {
      latestWeight = r.avgWeightGrams;
    }
    if (currentBirds == 0 && r.closingBirds > 0) {
      currentBirds = r.closingBirds;
    }

    if (r.vaccineNextDueDate != null && r.vaccineNextDueDate!.isAfter(now)) {
      final name = r.vaccineName ?? 'Vaccine';
      final dueStr =
          '${r.vaccineNextDueDate!.day}/${r.vaccineNextDueDate!.month}';
      upcomingVaccine = '$name (Due $dueStr)';
    }
  }

  return DailyRecordStats(
    feedUsedToday: todayFeed,
    waterUsedToday: todayWater,
    currentBirds: currentBirds,
    todaysMortality: todayMortality,
    averageWeight: latestWeight,
    medicineUsedToday: medicines.isEmpty ? 'None' : medicines.join(', '),
    upcomingVaccination: upcomingVaccine,
  );
});
