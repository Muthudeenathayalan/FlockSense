/// Temperature-Humidity Index (THI) and heat stress classifier for poultry.
class TemperatureHumidityIndex {
  /// Calculates THI:
  /// THI = T - (0.55 - (0.55 * RH / 100)) * (T - 14.4)
  static double calculateThi({
    required double temperatureC,
    required double relativeHumidityPercent,
  }) {
    final thi = temperatureC - (0.55 - (0.55 * relativeHumidityPercent / 100.0)) * (temperatureC - 14.4);
    return double.parse(thi.toStringAsFixed(1));
  }

  /// Evaluates heat stress category.
  static String evaluateHeatStress(double thi) {
    if (thi < 27.8) return 'Comfort';
    if (thi < 28.9) return 'Alert';
    if (thi < 30.0) return 'Danger';
    return 'Emergency';
  }
}
