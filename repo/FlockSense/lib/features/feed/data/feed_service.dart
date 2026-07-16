import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flock_sense/core/exceptions/app_exceptions.dart';
import 'package:flock_sense/features/daily_records/domain/daily_record_model.dart';
import 'package:flock_sense/features/feed/domain/feed_summary.dart';
import 'package:flock_sense/features/feed/domain/feed_transaction_model.dart';

class FeedService {
  FeedService._();

  static final _db = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  static CollectionReference<Map<String, dynamic>> _feedTransactionsRef(
    String uid,
    String farmId,
    String batchId,
  ) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('farms')
        .doc(farmId)
        .collection('batches')
        .doc(batchId)
        .collection('feedTransactions');
  }

  static CollectionReference<Map<String, dynamic>> _dailyRecordsRef(
    String uid,
    String farmId,
    String batchId,
  ) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('farms')
        .doc(farmId)
        .collection('batches')
        .doc(batchId)
        .collection('dailyRecords');
  }

  static Future<FeedTransactionModel> createFeedTransaction({
    required String farmId,
    required String batchId,
    required DateTime transactionDate,
    required String transactionType,
    required String feedType,
    String? feedBatchNumber,
    String? dcNumber,
    int bags = 0,
    double weightPerBagKg = 0,
    double? totalKg,
    String? supplierOrSource,
    String? destination,
    double costPerKg = 0,
    double totalCost = 0,
    String? notes,
  }) async {
    final user = _auth.currentUser;
    if (user == null)
      throw AuthException('Sign in before saving feed transactions.');

    if (transactionType.isEmpty) {
      throw ValidationException('Transaction type is required.');
    }
    if (feedType.trim().isEmpty) {
      throw ValidationException('Feed type is required.');
    }
    if (transactionType == 'transferOut' &&
        (destination?.trim().isEmpty ?? true)) {
      throw ValidationException('Destination is required for transfer out.');
    }

    final double computedTotalKg =
        (totalKg ??
                (bags > 0 && weightPerBagKg > 0 ? bags * weightPerBagKg : 0))
            .toDouble();
    final double resolvedTotalCost = totalCost > 0
        ? totalCost
        : (costPerKg > 0 && computedTotalKg > 0
              ? costPerKg * computedTotalKg
              : 0);
    if (computedTotalKg < 0) {
      throw ValidationException('Quantity cannot be negative.');
    }
    if (computedTotalKg == 0) {
      throw ValidationException('Quantity must be greater than zero.');
    }

    final transactionId = _db.collection('_tmp').doc().id;
    final now = DateTime.now();
    final transaction = FeedTransactionModel(
      id: transactionId,
      farmId: farmId,
      batchId: batchId,
      transactionDate: transactionDate,
      transactionType: transactionType,
      feedType: feedType.trim(),
      feedBatchNumber: feedBatchNumber?.trim(),
      dcNumber: dcNumber?.trim(),
      bags: bags,
      weightPerBagKg: weightPerBagKg,
      totalKg: computedTotalKg,
      supplierOrSource: supplierOrSource?.trim(),
      destination: destination?.trim(),
      costPerKg: costPerKg,
      totalCost: resolvedTotalCost,
      notes: notes?.trim(),
      ownerId: user.uid,
      createdAt: now,
      updatedAt: now,
    );

    await _feedTransactionsRef(
      user.uid,
      farmId,
      batchId,
    ).doc(transactionId).set(transaction.toJson());
    return transaction;
  }

  static Future<FeedTransactionModel> updateFeedTransaction({
    required String farmId,
    required String batchId,
    required String transactionId,
    required DateTime transactionDate,
    required String transactionType,
    required String feedType,
    String? feedBatchNumber,
    String? dcNumber,
    int bags = 0,
    double weightPerBagKg = 0,
    double? totalKg,
    String? supplierOrSource,
    String? destination,
    double costPerKg = 0,
    double totalCost = 0,
    String? notes,
  }) async {
    final user = _auth.currentUser;
    if (user == null)
      throw AuthException('Sign in before updating feed transactions.');

    final transactionRef = _feedTransactionsRef(
      user.uid,
      farmId,
      batchId,
    ).doc(transactionId);
    final snapshot = await transactionRef.get();
    if (!snapshot.exists)
      throw ValidationException('Feed transaction not found.');

    final now = DateTime.now();
    final double computedTotalKg =
        (totalKg ??
                (bags > 0 && weightPerBagKg > 0 ? bags * weightPerBagKg : 0))
            .toDouble();
    final double resolvedTotalCost = totalCost > 0
        ? totalCost
        : (costPerKg > 0 && computedTotalKg > 0
              ? costPerKg * computedTotalKg
              : 0);
    final updatedTransaction = FeedTransactionModel(
      id: transactionId,
      farmId: farmId,
      batchId: batchId,
      transactionDate: transactionDate,
      transactionType: transactionType,
      feedType: feedType.trim(),
      feedBatchNumber: feedBatchNumber?.trim(),
      dcNumber: dcNumber?.trim(),
      bags: bags,
      weightPerBagKg: weightPerBagKg,
      totalKg: computedTotalKg,
      supplierOrSource: supplierOrSource?.trim(),
      destination: destination?.trim(),
      costPerKg: costPerKg,
      totalCost: resolvedTotalCost,
      notes: notes?.trim(),
      ownerId: user.uid,
      createdAt: snapshot.data()?['createdAt'] is Timestamp
          ? (snapshot.data()!['createdAt'] as Timestamp).toDate()
          : now,
      updatedAt: now,
    );

    await transactionRef.update(updatedTransaction.toJson());
    return updatedTransaction;
  }

  static Future<void> deleteFeedTransaction({
    required String farmId,
    required String batchId,
    required String transactionId,
  }) async {
    final user = _auth.currentUser;
    if (user == null)
      throw AuthException('Sign in before deleting feed transactions.');

    await _feedTransactionsRef(
      user.uid,
      farmId,
      batchId,
    ).doc(transactionId).delete();
  }

  static Stream<List<FeedTransactionModel>> watchFeedTransactions({
    required String farmId,
    required String batchId,
  }) {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();

    return _feedTransactionsRef(user.uid, farmId, batchId)
        .orderBy('transactionDate', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => FeedTransactionModel.fromJson(doc.data()))
              .toList(),
        );
  }

  static Future<List<FeedTransactionModel>> getFeedTransactions({
    required String farmId,
    required String batchId,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return [];

    final snapshot = await _feedTransactionsRef(
      user.uid,
      farmId,
      batchId,
    ).get();
    return snapshot.docs
        .map((doc) => FeedTransactionModel.fromJson(doc.data()))
        .toList();
  }

  static Future<FeedSummary> calculateFeedSummary({
    required String farmId,
    required String batchId,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return FeedSummary.empty;

    try {
      final transactionsSnapshot = await _feedTransactionsRef(
        user.uid,
        farmId,
        batchId,
      ).get();
      final dailyRecordsSnapshot = await _dailyRecordsRef(
        user.uid,
        farmId,
        batchId,
      ).get();

      double totalReceivedKg = 0;
      double totalTransferInKg = 0;
      double totalTransferOutKg = 0;
      double totalAdjustedKg = 0;
      double totalFeedCost = 0;
      double totalConsumedKg = 0;

      for (final doc in transactionsSnapshot.docs) {
        final transaction = FeedTransactionModel.fromJson(doc.data());
        switch (transaction.transactionType) {
          case 'received':
            totalReceivedKg += transaction.totalKg;
            break;
          case 'transferIn':
            totalTransferInKg += transaction.totalKg;
            break;
          case 'transferOut':
            totalTransferOutKg += transaction.totalKg;
            break;
          case 'adjustmentAdd':
            totalAdjustedKg += transaction.totalKg;
            break;
          case 'adjustmentRemove':
            totalAdjustedKg -= transaction.totalKg;
            break;
        }
        totalFeedCost += transaction.totalCost;
      }

      for (final doc in dailyRecordsSnapshot.docs) {
        final record = DailyRecordModel.fromJson(doc.data());
        totalConsumedKg += record.feedConsumedKg;
      }

      final closingStockKg =
          (totalReceivedKg +
                  totalTransferInKg -
                  totalTransferOutKg -
                  totalConsumedKg +
                  totalAdjustedKg)
              .clamp(0.0, double.infinity);

      return FeedSummary(
        totalReceivedKg: totalReceivedKg,
        totalTransferInKg: totalTransferInKg,
        totalTransferOutKg: totalTransferOutKg,
        totalConsumedKg: totalConsumedKg,
        totalAdjustedKg: totalAdjustedKg,
        closingStockKg: closingStockKg,
        totalFeedCost: totalFeedCost,
      );
    } catch (_) {
      return FeedSummary.empty;
    }
  }

  static Future<List<Map<String, dynamic>>> getLowFeedStockAlerts(
    String uid,
  ) async {
    final user = _auth.currentUser;
    if (user == null || uid != user.uid) return const [];

    try {
      final farmsSnapshot = await _db
          .collection('users')
          .doc(uid)
          .collection('farms')
          .get();
      final alerts = <Map<String, dynamic>>[];
      const threshold = 500.0;

      for (final farmDoc in farmsSnapshot.docs) {
        final batchesSnapshot = await farmDoc.reference
            .collection('batches')
            .get();
        for (final batchDoc in batchesSnapshot.docs) {
          final summary = await calculateFeedSummary(
            farmId: farmDoc.id,
            batchId: batchDoc.id,
          );
          if (summary.closingStockKg < threshold) {
            alerts.add({
              'farmId': farmDoc.id,
              'batchId': batchDoc.id,
              'batchName': batchDoc.data()['batchName'] ?? 'Batch',
              'closingStockKg': summary.closingStockKg,
              'threshold': threshold,
            });
          }
        }
      }
      return alerts;
    } catch (_) {
      return const [];
    }
  }
}
