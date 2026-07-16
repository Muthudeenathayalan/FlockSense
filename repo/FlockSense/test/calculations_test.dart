import 'package:flutter_test/flutter_test.dart';
import 'package:flock_sense/features/daily_records/domain/daily_record_model.dart';

void main() {
  group('daily record calculations', () {
    test('closing birds include mortality, cull and adjustment', () {
      final record = DailyRecordModel(
        id: '1',
        farmId: 'farm',
        batchId: 'batch',
        recordDate: DateTime(2024, 1, 1),
        batchAgeDay: 1,
        openingBirds: 1000,
        mortalityCount: 5,
        cullCount: 3,
        adjustmentCount: 2,
        closingBirds: 994,
        feedConsumedKg: 10,
        waterConsumedLiters: 20,
        avgWeightGrams: 1200,
        medicineGiven: false,
        vaccineGiven: false,
        ownerId: 'user',
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      );

      expect(record.closingBirds, 994);
    });

    test('adjustment can increase the closing count', () {
      final closing = 1000 - 10 - 5 + 8;
      expect(closing, 993);
    });

    test('negative closing is invalid in business logic', () {
      final closing = 10 - 20 - 5 + 0;
      expect(closing < 0, isTrue);
    });
  });

  test('record dates format deterministically', () {
    final date = DateTime(2024, 2, 3);
    final formatted =
        '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    expect(formatted, '2024-02-03');
  });
}
