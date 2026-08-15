/// Water-to-Feed ratio evaluator and clinical anomaly detector.
class WaterIntakeRatio {
  /// Computes ratio of liters of water consumed per kg of feed.
  static double calculateRatio({
    required double waterLiters,
    required double feedKg,
  }) {
    if (feedKg <= 0.0) return 0.0;
    return double.parse((waterLiters / feedKg).toStringAsFixed(2));
  }

  /// Classifies water consumption: Normal is 1.6 to 2.0 at 21C.
  static String assessIntakeRatio(double ratio) {
    if (ratio < 1.4) return 'Low Intake (Check Line Pressure / Blockages)';
    if (ratio <= 2.1) return 'Normal Consumption';
    return 'High Intake (Check Leaks or Enteric Health)';
  }
}
