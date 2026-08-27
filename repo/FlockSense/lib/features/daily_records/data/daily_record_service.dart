import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flock_sense/core/models/sync_status.dart';
import 'package:flock_sense/core/exceptions/app_exceptions.dart';
import 'package:flock_sense/core/services/notification_service.dart';
import 'package:flock_sense/features/daily_records/domain/daily_record_model.dart';
import 'package:flock_sense/features/inventory/data/inventory_service.dart';
import 'package:flock_sense/features/notifications/data/models/notification_model.dart';
import 'package:flock_sense/features/notifications/data/services/notification_firestore_service.dart';

class DailyRecordService {
  DailyRecordService._();

  static final _db = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

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

  static CollectionReference<Map<String, dynamic>> _batchesRef(
    String uid,
    String farmId,
  ) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('farms')
        .doc(farmId)
        .collection('batches');
  }

  /// Create or update a full daily record with support for sub-fields
  static Future<DailyRecordModel> createOrUpdateDailyRecord({
    required String farmId,
    required String batchId,
    required DateTime recordDate,
    required int batchAgeDay,
    required int openingBirds,
    required int mortalityCount,
    required int cullCount,
    int adjustmentCount = 0,
    required double feedConsumedKg,
    required double waterConsumedLiters,
    required double avgWeightGrams,
    required bool medicineGiven,
    String? medicineName,
    required bool vaccineGiven,
    String? vaccineName,
    String? symptoms,
    String? notes,
    // Sub-fields for specialized types
    String? feedType,
    double? feedCost,
    String? feedSupplier,
    String? waterSource,
    String? waterQuality,
    String? mortalityCause,
    String? mortalityDisease,
    String? mortalityRemarks,
    int? sampleBirds,
    String? medicineDose,
    double? medicineQuantity,
    double? medicineCost,
    String? medicineReason,
    String? vaccineDose,
    String? vaccineCompletedBy,
    DateTime? vaccineNextDueDate,
    double? temperature,
    double? humidity,
    String? weather,
    double? dgLevelLiters,
    double? dgAddedLiters,
    double? dgRunningHours,
    String? dgName,
  }) async {
    final uid = _auth.currentUser?.uid ?? 'local_user';

    if (openingBirds < 0) {
      throw ValidationException('Opening birds must be zero or positive.');
    }
    if (mortalityCount < 0) {
      throw ValidationException('Mortality count must be zero or positive.');
    }
    if (cullCount < 0) {
      throw ValidationException('Cull count must be zero or positive.');
    }
    if (feedConsumedKg < 0) {
      throw ValidationException('Feed consumed quantity cannot be negative.');
    }
    if (waterConsumedLiters < 0) {
      throw ValidationException('Water consumed quantity cannot be negative.');
    }
    if (avgWeightGrams < 0) {
      throw ValidationException('Average weight cannot be negative.');
    }
    if (dgLevelLiters != null && dgLevelLiters < 0) {
      throw ValidationException('Current diesel level cannot be negative.');
    }
    if (dgAddedLiters != null && dgAddedLiters < 0) {
      throw ValidationException('Added diesel quantity cannot be negative.');
    }
    if (dgRunningHours != null && dgRunningHours < 0) {
      throw ValidationException('Generator running hours cannot be negative.');
    }
    if (adjustmentCount.isNaN || adjustmentCount.toString().contains('NaN')) {
      throw ValidationException('Adjustment count must be a valid number.');
    }

    final closingBirds =
        openingBirds - mortalityCount - cullCount + adjustmentCount;
    if (closingBirds < 0) {
      throw ValidationException('Closing birds cannot be negative.');
    }
    if (medicineGiven && (medicineName?.trim().isEmpty ?? true)) {
      throw ValidationException(
        'Medicine name is required when medicine is given.',
      );
    }
    if (vaccineGiven && (vaccineName?.trim().isEmpty ?? true)) {
      throw ValidationException(
        'Vaccine name is required when vaccine is given.',
      );
    }

    final recordId = _formatRecordDate(recordDate);
    final recordRef = _dailyRecordsRef(uid, farmId, batchId).doc(recordId);
    final batchRef = _batchesRef(uid, farmId).doc(batchId);

    final existingSnapshot = await recordRef.get();
    final createdAt = existingSnapshot.exists
        ? _parseTimestamp(existingSnapshot.data()?['createdAt']) ??
              DateTime.now()
        : DateTime.now();

    final record = DailyRecordModel(
      id: recordId,
      farmId: farmId,
      batchId: batchId,
      recordDate: recordDate,
      batchAgeDay: batchAgeDay,
      openingBirds: openingBirds,
      mortalityCount: mortalityCount,
      cullCount: cullCount,
      adjustmentCount: adjustmentCount,
      closingBirds: closingBirds,
      feedConsumedKg: feedConsumedKg,
      waterConsumedLiters: waterConsumedLiters,
      avgWeightGrams: avgWeightGrams,
      medicineGiven: medicineGiven,
      medicineName: medicineName?.trim(),
      vaccineGiven: vaccineGiven,
      vaccineName: vaccineName?.trim(),
      symptoms: symptoms?.trim(),
      notes: notes?.trim(),
      ownerId: uid,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      feedType: feedType?.trim(),
      feedCost: feedCost,
      feedSupplier: feedSupplier?.trim(),
      waterSource: waterSource?.trim(),
      waterQuality: waterQuality?.trim(),
      mortalityCause: mortalityCause?.trim(),
      mortalityDisease: mortalityDisease?.trim(),
      mortalityRemarks: mortalityRemarks?.trim(),
      sampleBirds: sampleBirds,
      medicineDose: medicineDose?.trim(),
      medicineQuantity: medicineQuantity,
      medicineCost: medicineCost,
      medicineReason: medicineReason?.trim(),
      vaccineDose: vaccineDose?.trim(),
      vaccineCompletedBy: vaccineCompletedBy?.trim(),
      vaccineNextDueDate: vaccineNextDueDate,
      temperature: temperature,
      humidity: humidity,
      weather: weather?.trim(),
      dgLevelLiters: dgLevelLiters,
      dgAddedLiters: dgAddedLiters,
      dgRunningHours: dgRunningHours,
      dgName: dgName?.trim(),
    );

    // Low Fuel Notification Trigger
    if (dgLevelLiters != null && dgLevelLiters < 80.0) {
      try {
        final title = '⚠️ Low DG Fuel Level';
        final body =
            'Diesel Generator fuel level is below 80L. Current level: ${dgLevelLiters.toStringAsFixed(0)} L. Please refill soon.';
        final priority = dgLevelLiters < 50.0
            ? NotificationPriority.critical
            : NotificationPriority.high;

        final notif = NotificationModel(
          id: 'dg_low_fuel_${farmId}_${_formatRecordDate(recordDate)}',
          title: title,
          body: body,
          type: NotificationType.dg,
          priority: priority,
          createdAt: DateTime.now(),
          relatedFarmId: farmId,
          relatedBatchId: batchId,
          metadata: {'currentLevel': dgLevelLiters, 'generatorName': dgName},
        );
        await NotificationFirestoreService.saveNotification(notif);
        await NotificationService.checkLowDgFuelAlert(
          currentLevel: dgLevelLiters,
          generatorName: dgName,
        );
      } catch (e) {
        debugPrint('[DailyRecordService] Low DG Fuel notification error: $e');
      }
    }

    final latestExistingRecord = await getLatestRecordBeforeDate(
      farmId: farmId,
      batchId: batchId,
      beforeDate: recordDate,
    );
    final shouldUpdateBatchSummary =
        latestExistingRecord == null ||
        latestExistingRecord.recordDate.isBefore(recordDate) ||
        latestExistingRecord.recordDate.isAtSameMomentAs(recordDate);

    final batch = _db.batch();
    batch.set(recordRef, record.toJson(), SetOptions(merge: true));
    if (shouldUpdateBatchSummary) {
      batch.set(batchRef, {
        'currentBirds': closingBirds,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
    await batch.commit();

    // Automatic Inventory Stock Deductions
    try {
      final invService = InventoryService();
      if (feedConsumedKg > 0) {
        await invService.autoDeductStock(
          uid: uid,
          farmId: farmId,
          category: 'Feed',
          itemName: feedType?.isNotEmpty == true ? feedType! : 'Feed',
          amountUsed: feedConsumedKg,
          reason: 'Feed Used (Daily Telemetry Log)',
        );
      }
      if (medicineGiven &&
          medicineName != null &&
          medicineName.trim().isNotEmpty) {
        await invService.autoDeductStock(
          uid: uid,
          farmId: farmId,
          category: 'Medicine',
          itemName: medicineName.trim(),
          amountUsed: medicineQuantity ?? 1.0,
          reason: 'Medicine Used (${medicineName.trim()})',
        );
      }
      if (vaccineGiven &&
          vaccineName != null &&
          vaccineName.trim().isNotEmpty) {
        await invService.autoDeductStock(
          uid: uid,
          farmId: farmId,
          category: 'Vaccines',
          itemName: vaccineName.trim(),
          amountUsed: 1.0,
          reason: 'Vaccine Administered (${vaccineName.trim()})',
        );
      }
    } catch (e) {
      debugPrint('Automatic inventory deduction error: $e');
    }

    return record;
  }

  /// Delete a daily record and update batch bird counts automatically
  static Future<void> deleteDailyRecord({
    required String farmId,
    required String batchId,
    required String recordId,
    required DateTime recordDate,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw AuthException('Sign in before deleting daily records.');
    }

    final recordRef = _dailyRecordsRef(user.uid, farmId, batchId).doc(recordId);
    await recordRef.delete();

    // Recalculate bird counts after deletion
    final priorRecord = await getLatestRecordBeforeDate(
      farmId: farmId,
      batchId: batchId,
      beforeDate: recordDate,
    );
    if (priorRecord != null) {
      await _batchesRef(user.uid, farmId).doc(batchId).set({
        'currentBirds': priorRecord.closingBirds,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }

  /// Realtime stream of daily records for a specific farm & batch
  static Stream<List<DailyRecordModel>> watchDailyRecords({
    required String farmId,
    required String batchId,
  }) async* {
    yield const [];
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final stream = _dailyRecordsRef(
        user.uid,
        farmId,
        batchId,
      ).orderBy('recordDate', descending: true).snapshots();

      await for (final snap in stream) {
        final list = snap.docs
            .map((doc) => DailyRecordModel.fromJson(doc.data()))
            .toList();
        yield list;
      }
    } catch (e) {
      debugPrint('[DailyRecordService] watchDailyRecords error: $e');
      yield const [];
    }
  }

  /// Stream ALL daily records across user farms
  static Stream<List<DailyRecordModel>> watchAllUserDailyRecords(
    String uid,
  ) async* {
    yield const [];
    try {
      final stream = _db.collectionGroup('dailyRecords').snapshots();

      await for (final snap in stream) {
        final list = snap.docs
            .map((doc) => DailyRecordModel.fromJson(doc.data()))
            .where((r) => r.ownerId == uid || r.ownerId.isEmpty)
            .toList();
        list.sort((a, b) => b.recordDate.compareTo(a.recordDate));
        yield list;
      }
    } catch (e) {
      debugPrint('[DailyRecordService] watchAllUserDailyRecords error: $e');
      yield const [];
    }
  }

  static Future<List<DailyRecordModel>> getAllDailyRecords({
    required String farmId,
    required String batchId,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return [];

    final snapshot = await _dailyRecordsRef(user.uid, farmId, batchId).get();
    return snapshot.docs
        .map((doc) => DailyRecordModel.fromJson(doc.data()))
        .toList();
  }

  static Future<DailyRecordModel?> getDailyRecordByDate({
    required String farmId,
    required String batchId,
    required DateTime recordDate,
  }) async {
    final uid = _auth.currentUser?.uid ?? 'local_user';

    final recordId = _formatRecordDate(recordDate);
    final snapshot = await _dailyRecordsRef(
      uid,
      farmId,
      batchId,
    ).doc(recordId).get();
    if (!snapshot.exists) return null;
    return DailyRecordModel.fromJson(snapshot.data()!);
  }

  static Future<int> getTodayMortalityCount(String uid) async {
    final effectiveUid = uid.isNotEmpty
        ? uid
        : (_auth.currentUser?.uid ?? 'local_user');
    final farms = await _db
        .collection('users')
        .doc(effectiveUid)
        .collection('farms')
        .get();
    if (farms.docs.isEmpty) return 0;

    final todayId = _formatRecordDate(DateTime.now());
    var total = 0;

    for (final farmDoc in farms.docs) {
      final batchSnapshot = await farmDoc.reference
          .collection('batches')
          .where('status', isEqualTo: 'active')
          .get();
      for (final batchDoc in batchSnapshot.docs) {
        final recordDoc = await batchDoc.reference
            .collection('dailyRecords')
            .doc(todayId)
            .get();
        if (!recordDoc.exists) continue;
        final data = recordDoc.data();
        if (data == null) continue;
        final mortality = data['mortalityCount'];
        if (mortality is int) {
          total += mortality;
        } else if (mortality is double) {
          total += mortality.toInt();
        } else if (mortality is String) {
          total += int.tryParse(mortality) ?? 0;
        }
      }
    }

    return total;
  }

  static Future<DailyRecordModel?> getLatestRecordBeforeDate({
    required String farmId,
    required String batchId,
    required DateTime beforeDate,
  }) async {
    final uid = _auth.currentUser?.uid ?? 'local_user';

    final snapshot = await _dailyRecordsRef(uid, farmId, batchId)
        .where('recordDate', isLessThan: _formatRecordDate(beforeDate))
        .orderBy('recordDate', descending: true)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    return DailyRecordModel.fromJson(snapshot.docs.first.data());
  }

  static Future<DailyRecordModel?> getBatchLatestRecord({
    required String farmId,
    required String batchId,
  }) async {
    final uid = _auth.currentUser?.uid ?? 'local_user';

    final snapshot = await _dailyRecordsRef(
      uid,
      farmId,
      batchId,
    ).orderBy('recordDate', descending: true).limit(1).get();

    if (snapshot.docs.isEmpty) return null;
    return DailyRecordModel.fromJson(snapshot.docs.first.data());
  }

  static String _formatRecordDate(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  static DateTime? _parseTimestamp(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  /// Recalculate records after an edit or delete
  static Future<void> recalculateRecordsAfterDate({
    required String farmId,
    required String batchId,
    required DateTime editedDate,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final editedRecord = await getDailyRecordByDate(
        farmId: farmId,
        batchId: batchId,
        recordDate: editedDate,
      );
      if (editedRecord == null) return;

      final snapshot = await _dailyRecordsRef(user.uid, farmId, batchId)
          .where('recordDate', isGreaterThan: _formatRecordDate(editedDate))
          .orderBy('recordDate', descending: false)
          .get();

      if (snapshot.docs.isEmpty) {
        await _batchesRef(user.uid, farmId).doc(batchId).set({
          'currentBirds': editedRecord.closingBirds,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        return;
      }

      var previousClosing = editedRecord.closingBirds;
      final batch = _db.batch();

      for (final doc in snapshot.docs) {
        final record = DailyRecordModel.fromJson(doc.data());
        final newClosing =
            previousClosing -
            record.mortalityCount -
            record.cullCount +
            record.adjustmentCount;
        if (newClosing < 0) {
          throw ValidationException(
            'Recalculation would result in negative bird count on ${record.recordDate}.',
          );
        }

        batch.set(doc.reference, {
          'openingBirds': previousClosing,
          'closingBirds': newClosing,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        previousClosing = newClosing;
      }

      batch.set(_batchesRef(user.uid, farmId).doc(batchId), {
        'currentBirds': previousClosing,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await batch.commit();
    } catch (e) {
      debugPrint(
        '[DailyRecordService] Error recalculating records after $editedDate: $e',
      );
      rethrow;
    }
  }

  /// Sync-status stream for daily records of a specific farm & batch
  static Stream<SyncStatus> watchSyncStatus({
    required String farmId,
    required String batchId,
  }) {
    final user = _auth.currentUser;
    if (user == null) return Stream.value(SyncStatus.synced);

    return _dailyRecordsRef(user.uid, farmId, batchId)
        .snapshots(includeMetadataChanges: true)
        .map(
          (snap) => SyncStatus(
            hasPendingWrites: snap.metadata.hasPendingWrites,
            isFromCache: snap.metadata.isFromCache,
          ),
        );
  }

  /// Revert a mortality logging action (offline-safe update without transactions)
  static Future<void> undoMortalityLog({
    required String farmId,
    required String batchId,
    required DateTime recordDate,
    required int previousMortality,
    required int previousClosing,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final recordId = _formatRecordDate(recordDate);
    final recordRef = _dailyRecordsRef(user.uid, farmId, batchId).doc(recordId);
    final batchRef = _batchesRef(user.uid, farmId).doc(batchId);

    final batch = _db.batch();
    batch.set(recordRef, {
      'mortalityCount': previousMortality,
      'closingBirds': previousClosing,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    batch.set(batchRef, {
      'currentBirds': previousClosing,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await batch.commit();
  }
}
