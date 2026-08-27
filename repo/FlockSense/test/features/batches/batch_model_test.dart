import 'package:flutter_test/flutter_test.dart';
import 'package:flock_sense/features/batches/domain/batch_model.dart';

void main() {
  group('BatchModel Validation & Calculation Tests', () {
    final testDate = DateTime(2026, 1, 10);

    test('validates placement bird counts', () {
      expect(BatchModel.isValidBirdCount(5000), isTrue);
      expect(BatchModel.isValidBirdCount(1), isTrue);
      expect(BatchModel.isValidBirdCount(0), isFalse);
      expect(BatchModel.isValidBirdCount(-10), isFalse);
    });

    test('validates placement dates', () {
      expect(BatchModel.isValidPlacementDate(DateTime(2026, 1, 1)), isTrue);
      expect(BatchModel.isValidPlacementDate(DateTime.now()), isTrue);
      expect(BatchModel.isValidPlacementDate(DateTime(2099, 1, 1)), isFalse);
    });

    test('calculates remaining birds accurately and handles edge cases', () {
      final remaining = BatchModel.calculateRemainingBirds(
        totalBirds: 5000,
        cumulativeMortality: 120,
        cumulativeCulls: 30,
        adjustments: 10,
      );
      expect(remaining, 4860);

      // Clamps to 0 if mortality exceeds placed birds
      final depleted = BatchModel.calculateRemainingBirds(
        totalBirds: 100,
        cumulativeMortality: 150,
        cumulativeCulls: 0,
      );
      expect(depleted, 0);
    });

    test('full BatchModel serialization and copyWith', () {
      final batch = BatchModel(
        id: 'b-101',
        farmId: 'f-1',
        shedId: 's-1',
        ownerId: 'u-1',
        batchName: 'Batch 101',
        hatchDate: testDate,
        placementDate: testDate,
        maleCount: 2500,
        femaleCount: 2500,
        totalBirds: 5000,
        currentBirds: 4920,
        breedOrFlockType: 'Cobb 500',
        chickAvgWeight: 42.5,
        status: 'active',
        createdAt: testDate,
        updatedAt: testDate,
      );

      final json = batch.toJson();
      expect(json['id'], 'b-101');
      expect(json['batchName'], 'Batch 101');
      expect(json['totalBirds'], 5000);
      expect(json['currentBirds'], 4920);
      expect(json['status'], 'active');

      final copy = BatchModel.fromJson(json);
      expect(copy.id, batch.id);
      expect(copy.farmId, batch.farmId);
      expect(copy.totalBirds, 5000);
      expect(copy.currentBirds, 4920);
      expect(copy.isActive, isTrue);
      expect(copy.isCompleted, isFalse);

      final updated = batch.copyWith(status: 'completed', currentBirds: 0);
      expect(updated.isActive, isFalse);
      expect(updated.isCompleted, isTrue);
      expect(updated.currentBirds, 0);
    });

    test('ShedAllocation serialization and copyWith', () {
      final allocation = ShedAllocation(
        shedId: 'shed-A',
        birdCount: 2500,
        startDate: testDate,
      );

      final json = allocation.toJson();
      expect(json['shedId'], 'shed-A');
      expect(json['birdCount'], 2500);

      final copy = ShedAllocation.fromJson(json);
      expect(copy.shedId, 'shed-A');
      expect(copy.birdCount, 2500);
    });
  });
}
