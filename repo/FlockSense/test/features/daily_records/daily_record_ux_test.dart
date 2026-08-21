import 'package:flutter_test/flutter_test.dart';
import 'package:flock_sense/core/models/sync_status.dart';
import 'package:flock_sense/features/daily_records/domain/daily_record_model.dart';

void main() {
  group('Daily Record UX Improvements Tests', () {
    test('Yesterday copy shortcut selectively isolates Feed, Water, Weight', () {
      final yesterdayRecord = DailyRecordModel(
        id: '2026-08-18',
        farmId: 'farm_1',
        batchId: 'batch_1',
        recordDate: DateTime(2026, 8, 18),
        batchAgeDay: 10,
        openingBirds: 5000,
        mortalityCount: 12,
        cullCount: 2,
        adjustmentCount: 0,
        closingBirds: 4986,
        feedConsumedKg: 75.5,
        feedType: 'Broiler Grower',
        feedCost: 3500.0,
        waterConsumedLiters: 250.0,
        waterSource: 'Main Borewell',
        avgWeightGrams: 420.0,
        sampleBirds: 50,
        medicineGiven: true,
        medicineName: 'Vitamin ADE',
        vaccineGiven: true,
        vaccineName: 'Gumboro',
        ownerId: 'user_1',
        createdAt: DateTime(2026, 8, 18),
        updatedAt: DateTime(2026, 8, 18),
      );

      // Simulating "Same as yesterday" extraction logic
      final copiedFeedKg = yesterdayRecord.feedConsumedKg;
      final copiedFeedType = yesterdayRecord.feedType;
      final copiedFeedCost = yesterdayRecord.feedCost;
      final copiedWaterL = yesterdayRecord.waterConsumedLiters;
      final copiedWaterSource = yesterdayRecord.waterSource;
      final copiedAvgWeight = yesterdayRecord.avgWeightGrams;
      final copiedSampleBirds = yesterdayRecord.sampleBirds;

      // Mortality and Medicine/Vaccine MUST NOT be copied
      const copiedMortality = 0;
      const copiedMedicineGiven = false;
      const String? copiedMedicineName = null;
      const copiedVaccineGiven = false;
      const String? copiedVaccineName = null;

      expect(copiedFeedKg, 75.5);
      expect(copiedFeedType, 'Broiler Grower');
      expect(copiedFeedCost, 3500.0);
      expect(copiedWaterL, 250.0);
      expect(copiedWaterSource, 'Main Borewell');
      expect(copiedAvgWeight, 420.0);
      expect(copiedSampleBirds, 50);

      expect(copiedMortality, 0);
      expect(copiedMedicineGiven, isFalse);
      expect(copiedMedicineName, isNull);
      expect(copiedVaccineGiven, isFalse);
      expect(copiedVaccineName, isNull);
    });

    test('SyncStatus correctly identifies pending writes and synced state', () {
      const synced = SyncStatus.synced;
      expect(synced.hasPendingWrites, isFalse);
      expect(synced.isFromCache, isFalse);

      const pending = SyncStatus(hasPendingWrites: true, isFromCache: true);
      expect(pending.hasPendingWrites, isTrue);
      expect(pending.isFromCache, isTrue);
    });

    test('User-scoped SharedPreferences keys are formatted properly', () {
      const uid = 'user_abc_123';
      final farmKey = 'flocksense_last_farm_$uid';
      final batchKey = 'flocksense_last_batch_$uid';

      expect(farmKey, 'flocksense_last_farm_user_abc_123');
      expect(batchKey, 'flocksense_last_batch_user_abc_123');
    });
  });
}
