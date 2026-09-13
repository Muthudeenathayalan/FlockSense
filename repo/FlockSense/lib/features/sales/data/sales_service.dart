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
        final seen = <String>{};
        final records = <SalesRecordModel>[];
        for (final doc in snapshot.docs) {
          final r = SalesRecordModel.fromJson(doc.data());
          if (seen.add(r.id)) {
            records.add(r);
          }
        }
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
    final seen = <String>{};
    final list = <SalesRecordModel>[];
    for (final doc in snapshot.docs) {
      final r = SalesRecordModel.fromJson(doc.data());
      if (seen.add(r.id)) {
        list.add(r);
      }
    }
    return list;
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

      final salesDocRef = _salesRef(user.uid, farmId, batchId).doc(record.id);
      final batchRef = _db
          .collection('users')
          .doc(user.uid)
          .collection('farms')
          .doc(farmId)
          .collection('batches')
          .doc(batchId);

      await salesDocRef.set(record.toJson());

      // Update currentBirds in batch and mark completed if all birds sold
      try {
        final batchSnap = await batchRef.get();
        if (batchSnap.exists) {
          final current =
              (batchSnap.data()?['currentBirds'] as num?)?.toInt() ??
              (batchSnap.data()?['totalBirds'] as num?)?.toInt() ??
              0;
          final updated = (current - birdsSold).clamp(0, 9999999);
          final updateMap = <String, dynamic>{
            'currentBirds': updated,
            'updatedAt': FieldValue.serverTimestamp(),
          };
          if (updated <= 0) {
            updateMap['status'] = 'completed';
          }
          await batchRef.set(updateMap, SetOptions(merge: true));
        }
      } catch (err) {
        debugPrint('Failed to update batch birds after sale: $err');
      }

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

      final salesDocRef = _salesRef(user.uid, farmId, batchId).doc(recordId);
      final salesSnap = await salesDocRef.get();
      if (salesSnap.exists) {
        final sold = (salesSnap.data()?['birdsSold'] as num?)?.toInt() ?? 0;
        if (sold > 0) {
          final batchRef = _db
              .collection('users')
              .doc(user.uid)
              .collection('farms')
              .doc(farmId)
              .collection('batches')
              .doc(batchId);
          try {
            final batchSnap = await batchRef.get();
            if (batchSnap.exists) {
              final current =
                  (batchSnap.data()?['currentBirds'] as num?)?.toInt() ?? 0;
              await batchRef.set({
                'currentBirds': current + sold,
                'updatedAt': FieldValue.serverTimestamp(),
              }, SetOptions(merge: true));
            }
          } catch (_) {}
        }
      }

      await salesDocRef.delete();
    } catch (e) {
      debugPrint('SalesService.deleteSalesRecord failed: $e');
      throw ExceptionMapper.mapException(e);
    }
  }
}
