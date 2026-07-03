import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flock_sense/features/sheds/domain/shed_model.dart';
import 'package:flock_sense/core/exceptions/app_exceptions.dart';
import 'package:flock_sense/core/models/sync_status.dart';

/// Shed data service — all writes are offline-safe plain set()/delete() calls.
/// Path: users/{uid}/farms/{farmId}/sheds/{shedId}
class ShedService {
  ShedService._();

  static final _db = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  static CollectionReference<Map<String, dynamic>> _shedsRef(String uid, String farmId) =>
      _db.collection('users').doc(uid).collection('farms').doc(farmId).collection('sheds');

  // ── STREAMS ───────────────────────────────────────────────────────────────

  /// Real-time list of sheds for a farm. Works offline via Firestore cache.
  static Stream<List<ShedModel>> watchSheds(String farmId) {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();

    return _shedsRef(user.uid, farmId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snap) => snap.docs.map((d) => ShedModel.fromJson(d.data())).toList());
  }

  /// Sync-status stream — hasPendingWrites signals a local write not yet
  /// confirmed by the server.
  static Stream<SyncStatus> watchSyncStatus(String farmId) {
    final user = _auth.currentUser;
    if (user == null) return Stream.value(SyncStatus.synced);

    return _shedsRef(user.uid, farmId)
        .snapshots(includeMetadataChanges: true)
        .map((snap) => SyncStatus(
              hasPendingWrites: snap.metadata.hasPendingWrites,
              isFromCache: snap.metadata.isFromCache,
            ));
  }

  // ── CREATE ────────────────────────────────────────────────────────────────

  static Future<ShedModel> createShed({
    required String farmId,
    required String name,
    required double lengthFt,
    required double widthFt,
    int? capacity,
    String? notes,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw AuthException('Sign in before creating a shed.');

    if (name.trim().length < 2) throw ValidationException('Shed name must be at least 2 characters.');
    if (lengthFt <= 0) throw ValidationException('Length must be greater than zero.');
    if (widthFt <= 0) throw ValidationException('Width must be greater than zero.');

    final shedId = _db.collection('_tmp').doc().id;
    final totalSqFt = lengthFt * widthFt;
    final shedData = {
      'id': shedId,
      'farmId': farmId,
      'userId': user.uid,
      'ownerId': user.uid,
      'name': name.trim(),
      'shedName': name.trim(),
      'lengthFt': lengthFt,
      'widthFt': widthFt,
      'totalSqFt': totalSqFt,
      'capacity': capacity,
      'notes': notes?.trim(),
      'status': 'active',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    // Offline-safe write — SDK queues locally if no network.
    await _shedsRef(user.uid, farmId).doc(shedId).set(shedData);
    debugPrint('[ShedService] Shed $shedId saved (may be queued offline)');

    return ShedModel(
      id: shedId,
      farmId: farmId,
      ownerId: user.uid,
      name: name.trim(),
      lengthFt: lengthFt,
      widthFt: widthFt,
      totalSqFt: totalSqFt,
      capacity: capacity,
      notes: notes?.trim(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Returns the total bird capacity from all sheds across the current user.
  static Future<int> getUserShedCapacity(String uid) async {
    final querySnapshot = await _db.collectionGroup('sheds')
      .where('userId', isEqualTo: uid)
      .get();

    return querySnapshot.docs.fold<int>(0, (total, doc) {
      final data = doc.data();
      final capacityValue = data['capacity'] ?? data['physicalCapacity'] ?? data['birdCapacity'];
      if (capacityValue is num) return total + capacityValue.toInt();
      if (capacityValue is String) return total + (int.tryParse(capacityValue) ?? 0);
      return total;
    });
  }

  /// Returns the total number of sheds for the current user.
  static Future<int> getUserShedCount(String uid) async {
    final farmSnapshot = await _db.collection('users').doc(uid).collection('farms').get();
    if (farmSnapshot.docs.isEmpty) return 0;

    var shedCount = 0;
    for (final farmDoc in farmSnapshot.docs) {
      final shedSnapshot = await farmDoc.reference.collection('sheds').get();
      shedCount += shedSnapshot.docs.length;
    }
    return shedCount;
  }

  // ── UPDATE ────────────────────────────────────────────────────────────────────────────────

  static Future<void> updateShed(String farmId, String shedId, Map<String, dynamic> updates) async {
    final user = _auth.currentUser;
    if (user == null) throw AuthException('Sign in before updating a shed.');

    await _shedsRef(user.uid, farmId).doc(shedId).update({
      ...updates,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ── DELETE ────────────────────────────────────────────────────────────────

  static Future<void> deleteShed(String farmId, String shedId) async {
    final user = _auth.currentUser;
    if (user == null) throw AuthException('Sign in before deleting a shed.');

    await _shedsRef(user.uid, farmId).doc(shedId).delete();
    debugPrint('[ShedService] Shed $shedId deleted');
  }
}
