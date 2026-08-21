import 'package:flutter_test/flutter_test.dart';
import 'package:flock_sense/core/utils/flock_uniformity_calculator.dart';

void main() {
  group('FlockUniformityCalculator Tests', () {
    final sample = [1900.0, 1950.0, 2000.0, 2050.0, 2100.0];

    test('calculates mean and standard deviation', () {
      expect(FlockUniformityCalculator.calculateMean(sample), 2000.0);
      expect(FlockUniformityCalculator.calculateStandardDeviation(sample), 79.06);
    });

    test('calculates CV% and Uniformity%', () {
      final cv = FlockUniformityCalculator.calculateCvPercent(sample);
      expect(cv, 3.95);

      final uniformity = FlockUniformityCalculator.calculateUniformityPercent(sample);
      expect(uniformity, 100.0); // All values within 1800 - 2200
    });
  });
}
