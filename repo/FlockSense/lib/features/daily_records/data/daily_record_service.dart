import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flock_sense/core/exceptions/app_exceptions.dart';
import 'package:flock_sense/features/daily_records/domain/daily_record_model.dart';

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
  }) async {
    final user = _auth.currentUser;
    if (user == null)
      throw AuthException('Sign in before saving daily records.');

    if (openingBirds < 0)
      throw ValidationException('Opening birds must be zero or positive.');
    if (mortalityCount < 0)
      throw ValidationException('Mortality count must be zero or positive.');
    if (cullCount < 0)
      throw ValidationException('Cull count must be zero or positive.');
    if (adjustmentCount.isNaN || adjustmentCount.toString().contains('NaN'))
      throw ValidationException('Adjustment count must be a valid number.');

    final closingBirds =
        openingBirds - mortalityCount - cullCount + adjustmentCount;
    if (closingBirds < 0)
      throw ValidationException('Closing birds cannot be negative.');
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
    final recordRef = _dailyRecordsRef(user.uid, farmId, batchId).doc(recordId);
    final batchRef = _batchesRef(user.uid, farmId).doc(batchId);

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
      ownerId: user.uid,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );

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
    batch.set(recordRef, record.toJson());
    if (shouldUpdateBatchSummary) {
      batch.update(batchRef, {
        'currentBirds': closingBirds,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();

    return record;
  }

  static Stream<List<DailyRecordModel>> watchDailyRecords({
    required String farmId,
    required String batchId,
  }) {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();

    return _dailyRecordsRef(user.uid, farmId, batchId)
        .orderBy('recordDate', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => DailyRecordModel.fromJson(doc.data()))
              .toList(),
        );
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
    final user = _auth.currentUser;
    if (user == null) return null;

    final recordId = _formatRecordDate(recordDate);
    final snapshot = await _dailyRecordsRef(
      user.uid,
      farmId,
      batchId,
    ).doc(recordId).get();
    if (!snapshot.exists) return null;
    return DailyRecordModel.fromJson(snapshot.data()!);
  }

  static Future<int> getTodayMortalityCount(String uid) async {
    final farms = await _db
        .collection('users')
        .doc(uid)
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
    final user = _auth.currentUser;
    if (user == null) return null;

    final snapshot = await _dailyRecordsRef(user.uid, farmId, batchId)
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
    final user = _auth.currentUser;
    if (user == null) return null;

    final snapshot = await _dailyRecordsRef(
      user.uid,
      farmId,
      batchId,
    ).orderBy('recordDate', descending: true).limit(1).get();

    if (snapshot.docs.isEmpty) return null;
    return DailyRecordModel.fromJson(snapshot.docs.first.data());
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

  static String _formatRecordDate(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  static DateTime? _parseTimestamp(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  /// When an older daily record is edited, recalculate all subsequent records
  /// to maintain data integrity (opening = prior closing, closing = opening - mortality - cull)
  static Future<void> recalculateRecordsAfterDate({
    required String farmId,
    required String batchId,
    required DateTime editedDate,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      // Get the edited record to start the chain from its closing birds
      final editedRecord = await getDailyRecordByDate(
        farmId: farmId,
        batchId: batchId,
        recordDate: editedDate,
      );
      if (editedRecord == null) return;

      // Get all records AFTER the edited date, ordered by date ascending
      final snapshot = await _dailyRecordsRef(user.uid, farmId, batchId)
          .where('recordDate', isGreaterThan: _formatRecordDate(editedDate))
          .orderBy('recordDate', descending: false)
          .get();

      if (snapshot.docs.isEmpty) {
        // No later records, just update batch currentBirds to edited record's closing
        await _batchesRef(user.uid, farmId).doc(batchId).update({
          'currentBirds': editedRecord.closingBirds,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        return;
      }

      // Recalculate each subsequent record
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

        // Update this record with new opening and closing
        batch.update(doc.reference, {
          'openingBirds': previousClosing,
          'closingBirds': newClosing,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        previousClosing = newClosing;
      }

      // Update batch currentBirds to the final closing count
      batch.update(_batchesRef(user.uid, farmId).doc(batchId), {
        'currentBirds': previousClosing,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();
    } catch (e) {
      debugPrint(
        '[DailyRecordService] Error recalculating records after $editedDate: $e',
      );
      rethrow;
    }
  }
}
