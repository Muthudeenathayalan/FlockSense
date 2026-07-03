import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flock_sense/features/flock/domain/flock.dart';

void main() {
  test('Flock serialization round trip', () {
    final placementDate = DateTime(2025, 1, 1);
    final createdAt = DateTime(2025, 1, 2, 12);
    final flock = Flock(
      id: 'batch-1',
      userId: 'user-123',
      farmId: 'farm-456',
      name: 'Batch One',
      birdType: 'Broiler',
      breed: 'Cobb 500',
      placementDate: placementDate,
      openingCount: 1200,
      targetFcr: 1.75,
      expectedHarvestDay: 42,
      createdAt: createdAt,
    );

    final json = flock.toJson();

    expect(json['name'], 'Batch One');
    expect(json['birdType'], 'Broiler');
    expect(json['breed'], 'Cobb 500');
    expect((json['placementDate'] as Timestamp).toDate(), placementDate);
    expect(json['openingCount'], 1200);
    expect(json['targetFcr'], 1.75);
    expect(json['expectedHarvestDay'], 42);
    expect((json['createdAt'] as Timestamp).toDate(), createdAt);

    final copy = Flock.fromMap({
      'name': 'Batch One',
      'birdType': 'Broiler',
      'breed': 'Cobb 500',
      'placementDate': Timestamp.fromDate(placementDate),
      'openingCount': 1200,
      'targetFcr': 1.75,
      'expectedHarvestDay': 42,
      'createdAt': Timestamp.fromDate(createdAt),
    }, 'batch-1');

    expect(copy.id, 'batch-1');
    expect(copy.name, flock.name);
    expect(copy.birdType, flock.birdType);
    expect(copy.breed, flock.breed);
    expect(copy.placementDate, flock.placementDate);
    expect(copy.openingCount, flock.openingCount);
    expect(copy.targetFcr, flock.targetFcr);
    expect(copy.expectedHarvestDay, flock.expectedHarvestDay);
    expect(copy.createdAt, flock.createdAt);
  });
}
