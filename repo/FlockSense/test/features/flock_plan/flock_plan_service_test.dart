import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flock_sense/features/batches/domain/batch_model.dart';
import 'package:flock_sense/features/flock_plan/data/flock_plan_service.dart';
import 'package:flock_sense/features/flock_plan/domain/daily_plan_model.dart';
import 'package:flock_sense/features/flock_plan/domain/flock_lifecycle_standard.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FlockPlanService Tests', () {
    late BatchModel testBatch;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      final now = DateTime.now();
      testBatch = BatchModel(
        id: 'batch_test_101',
        farmId: 'farm_test_1',
        ownerId: 'user_1',
        batchName: 'Batch 101',
        breedOrFlockType: 'Cobb 500 Broiler',
        maleCount: 1500,
        femaleCount: 1500,
        totalBirds: 3000,
        currentBirds: 2950,
        hatchDate: now.subtract(const Duration(days: 14)),
        placementDate: now.subtract(const Duration(days: 13)), // Day 14 today
        status: 'active',
        createdAt: now,
        updatedAt: now,
      );
    });

    test('calculates flock age accurately from placement date', () {
      final age = FlockPlanService.getFlockAge(testBatch);
      expect(age, 14);

      final todayPlacedBatch = testBatch.copyWith(
        placementDate: DateTime.now(),
      );
      expect(FlockPlanService.getFlockAge(todayPlacedBatch), 1);
    });

    test('generates full cycle chart sync with 42 distinct days', () {
      final chart = FlockPlanService.getFullCycleChartSync(testBatch);
      expect(chart.length, 42);
      expect(chart.first.day, 1);
      expect(chart.last.day, 42);
      expect(chart.first.totalFeedKg, greaterThan(0));
      expect(chart.last.totalFeedKg, greaterThan(chart.first.totalFeedKg));
    });

    test('persists task completion toggle in SharedPreferences', () async {
      await FlockPlanService.toggleTaskCompletion(
        batchId: testBatch.id,
        day: 14,
        taskId: 'test_task_1',
        completed: true,
      );

      final prefs = await SharedPreferences.getInstance();
      final key = 'flock_plan_task_${testBatch.id}_d14_test_task_1';
      expect(prefs.getBool(key), isTrue);

      await FlockPlanService.toggleTaskCompletion(
        batchId: testBatch.id,
        day: 14,
        taskId: 'test_task_1',
        completed: false,
      );
      expect(prefs.getBool(key), isFalse);
    });

    test('verifies real-time telemetry & validation fields on DailyFlockPlan', () {
      const plan = DailyFlockPlan(
        day: 14,
        phase: 'Starter Phase',
        liveBirds: 2950,
        targetWeightGrams: 500,
        dailyFeedPerBirdGrams: 64,
        totalFeedKg: 188.8,
        dailyWaterPerBirdMl: 128,
        totalWaterLiters: 377.6,
        feedType: 'Starter Pellets',
        targetTempCelsius: 27.0,
        lightingHours: 18,
        isRealDataValidated: true,
        hasLoggedTodayRecord: true,
        actualFeedGivenKg: 185.0,
        actualWaterGivenLiters: 370.0,
        actualAvgWeightGrams: 495.0,
        actualMortalityToday: 2,
        cumulativeMortality: 50,
        cumulativeMortalityPct: 1.67,
        actualFcr: 1.28,
        feedStockDaysRemaining: 4.5,
        feedStockBagsAvailable: 17.0,
        tasks: [
          DailyPlanTask(
            id: 'feed_14',
            title: '✓ Feed Provided: 185.0 kg (Starter Pellets)',
            description: 'Logged 185.0 kg vs target 188.8 kg (98%).',
            category: TaskCategory.feeding,
            priority: TaskPriority.high,
            isCompleted: true,
            isRealRecordVerified: true,
            verificationNote: '185.0 kg logged in daily record',
          ),
          DailyPlanTask(
            id: 'vac_14',
            title: '✓ Vaccine Administered: Gumboro (IBD)',
            description: 'Administration verified from batch health logs.',
            category: TaskCategory.vaccine,
            priority: TaskPriority.critical,
            isCompleted: true,
            isRealRecordVerified: true,
            verificationNote: 'Verified from batch health logs',
          ),
        ],
        diagnosticAlerts: [
          'Feed stock: ~4.5 days remaining (17 bags).',
        ],
      );

      expect(plan.isRealDataValidated, isTrue);
      expect(plan.hasLoggedTodayRecord, isTrue);
      expect(plan.actualFeedGivenKg, 185.0);
      expect(plan.actualWaterGivenLiters, 370.0);
      expect(plan.actualAvgWeightGrams, 495.0);
      expect(plan.actualMortalityToday, 2);
      expect(plan.cumulativeMortality, 50);
      expect(plan.actualFcr, 1.28);
      expect(plan.feedStockDaysRemaining, 4.5);
      expect(plan.completedCount, 2);
      expect(plan.totalCount, 2);
      expect(plan.completionProgress, 1.0);

      // Verify task verification flags
      expect(plan.tasks.first.isRealRecordVerified, isTrue);
      expect(plan.tasks.first.verificationNote, contains('daily record'));
      expect(plan.tasks[1].isRealRecordVerified, isTrue);
      expect(plan.tasks[1].verificationNote, contains('health logs'));
    });

    test('verifies getStandardPlanForDay generates valid, non-null daily plan', () {
      final plan = FlockPlanService.getStandardPlanForDay(batch: testBatch, day: 1);
      expect(plan.day, 1);
      expect(plan.phase, 'Brooding Phase');
      expect(plan.totalFeedKg, greaterThan(0));
      expect(plan.totalWaterLiters, greaterThan(0));
      expect(plan.tasks.isNotEmpty, isTrue);
      expect(plan.tasks.any((t) => t.category == TaskCategory.feeding), isTrue);
      expect(plan.tasks.any((t) => t.category == TaskCategory.water), isTrue);
      expect(plan.tasks.any((t) => t.category == TaskCategory.environment), isTrue);
    });

    test('verifies standardFcr benchmark curve across lifecycle', () {
      final day1Std = FlockLifecycleStandard.getForDay(1);
      final day7Std = FlockLifecycleStandard.getForDay(7);
      final day21Std = FlockLifecycleStandard.getForDay(21);
      final day42Std = FlockLifecycleStandard.getForDay(42);

      expect(day1Std.standardFcr, greaterThan(0));
      expect(day7Std.standardFcr, greaterThan(0.8));
      expect(day21Std.standardFcr, greaterThan(day7Std.standardFcr));
      expect(day42Std.standardFcr, greaterThan(1.5));
    });
  });
}
