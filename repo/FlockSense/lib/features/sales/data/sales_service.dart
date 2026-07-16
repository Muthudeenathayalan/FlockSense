import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flock_sense/core/exceptions/app_exceptions.dart';
import 'package:flock_sense/features/sales/domain/sales_record_model.dart';

class SalesService {
  SalesService._();

  static final _db = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  static CollectionReference<Map<String, dynamic>> _salesRef(
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
        .collection('salesRecords');
  }

  static Stream<List<SalesRecordModel>> watchSalesRecords(
    String farmId,
    String batchId,
  ) {
    try {
      final user = _auth.currentUser;
      if (user == null) return const Stream.empty();

      return _salesRef(user.uid, farmId, batchId).snapshots().map((snapshot) {
        final records = snapshot.docs
            .map((doc) => SalesRecordModel.fromJson(doc.data()))
            .toList();
        records.sort((a, b) => b.date.compareTo(a.date));
        return records;
      });
    } catch (e) {
      debugPrint('SalesService.watchSalesRecords failed: $e');
      throw ExceptionMapper.mapException(e);
    }
  }

  static Future<List<SalesRecordModel>> getBirdSales({
    required String farmId,
    required String batchId,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return [];

    final snapshot = await _salesRef(user.uid, farmId, batchId).get();
    return snapshot.docs
        .map((doc) => SalesRecordModel.fromJson(doc.data()))
        .toList();
  }

  static Future<SalesRecordModel> createSalesRecord({
    required String farmId,
    required String batchId,
    required String customerName,
    required int birdsSold,
    required double averageWeightKg,
    required double pricePerBird,
    required DateTime date,
    required int batchAgeDay,
    String? vehicleNumber,
    String? notes,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw AuthException('Sign in before saving sales records.');
      }

      if (customerName.trim().isEmpty) {
        throw ValidationException('Customer name is required.');
      }
      if (birdsSold <= 0) {
        throw ValidationException('Birds sold must be greater than zero.');
      }

      final totalValue = birdsSold * pricePerBird;
      final now = DateTime.now();
      final record = SalesRecordModel(
        id: _db.collection('_tmp').doc().id,
        farmId: farmId,
        batchId: batchId,
        ownerId: user.uid,
        createdAt: now,
        updatedAt: now,
        date: date,
        batchAgeDay: batchAgeDay,
        customerName: customerName.trim(),
        birdsSold: birdsSold,
        averageWeightKg: averageWeightKg,
        pricePerBird: pricePerBird,
        totalValue: totalValue,
        vehicleNumber: vehicleNumber?.trim(),
        notes: notes?.trim(),
      );

      await _salesRef(
        user.uid,
        farmId,
        batchId,
      ).doc(record.id).set(record.toJson());
      return record;
    } catch (e) {
      debugPrint('SalesService.createSalesRecord failed: $e');
      throw ExceptionMapper.mapException(e);
    }
  }

  static Future<void> deleteSalesRecord(
    String farmId,
    String batchId,
    String recordId,
  ) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw AuthException('Sign in before deleting sales records.');
      }

      await _salesRef(user.uid, farmId, batchId).doc(recordId).delete();
    } catch (e) {
      debugPrint('SalesService.deleteSalesRecord failed: $e');
      throw ExceptionMapper.mapException(e);
    }
  }
}
