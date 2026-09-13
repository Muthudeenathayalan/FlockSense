import 'package:flutter_test/flutter_test.dart';
import 'package:flock_sense/features/daily_records/domain/daily_record_model.dart';
import 'package:flock_sense/features/feed/domain/feed_transaction_model.dart';

void main() {
  group('DailyRecordModel Validation & Calculations', () {
    test('validates mortality inputs against live bird count', () {
      expect(DailyRecordModel.isValidMortality(0, 1000), isTrue);
      expect(DailyRecordModel.isValidMortality(50, 1000), isTrue);
      expect(DailyRecordModel.isValidMortality(1000, 1000), isTrue);

      // Invalid: negative mortality
      expect(DailyRecordModel.isValidMortality(-5, 1000), isFalse);

      // Invalid: mortality exceeds live birds
      expect(DailyRecordModel.isValidMortality(1001, 1000), isFalse);
    });

    test('validates feed, water, and environmental inputs', () {
      expect(DailyRecordModel.isValidFeedIntake(150.0), isTrue);
      expect(DailyRecordModel.isValidFeedIntake(0.0), isTrue);
      expect(DailyRecordModel.isValidFeedIntake(-1.0), isFalse);

      expect(DailyRecordModel.isValidWaterIntake(300.0), isTrue);
      expect(DailyRecordModel.isValidWaterIntake(-5.0), isFalse);

      expect(DailyRecordModel.isValidTemperature(28.5), isTrue);
      expect(DailyRecordModel.isValidTemperature(-10.0), isFalse);
      expect(DailyRecordModel.isValidTemperature(75.0), isFalse);

      expect(DailyRecordModel.isValidHumidity(65.0), isTrue);
      expect(DailyRecordModel.isValidHumidity(-5.0), isFalse);
      expect(DailyRecordModel.isValidHumidity(105.0), isFalse);
    });

    test('validates average bird weight within plausible bounds', () {
      expect(DailyRecordModel.isValidBirdWeight(42.0), isTrue);
      expect(DailyRecordModel.isValidBirdWeight(2150.5), isTrue);
      expect(DailyRecordModel.isValidBirdWeight(0.0), isTrue);
      expect(DailyRecordModel.isValidBirdWeight(10000.0), isTrue);

      expect(DailyRecordModel.isValidBirdWeight(-1.0), isFalse);
      expect(DailyRecordModel.isValidBirdWeight(10001.0), isFalse);
    });

    test('calculates closing birds accurately and handles loss exceeding opening', () {
      final normalClosing = DailyRecordModel.calculateClosingBirds(
        opening: 5000,
        mortality: 15,
        culls: 5,
        adjustments: 10,
      );
      expect(normalClosing, 4990);

      // Excess loss clamps to zero
      final depleted = DailyRecordModel.calculateClosingBirds(
        opening: 100,
        mortality: 120,
        culls: 10,
      );
      expect(depleted, 0);

      // Negative mortality/culls are sanitized to 0
      final sanitized = DailyRecordModel.calculateClosingBirds(
        opening: 1000,
        mortality: -5,
        culls: -10,
      );
      expect(sanitized, 1000);
    });

    test(
      'fromJson prevents negative closing count and clamps negative mortality/culls',
      () {
        final record = DailyRecordModel.fromJson({
          'id': 'rec-1',
          'farmId': 'f1',
          'batchId': 'b1',
          'recordDate': '2026-01-01',
          'openingBirds': 100,
          'mortalityCount': -10, // negative raw input
          'cullCount': 120, // exceeds opening
          'adjustmentCount': 0,
          'closingBirds': -25, // explicit negative in json
          'feedConsumedKg': 50,
          'waterConsumedLiters': 100,
          'avgWeightGrams': 1500,
        });

        expect(record.mortalityCount, 0); // clamped to 0
        expect(record.closingBirds, 0); // non-negative clamp

        final autoCalcRecord = DailyRecordModel.fromJson({
          'id': 'rec-2',
          'farmId': 'f1',
          'batchId': 'b1',
          'recordDate': '2026-01-01',
          'openingBirds': 1000,
          'mortalityCount': 10,
          'cullCount': 5,
          'adjustmentCount': 0,
          'closingBirds': 0,
          'feedConsumedKg': 50,
          'waterConsumedLiters': 100,
          'avgWeightGrams': 1500,
        });
        expect(autoCalcRecord.closingBirds, 985);
      },
    );
  });

  group('FeedTransactionModel Validation', () {
    test('validates transaction non-negative values', () {
      expect(
        FeedTransactionModel.isValidTransaction(
          bags: 10,
          weightKg: 500,
          totalCost: 15000,
        ),
        isTrue,
      );

      expect(
        FeedTransactionModel.isValidTransaction(
          bags: -1,
          weightKg: 500,
          totalCost: 15000,
        ),
        isFalse,
      );

      expect(
        FeedTransactionModel.isValidTransaction(
          bags: 10,
          weightKg: -50,
          totalCost: 15000,
        ),
        isFalse,
      );
    });
  });
}
