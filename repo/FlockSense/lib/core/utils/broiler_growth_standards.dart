/// Standard growth performance benchmarks for commercial broiler breeds.
class BroilerGrowthStandards {
  static const Map<int, double> _ross308WeightGrams = {
    0: 42.0,
    7: 190.0,
    14: 480.0,
    21: 950.0,
    28: 1550.0,
    35: 2280.0,
    42: 3050.0,
  };

  static const Map<int, double> _cobb500WeightGrams = {
    0: 42.0,
    7: 185.0,
    14: 460.0,
    21: 930.0,
    28: 1520.0,
    35: 2250.0,
    42: 3020.0,
  };

  /// Returns standard target weight in grams for a given age and breed.
  static double getTargetWeightGrams({required int ageDays, String breed = 'Ross 308'}) {
    final table = breed.toLowerCase().contains('cobb') ? _cobb500WeightGrams : _ross308WeightGrams;
    if (table.containsKey(ageDays)) return table[ageDays]!;
    
    // Linear interpolation between weekly benchmarks
    final lowerKey = table.keys.where((k) => k <= ageDays).lastOrNull ?? 0;
    final upperKey = table.keys.where((k) => k >= ageDays).firstOrNull ?? 42;
    if (lowerKey == upperKey) return table[lowerKey]!;

    final lowerVal = table[lowerKey]!;
    final upperVal = table[upperKey]!;
    final fraction = (ageDays - lowerKey) / (upperKey - lowerKey);
    return double.parse((lowerVal + (upperVal - lowerVal) * fraction).toStringAsFixed(1));
  }

  /// Calculates percentage deviation from target weight.
  static double calculateWeightDeviationPercent({
    required int ageDays,
    required double actualWeightGrams,
    String breed = 'Ross 308',
  }) {
    final target = getTargetWeightGrams(ageDays: ageDays, breed: breed);
    if (target <= 0.0) return 0.0;
    final dev = ((actualWeightGrams - target) / target) * 100.0;
    return double.parse(dev.toStringAsFixed(2));
  }
}
