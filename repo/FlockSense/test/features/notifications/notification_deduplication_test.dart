import 'package:flutter_test/flutter_test.dart';
import 'package:flock_sense/features/notifications/data/models/notification_model.dart';

void main() {
  group('Notification Model & Deduplication Tests', () {
    test('NotificationModel serializes and deserializes cleanly', () {
      final now = DateTime(2026, 9, 13, 12, 0);
      final model = NotificationModel(
        id: 'notif_test_1',
        title: 'Vaccination Due',
        body: 'Batch A Day 7 Lasota booster is due today.',
        type: NotificationType.vaccination,
        priority: NotificationPriority.high,
        status: NotificationStatus.unread,
        createdAt: now,
        relatedFarmId: 'farm_1',
        relatedBatchId: 'batch_1',
      );

      final json = model.toJson();
      expect(json['id'], 'notif_test_1');
      expect(json['type'], 'vaccination');
      expect(json['priority'], 'high');

      final fromJson = NotificationModel.fromJson(json);
      expect(fromJson.id, 'notif_test_1');
      expect(fromJson.title, 'Vaccination Due');
      expect(fromJson.type, NotificationType.vaccination);
    });

    test('Semantic key deduplication eliminates duplicate notifications', () {
      final list = [
        NotificationModel(
          id: 'doc_1',
          title: 'Low Feed Stock Alert',
          body: 'Starter Feed is running low (12 kg remaining).',
          type: NotificationType.feed,
          priority: NotificationPriority.critical,
          createdAt: DateTime(2026, 9, 13, 10, 0),
        ),
        NotificationModel(
          id: 'doc_2',
          title: 'Low Feed Stock Alert',
          body: 'Starter Feed is running low (12 kg remaining).',
          type: NotificationType.feed,
          priority: NotificationPriority.critical,
          createdAt: DateTime(2026, 9, 13, 10, 5),
        ),
        NotificationModel(
          id: 'doc_3',
          title: 'Routine Vaccine',
          body: 'Gumboro due tomorrow.',
          type: NotificationType.vaccination,
          priority: NotificationPriority.normal,
          createdAt: DateTime(2026, 9, 13, 11, 0),
        ),
      ];

      final seenKeys = <String>{};
      final deduplicated = <NotificationModel>[];

      for (final n in list) {
        final key = '${n.type.name}_${n.title.trim().toLowerCase()}_${n.body.trim().toLowerCase()}';
        if (seenKeys.add(key)) {
          deduplicated.add(n);
        }
      }

      expect(deduplicated.length, 2);
      expect(deduplicated.first.id, 'doc_1');
      expect(deduplicated.last.id, 'doc_3');
    });
  });
}
