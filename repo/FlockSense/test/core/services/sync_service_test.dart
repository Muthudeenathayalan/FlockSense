import 'package:flutter_test/flutter_test.dart';
import 'package:flock_sense/core/services/sync_service.dart';

void main() {
  group('PendingOperation Model Tests', () {
    test('serializes and deserializes PendingOperation cleanly', () {
      final now = DateTime(2026, 9, 28, 12, 0, 0);
      final op = PendingOperation(
        id: 'daily_b1_2026-09-28',
        type: PendingOpType.dailyRecordCreate,
        path: 'users/u1/farms/f1/batches/b1/dailyRecords/2026-09-28',
        data: {
          'openingBirds': 1000,
          'mortalityCount': 5,
          'cullCount': 2,
          'feedConsumedKg': 120.5,
        },
        queuedAt: now,
        retryCount: 0,
      );

      final json = op.toJson();
      expect(json['id'], 'daily_b1_2026-09-28');
      expect(json['type'], 'dailyRecordCreate');
      expect(json['path'], 'users/u1/farms/f1/batches/b1/dailyRecords/2026-09-28');
      expect(json['data']['openingBirds'], 1000);
      expect(json['retryCount'], 0);

      final restored = PendingOperation.fromJson(json);
      expect(restored.id, op.id);
      expect(restored.type, PendingOpType.dailyRecordCreate);
      expect(restored.path, op.path);
      expect(restored.data['feedConsumedKg'], 120.5);
      expect(restored.queuedAt, now);
      expect(restored.retryCount, 0);
    });

    test('withRetry increments retryCount while preserving all other properties', () {
      final now = DateTime.now();
      final op = PendingOperation(
        id: 'sales_b1_s1',
        type: PendingOpType.salesRecordCreate,
        path: 'users/u1/farms/f1/batches/b1/salesRecords/s1',
        data: {'birdsSold': 500, 'totalValue': 125000.0},
        queuedAt: now,
        retryCount: 1,
      );

      final retried = op.withRetry();
      expect(retried.retryCount, 2);
      expect(retried.id, op.id);
      expect(retried.type, op.type);
      expect(retried.path, op.path);
      expect(retried.data, op.data);
    });

    test('fromJson falls back to default dailyRecordCreate on unknown operation type', () {
      final json = {
        'id': 'legacy_op_1',
        'type': 'unsupported_future_op_type',
        'path': 'users/u1/settings/doc',
        'data': <String, dynamic>{},
        'queuedAt': DateTime.now().toIso8601String(),
        'retryCount': 0,
      };

      final restored = PendingOperation.fromJson(json);
      expect(restored.type, PendingOpType.dailyRecordCreate);
    });

    test('all required PendingOpType values exist for full poultry lifecycle', () {
      expect(PendingOpType.values.contains(PendingOpType.dailyRecordCreate), isTrue);
      expect(PendingOpType.values.contains(PendingOpType.dailyRecordUpdate), isTrue);
      expect(PendingOpType.values.contains(PendingOpType.dailyRecordDelete), isTrue);
      expect(PendingOpType.values.contains(PendingOpType.batchCreate), isTrue);
      expect(PendingOpType.values.contains(PendingOpType.batchUpdate), isTrue);
      expect(PendingOpType.values.contains(PendingOpType.salesRecordCreate), isTrue);
      expect(PendingOpType.values.contains(PendingOpType.financeTransactionCreate), isTrue);
    });
  });

  group('SyncService In-Memory State Tests', () {
    test('singleton instance initializes and exposes pending state safely', () {
      final service = SyncService();
      expect(service, isNotNull);
      expect(service.pendingCount, isNonNegative);
    });

    test('enqueue replaces existing operation with matching id', () async {
      final service = SyncService();
      await service.clearQueue();

      final op1 = PendingOperation(
        id: 'dup_op',
        type: PendingOpType.dailyRecordCreate,
        path: 'path/to/record',
        data: {'version': 1},
        queuedAt: DateTime.now(),
      );

      final op2 = PendingOperation(
        id: 'dup_op',
        type: PendingOpType.dailyRecordUpdate,
        path: 'path/to/record',
        data: {'version': 2},
        queuedAt: DateTime.now(),
      );

      await service.enqueue(op1);
      expect(service.pendingCount, 1);
      expect(service.queue.first.data['version'], 1);

      await service.enqueue(op2);
      expect(service.pendingCount, 1);
      expect(service.queue.first.data['version'], 2);

      await service.removePendingById('dup_op');
      expect(service.pendingCount, 0);
    });

    test('clearQueue empties pending items and resets count', () async {
      final service = SyncService();
      await service.clearQueue();
      expect(service.pendingCount, 0);
      expect(service.hasPending, isFalse);

      await service.enqueue(
        PendingOperation(
          id: 'temp_1',
          type: PendingOpType.farmCreate,
          path: 'users/u1/farms/f1',
          data: {'name': 'Test Farm'},
          queuedAt: DateTime.now(),
        ),
      );
      expect(service.hasPending, isTrue);

      await service.clearQueue();
      expect(service.hasPending, isFalse);
      expect(service.pendingCount, 0);
    });
  });
}
