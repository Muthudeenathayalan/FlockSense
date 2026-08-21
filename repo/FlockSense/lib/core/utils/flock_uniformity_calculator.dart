import 'dart:math' as math;

/// Statistical uniformity and CV% calculator for batch bird sample weighings.
class FlockUniformityCalculator {
  /// Calculates mean weight of sample.
  static double calculateMean(List<double> weightsGrams) {
    if (weightsGrams.isEmpty) return 0.0;
    final sum = weightsGrams.fold(0.0, (prev, elem) => prev + elem);
    return double.parse((sum / weightsGrams.length).toStringAsFixed(1));
  }

  /// Calculates sample standard deviation.
  static double calculateStandardDeviation(List<double> weightsGrams) {
    if (weightsGrams.length < 2) return 0.0;
    final mean = calculateMean(weightsGrams);
    final variance = weightsGrams.fold(0.0, (prev, elem) => prev + math.pow(elem - mean, 2)) / (weightsGrams.length - 1);
    return double.parse(math.sqrt(variance).toStringAsFixed(2));
  }

  /// Calculates Coefficient of Variation (CV%): (StdDev / Mean) * 100
  static double calculateCvPercent(List<double> weightsGrams) {
    final mean = calculateMean(weightsGrams);
    if (mean <= 0.0) return 0.0;
    final sd = calculateStandardDeviation(weightsGrams);
    return double.parse(((sd / mean) * 100.0).toStringAsFixed(2));
  }

  /// Calculates Flock Uniformity %: percentage of birds within +/- 10% of mean weight.
  static double calculateUniformityPercent(List<double> weightsGrams) {
    if (weightsGrams.isEmpty) return 0.0;
    final mean = calculateMean(weightsGrams);
    final lowerBound = mean * 0.90;
    final upperBound = mean * 1.10;
    final inRangeCount = weightsGrams.where((w) => w >= lowerBound && w <= upperBound).length;
    return double.parse(((inRangeCount / weightsGrams.length) * 100.0).toStringAsFixed(2));
  }
}
