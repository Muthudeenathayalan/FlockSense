import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flock_sense/core/exceptions/app_exceptions.dart';
import 'package:flock_sense/features/medicine/domain/medicine_record_model.dart';

class MedicineService {
  MedicineService._();

  static final _db = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  static CollectionReference<Map<String, dynamic>> _medicineRef(
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
        .collection('medicineRecords');
  }

  static Stream<List<MedicineRecordModel>> watchMedicineRecords(
    String farmId,
    String batchId,
  ) {
    try {
      final user = _auth.currentUser;
      if (user == null) return const Stream.empty();

      return _medicineRef(user.uid, farmId, batchId).snapshots().map((
        snapshot,
      ) {
        final records = snapshot.docs
            .map((doc) => MedicineRecordModel.fromJson(doc.data()))
            .toList();
        records.sort((a, b) => b.date.compareTo(a.date));
        return records;
      });
    } catch (e) {
      debugPrint('MedicineService.watchMedicineRecords failed: $e');
      throw ExceptionMapper.mapException(e);
    }
  }

  static Future<List<MedicineRecordModel>> getMedicineRecords({
    required String farmId,
    required String batchId,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return [];

    final snapshot = await _medicineRef(user.uid, farmId, batchId).get();
    return snapshot.docs
        .map((doc) => MedicineRecordModel.fromJson(doc.data()))
        .toList();
  }

  static Future<MedicineRecordModel> createMedicineRecord({
    required String farmId,
    required String batchId,
    required String medicineName,
    required double quantity,
    required String unit,
    required DateTime date,
    required int batchAgeDay,
    String? dcNumber,
    double? valueRs,
    String? route,
    String? notes,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw AuthException('Sign in before saving medicine records.');
      }

      final trimmedName = medicineName.trim();
      final trimmedUnit = unit.trim();
      if (trimmedName.isEmpty) {
        throw ValidationException('Medicine name is required.');
      }
      if (quantity <= 0) {
        throw ValidationException('Quantity must be greater than zero.');
      }
      if (trimmedUnit.isEmpty) {
        throw ValidationException('Unit is required.');
      }

      final now = DateTime.now();
      final record = MedicineRecordModel(
        id: _db.collection('_tmp').doc().id,
        farmId: farmId,
        batchId: batchId,
        ownerId: user.uid,
        createdAt: now,
        updatedAt: now,
        date: date,
        batchAgeDay: batchAgeDay,
        dcNumber: dcNumber?.trim(),
        medicineName: trimmedName,
        quantity: quantity,
        unit: trimmedUnit,
        valueRs: valueRs,
        route: route?.trim(),
        notes: notes?.trim(),
      );

      await _medicineRef(
        user.uid,
        farmId,
        batchId,
      ).doc(record.id).set(record.toJson());
      return record;
    } catch (e) {
      debugPrint('MedicineService.createMedicineRecord failed: $e');
      throw ExceptionMapper.mapException(e);
    }
  }

  static Future<void> deleteMedicineRecord(
    String farmId,
    String batchId,
    String recordId,
  ) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw AuthException('Sign in before deleting medicine records.');
      }

      await _medicineRef(user.uid, farmId, batchId).doc(recordId).delete();
    } catch (e) {
      debugPrint('MedicineService.deleteMedicineRecord failed: $e');
      throw ExceptionMapper.mapException(e);
    }
  }
}
