import 'package:flutter_test/flutter_test.dart';
import 'package:flock_sense/features/feed/domain/feed_transaction_model.dart';

void main() {
  group('FeedTransactionModel', () {
    test('calculates totalKg from bags and weight per bag when provided', () {
      final transaction = FeedTransactionModel(
        id: 'tx-1',
        farmId: 'farm-1',
        batchId: 'batch-1',
        transactionDate: DateTime(2024, 1, 10),
        transactionType: 'received',
        feedType: 'Starter',
        bags: 10,
        weightPerBagKg: 25,
        totalKg: 0,
        ownerId: 'user-1',
        createdAt: DateTime(2024, 1, 10),
        updatedAt: DateTime(2024, 1, 10),
      );

      expect(transaction.totalKg, 250);
    });

    test('keeps explicit totalKg when provided', () {
      final transaction = FeedTransactionModel(
        id: 'tx-2',
        farmId: 'farm-1',
        batchId: 'batch-1',
        transactionDate: DateTime(2024, 1, 10),
        transactionType: 'received',
        feedType: 'Grower',
        bags: 4,
        weightPerBagKg: 25,
        totalKg: 120,
        ownerId: 'user-1',
        createdAt: DateTime(2024, 1, 10),
        updatedAt: DateTime(2024, 1, 10),
      );

      expect(transaction.totalKg, 120);
    });
  });
}
