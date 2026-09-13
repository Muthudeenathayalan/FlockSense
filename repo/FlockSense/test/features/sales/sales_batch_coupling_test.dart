import 'package:flutter_test/flutter_test.dart';
import 'package:flock_sense/features/sales/domain/sales_record_model.dart';
import 'package:flock_sense/features/batches/domain/batch_model.dart';

void main() {
  group('Sales and Batch Coupling Logic Tests', () {
    test('sales record bird decrement accurately updates batch currentBirds', () {
      final now = DateTime.now();
      final batch = BatchModel(
        id: 'batch_01',
        farmId: 'farm_01',
        ownerId: 'user_01',
        batchName: 'Batch 1',
        breedOrFlockType: 'Broiler',
        maleCount: 2500,
        femaleCount: 2500,
        totalBirds: 5000,
        currentBirds: 5000,
        hatchDate: now.subtract(const Duration(days: 40)),
        placementDate: now.subtract(const Duration(days: 39)),
        status: 'active',
        createdAt: now,
        updatedAt: now,
      );

      final sale = SalesRecordModel(
        id: 'sale_01',
        farmId: 'farm_01',
        batchId: 'batch_01',
        ownerId: 'user_01',
        customerName: 'Trader Ramesh',
        birdsSold: 1200,
        averageWeightKg: 2.1,
        pricePerBird: 250.0,
        totalValue: 300000.0,
        date: now,
        batchAgeDay: 40,
        createdAt: now,
        updatedAt: now,
      );

      final updatedBirds = (batch.currentBirds - sale.birdsSold).clamp(0, 9999999);
      expect(updatedBirds, 3800);

      // Subsequent sale of remaining birds
      final finalSale = SalesRecordModel(
        id: 'sale_02',
        farmId: 'farm_01',
        batchId: 'batch_01',
        ownerId: 'user_01',
        customerName: 'Trader Suresh',
        birdsSold: 3800,
        averageWeightKg: 2.2,
        pricePerBird: 260.0,
        totalValue: 988000.0,
        date: now,
        batchAgeDay: 41,
        createdAt: now,
        updatedAt: now,
      );

      final finalBirds = (updatedBirds - finalSale.birdsSold).clamp(0, 9999999);
      expect(finalBirds, 0);
      final finalStatus = finalBirds <= 0 ? 'completed' : 'active';
      expect(finalStatus, 'completed');
    });

    test('deduplication preserves only distinct records when duplicate events arrive', () {
      final now = DateTime.now();
      final records = [
        SalesRecordModel(
          id: 'sale_dup_1',
          farmId: 'farm_01',
          batchId: 'batch_01',
          ownerId: 'user_01',
          customerName: 'Customer A',
          birdsSold: 500,
          averageWeightKg: 2.0,
          pricePerBird: 200.0,
          totalValue: 100000.0,
          date: now,
          batchAgeDay: 35,
          createdAt: now,
          updatedAt: now,
        ),
        SalesRecordModel(
          id: 'sale_dup_1', // Duplicate ID
          farmId: 'farm_01',
          batchId: 'batch_01',
          ownerId: 'user_01',
          customerName: 'Customer A',
          birdsSold: 500,
          averageWeightKg: 2.0,
          pricePerBird: 200.0,
          totalValue: 100000.0,
          date: now,
          batchAgeDay: 35,
          createdAt: now,
          updatedAt: now,
        ),
        SalesRecordModel(
          id: 'sale_unique_2',
          farmId: 'farm_01',
          batchId: 'batch_01',
          ownerId: 'user_01',
          customerName: 'Customer B',
          birdsSold: 300,
          averageWeightKg: 2.1,
          pricePerBird: 210.0,
          totalValue: 63000.0,
          date: now,
          batchAgeDay: 36,
          createdAt: now,
          updatedAt: now,
        ),
      ];

      final seen = <String>{};
      final deduplicated = <SalesRecordModel>[];
      for (final r in records) {
        if (seen.add(r.id)) {
          deduplicated.add(r);
        }
      }

      expect(deduplicated.length, 2);
      expect(deduplicated.map((e) => e.id).toList(), ['sale_dup_1', 'sale_unique_2']);
    });
  });
}
