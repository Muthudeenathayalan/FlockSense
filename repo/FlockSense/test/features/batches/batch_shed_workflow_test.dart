import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flock_sense/core/exceptions/app_exceptions.dart';
import 'package:flock_sense/features/batches/data/batch_service.dart';
import 'package:flock_sense/features/batches/domain/batch_model.dart';
import 'package:flock_sense/features/farms/domain/farm_model.dart';
import 'package:flock_sense/features/farms/presentation/widgets/farm_active_batches_section.dart';
import 'package:flock_sense/features/farms/presentation/widgets/farm_sheds_section.dart';
import 'package:flock_sense/features/sheds/domain/shed_model.dart';

void main() {
  final sampleFarm = FarmModel(
    id: 'farm_123',
    userId: 'user_123',
    farmName: 'Test Farm 1',
    farmType: 'EC',
    flockType: 'Broiler',
    address: 'Nedungur, Trichy',
    lengthFt: 100,
    widthFt: 80,
    totalSqFt: 8000,
    capacity: 6667,
    createdAt: DateTime(2026, 9, 25),
    updatedAt: DateTime(2026, 9, 25),
  );

  final sampleShed = ShedModel(
    id: 'shed_123',
    farmId: 'farm_123',
    ownerId: 'user_123',
    name: 'Shed 1',
    lengthFt: 100,
    widthFt: 80,
    totalSqFt: 8000,
    capacity: 10667,
    createdAt: DateTime(2026, 9, 25),
    updatedAt: DateTime(2026, 9, 25),
  );

  group('Farm -> Shed -> Batch Workflow & Prerequisite Tests', () {
    test('BatchService.createBatch throws ValidationException if shedId is omitted or empty', () async {
      expect(
        () => BatchService.createBatch(
          farmId: 'farm_123',
          shedId: null,
          batchName: 'Batch 1',
          lengthFt: 100,
          widthFt: 80,
          sizeUnit: 'ft',
          hatchDate: DateTime(2026, 9, 20),
          placementDate: DateTime(2026, 9, 25),
          maleCount: 100,
          femaleCount: 100,
          breedOrFlockType: 'Broiler',
        ),
        throwsA(isA<AppException>()),
      );

      expect(
        () => BatchService.createBatch(
          farmId: 'farm_123',
          shedId: '   ',
          batchName: 'Batch 1',
          lengthFt: 100,
          widthFt: 80,
          sizeUnit: 'ft',
          hatchDate: DateTime(2026, 9, 20),
          placementDate: DateTime(2026, 9, 25),
          maleCount: 100,
          femaleCount: 100,
          breedOrFlockType: 'Broiler',
        ),
        throwsA(isA<AppException>()),
      );
    });

    testWidgets('FarmActiveBatchesSection shows "Shed Required First" when farm has 0 sheds', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: FarmActiveBatchesSection(
                farm: sampleFarm,
                sheds: const <ShedModel>[],
                batches: const <BatchModel>[],
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Shed Required First'), findsOneWidget);
      expect(find.text('Create a shed before placing flock batches'), findsOneWidget);
      expect(find.text('Add Shed First'), findsOneWidget);
      expect(find.text('Add First Batch'), findsNothing);
    });

    testWidgets('FarmActiveBatchesSection shows "No Active Batches" & "Add First Batch" when shed exists', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: FarmActiveBatchesSection(
                farm: sampleFarm,
                sheds: [sampleShed],
                batches: const <BatchModel>[],
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('No Active Batches'), findsOneWidget);
      expect(find.text('Start a new flock cycle on this farm'), findsOneWidget);
      expect(find.text('Add First Batch'), findsOneWidget);
      expect(find.text('Add Shed First'), findsNothing);
    });

    testWidgets('FarmShedsSection displays "Create Batch" and empty sanitized label without overflow', (tester) async {
      FlutterErrorDetails? errorDetails;
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {
        errorDetails = details;
        debugPrint('FLUTTER_ERROR: ${details.exceptionAsString()}');
      };
      addTearDown(() {
        FlutterError.onError = originalOnError;
      });

      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: FarmShedsSection(
                farm: sampleFarm,
                sheds: [sampleShed],
                batches: const <BatchModel>[],
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Shed is empty & sanitized'), findsOneWidget);
      expect(find.text('Create Batch'), findsOneWidget);
      expect(errorDetails, isNull);
    });
  });
}
