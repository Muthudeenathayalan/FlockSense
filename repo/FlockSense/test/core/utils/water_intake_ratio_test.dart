import 'package:flutter_test/flutter_test.dart';
import 'package:flock_sense/core/utils/water_intake_ratio.dart';

void main() {
  group('WaterIntakeRatio Tests', () {
    test('calculates water to feed ratio correctly', () {
      final ratio = WaterIntakeRatio.calculateRatio(waterLiters: 360.0, feedKg: 200.0);
      expect(ratio, 1.80);
      expect(WaterIntakeRatio.assessIntakeRatio(ratio), 'Normal Consumption');
    });

    test('flags low intake anomalies accurately', () {
      final low = WaterIntakeRatio.calculateRatio(waterLiters: 200.0, feedKg: 200.0);
      expect(low, 1.00);
      expect(WaterIntakeRatio.assessIntakeRatio(low), contains('Low Intake'));
    });

    test('flags high intake leaks accurately', () {
      final high = WaterIntakeRatio.calculateRatio(waterLiters: 500.0, feedKg: 200.0);
      expect(high, 2.50);
      expect(WaterIntakeRatio.assessIntakeRatio(high), contains('High Intake'));
    });
  });
}
