import 'package:flutter_test/flutter_test.dart';
import 'package:flock_sense/core/utils/mortality_rate_calculator.dart';

void main() {
  group('MortalityRateCalculator Tests', () {
    test('calculates cumulative mortality correctly', () {
      final pct = MortalityRateCalculator.calculateCumulativeMortalityPercent(
        placedBirds: 10000,
        totalDeadAndCulled: 280,
      );
      expect(pct, 2.80);
    });

    test('triggers spike alert when daily threshold is exceeded', () {
      expect(
        MortalityRateCalculator.isSpikeAlert(
          activeBirds: 5000,
          todayDead: 30, // 0.6% >= 0.5%
        ),
        isTrue,
      );
      expect(
        MortalityRateCalculator.isSpikeAlert(
          activeBirds: 5000,
          todayDead: 10, // 0.2% < 0.5%
        ),
        isFalse,
      );
    });
  });
}
