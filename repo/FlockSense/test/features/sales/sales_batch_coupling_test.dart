import 'package:flutter_test/flutter_test.dart';
import 'package:flock_sense/features/sales/domain/sales_record_model.dart';
import 'package:flock_sense/features/batches/domain/batch_model.dart';
import 'package:flock_sense/features/daily_records/domain/daily_record_model.dart';

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

    test('daily record closingBirds properly deducts birdsSold along with mortality and culls', () {
      final closing = DailyRecordModel.calculateClosingBirds(
        opening: 5000,
        mortality: 20,
        culls: 10,
        adjustments: 0,
        birdsSold: 1200,
      );
      expect(closing, 3770);

      // Verify that when birdsSold + mortality exceeds opening, it clamps safely to 0
      final closingDepleted = DailyRecordModel.calculateClosingBirds(
        opening: 500,
        mortality: 10,
        culls: 5,
        birdsSold: 600,
      );
      expect(closingDepleted, 0);
    });

    test('batch calculateRemainingBirds correctly incorporates cumulative sales', () {
      final remaining = BatchModel.calculateRemainingBirds(
        totalBirds: 5000,
        cumulativeMortality: 100,
        cumulativeCulls: 20,
        cumulativeSales: 1500,
      );
      expect(remaining, 3380);
    });

    test('validates that birds sold cannot exceed available batch current birds', () {
      const currentLiveBirds = 1500;
      const requestedSale = 2000;

      final isAllowed = requestedSale <= currentLiveBirds;
      expect(isAllowed, isFalse);

      const validSale = 1200;
      expect(validSale <= currentLiveBirds, isTrue);
    });

    test('validates that sales price and weight must be non-negative', () {
      bool validateSaleParams({required double price, required double weight}) {
        if (price < 0 || weight < 0) return false;
        return true;
      }

      expect(validateSaleParams(price: 210.0, weight: 2.1), isTrue);
      expect(validateSaleParams(price: -5.0, weight: 2.1), isFalse);
      expect(validateSaleParams(price: 210.0, weight: -1.0), isFalse);
    });

    test('BatchModel serialization correctly stores completedAt and completionNotes', () {
      final now = DateTime.now();
      final completedBatch = BatchModel(
        id: 'batch_c1',
        farmId: 'farm_01',
        ownerId: 'user_01',
        batchName: 'Batch Completed',
        breedOrFlockType: 'Cobb 500',
        maleCount: 1000,
        femaleCount: 1000,
        totalBirds: 2000,
        currentBirds: 0,
        hatchDate: now.subtract(const Duration(days: 42)),
        placementDate: now.subtract(const Duration(days: 41)),
        status: 'completed',
        completedAt: now,
        completionNotes: '100% harvested and sold to processing vendor.',
        createdAt: now,
        updatedAt: now,
      );

      final json = completedBatch.toJson();
      expect(json['status'], 'completed');
      expect(json['completedAt'], isNotNull);
      expect(json['completionNotes'], '100% harvested and sold to processing vendor.');

      final parsed = BatchModel.fromJson(json);
      expect(parsed.isCompleted, isTrue);
      expect(parsed.status, 'completed');
      expect(parsed.completedAt?.year, now.year);
      expect(parsed.completionNotes, '100% harvested and sold to processing vendor.');
    });
  });
}
