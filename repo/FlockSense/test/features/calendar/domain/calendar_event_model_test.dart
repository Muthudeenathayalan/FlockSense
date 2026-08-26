import 'package:flutter_test/flutter_test.dart';
import 'package:flock_sense/features/calendar/domain/calendar_event_model.dart';

void main() {
  group('CalendarEventModel Tests', () {
    final now = DateTime(2026, 8, 26, 9, 0);

    test('evaluates priority, status, and formatting correctly', () {
      final event = CalendarEventModel(
        id: 'cal-01',
        farmId: 'farm-01',
        batchId: 'batch-01',
        ownerId: 'user-01',
        title: 'ND Vaccine Booster',
        eventType: 'Vaccination',
        description: 'LaSota drinking water administration',
        eventDate: now,
        eventTime: '09:30',
        repeat: 'none',
        priority: 'high',
        reminderBeforeMinutes: 60,
        createdAt: now,
        updatedAt: now,
      );

      expect(event.title, 'ND Vaccine Booster');
      expect(event.isCompleted, isFalse);
      expect(event.priorityLabel, 'High');
      expect(event.color, isNotNull);

      final completed = event.copyWith(isCompleted: true, completedAt: now);
      expect(completed.isCompleted, isTrue);
      expect(completed.completedAt, now);
    });

    test('serializes and deserializes correctly', () {
      final event = CalendarEventModel(
        id: 'cal-02',
        farmId: 'farm-01',
        ownerId: 'user-01',
        title: 'Feed Delivery',
        eventType: 'Feed Delivery',
        eventDate: now,
        eventTime: '14:00',
        createdAt: now,
        updatedAt: now,
      );

      final json = event.toJson();
      expect(json['title'], 'Feed Delivery');
      expect(json['eventType'], 'Feed Delivery');

      final restored = CalendarEventModel.fromJson(json);
      expect(restored.id, 'cal-02');
      expect(restored.title, 'Feed Delivery');
    });
  });
}
