import 'package:flutter_test/flutter_test.dart';
import 'package:flock_sense/features/farms/domain/farm_model.dart';

void main() {
  group('FarmModel Tests', () {
    final testDate = DateTime(2026, 1, 15);

    test('keeps width-only payloads from being treated as length', () {
      final farm = FarmModel.fromJson({
        'id': 'farm-1',
        'farmName': 'Sample Farm',
        'farmType': 'EC',
        'widthFt': 8.5,
      });

      expect(farm.lengthFt, 0.0);
      expect(farm.widthFt, 8.5);
      expect(farm.totalSqFt, 0.0);
    });

    test(
      'calculates totalSqFt from length and width when totalSqFt is absent',
      () {
        final farm = FarmModel.fromJson({
          'id': 'farm-2',
          'farmName': 'Green Valley',
          'farmType': 'EC',
          'lengthFt': 120.0,
          'widthFt': 40.0,
        });

        expect(farm.lengthFt, 120.0);
        expect(farm.widthFt, 40.0);
        expect(farm.totalSqFt, 4800.0);
      },
    );

    test('estimates broiler capacity based on standard 1.2 sq ft per bird', () {
      expect(FarmModel.estimateBroilerCapacity(4800.0), 4000);
      expect(FarmModel.estimateBroilerCapacity(0.0), 0);
      expect(FarmModel.estimateBroilerCapacity(-100.0), 0);
    });

    test('validates dimensions and capacity', () {
      expect(FarmModel.isValidDimensions(100, 40), isTrue);
      expect(FarmModel.isValidDimensions(-1, 40), isFalse);
      expect(FarmModel.isValidDimensions(100, -5), isFalse);

      expect(FarmModel.isValidCapacity(5000), isTrue);
      expect(FarmModel.isValidCapacity(null), isTrue);
      expect(FarmModel.isValidCapacity(-100), isFalse);
    });

    test('full serialization round trip', () {
      final farm = FarmModel(
        id: 'f-100',
        userId: 'u-1',
        farmName: 'Sunrise Farms',
        farmType: 'EC',
        flockType: 'Broiler',
        address: 'Plot 42, North Wing',
        lengthFt: 150,
        widthFt: 50,
        totalSqFt: 7500,
        capacity: 6000,
        district: 'Coimbatore',
        state: 'Tamil Nadu',
        country: 'India',
        phoneNumber: '+919876543210',
        createdAt: testDate,
        updatedAt: testDate,
      );

      final json = farm.toJson();
      expect(json['id'], 'f-100');
      expect(json['farmName'], 'Sunrise Farms');
      expect(json['capacity'], 6000);
      expect(json['district'], 'Coimbatore');
      expect(json['state'], 'Tamil Nadu');

      final copy = FarmModel.fromJson(json);
      expect(copy.id, farm.id);
      expect(copy.farmName, farm.farmName);
      expect(copy.totalSqFt, 7500.0);
      expect(copy.capacity, 6000);
    });
  });
}
