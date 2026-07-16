import 'package:flutter_test/flutter_test.dart';
import 'package:flock_sense/features/farms/domain/farm_model.dart';

void main() {
  group('FarmModel.fromJson', () {
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
  });
}
