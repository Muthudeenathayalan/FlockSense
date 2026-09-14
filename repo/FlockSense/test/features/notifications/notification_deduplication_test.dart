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

    test('Dummy and sample notifications are filtered out correctly', () {
      final list = [
        NotificationModel(
          id: 'dummy_1',
          title: 'Dummy notification for testing',
          body: 'This is a sample test alert',
          type: NotificationType.system,
          priority: NotificationPriority.normal,
          createdAt: DateTime.now(),
        ),
        NotificationModel(
          id: 'valid_1',
          title: 'Vaccination Due Today (ND Lasota)',
          body: 'Flock A reaches Day 7 today. Administer ND Lasota.',
          type: NotificationType.vaccination,
          priority: NotificationPriority.high,
          createdAt: DateTime.now(),
        ),
        NotificationModel(
          id: 'test_demo_2',
          title: 'Demo alert for UI',
          body: 'Just testing cards',
          type: NotificationType.system,
          priority: NotificationPriority.low,
          createdAt: DateTime.now(),
        ),
      ];

      final filtered = list.where((n) {
        final titleLower = n.title.toLowerCase();
        final bodyLower = n.body.toLowerCase();
        final isDummy = titleLower.contains('dummy') ||
            bodyLower.contains('dummy') ||
            titleLower.contains('sample alert') ||
            titleLower.contains('test notification') ||
            titleLower.contains('demo notification') ||
            n.id.contains('test_');
        return !isDummy;
      }).toList();

      expect(filtered.length, 1);
      expect(filtered.first.id, 'valid_1');
    });

    test('Multiple pending daily record alerts for same batch are deduplicated to 1', () {
      final list = [
        NotificationModel(
          id: 'daily_record_pending_batch_1',
          title: 'Daily Record Pending — Batch 1',
          body: 'You haven\'t entered today\'s daily record for Batch 1',
          type: NotificationType.batch,
          priority: NotificationPriority.high,
          relatedBatchId: 'batch_1',
          createdAt: DateTime(2026, 9, 14, 8, 0),
        ),
        NotificationModel(
          id: 'daily_record_pending_batch_1_2026-09-13',
          title: 'Daily Record Pending — Batch 1',
          body: 'You haven\'t entered today\'s daily record for Batch 1',
          type: NotificationType.batch,
          priority: NotificationPriority.high,
          relatedBatchId: 'batch_1',
          createdAt: DateTime(2026, 9, 13, 8, 0),
        ),
        NotificationModel(
          id: 'daily_record_pending_batch_2',
          title: 'Daily Record Pending — Batch 2',
          body: 'You haven\'t entered today\'s daily record for Batch 2',
          type: NotificationType.batch,
          priority: NotificationPriority.high,
          relatedBatchId: 'batch_2',
          createdAt: DateTime(2026, 9, 14, 8, 30),
        ),
      ];

      final seenPendingBatches = <String>{};
      final deduplicated = <NotificationModel>[];

      for (final n in list) {
        if (n.id.startsWith('daily_record_pending') ||
            n.title.contains('Daily Record Pending')) {
          final batchId = n.relatedBatchId ?? n.id.replaceFirst('daily_record_pending_', '');
          if (!seenPendingBatches.add(batchId)) continue;
        }
        deduplicated.add(n);
      }

      expect(deduplicated.length, 2);
      expect(deduplicated.map((n) => n.relatedBatchId).toList(), ['batch_1', 'batch_2']);
    });
  });
}
