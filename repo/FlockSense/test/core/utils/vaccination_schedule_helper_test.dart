import 'package:flutter_test/flutter_test.dart';
import 'package:flock_sense/core/utils/vaccination_schedule_helper.dart';

void main() {
  group('VaccinationScheduleHelper Tests', () {
    test('generates vaccination dates accurately from placement date', () {
      final placement = DateTime(2026, 9, 1);
      final schedule = VaccinationScheduleHelper.generateSchedule(placement);

      expect(schedule.length, 5);
      expect(schedule[0]['day'], 0);
      expect(schedule[0]['targetDate'], DateTime(2026, 9, 1));

      expect(schedule[2]['day'], 12);
      expect(schedule[2]['targetDate'], DateTime(2026, 9, 13));
      expect(schedule[2]['vaccine'], contains('Gumboro'));
    });
  });
}
