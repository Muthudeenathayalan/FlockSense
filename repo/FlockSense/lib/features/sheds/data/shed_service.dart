import 'dart:async';
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

  static CollectionReference<Map<String, dynamic>> _shedsRef(
    String uid,
    String farmId,
  ) => _db
      .collection('users')
      .doc(uid)
      .collection('farms')
      .doc(farmId)
      .collection('sheds');

  // ── STREAMS ───────────────────────────────────────────────────────────────

  /// Real-time list of sheds for a farm. Works offline via Firestore cache.
  static Stream<List<ShedModel>> watchSheds(String farmId) {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();

    return _shedsRef(user.uid, farmId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map(
          (snap) => snap.docs.map((d) => ShedModel.fromJson(d.data())).toList(),
        );
  }

  /// Real-time stream of ALL sheds across all farms owned by the user.
  /// Uses direct subcollection listeners so no Firestore collection group index is required.
  static Stream<List<ShedModel>> watchAllUserSheds(String uid) {
    final controller = StreamController<List<ShedModel>>.broadcast();
    StreamSubscription? farmsSub;
    final Map<String, StreamSubscription> shedSubs = {};
    final Map<String, List<ShedModel>> farmSheds = {};

    void emit() {
      if (controller.isClosed) return;
      final all = <ShedModel>[];
      for (final list in farmSheds.values) {
        all.addAll(list);
      }
      all.sort((a, b) => a.shedName.compareTo(b.shedName));
      controller.add(all);
    }

    farmsSub = _db
        .collection('users')
        .doc(uid)
        .collection('farms')
        .snapshots()
        .listen((farmSnap) {
          final currentFarmIds = farmSnap.docs.map((d) => d.id).toSet();

          final removedFarmIds =
              shedSubs.keys.where((id) => !currentFarmIds.contains(id)).toList();
          for (final farmId in removedFarmIds) {
            shedSubs[farmId]?.cancel();
            shedSubs.remove(farmId);
            farmSheds.remove(farmId);
          }

          if (currentFarmIds.isEmpty) {
            farmSheds.clear();
            emit();
            return;
          }

          for (final farmId in currentFarmIds) {
            if (!shedSubs.containsKey(farmId)) {
              shedSubs[farmId] = _shedsRef(uid, farmId).snapshots().listen(
                (shedSnap) {
                  farmSheds[farmId] = shedSnap.docs
                      .map((doc) => ShedModel.fromJson(doc.data()))
                      .toList();
                  emit();
                },
                onError: (e) {
                  debugPrint('[watchAllUserSheds] Error on farm $farmId: $e');
                },
              );
            }
          }
          emit();
        }, onError: (e) {
          debugPrint('[watchAllUserSheds] Error watching farms: $e');
        });

    controller.onCancel = () {
      farmsSub?.cancel();
      for (final sub in shedSubs.values) {
        sub.cancel();
      }
      shedSubs.clear();
      farmSheds.clear();
    };

    return controller.stream;
  }

  /// Sync-status stream — hasPendingWrites signals a local write not yet
  /// confirmed by the server.
  static Stream<SyncStatus> watchSyncStatus(String farmId) {
    final user = _auth.currentUser;
    if (user == null) return Stream.value(SyncStatus.synced);

    return _shedsRef(user.uid, farmId)
        .snapshots(includeMetadataChanges: true)
        .map(
          (snap) => SyncStatus(
            hasPendingWrites: snap.metadata.hasPendingWrites,
            isFromCache: snap.metadata.isFromCache,
          ),
        );
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

    if (name.trim().length < 2)
      throw ValidationException('Shed name must be at least 2 characters.');
    if (lengthFt <= 0)
      throw ValidationException('Length must be greater than zero.');
    if (widthFt <= 0)
      throw ValidationException('Width must be greater than zero.');

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
    final querySnapshot = await _db
        .collectionGroup('sheds')
        .where('userId', isEqualTo: uid)
        .get();

    return querySnapshot.docs.fold<int>(0, (total, doc) {
      final data = doc.data();
      final capacityValue =
          data['capacity'] ?? data['physicalCapacity'] ?? data['birdCapacity'];
      if (capacityValue is num) return total + capacityValue.toInt();
      if (capacityValue is String)
        return total + (int.tryParse(capacityValue) ?? 0);
      return total;
    });
  }

  /// Returns the total number of sheds for the current user.
  static Future<int> getUserShedCount(String uid) async {
    final farmSnapshot = await _db
        .collection('users')
        .doc(uid)
        .collection('farms')
        .get();
    if (farmSnapshot.docs.isEmpty) return 0;

    var shedCount = 0;
    for (final farmDoc in farmSnapshot.docs) {
      final shedSnapshot = await farmDoc.reference.collection('sheds').get();
      shedCount += shedSnapshot.docs.length;
    }
    return shedCount;
  }

  // ── UPDATE ────────────────────────────────────────────────────────────────────────────────

  static Future<void> updateShed(
    String farmId,
    String shedId,
    Map<String, dynamic> updates,
  ) async {
    final user = _auth.currentUser;
    if (user == null) throw AuthException('Sign in before updating a shed.');

    await _shedsRef(user.uid, farmId).doc(shedId).update({
      ...updates,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ── DELETE ────────────────────────────────────────────────────────────────

  static Future<List<ShedModel>> getShedsByFarmId(String farmId) async {
    final user = _auth.currentUser;
    if (user == null) return [];

    final snapshot = await _shedsRef(user.uid, farmId).get();
    return snapshot.docs.map((doc) => ShedModel.fromJson(doc.data())).toList();
  }

  static Future<void> deleteShed(String farmId, String shedId) async {
    final user = _auth.currentUser;
    if (user == null) throw AuthException('Sign in before deleting a shed.');

    await _shedsRef(user.uid, farmId).doc(shedId).delete();
    debugPrint('[ShedService] Shed $shedId deleted');
  }
}
