import 'package:flutter_test/flutter_test.dart';
import 'package:flock_sense/features/flock_plan/domain/flock_lifecycle_standard.dart';

void main() {
  group('FlockLifecycleStandard Tests', () {
    test('retrieves accurate day 1 brooding standards', () {
      final day1 = FlockLifecycleStandard.getForDay(1);
      expect(day1.day, 1);
      expect(day1.phase, 'Brooding Phase');
      expect(day1.targetTempCelsius, 33.5);
      expect(day1.targetWeightGrams, 56.0);
      expect(day1.dailyFeedPerBirdGrams, 15.0);
      expect(day1.dailyWaterPerBirdMl, 30.0);
      expect(day1.feedType, 'Pre-Starter Crumbles');
      expect(day1.vaccineName, contains("Marek's"));
      expect(day1.medicineProtocol, contains('Electrolytes'));
    });

    test('retrieves critical milestone days correctly', () {
      // Day 7: ND LaSota Vaccine, 185g
      final day7 = FlockLifecycleStandard.getForDay(7);
      expect(day7.targetWeightGrams, 185.0);
      expect(day7.vaccineName, contains('Newcastle Disease'));

      // Day 14: Gumboro IBD Vaccine, 500g
      final day14 = FlockLifecycleStandard.getForDay(14);
      expect(day14.targetWeightGrams, 500.0);
      expect(day14.vaccineName, contains('Gumboro'));

      // Day 21: ND Booster, ~913g
      final day21 = FlockLifecycleStandard.getForDay(21);
      expect(day21.targetWeightGrams, 913.0);
      expect(day21.vaccineName, contains('Newcastle Disease Booster'));

      // Day 35: Strict withdrawal, ~2,115g
      final day35 = FlockLifecycleStandard.getForDay(35);
      expect(day35.targetWeightGrams, 2115.0);
      expect(day35.medicineProtocol, contains('STRICT WITHDRAWAL'));

      // Day 42: Harvest & Marketing, 2,750g
      final day42 = FlockLifecycleStandard.getForDay(42);
      expect(day42.targetWeightGrams, 2750.0);
      expect(day42.phase, 'Harvest & Marketing');
    });

    test('calculates daily feed kg scaled by live birds accurately', () {
      // Day 1: 15g per bird * 5,000 birds = 75 kg
      final feedDay1 = FlockLifecycleStandard.calculateDailyFeedKg(1, 5000);
      expect(feedDay1, 75.0);

      // Day 14: 76g per bird * 2,000 birds = 152 kg
      final feedDay14 = FlockLifecycleStandard.calculateDailyFeedKg(14, 2000);
      expect(feedDay14, 152.0);

      // 0 birds should return 0.0 kg
      expect(FlockLifecycleStandard.calculateDailyFeedKg(14, 0), 0.0);
    });

    test('calculates daily water liters scaled by live birds accurately', () {
      // Day 1: 30 ml per bird * 5,000 birds = 150 L
      final waterDay1 = FlockLifecycleStandard.calculateDailyWaterLiters(1, 5000);
      expect(waterDay1, 150.0);

      // Day 28: 346 ml per bird * 1,000 birds = 346 L
      final waterDay28 = FlockLifecycleStandard.calculateDailyWaterLiters(28, 1000);
      expect(waterDay28, 346.0);

      // 0 birds should return 0.0 L
      expect(FlockLifecycleStandard.calculateDailyWaterLiters(28, 0), 0.0);
    });

    test('guards against day out-of-bounds gracefully', () {
      final day0 = FlockLifecycleStandard.getForDay(0);
      expect(day0.day, 1);

      final day50 = FlockLifecycleStandard.getForDay(50);
      expect(day50.day, 45);
    });
  });
}
