import 'package:flutter_test/flutter_test.dart';
import 'package:flock_sense/features/flock/domain/flock.dart';

void main() {
  test('Flock model constructs and serializes correctly', () {
    final placementDate = DateTime(2025, 1, 1);
    final createdAt = DateTime(2025, 1, 2, 12);
    final flock = Flock(
      id: 'batch-1',
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
    expect(json['openingCount'], 1200);
    expect(json['targetFcr'], 1.75);
  });
}
