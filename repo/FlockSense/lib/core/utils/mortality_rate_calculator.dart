/// Velocity tracker for flock mortality and early epidemic detection.
class MortalityRateCalculator {
  /// Calculates cumulative mortality percentage against placed birds.
  static double calculateCumulativeMortalityPercent({
    required int placedBirds,
    required int totalDeadAndCulled,
  }) {
    if (placedBirds <= 0) return 0.0;
    final pct = (totalDeadAndCulled / placedBirds) * 100.0;
    return double.parse(pct.toStringAsFixed(2));
  }

  /// Detects abnormal daily mortality spike relative to flock size.
  static bool isSpikeAlert({
    required int activeBirds,
    required int todayDead,
    double thresholdPercent = 0.5,
  }) {
    if (activeBirds <= 0) return false;
    final dailyPct = (todayDead / activeBirds) * 100.0;
    return dailyPct >= thresholdPercent;
  }
}
