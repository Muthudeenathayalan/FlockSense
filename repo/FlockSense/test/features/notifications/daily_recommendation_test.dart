import 'package:flutter_test/flutter_test.dart';
import 'package:flock_sense/features/batches/domain/batch_model.dart';
import 'package:flock_sense/features/daily_records/domain/daily_record_model.dart';
import 'package:flock_sense/features/notifications/data/models/notification_model.dart';
import 'package:flock_sense/features/notifications/data/services/daily_recommendation_service.dart';

void main() {
  group('Daily Settings & Recommendations Tests', () {
    test('NotificationSettingsModel serializes daily push notification fields', () {
      const settings = NotificationSettingsModel(
        dailyReminderEnabled: true,
        dailyReminderTime: '19:30',
        dailySmartTipsEnabled: true,
      );

      final json = settings.toJson();
      expect(json['dailyReminderEnabled'], true);
      expect(json['dailyReminderTime'], '19:30');
      expect(json['dailySmartTipsEnabled'], true);

      final fromJson = NotificationSettingsModel.fromJson(json);
      expect(fromJson.dailyReminderEnabled, true);
      expect(fromJson.dailyReminderTime, '19:30');
      expect(fromJson.dailySmartTipsEnabled, true);

      final updated = settings.copyWith(dailyReminderTime: '08:00');
      expect(updated.dailyReminderTime, '08:00');
      expect(updated.dailyReminderEnabled, true);
    });

    test('DailyRecommendationService provides brooding guidance for young flock (Day 1)', () {
      final now = DateTime.now();
      final batch = BatchModel(
        id: 'batch_test_1',
        farmId: 'farm_test_1',
        ownerId: 'user_1',
        batchName: 'Brood Batch 101',
        breedOrFlockType: 'Cobb 500',
        maleCount: 1000,
        femaleCount: 1000,
        totalBirds: 2000,
        currentBirds: 2000,
        hatchDate: now,
        placementDate: now, // Day 1
        status: 'active',
        createdAt: now,
        updatedAt: now,
      );

      final guidance = DailyRecommendationService.getGuidanceForBatch(batch: batch);

      expect(guidance.ageDays, 1);
      expect(guidance.phase, contains('Brooding'));
      expect(guidance.targetTempCelsius, greaterThanOrEqualTo(32.0));
      expect(guidance.actionItems, isNotEmpty);
      expect(guidance.pushNotificationTitle, contains('Day 1 Log'));
      expect(guidance.pushNotificationBody, contains('Recommendation'));
    });

    test('DailyRecommendationService alerts scheduled vaccine on Day 7 (Lasota)', () {
      final now = DateTime.now();
      final batch = BatchModel(
        id: 'batch_test_7',
        farmId: 'farm_test_1',
        ownerId: 'user_1',
        batchName: 'Batch Day 7',
        breedOrFlockType: 'Ross 308',
        maleCount: 500,
        femaleCount: 500,
        totalBirds: 1000,
        currentBirds: 990,
        hatchDate: now.subtract(const Duration(days: 7)),
        placementDate: now.subtract(const Duration(days: 6)), // Day 7
        status: 'active',
        createdAt: now,
        updatedAt: now,
      );

      final guidance = DailyRecommendationService.getGuidanceForBatch(batch: batch);

      expect(guidance.ageDays, 7);
      expect(guidance.scheduledVaccine, isNotNull);
      expect(guidance.scheduledVaccine!.toLowerCase(), contains('lasota'));
      expect(guidance.actionItems.any((a) => a.contains('Vaccination due today')), isTrue);
    });

    test('DailyRecommendationService flags high mortality anomaly from latest telemetry', () {
      final now = DateTime.now();
      final batch = BatchModel(
        id: 'batch_mort_test',
        farmId: 'farm_test_1',
        ownerId: 'user_1',
        batchName: 'Batch High Mortality',
        breedOrFlockType: 'Cobb 500',
        maleCount: 500,
        femaleCount: 500,
        totalBirds: 1000,
        currentBirds: 980,
        hatchDate: now.subtract(const Duration(days: 11)),
        placementDate: now.subtract(const Duration(days: 10)),
        status: 'active',
        createdAt: now,
        updatedAt: now,
      );

      // Latest daily record shows 15 dead out of 980 (~1.53% mortality)
      final record = DailyRecordModel(
        id: 'rec_1',
        farmId: 'farm_test_1',
        batchId: 'batch_mort_test',
        recordDate: now.subtract(const Duration(days: 1)),
        batchAgeDay: 9,
        openingBirds: 980,
        mortalityCount: 15,
        cullCount: 0,
        adjustmentCount: 0,
        closingBirds: 965,
        feedConsumedKg: 80.0,
        waterConsumedLiters: 160.0,
        avgWeightGrams: 280.0,
        medicineGiven: false,
        vaccineGiven: false,
        ownerId: 'user_1',
        createdAt: now,
        updatedAt: now,
        temperature: 28.0,
        humidity: 60.0,
      );

      final guidance = DailyRecommendationService.getGuidanceForBatch(
        batch: batch,
        recentRecords: [record],
      );

      expect(guidance.primaryTip, contains('mortality'));
      expect(guidance.actionItems.any((a) => a.contains('High mortality detected')), isTrue);
    });

    test('DailyRecommendationService flags heat stress (THI >= 78) and water ratio anomalies', () {
      final now = DateTime.now();
      final batch = BatchModel(
        id: 'batch_heat_test',
        farmId: 'farm_test_1',
        ownerId: 'user_1',
        batchName: 'Heat Stress Batch',
        breedOrFlockType: 'Cobb 500',
        maleCount: 500,
        femaleCount: 500,
        totalBirds: 1000,
        currentBirds: 1000,
        hatchDate: now.subtract(const Duration(days: 21)),
        placementDate: now.subtract(const Duration(days: 20)),
        status: 'active',
        createdAt: now,
        updatedAt: now,
      );

      // Temperature 34°C, Humidity 75% -> THI = 0.8*34 + 0.75*(34-14.4) + 46.4 = 27.2 + 14.7 + 46.4 = 88.3 (High heat stress)
      // Water = 250L, Feed = 100kg -> ratio 2.5:1 (Elevated drinking / panting / leak)
      final record = DailyRecordModel(
        id: 'rec_heat',
        farmId: 'farm_test_1',
        batchId: 'batch_heat_test',
        recordDate: now.subtract(const Duration(days: 1)),
        batchAgeDay: 19,
        openingBirds: 1000,
        mortalityCount: 2,
        cullCount: 0,
        adjustmentCount: 0,
        closingBirds: 998,
        feedConsumedKg: 100.0,
        waterConsumedLiters: 250.0,
        avgWeightGrams: 850.0,
        medicineGiven: false,
        vaccineGiven: false,
        ownerId: 'user_1',
        createdAt: now,
        updatedAt: now,
        temperature: 34.0,
        humidity: 75.0,
      );

      final guidance = DailyRecommendationService.getGuidanceForBatch(
        batch: batch,
        recentRecords: [record],
      );

      expect(guidance.actionItems.any((a) => a.contains('Heat stress risk')), isTrue);
      expect(guidance.actionItems.any((a) => a.contains('Water-to-feed ratio is elevated')), isTrue);
    });
  });
}
