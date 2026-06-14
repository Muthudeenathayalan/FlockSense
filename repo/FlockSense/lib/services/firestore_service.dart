import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flock_sense/models/daily_record.dart';
import 'package:flock_sense/models/flock.dart';

class FirestoreService {
  final FirebaseFirestore _firestore;
  final String uid;

  FirestoreService({required this.uid})
      : assert(uid.isNotEmpty, 'uid cannot be empty'),
        _firestore = FirebaseFirestore.instance;

  factory FirestoreService.forCurrentUser() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) {
      throw StateError('No authenticated user available for Firestore service.');
    }
    return FirestoreService(uid: uid);
  }

  CollectionReference<Map<String, dynamic>> get _flocksRef {
    return _firestore.collection('users').doc(uid).collection('flocks');
  }

  Stream<List<Flock>> watchFlocks() {
    return _flocksRef.orderBy('createdAt', descending: true).snapshots().map(
          (snapshot) => snapshot.docs.map(Flock.fromDocument).toList(),
        );
  }

  Future<void> createFlock(Flock flock) async {
    await _flocksRef.add(flock.toJson());
  }

  Stream<List<DailyRecord>> watchDailyRecords(String flockId) {
    return _flocksRef
        .doc(flockId)
        .collection('dailyRecords')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(DailyRecord.fromDocument).toList());
  }

  Future<void> addDailyRecord(String flockId, DailyRecord record) async {
    await _flocksRef.doc(flockId).collection('dailyRecords').add(record.toJson());
  }
}
