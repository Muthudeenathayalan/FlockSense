import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flock_sense/features/batches/presentation/screens/batch_command_center_screen.dart';
import 'package:flock_sense/features/farms/presentation/screens/farm_command_center_screen.dart';
import 'package:flock_sense/features/farms/domain/farm_model.dart';

void main() {
  final sampleFarm = FarmModel(
    id: 'farm_cc_1',
    userId: 'user_test',
    farmName: 'Command Farm',
    farmType: 'EC',
    flockType: 'Broiler',
    address: 'Green Valley, Tamil Nadu',
    lengthFt: 120,
    widthFt: 40,
    totalSqFt: 4800,
    capacity: 4000,
    createdAt: DateTime(2026, 9, 1),
    updatedAt: DateTime(2026, 9, 1),
  );

  group('Command Centers Segmented Tabs Tests', () {
    testWidgets('BatchCommandCenterScreen renders segments and toggles operations vs specifications', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: BatchCommandCenterScreen(
            farmId: 'farm_cc_1',
            batchId: 'batch_cc_1',
            batchName: 'Batch Alpha',
          ),
        ),
      );
      await tester.pump();

      // Verify segmented control items exist
      expect(find.text('Quick Operations'), findsWidgets);
      expect(find.text('Batch Specifications'), findsWidgets);

      // Tap on Batch Specifications segment
      await tester.tap(find.text('Batch Specifications'));
      await tester.pumpAndSettle();

      // Should show the title for specifications & schedule
      expect(find.text('Batch Profile & Schedule'), findsOneWidget);

      // Tap back to Quick Operations
      await tester.tap(find.text('Quick Operations').first);
      await tester.pumpAndSettle();

      expect(find.text('Daily Records'), findsOneWidget);
      expect(find.text('Bird Sales'), findsOneWidget);
    });

    testWidgets('FarmCommandCenterScreen renders 3-segment pill and toggles between Infrastructure, Operations, and Farm Specs', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          home: FarmCommandCenterScreen(
            farm: sampleFarm,
          ),
        ),
      );
      await tester.pump();

      // Verify the 3 segment labels
      expect(find.text('Infrastructure'), findsOneWidget);
      expect(find.text('Operations'), findsOneWidget);
      expect(find.text('Farm Specs'), findsOneWidget);

      // Tap on Operations
      await tester.tap(find.text('Operations'));
      await tester.pumpAndSettle();

      // Operations tab shows quick actions
      expect(find.text('Quick Actions'), findsOneWidget);
      expect(find.text('Daily Records'), findsOneWidget);
      expect(find.text('Feed Log'), findsOneWidget);
      expect(find.text('Medicine'), findsOneWidget);

      // Tap on Farm Specs
      await tester.tap(find.text('Farm Specs'));
      await tester.pumpAndSettle();

      // Farm Specs shows Farm Specifications
      expect(find.text('Farm Details & Specs'), findsOneWidget);
      expect(find.text('Total Area'), findsOneWidget);

      // Tap back to Infrastructure
      await tester.tap(find.text('Infrastructure'));
      await tester.pumpAndSettle();

      expect(find.text('Active Batches'), findsOneWidget);
      expect(find.text('SHEDS & HOUSES (0)'), findsOneWidget);
    });
  });
}
