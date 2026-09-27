import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flock_sense/features/batches/domain/batch_model.dart';
import 'package:flock_sense/features/flock_plan/data/flock_plan_service.dart';
import 'package:flock_sense/features/flock_plan/presentation/screens/flock_plan_screen.dart';
import 'package:flock_sense/features/home/presentation/widgets/home_action_plan_button.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Dynamic Lifecycle Days and Zero Mock Data Tests', () {
    test('BatchModel computes cycleTargetDays dynamically from hatchDate to targetDeliveryDate', () {
      final hatch = DateTime(2026, 9, 1);
      final delivery35 = DateTime(2026, 10, 6); // 35 days
      final delivery45 = DateTime(2026, 10, 16); // 45 days

      final batch35 = BatchModel(
        id: 'b1',
        farmId: 'f1',
        ownerId: 'u1',
        batchName: 'Batch 35',
        hatchDate: hatch,
        placementDate: hatch,
        targetDeliveryDate: delivery35,
        maleCount: 250,
        femaleCount: 250,
        totalBirds: 500,
        currentBirds: 500,
        breedOrFlockType: 'Broiler',
        createdAt: hatch,
        updatedAt: hatch,
      );

      final batch45 = batch35.copyWith(
        id: 'b2',
        batchName: 'Batch 45',
        targetDeliveryDate: delivery45,
      );

      final batchDefault = BatchModel(
        id: 'b3',
        farmId: 'f1',
        ownerId: 'u1',
        batchName: 'Batch Standard',
        hatchDate: hatch,
        placementDate: hatch,
        maleCount: 250,
        femaleCount: 250,
        totalBirds: 500,
        currentBirds: 500,
        breedOrFlockType: 'Broiler',
        createdAt: hatch,
        updatedAt: hatch,
      );

      expect(batch35.cycleTargetDays, 35);
      expect(batch45.cycleTargetDays, 45);
      expect(batchDefault.cycleTargetDays, 42);
    });

    test('FlockPlanService.getFullCycleChartSync generates exactly cycleTargetDays count with no mock data', () {
      final hatch = DateTime(2026, 9, 1);
      final delivery38 = DateTime(2026, 10, 9); // 38 days

      final batch = BatchModel(
        id: 'b38',
        farmId: 'f1',
        ownerId: 'u1',
        batchName: 'Batch 38',
        hatchDate: hatch,
        placementDate: hatch,
        targetDeliveryDate: delivery38,
        maleCount: 400,
        femaleCount: 400,
        totalBirds: 800,
        currentBirds: 780,
        breedOrFlockType: 'Ross 308',
        createdAt: hatch,
        updatedAt: hatch,
      );

      final chart = FlockPlanService.getFullCycleChartSync(batch);

      expect(chart.length, 38);
      expect(chart.first.day, 1);
      expect(chart.last.day, 38);
      // Verify real bird count is used instead of 1000 fallback
      expect(chart.first.liveBirds, 780);
      expect(chart.last.liveBirds, 780);
    });

    testWidgets('FlockPlanScreen dynamically displays 35-Day Chart tab for a 35-day batch', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final now = DateTime.now();
      final hatch = now;
      final delivery = now.add(const Duration(days: 35));

      final batch = BatchModel(
        id: 'b35',
        farmId: 'f1',
        ownerId: 'u1',
        batchName: 'Quick Cycle Batch',
        hatchDate: hatch,
        placementDate: hatch,
        targetDeliveryDate: delivery,
        maleCount: 300,
        femaleCount: 300,
        totalBirds: 600,
        currentBirds: 600,
        breedOrFlockType: 'Cobb 500',
        createdAt: now,
        updatedAt: now,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: FlockPlanScreen(
            farmId: 'f1',
            batch: batch,
          ),
        ),
      );

      await tester.pump();

      // Dynamic tab label
      expect(find.text('35-Day Chart'), findsOneWidget);
    });

    testWidgets('HomeActionPlanButton renders compactly and navigates to FlockPlanScreen', (tester) async {
      final now = DateTime.now();
      final batch = BatchModel(
        id: 'b1',
        farmId: 'f1',
        ownerId: 'u1',
        batchName: 'Alpha Flock',
        hatchDate: now,
        placementDate: now,
        targetDeliveryDate: now.add(const Duration(days: 42)),
        maleCount: 500,
        femaleCount: 500,
        totalBirds: 1000,
        currentBirds: 980,
        breedOrFlockType: 'Broiler',
        createdAt: now,
        updatedAt: now,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HomeActionPlanButton(
              batch: batch,
              farmId: 'f1',
              farmName: 'Green Valley Farm',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text("Today's Action Plan"), findsOneWidget);
      expect(find.text('View Plan'), findsOneWidget);
      expect(find.textContaining('Day 1'), findsOneWidget);

      // Tap on button opens full plan screen
      await tester.tap(find.text("Today's Action Plan"));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(FlockPlanScreen), findsOneWidget);
    });
  });
}
