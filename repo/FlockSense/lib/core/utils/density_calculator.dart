/// Stocking density calculator for commercial poultry sheds.
class DensityCalculator {
  /// Birds per square meter.
  static double birdsPerSqMeter({
    required int birdCount,
    required double areaSqMeters,
  }) {
    if (areaSqMeters <= 0.0) return 0.0;
    return double.parse((birdCount / areaSqMeters).toStringAsFixed(1));
  }

  /// Live biomass kg per square meter (EU Animal Welfare limit: typically 33-39 kg/m2).
  static double liveBiomassKgPerSqMeter({
    required int birdCount,
    required double averageWeightKg,
    required double areaSqMeters,
  }) {
    if (areaSqMeters <= 0.0) return 0.0;
    return double.parse(((birdCount * averageWeightKg) / areaSqMeters).toStringAsFixed(2));
  }

  /// Square feet allocated per bird.
  static double sqFtPerBird({
    required int birdCount,
    required double areaSqFt,
  }) {
    if (birdCount <= 0) return 0.0;
    return double.parse((areaSqFt / birdCount).toStringAsFixed(2));
  }
}
