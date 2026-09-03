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
          'closingBirds': 0,
          'feedConsumedKg': 50,
          'waterConsumedLiters': 100,
          'avgWeightGrams': 1500,
        });

        expect(record.mortalityCount, 0); // clamped to 0
        expect(record.closingBirds, 0); // non-negative clamp
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
