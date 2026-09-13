import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flock_sense/core/exceptions/app_exceptions.dart';
import 'package:flock_sense/features/weight/domain/weight_record_model.dart';

class WeightRecordService {
  WeightRecordService._();

  static final _db = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  static CollectionReference<Map<String, dynamic>> _weightRecordsRef(
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
        .collection('weightRecords');
  }

  static Future<WeightRecordModel> createOrUpdateWeightRecord({
    required String farmId,
    required String batchId,
    required DateTime recordDate,
    required double averageWeight,
    required String unit,
    int? sampleCount,
    String? notes,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw AuthException('Sign in before saving weight records.');
    }

    if (averageWeight <= 0) {
      throw ValidationException('Average weight must be greater than zero.');
    }

    if (sampleCount != null && sampleCount < 0) {
      throw ValidationException('Sample count cannot be negative.');
    }

    final recordId = _formatRecordDate(recordDate);
    final recordRef = _weightRecordsRef(
      user.uid,
      farmId,
      batchId,
    ).doc(recordId);

    final existingSnapshot = await recordRef.get();
    final createdAt = existingSnapshot.exists
        ? _parseTimestamp(existingSnapshot.data()?['createdAt']) ??
              DateTime.now()
        : DateTime.now();

    final record = WeightRecordModel(
      id: recordId,
      userId: user.uid,
      farmId: farmId,
      batchId: batchId,
      recordDate: recordDate,
      averageWeight: averageWeight,
      unit: unit,
      sampleCount: sampleCount,
      notes: notes?.trim(),
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );

    await recordRef.set(record.toJson());

    // Merge average weight into dailyRecords for seamless growth analytics
    try {
      final weightInGrams = unit.toLowerCase().startsWith('k')
          ? averageWeight * 1000.0
          : averageWeight;

      final dailyRef = _db
          .collection('users')
          .doc(user.uid)
          .collection('farms')
          .doc(farmId)
          .collection('batches')
          .doc(batchId)
          .collection('dailyRecords')
          .doc(recordId);

      final dailySnap = await dailyRef.get();
      if (dailySnap.exists) {
        await dailyRef.set({
          'avgWeightGrams': weightInGrams,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint('[WeightRecordService] Sync to dailyRecord error: $e');
    }

    return record;
  }

  static Stream<List<WeightRecordModel>> watchWeightRecords({
    required String farmId,
    required String batchId,
  }) {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();

    return _weightRecordsRef(user.uid, farmId, batchId)
        .orderBy('recordDate', descending: true)
        .snapshots()
        .map(
          (snap) {
            final seen = <String>{};
            final list = <WeightRecordModel>[];
            for (final doc in snap.docs) {
              final r = WeightRecordModel.fromJson(doc.data());
              if (seen.add(r.id)) {
                list.add(r);
              }
            }
            return list;
          },
        );
  }

  static Future<WeightRecordModel?> getWeightRecordByDate({
    required String farmId,
    required String batchId,
    required DateTime recordDate,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final recordId = _formatRecordDate(recordDate);
    final snapshot = await _weightRecordsRef(
      user.uid,
      farmId,
      batchId,
    ).doc(recordId).get();
    if (!snapshot.exists) return null;
    return WeightRecordModel.fromJson(snapshot.data()!);
  }

  static Future<void> deleteWeightRecord({
    required String farmId,
    required String batchId,
    required DateTime recordDate,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw AuthException('Sign in before deleting weight records.');
    }

    final recordId = _formatRecordDate(recordDate);
    await _weightRecordsRef(user.uid, farmId, batchId).doc(recordId).delete();
  }

  static String _formatRecordDate(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  static DateTime? _parseTimestamp(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
