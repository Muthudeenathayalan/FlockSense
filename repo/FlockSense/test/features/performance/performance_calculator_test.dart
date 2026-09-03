import 'package:flutter_test/flutter_test.dart';
import 'package:flock_sense/features/daily_records/domain/daily_record_model.dart';
import 'package:flock_sense/features/performance/domain/performance_calculator.dart';

void main() {
  group('PerformanceCalculator Tests', () {
    final testDate = DateTime(2026, 1, 1);

    DailyRecordModel createRecord({
      required int day,
      required int opening,
      required int closing,
      required int mortality,
      required double feedKg,
      required double weightGrams,
    }) {
      return DailyRecordModel(
        id: 'r-$day',
        farmId: 'f-1',
        batchId: 'b-1',
        recordDate: testDate.add(Duration(days: day - 1)),
        batchAgeDay: day,
        openingBirds: opening,
        mortalityCount: mortality,
        cullCount: 0,
        adjustmentCount: 0,
        closingBirds: closing,
        feedConsumedKg: feedKg,
        waterConsumedLiters: feedKg * 2,
        avgWeightGrams: weightGrams,
        medicineGiven: false,
        vaccineGiven: false,
        ownerId: 'u-1',
        createdAt: testDate,
        updatedAt: testDate,
      );
    }

    test(
      'calculates cumulative FCR accurately from total feed and total live biomass',
      () {
        // 1000 birds placed.
        // Day 1: 1000 birds, 50 kg feed, 160g weight
        // Day 2: 995 birds (5 mort), 80 kg feed, 300g weight (0.300 kg)
        // Total Feed = 130 kg.
        // Total Live Biomass = 995 * 0.300 = 298.5 kg.
        // Expected FCR = 130 / 298.5 = 0.4355 -> 0.436
        final records = [
          createRecord(
            day: 1,
            opening: 1000,
            closing: 1000,
            mortality: 0,
            feedKg: 50,
            weightGrams: 160,
          ),
          createRecord(
            day: 2,
            opening: 1000,
            closing: 995,
            mortality: 5,
            feedKg: 80,
            weightGrams: 300,
          ),
        ];

        final fcr = PerformanceCalculator.calculateCumulativeFcr(records, 2);
        expect(fcr, 0.436);
      },
    );

    test('calculates ADG (Average Daily Gain) in grams/bird/day', () {
      // Current weight = 2200g at Day 35. Chick weight = 42g.
      // Net Gain = 2200 - 42 = 2158g.
      // ADG = 2158 / 35 = 61.657 -> 61.66 g/day.
      final adg = PerformanceCalculator.calculateAdg(
        currentAvgWeightGrams: 2200,
        ageDays: 35,
      );
      expect(adg, 61.66);
    });

    test(
      'calculates Cumulative Mortality % correctly against placed total',
      () {
        final records = [
          createRecord(
            day: 1,
            opening: 5000,
            closing: 4980,
            mortality: 20,
            feedKg: 100,
            weightGrams: 150,
          ),
          createRecord(
            day: 2,
            opening: 4980,
            closing: 4950,
            mortality: 30,
            feedKg: 120,
            weightGrams: 220,
          ),
        ];

        // Total mortality = 50 out of 5000 placed birds = 1.0%
        final mortPct = PerformanceCalculator.calculateCumulativeMortalityPct(
          records,
          5000,
          2,
        );
        expect(mortPct, 1.0);
      },
    );

    test('calculates EPEF (European Production Efficiency Factor)', () {
      // 5000 birds placed. 100 mortality = 4900 live (98% liveability).
      // Age = 35 days. Avg weight = 2.1 kg (2100g). Total Feed = 15,000 kg.
      // Biomass = 4900 * 2.1 = 10,290 kg.
      // FCR = 15,000 / 10,290 = 1.458
      // EPEF = (98 * 2.1) / (35 * 1.458) * 100 = 205.8 / 51.03 * 100 = 403.29 -> 403.3
      final records = [
        createRecord(
          day: 35,
          opening: 4900,
          closing: 4900,
          mortality: 100,
          feedKg: 15000,
          weightGrams: 2100,
        ),
      ];

      final pef = PerformanceCalculator.calculatePef(records, 5000, 35);
      expect(pef, isNotNull);
      expect(pef!, greaterThan(350));
      expect(pef, lessThan(450));
    });

    test(
      'returns null gracefully when records list is empty or zero-range',
      () {
        expect(PerformanceCalculator.calculateCumulativeFcr([], 10), isNull);
        expect(PerformanceCalculator.calculatePef([], 5000, 35), isNull);
        expect(
          PerformanceCalculator.calculateAdg(
            currentAvgWeightGrams: 0,
            ageDays: 0,
          ),
          isNull,
        );
      },
    );
  });
}
