import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flock_sense/features/batches/domain/batch_model.dart';
import 'package:flock_sense/core/exceptions/app_exceptions.dart';

class BatchService {
  BatchService._();

  static final _db = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  static CollectionReference<Map<String, dynamic>> _batchesRef(String uid, String farmId) =>
      _db.collection('users').doc(uid).collection('farms').doc(farmId).collection('batches');

  static Stream<List<BatchModel>> watchBatches(String farmId) {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();

    return _batchesRef(user.uid, farmId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snap) => snap.docs.map((d) => BatchModel.fromJson(d.data())).toList());
  }

  /// Returns the total number of active batches for the current user.
  static Future<int> getUserActiveBatchCount(String uid) async {
    final farmSnapshot = await _db.collection('users').doc(uid).collection('farms').get();
    if (farmSnapshot.docs.isEmpty) return 0;

    var activeCount = 0;
    for (final farmDoc in farmSnapshot.docs) {
      final batchSnapshot = await farmDoc.reference
          .collection('batches')
          .where('status', isEqualTo: 'active')
          .get();
      activeCount += batchSnapshot.docs.length;
    }
    return activeCount;
  }

  /// Returns the total live birds across all active batches for the current user.
  static Future<int> getUserLiveBirdCount(String uid) async {
    final farmSnapshot = await _db.collection('users').doc(uid).collection('farms').get();
    if (farmSnapshot.docs.isEmpty) return 0;

    var liveBirdCount = 0;
    for (final farmDoc in farmSnapshot.docs) {
      final batchSnapshot = await farmDoc.reference
          .collection('batches')
          .where('status', isEqualTo: 'active')
          .get();
      for (final doc in batchSnapshot.docs) {
        final data = doc.data();
        final currentBirds = data['currentBirds'] ?? data['totalBirds'];
        if (currentBirds is num) {
          liveBirdCount += currentBirds.toInt();
        } else if (currentBirds is String) {
          liveBirdCount += int.tryParse(currentBirds) ?? 0;
        }
      }
    }
    return liveBirdCount;
  }

  static Future<BatchModel> createBatch({
    required String farmId,
    String? shedId,
    required String batchName,
    required DateTime hatchDate,
    required DateTime placementDate,
    required int maleCount,
    required int femaleCount,
    required String breedOrFlockType,
    double? chickAvgWeight,
    String? hatcheryName,
    String? supervisorName,
    String? vehicleNumber,
    String? notes,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw AuthException('Sign in before creating a batch.');

    if (batchName.trim().isEmpty) throw ValidationException('Batch name is required.');
    if (maleCount < 0 || femaleCount < 0) throw ValidationException('Bird counts must be zero or positive.');
    if (maleCount + femaleCount <= 0) throw ValidationException('Total birds must be greater than zero.');

    final batchId = _db.collection('_tmp').doc().id;
    final totalBirds = maleCount + femaleCount;
    final batchData = {
      'id': batchId,
      'farmId': farmId,
      'shedId': shedId,
      'ownerId': user.uid,
      'batchName': batchName.trim(),
      'hatchDate': hatchDate.toIso8601String(),
      'placementDate': placementDate.toIso8601String(),
      'maleCount': maleCount,
      'femaleCount': femaleCount,
      'totalBirds': totalBirds,
      'currentBirds': totalBirds,
      'breedOrFlockType': breedOrFlockType,
      'chickAvgWeight': chickAvgWeight,
      'hatcheryName': hatcheryName,
      'supervisorName': supervisorName,
      'vehicleNumber': vehicleNumber,
      'status': 'active',
      'notes': notes?.trim(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    await _batchesRef(user.uid, farmId).doc(batchId).set(batchData);
    debugPrint('[BatchService] Batch $batchId saved (may be queued offline)');

    return BatchModel(
      id: batchId,
      farmId: farmId,
      shedId: shedId,
      ownerId: user.uid,
      batchName: batchName.trim(),
      hatchDate: hatchDate,
      placementDate: placementDate,
      maleCount: maleCount,
      femaleCount: femaleCount,
      totalBirds: totalBirds,
      currentBirds: totalBirds,
      breedOrFlockType: breedOrFlockType,
      chickAvgWeight: chickAvgWeight,
      hatcheryName: hatcheryName,
      supervisorName: supervisorName,
      vehicleNumber: vehicleNumber,
      notes: notes?.trim(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  static Future<void> updateBatch(String farmId, String batchId, Map<String, dynamic> updates) async {
    final user = _auth.currentUser;
    if (user == null) throw AuthException('Sign in before updating a batch.');

    await _batchesRef(user.uid, farmId).doc(batchId).update({
      ...updates,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> deleteBatch(String farmId, String batchId) async {
    final user = _auth.currentUser;
    if (user == null) throw AuthException('Sign in before deleting a batch.');

    await _batchesRef(user.uid, farmId).doc(batchId).delete();
    debugPrint('[BatchService] Batch $batchId deleted');
  }
}
