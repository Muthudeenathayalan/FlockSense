import 'package:flutter_test/flutter_test.dart';
import 'package:flock_sense/core/utils/broiler_growth_standards.dart';

void main() {
  group('BroilerGrowthStandards Tests', () {
    test('returns exact benchmark weights at weekly milestones', () {
      expect(BroilerGrowthStandards.getTargetWeightGrams(ageDays: 0), 42.0);
      expect(BroilerGrowthStandards.getTargetWeightGrams(ageDays: 7), 190.0);
      expect(BroilerGrowthStandards.getTargetWeightGrams(ageDays: 35), 2280.0);
    });

    test('interpolates weight smoothly on intermediate days', () {
      final midDay = BroilerGrowthStandards.getTargetWeightGrams(ageDays: 10);
      expect(midDay, greaterThan(190.0));
      expect(midDay, lessThan(480.0));
    });

    test('calculates weight deviation percentage accurately', () {
      final dev = BroilerGrowthStandards.calculateWeightDeviationPercent(
        ageDays: 35,
        actualWeightGrams: 2394.0, // +5% over 2280g
      );
      expect(dev, 5.0);
    });
  });
}
