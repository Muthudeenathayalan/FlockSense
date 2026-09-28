import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flock_sense/features/batches/domain/batch_model.dart';
import 'package:flock_sense/features/daily_records/domain/daily_record_model.dart';
import 'package:flock_sense/features/flock_plan/data/flock_plan_service.dart';
import 'package:flock_sense/features/flock_plan/presentation/screens/flock_plan_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('FlockPlanScreen with live screenshot 4 data renders without blank screen or errors', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final now = DateTime.now();
    final batch = BatchModel(
      id: 'batch_live_1',
      farmId: 'farm_live_1',
      ownerId: 'user_1',
      batchName: 'Shed 1 - Batch 27/9',
      breedOrFlockType: 'Cobb 500',
      maleCount: 500,
      femaleCount: 500,
      totalBirds: 1000,
      currentBirds: 998,
      hatchDate: now,
      placementDate: now,
      targetDeliveryDate: now.add(const Duration(days: 60)), // 60-day chart
      status: 'active',
      createdAt: now,
      updatedAt: now,
    );

    final dailyRecord = DailyRecordModel(
      id: 'rec_1',
      farmId: 'farm_live_1',
      batchId: 'batch_live_1',
      recordDate: now,
      batchAgeDay: 1,
      openingBirds: 1000,
      mortalityCount: 2,
      cullCount: 0,
      adjustmentCount: 0,
      closingBirds: 998,
      feedConsumedKg: 25.0,
      waterConsumedLiters: 50.0,
      avgWeightGrams: 0.0, // 0 weight
      medicineGiven: false,
      vaccineGiven: false,
      ownerId: 'user_1',
      createdAt: now,
      updatedAt: now,
    );

    // Test getPlanForSpecificDay directly
    final plan = await FlockPlanService.getPlanForSpecificDay(
      farmId: 'farm_live_1',
      batch: batch,
      day: 1,
      prefetchedDailyRecords: [dailyRecord],
    );

    expect(plan.day, 1);
    expect(plan.liveBirds, 998);
    expect(plan.actualFeedGivenKg, 25.0);
    expect(plan.actualWaterGivenLiters, 50.0);
    expect(plan.actualAvgWeightGrams, isNull);
    expect(plan.actualMortalityToday, 2);
    expect(plan.cumulativeMortality, 2);

    // Pump widget
    await tester.pumpWidget(
      MaterialApp(
        home: FlockPlanScreen(
          farmId: 'farm_live_1',
          batch: batch,
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    // Verify TabBar
    expect(find.text('Today (Day 1)'), findsOneWidget);
    expect(find.text('This Week'), findsOneWidget);
    expect(find.text('60-Day Chart'), findsOneWidget);

    // Verify today's plan content is displayed (NOT blank)
    expect(find.textContaining('FLOCK DAY 1'), findsOneWidget);
    expect(find.text("Today's Action Checklist"), findsOneWidget);
  });
}
