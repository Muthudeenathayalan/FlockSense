/// European Production Efficiency Factor (EPEF / PEF / EPI) Calculator
///
/// Standard poultry industry index assessing overall flock biological efficiency.
class EuropeanBroilerIndex {
  /// Calculates EPEF:
  /// EPEF = (Liveability % * Average Weight in kg) / (Age in days * FCR) * 100
  static double calculateEpef({
    required double liveabilityPercent,
    required double averageWeightKg,
    required int ageDays,
    required double fcr,
  }) {
    if (ageDays <= 0 || fcr <= 0.0) return 0.0;
    if (liveabilityPercent <= 0.0 || averageWeightKg <= 0.0) return 0.0;

    final epef = (liveabilityPercent * averageWeightKg) / (ageDays * fcr) * 100.0;
    return double.parse(epef.toStringAsFixed(2));
  }

  /// Returns standard commercial performance rating for a given EPEF score.
  static String getPerformanceRating(double epef) {
    if (epef >= 400.0) return 'Excellent';
    if (epef >= 350.0) return 'Good';
    if (epef >= 300.0) return 'Moderate';
    return 'Substandard';
  }
}
