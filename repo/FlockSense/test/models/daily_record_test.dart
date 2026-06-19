import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flock_sense/features/flock/domain/daily_record.dart';

void main() {
  test('DailyRecord serialization round trip', () {
    final createdAt = DateTime(2025, 1, 3, 9, 15);
    final record = DailyRecord(
      id: 'record-1',
      flockId: 'batch-1',
      date: '2025-01-03',
      openingCount: 1200,
      mortality: 5,
      culls: 2,
      closingCount: 1193,
      feedConsumedKg: 145.5,
      avgWeightGrams: 1700.0,
      createdAt: createdAt,
    );

    final json = record.toJson();

    expect(json['flockId'], 'batch-1');
    expect(json['date'], '2025-01-03');
    expect(json['openingCount'], 1200);
    expect(json['mortality'], 5);
    expect(json['culls'], 2);
    expect(json['closingCount'], 1193);
    expect(json['feedConsumedKg'], 145.5);
    expect(json['avgWeightGrams'], 1700.0);
    expect((json['createdAt'] as Timestamp).toDate(), createdAt);

    final copy = DailyRecord.fromMap(
      {
        'flockId': 'batch-1',
        'date': '2025-01-03',
        'openingCount': 1200,
        'mortality': 5,
        'culls': 2,
        'closingCount': 1193,
        'feedConsumedKg': 145.5,
        'avgWeightGrams': 1700.0,
        'createdAt': Timestamp.fromDate(createdAt),
      },
      'record-1',
    );

    expect(copy.id, 'record-1');
    expect(copy.flockId, record.flockId);
    expect(copy.date, record.date);
    expect(copy.openingCount, record.openingCount);
    expect(copy.mortality, record.mortality);
    expect(copy.culls, record.culls);
    expect(copy.closingCount, record.closingCount);
    expect(copy.feedConsumedKg, record.feedConsumedKg);
    expect(copy.avgWeightGrams, record.avgWeightGrams);
    expect(copy.createdAt, record.createdAt);
  });
}
