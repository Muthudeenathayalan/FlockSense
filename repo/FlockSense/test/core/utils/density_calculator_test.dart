import 'package:flutter_test/flutter_test.dart';
import 'package:flock_sense/core/utils/density_calculator.dart';

void main() {
  group('DensityCalculator Tests', () {
    test('computes birds per sq meter correctly', () {
      final density = DensityCalculator.birdsPerSqMeter(birdCount: 15000, areaSqMeters: 1000.0);
      expect(density, 15.0);
    });

    test('computes live biomass kg/m2 correctly', () {
      final biomass = DensityCalculator.liveBiomassKgPerSqMeter(
        birdCount: 15000,
        averageWeightKg: 2.2,
        areaSqMeters: 1000.0,
      );
      expect(biomass, 33.0);
    });

    test('computes sq ft per bird correctly', () {
      final sqft = DensityCalculator.sqFtPerBird(birdCount: 10000, areaSqFt: 12000.0);
      expect(sqft, 1.20);
    });
  });
}
