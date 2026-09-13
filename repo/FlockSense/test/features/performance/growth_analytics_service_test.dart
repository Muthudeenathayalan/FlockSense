import 'package:flutter_test/flutter_test.dart';
import 'package:flock_sense/features/batches/domain/batch_model.dart';
import 'package:flock_sense/features/daily_records/domain/daily_record_model.dart';
import 'package:flock_sense/features/farms/domain/farm_model.dart';
import 'package:flock_sense/features/performance/data/growth_analytics_service.dart';
import 'package:flock_sense/features/performance/domain/growth_analytics_model.dart';

void main() {
  group('GrowthAnalyticsService Calculations & Data Consistency Tests', () {
    final testDate = DateTime(2026, 1, 1);
    final service = GrowthAnalyticsService();

    final testFarm = FarmModel(
      id: 'f-1',
      userId: 'u-1',
      farmName: 'Farm Green',
      farmType: 'Open',
      flockType: 'Broiler',
      address: 'Zone A',
      lengthFt: 100,
      widthFt: 40,
      totalSqFt: 4000,
      createdAt: testDate,
      updatedAt: testDate,
    );

    final testBatch = BatchModel(
      id: 'b-1',
      farmId: 'f-1',
      shedId: 's-1',
      ownerId: 'u-1',
      batchName: 'Batch Alpha',
      hatchDate: testDate,
      placementDate: testDate,
      maleCount: 500,
      femaleCount: 500,
      totalBirds: 1000,
      currentBirds: 1000,
      breedOrFlockType: 'Cobb 500',
      chickAvgWeight: 42.0, // 42g
      status: 'active',
      createdAt: testDate,
      updatedAt: testDate,
    );

    DailyRecordModel createRecord({
      required int day,
      required int opening,
      required int closing,
      required int mortality,
      int culls = 0,
      required double feedKg,
      required double weightGrams,
      double? temperature,
      double? humidity,
    }) {
      return DailyRecordModel(
        id: 'r-$day',
        farmId: 'f-1',
        batchId: 'b-1',
        recordDate: testDate.add(Duration(days: day - 1)),
        batchAgeDay: day,
        openingBirds: opening,
        mortalityCount: mortality,
        cullCount: culls,
        adjustmentCount: 0,
        closingBirds: closing,
        feedConsumedKg: feedKg,
        waterConsumedLiters: feedKg * 2,
        avgWeightGrams: weightGrams,
        medicineGiven: false,
        vaccineGiven: false,
        temperature: temperature,
        humidity: humidity,
        ownerId: 'u-1',
        createdAt: testDate,
        updatedAt: testDate,
      );
    }

    test('calculates standard commercial broiler FCR accurately based on live biomass', () {
      // Placed: 1000 birds.
      // Day 1: 1000 birds, 50kg feed, 160g weight
      // Day 2: 995 closing birds (5 mort), 80kg feed, 300g weight (0.300 kg)
      // Total Feed = 130 kg
      // Total Live Biomass = 995 * 0.300 = 298.5 kg
      // Expected FCR = 130 / 298.5 = 0.4355... -> 0.44
      final records = [
        createRecord(
          day: 1,
          opening: 1000,
          closing: 1000,
          mortality: 0,
          feedKg: 50,
          weightGrams: 160,
        ),
        createRecord(
          day: 2,
          opening: 1000,
          closing: 995,
          mortality: 5,
          feedKg: 80,
          weightGrams: 300,
        ),
      ];

      final analytics = service.processAnalytics(
        farms: [testFarm],
        batches: [testBatch],
        activeFarm: testFarm,
        activeBatch: testBatch,
        filter: const GrowthAnalyticsFilterState(),
        rawRecords: records,
        rawMedicine: [],
        rawVaccine: [],
        rawSales: [],
      );

      expect(analytics.fcr, 0.44);
      expect(analytics.currentBirds, 995);
      expect(analytics.feedConsumedKg, 130.0);
      expect(analytics.averageWeightGrams, 300.0);
    });

    test('handles records with zero weighed weight without fabricating fake FCR or PEF', () {
      // Feed logged, but birds were not weighed on these days
      final records = [
        createRecord(
          day: 1,
          opening: 1000,
          closing: 1000,
          mortality: 0,
          feedKg: 50,
          weightGrams: 0,
        ),
        createRecord(
          day: 2,
          opening: 1000,
          closing: 1000,
          mortality: 0,
          feedKg: 60,
          weightGrams: 0,
        ),
      ];

      final analytics = service.processAnalytics(
        farms: [testFarm],
        batches: [testBatch],
        activeFarm: testFarm,
        activeBatch: testBatch,
        filter: const GrowthAnalyticsFilterState(),
        rawRecords: records,
        rawMedicine: [],
        rawVaccine: [],
        rawSales: [],
      );

      // Should not fabricate FCR when weight is unmeasured
      expect(analytics.fcr, 0.0);
      expect(analytics.pef, isNull);
      expect(analytics.avgDailyGainGrams, 0.0);
    });

    test('aggregates both mortality and culls into total bird loss and authoritative live birds', () {
      final records = [
        createRecord(
          day: 1,
          opening: 1000,
          closing: 980,
          mortality: 15,
          culls: 5,
          feedKg: 50,
          weightGrams: 160,
        ),
        createRecord(
          day: 2,
          opening: 980,
          closing: 965,
          mortality: 10,
          culls: 5,
          feedKg: 60,
          weightGrams: 220,
        ),
      ];

      final analytics = service.processAnalytics(
        farms: [testFarm],
        batches: [testBatch],
        activeFarm: testFarm,
        activeBatch: testBatch,
        filter: const GrowthAnalyticsFilterState(),
        rawRecords: records,
        rawMedicine: [],
        rawVaccine: [],
        rawSales: [],
      );

      // Total mortality + culls = (15 + 5) + (10 + 5) = 35
      expect(analytics.mortalityCount, 35);
      expect(analytics.currentBirds, 965);
      expect(analytics.mortalityPercentage, 3.5);
    });

    test('populates weightGrowthPoints with Day 0 starting chick weight and true batchAgeDay', () {
      final records = [
        createRecord(
          day: 7,
          opening: 1000,
          closing: 990,
          mortality: 10,
          feedKg: 150,
          weightGrams: 185,
        ),
        createRecord(
          day: 14,
          opening: 990,
          closing: 985,
          mortality: 5,
          feedKg: 350,
          weightGrams: 500,
        ),
      ];

      final analytics = service.processAnalytics(
        farms: [testFarm],
        batches: [testBatch],
        activeFarm: testFarm,
        activeBatch: testBatch,
        filter: const GrowthAnalyticsFilterState(),
        rawRecords: records,
        rawMedicine: [],
        rawVaccine: [],
        rawSales: [],
      );

      // Point 0: Day 0 Chick weight (42g = 0.042kg)
      expect(analytics.weightGrowthPoints.length, 3);
      expect(analytics.weightGrowthPoints[0].day, 0);
      expect(analytics.weightGrowthPoints[0].value, 0.042);
      expect(analytics.weightGrowthPoints[0].label, 'D0');

      // Point 1: Day 7
      expect(analytics.weightGrowthPoints[1].day, 7);
      expect(analytics.weightGrowthPoints[1].value, 0.185);
      expect(analytics.weightGrowthPoints[1].label, 'D7');

      // Point 2: Day 14
      expect(analytics.weightGrowthPoints[2].day, 14);
      expect(analytics.weightGrowthPoints[2].value, 0.500);
      expect(analytics.weightGrowthPoints[2].label, 'D14');
    });

    test('hasEnvironmentalData is false when no telemetry is logged and true when logged', () {
      final noEnvRecords = [
        createRecord(
          day: 1,
          opening: 1000,
          closing: 1000,
          mortality: 0,
          feedKg: 50,
          weightGrams: 160,
        ),
      ];

      final analyticsNoEnv = service.processAnalytics(
        farms: [testFarm],
        batches: [testBatch],
        activeFarm: testFarm,
        activeBatch: testBatch,
        filter: const GrowthAnalyticsFilterState(),
        rawRecords: noEnvRecords,
        rawMedicine: [],
        rawVaccine: [],
        rawSales: [],
      );

      expect(analyticsNoEnv.hasEnvironmentalData, isFalse);

      final withEnvRecords = [
        createRecord(
          day: 1,
          opening: 1000,
          closing: 1000,
          mortality: 0,
          feedKg: 50,
          weightGrams: 160,
          temperature: 31.5,
          humidity: 65.0,
        ),
      ];

      final analyticsWithEnv = service.processAnalytics(
        farms: [testFarm],
        batches: [testBatch],
        activeFarm: testFarm,
        activeBatch: testBatch,
        filter: const GrowthAnalyticsFilterState(),
        rawRecords: withEnvRecords,
        rawMedicine: [],
        rawVaccine: [],
        rawSales: [],
      );

      expect(analyticsWithEnv.hasEnvironmentalData, isTrue);
    });

    test('calculates EPEF (PEF) accurately when valid telemetry exists', () {
      // 35 days, 5000 birds placed, 150 mortality/cull (4850 remaining = 97.0% livability)
      // Avg weight: 2100g (2.1 kg)
      // Total Feed = 15277.5 kg
      // Live Biomass = 4850 * 2.1 = 10185 kg
      // FCR = 15277.5 / 10185 = 1.50
      // PEF = (97.0 * 2.1) / (35 * 1.50) * 100 = 203.7 / 52.5 * 100 = 388.0
      final largeBatch = testBatch.copyWith(totalBirds: 5000, currentBirds: 4850);
      final records = [
        createRecord(
          day: 35,
          opening: 4860,
          closing: 4850,
          mortality: 100,
          culls: 50,
          feedKg: 15277.5,
          weightGrams: 2100,
        ),
      ];

      final analytics = service.processAnalytics(
        farms: [testFarm],
        batches: [largeBatch],
        activeFarm: testFarm,
        activeBatch: largeBatch,
        filter: const GrowthAnalyticsFilterState(),
        rawRecords: records,
        rawMedicine: [],
        rawVaccine: [],
        rawSales: [],
      );

      expect(analytics.fcr, 1.50);
      expect(analytics.pef, isNotNull);
      expect(analytics.pef, 388.0);
    });
  });
}
