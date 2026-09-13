import 'package:flutter_test/flutter_test.dart';
import 'package:flock_sense/core/utils/european_broiler_index.dart';

void main() {
  group('EuropeanBroilerIndex Tests', () {
    test('calculates EPEF accurately for standard broiler performance', () {
      final epef = EuropeanBroilerIndex.calculateEpef(
        liveabilityPercent: 96.0,
        averageWeightKg: 2.2,
        ageDays: 35,
        fcr: 1.55,
      );
      expect(epef, 389.31);
      expect(EuropeanBroilerIndex.getPerformanceRating(epef), 'Good');
    });

    test('handles edge cases with zero days or zero fcr safely', () {
      expect(
        EuropeanBroilerIndex.calculateEpef(
          liveabilityPercent: 98.0,
          averageWeightKg: 1.5,
          ageDays: 0,
          fcr: 1.5,
        ),
        0.0,
      );
      expect(
        EuropeanBroilerIndex.calculateEpef(
          liveabilityPercent: 98.0,
          averageWeightKg: 1.5,
          ageDays: 30,
          fcr: 0.0,
        ),
        0.0,
      );
    });

    test('returns accurate ratings across performance bands', () {
      expect(EuropeanBroilerIndex.getPerformanceRating(420.0), 'Excellent');
      expect(EuropeanBroilerIndex.getPerformanceRating(370.0), 'Good');
      expect(EuropeanBroilerIndex.getPerformanceRating(320.0), 'Moderate');
      expect(EuropeanBroilerIndex.getPerformanceRating(275.0), 'Substandard');
    });
  });
}
