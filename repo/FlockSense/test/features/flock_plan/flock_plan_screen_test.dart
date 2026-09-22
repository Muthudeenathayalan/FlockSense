import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flock_sense/features/batches/domain/batch_model.dart';
import 'package:flock_sense/features/flock_plan/presentation/screens/flock_plan_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('FlockPlanScreen renders without error and shows daily plan', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final now = DateTime.now();
    final batch = BatchModel(
      id: 'batch_test_1',
      farmId: 'farm_test_1',
      ownerId: 'user_1',
      batchName: 'Batch 1.1',
      breedOrFlockType: 'Cobb 500',
      maleCount: 500,
      femaleCount: 500,
      totalBirds: 1000,
      currentBirds: 990,
      hatchDate: now,
      placementDate: now,
      status: 'active',
      createdAt: now,
      updatedAt: now,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: FlockPlanScreen(
          farmId: 'farm_test_1',
          batch: batch,
        ),
      ),
    );

    // Initial pump
    await tester.pump();

    // Verify AppBar
    expect(find.text('Flock Action Plan & Lifecycle Chart'), findsOneWidget);
    expect(find.textContaining('Batch 1.1'), findsOneWidget);

    // Let's check what's visible initially
    expect(find.textContaining('FLOCK DAY 1'), findsOneWidget);
    expect(find.text("Today's Action Checklist"), findsOneWidget);

    // Wait for _loadData to complete
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    expect(find.textContaining('FLOCK DAY 1'), findsOneWidget);
    expect(find.text("Today's Action Checklist"), findsOneWidget);

    // Verify TabBar has This Week and 42-Day Chart
    expect(find.text('This Week'), findsOneWidget);
    expect(find.text('42-Day Chart'), findsOneWidget);

    // Switch to This Week tab
    await tester.tap(find.text('This Week'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Week 1'), findsWidgets);
  });
}
