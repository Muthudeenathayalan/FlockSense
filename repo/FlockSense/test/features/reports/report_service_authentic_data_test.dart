import 'package:flutter_test/flutter_test.dart';
import 'package:flock_sense/features/reports/data/report_service.dart';
import 'package:flock_sense/features/reports/data/report_history_service.dart';
import 'package:flock_sense/features/reports/domain/report_data.dart';
import 'package:flock_sense/features/farms/domain/farm_model.dart';
import 'package:flock_sense/features/batches/domain/batch_model.dart';
import 'package:flock_sense/features/daily_records/domain/daily_record_model.dart';
import 'package:flock_sense/features/vaccine/domain/vaccine_record_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ReportService Authentic User Data Tests', () {
    test('getFallbackReportData returns clean empty model with zero synthetic items', () {
      final fallback = ReportService.getFallbackReportData();

      expect(fallback.farm.id, isEmpty);
      expect(fallback.farm.farmName, 'No Farm Selected');
      expect(fallback.batch.id, isEmpty);
      expect(fallback.batch.totalBirds, 0);
      expect(fallback.batch.currentBirds, 0);
      expect(fallback.farms, isEmpty);
      expect(fallback.batches, isEmpty);
      expect(fallback.sheds, isEmpty);
      expect(fallback.dailyRecords, isEmpty);
      expect(fallback.feedTransactions, isEmpty);
      expect(fallback.medicineRecords, isEmpty);
      expect(fallback.vaccineRecords, isEmpty);
      expect(fallback.birdSales, isEmpty);
      expect(fallback.inventoryItems, isEmpty);
      expect(fallback.totalMortality, 0);
      expect(fallback.totalFeedKg, 0.0);
      expect(fallback.totalBirdsSold, 0);
      expect(fallback.totalRevenue, 0.0);
    });

    test('ReportHistoryService returns empty list when no user history has been recorded', () async {
      final history = await ReportHistoryService.getHistory();
      expect(history, isEmpty);
    });

    test('Farming technique audit correctly detects disadvantages, advantages, and financial leakage', () {
      final now = DateTime.now();
      final farm = FarmModel(
        id: 'farm_1',
        userId: 'owner_1',
        ownerId: 'owner_1',
        farmName: 'Sunrise Broiler Farm',
        farmType: 'Broiler',
        flockType: 'Commercial',
        address: 'Madurai',
        lengthFt: 100,
        widthFt: 30,
        totalSqFt: 3000,
        createdAt: now,
        updatedAt: now,
      );

      final batch = BatchModel(
        id: 'batch_1',
        farmId: 'farm_1',
        ownerId: 'owner_1',
        batchName: 'Batch A',
        hatchDate: now.subtract(const Duration(days: 35)),
        placementDate: now.subtract(const Duration(days: 35)),
        maleCount: 500,
        femaleCount: 500,
        totalBirds: 1000,
        currentBirds: 975,
        breedOrFlockType: 'Cobb 500',
        createdAt: now,
        updatedAt: now,
      );

      // Daily records simulating high FCR (1.70) and elevated water:feed ratio (2.35:1)
      final dailyRecords = [
        DailyRecordModel(
          id: 'rec_1',
          farmId: 'farm_1',
          batchId: 'batch_1',
          recordDate: now.subtract(const Duration(days: 1)),
          batchAgeDay: 35,
          openingBirds: 980,
          mortalityCount: 5,
          cullCount: 0,
          adjustmentCount: 0,
          closingBirds: 975,
          feedConsumedKg: 3480.0, // High feed consumed => FCR ~ 1.70
          waterConsumedLiters: 8180.0, // Water ratio = 8180 / 3480 = 2.35
          avgWeightGrams: 2100.0,
          medicineGiven: false,
          vaccineGiven: true,
          vaccineName: 'Lasota Booster',
          ownerId: 'owner_1',
          temperature: 32.5, // Heat peak
          createdAt: now,
          updatedAt: now,
        ),
      ];

      final vaccineRecords = [
        VaccineRecordModel(
          id: 'v1',
          farmId: 'farm_1',
          batchId: 'batch_1',
          ownerId: 'owner_1',
          date: now.subtract(const Duration(days: 20)),
          batchAgeDay: 15,
          vaccineName: 'Gumboro IBD',
          vaccineType: 'Live',
          quantity: 1000,
          unit: 'doses',
          route: 'Drinking Water',
          createdAt: now,
          updatedAt: now,
        ),
      ];

      final report = ReportData(
        farm: farm,
        batch: batch,
        farms: [farm],
        batches: [batch],
        sheds: [],
        dailyRecords: dailyRecords,
        feedTransactions: [],
        medicineRecords: [],
        vaccineRecords: vaccineRecords,
        birdSales: [],
        inventoryItems: [],
        generatedAt: now,
      );

      // 1. Verify Disadvantages Detected
      final disadvantages = report.techniqueDisadvantages;
      expect(disadvantages, isNotEmpty);
      expect(disadvantages.any((d) => d.category == 'Feeding & FCR'), isTrue);
      expect(disadvantages.any((d) => d.category == 'Water & Litter Hygiene'), isTrue);
      expect(disadvantages.any((d) => d.category == 'Climate & Ventilation'), isTrue);

      // 2. Verify Financial Leakage Calculation
      final totalLoss = report.totalTechniqueFinancialLeakage;
      expect(totalLoss, greaterThan(0.0));
      expect(report.excessFeedCostRs, greaterThan(0.0));

      // 3. Verify Advantages Detected
      final advantages = report.techniqueAdvantages;
      expect(advantages, isNotEmpty);
      expect(advantages.any((a) => a.title.contains('Biosecurity')), isTrue);
      expect(advantages.any((a) => a.title.contains('Immunization')), isTrue);

      // 4. Verify Benchmark Matrix
      final matrix = report.benchmarkMatrix;
      expect(matrix.length, equals(6));
      expect(matrix.map((m) => m['metric']), containsAll([
        'Average Body Weight',
        'Feed Conversion (FCR)',
        'Flock Mortality',
        'Water : Feed Ratio',
        'Average Daily Gain (ADG)',
        'Production Index (EPEF)',
      ]));

      // 5. Verify Action Plan Generation
      final actions = report.techniqueActionPlan;
      expect(actions, isNotEmpty);
      expect(actions.any((a) => a.contains('feeder')), isTrue);
    });
  });
}
