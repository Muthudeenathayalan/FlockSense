import 'package:flutter_test/flutter_test.dart';
import 'package:flock_sense/features/sheds/domain/shed_model.dart';

void main() {
  group('ShedModel Tests', () {
    final now = DateTime(2026, 8, 20);

    test('constructs and serializes to JSON correctly', () {
      final shed = ShedModel(
        id: 'shed-101',
        farmId: 'farm-01',
        ownerId: 'user-01',
        name: 'Broiler House 1',
        lengthFt: 250.0,
        widthFt: 40.0,
        totalSqFt: 10000.0,
        capacity: 8000,
        notes: 'Tunnel ventilated shed',
        status: 'active',
        createdAt: now,
        updatedAt: now,
      );

      expect(shed.shedName, 'Broiler House 1');
      expect(shed.physicalCapacity, 8000);
      expect(shed.areaSqFt, 10000.0);

      final json = shed.toJson();
      expect(json['id'], 'shed-101');
      expect(json['name'], 'Broiler House 1');
      expect(json['totalSqFt'], 10000.0);
    });

    test('deserializes from JSON correctly and handles copyWith', () {
      final json = {
        'id': 'shed-102',
        'farmId': 'farm-01',
        'ownerId': 'user-01',
        'name': 'Shed 2',
        'lengthFt': 200,
        'widthFt': 30,
        'totalSqFt': 6000,
        'capacity': '5000',
        'status': 'active',
        'createdAt': '2026-08-20T00:00:00.000Z',
        'updatedAt': '2026-08-20T00:00:00.000Z',
      };

      final shed = ShedModel.fromJson(json);
      expect(shed.id, 'shed-102');
      expect(shed.capacity, 5000);
      expect(shed.totalSqFt, 6000.0);

      final updated = shed.copyWith(name: 'Shed 2 Renovated', capacity: 5500);
      expect(updated.name, 'Shed 2 Renovated');
      expect(updated.capacity, 5500);
      expect(updated.id, shed.id);
    });
  });
}
