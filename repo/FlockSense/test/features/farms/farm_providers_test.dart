import 'package:flutter_test/flutter_test.dart';
import 'package:flock_sense/features/batches/domain/batch_model.dart';
import 'package:flock_sense/features/farms/domain/farm_model.dart';
import 'package:flock_sense/features/farms/presentation/providers/farm_providers.dart';
import 'package:flock_sense/features/sheds/domain/shed_model.dart';

void main() {
  group('FarmDashboardStats calculations', () {
    final testDate = DateTime(2026, 1, 1);

    test('returns zeros when all lists are empty', () {
      final stats = calculateFarmDashboardStats(
        farms: [],
        batches: [],
        sheds: [],
      );

      expect(stats.totalFarms, 0);
      expect(stats.totalShedCapacity, 0);
      expect(stats.currentBirds, 0);
      expect(stats.activeBatches, 0);
    });

    test(
      'computes bird population and active count from active batches only',
      () {
        final activeBatch1 = BatchModel(
          id: 'b1',
          farmId: 'f1',
          ownerId: 'u1',
          batchName: 'Batch 1',
          hatchDate: testDate,
          placementDate: testDate,
          maleCount: 1000,
          femaleCount: 1500,
          totalBirds: 2500,
          currentBirds: 2450,
          breedOrFlockType: 'Broiler',
          status: 'active',
          createdAt: testDate,
          updatedAt: testDate,
        );

        final activeBatch2 = BatchModel(
          id: 'b2',
          farmId: 'f2',
          ownerId: 'u1',
          batchName: 'Batch 2',
          hatchDate: testDate,
          placementDate: testDate,
          maleCount: 2000,
          femaleCount: 2000,
          totalBirds: 4000,
          currentBirds: 3900,
          breedOrFlockType: 'Layer',
          status: 'active',
          createdAt: testDate,
          updatedAt: testDate,
        );

        final completedBatch = BatchModel(
          id: 'b3',
          farmId: 'f1',
          ownerId: 'u1',
          batchName: 'Batch Old',
          hatchDate: testDate,
          placementDate: testDate,
          maleCount: 500,
          femaleCount: 500,
          totalBirds: 1000,
          currentBirds: 0,
          breedOrFlockType: 'Broiler',
          status: 'completed',
          createdAt: testDate,
          updatedAt: testDate,
        );

        final stats = calculateFarmDashboardStats(
          farms: [
            FarmModel(
              id: 'f1',
              userId: 'u1',
              farmName: 'Farm A',
              farmType: 'EC',
              flockType: 'Broiler',
              address: 'Addr',
              lengthFt: 100,
              widthFt: 40,
              totalSqFt: 4000,
              capacity: 5000,
              createdAt: testDate,
              updatedAt: testDate,
            ),
          ],
          batches: [activeBatch1, activeBatch2, completedBatch],
          sheds: [],
        );

        expect(stats.totalFarms, 1);
        expect(stats.activeBatches, 2);
        expect(stats.currentBirds, 6350); // 2450 + 3900
        expect(stats.totalShedCapacity, 5000); // from farm capacity
      },
    );

    test(
      'prioritizes shed capacity sum over farm capacity when sheds are present',
      () {
        final shed1 = ShedModel(
          id: 's1',
          farmId: 'f1',
          ownerId: 'u1',
          name: 'Shed 1',
          lengthFt: 50,
          widthFt: 30,
          totalSqFt: 1500,
          capacity: 3000,
          createdAt: testDate,
          updatedAt: testDate,
        );

        final shed2 = ShedModel(
          id: 's2',
          farmId: 'f1',
          ownerId: 'u1',
          name: 'Shed 2',
          lengthFt: 50,
          widthFt: 30,
          totalSqFt: 1500,
          capacity: 3500,
          createdAt: testDate,
          updatedAt: testDate,
        );

        final stats = calculateFarmDashboardStats(
          farms: [
            FarmModel(
              id: 'f1',
              userId: 'u1',
              farmName: 'Farm 1',
              farmType: 'EC',
              flockType: 'Broiler',
              address: 'Addr',
              lengthFt: 100,
              widthFt: 60,
              totalSqFt: 6000,
              capacity: 10000,
              createdAt: testDate,
              updatedAt: testDate,
            ),
          ],
          batches: [],
          sheds: [shed1, shed2],
        );

        expect(stats.totalShedCapacity, 6500); // 3000 + 3500
      },
    );
  });
}
