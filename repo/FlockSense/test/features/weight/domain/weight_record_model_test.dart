import 'package:flutter_test/flutter_test.dart';
import 'package:flock_sense/features/weight/domain/weight_record_model.dart';

void main() {
  group('WeightRecordModel Tests', () {
    final now = DateTime(2026, 8, 25);

    test('constructs and serializes round trip correctly', () {
      final record = WeightRecordModel(
        id: 'wt-01',
        userId: 'user-01',
        farmId: 'farm-01',
        batchId: 'batch-01',
        recordDate: now,
        averageWeight: 1450.0,
        unit: 'grams',
        sampleCount: 50,
        notes: 'Weekly random sampling in 4 pen corners',
        createdAt: now,
        updatedAt: now,
      );

      expect(record.averageWeight, 1450.0);
      expect(record.sampleCount, 50);

      final json = record.toJson();
      expect(json['id'], 'wt-01');
      expect(json['averageWeight'], 1450.0);
      expect(json['sampleCount'], 50);
    });

    test('deserializes from JSON gracefully', () {
      final json = {
        'id': 'wt-02',
        'userId': 'user-01',
        'farmId': 'farm-01',
        'batchId': 'batch-01',
        'recordDate': '2026-08-25',
        'averageWeight': '2.15',
        'unit': 'kilograms',
        'sampleCount': '100',
        'createdAt': '2026-08-25T00:00:00.000Z',
        'updatedAt': '2026-08-25T00:00:00.000Z',
      };

      final record = WeightRecordModel.fromJson(json);
      expect(record.averageWeight, 2.15);
      expect(record.unit, 'kilograms');
      expect(record.sampleCount, 100);
    });
  });
}
