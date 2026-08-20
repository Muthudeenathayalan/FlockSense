/// Atmospheric ammonia (NH3) safety thresholds and ventilation guidance.
class AmmoniaThresholdHelper {
  /// Evaluates exposure level from sensor reading in parts per million (PPM).
  static String evaluateAmmoniaPpm(double ppm) {
    if (ppm < 10.0) return 'Optimal';
    if (ppm <= 20.0) return 'Acceptable';
    if (ppm <= 25.0) return 'Warning: Eye & Respiratory Irritation';
    return 'Critical: Severe Mucosal Damage Risk';
  }

  /// Ventilation action advisory.
  static String getVentilationAdvisory(double ppm) {
    if (ppm < 10.0) return 'Maintain minimum ventilation rate.';
    if (ppm <= 20.0) return 'Verify litter moisture and increase timer fan cycles by 10%.';
    if (ppm <= 25.0) return 'Increase ventilation rate immediately and inspect drinkers for leaks.';
    return 'Emergency purge ventilation required. Top-dress or remove wet litter patches.';
  }
}
