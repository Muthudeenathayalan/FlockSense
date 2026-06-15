import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flock_sense/features/farms/domain/farm_model.dart';

class FarmService {
  FarmService._();

  static final _firestore = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  static String _generateFarmId() {
    return _firestore.collection('farms').doc().id;
  }

  static Future<FarmModel> createFarm({
    required String farmName,
    required String location,
    required String farmType,
    required int totalCapacity,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw FirebaseException(
        plugin: 'firebase_auth',
        message: 'You must be signed in before creating a farm.',
      );
    }

    final farmId = _generateFarmId();

    // Save farm to Firestore using server timestamps for createdAt/updatedAt
    await _firestore.collection('farms').doc(farmId).set({
      'farmId': farmId,
      'ownerId': user.uid,
      'farmName': farmName,
      'location': location,
      'farmType': farmType,
      'totalCapacity': totalCapacity,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await _firestore.collection('users').doc(user.uid).update({
      'hasFarm': true,
      'activeFarmId': farmId,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return FarmModel(
      farmId: farmId,
      ownerId: user.uid,
      farmName: farmName,
      location: location,
      farmType: farmType,
      totalCapacity: totalCapacity,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  static Future<List<FarmModel>> getUserFarms() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final snapshot = await _firestore
        .collection('farms')
        .where('ownerId', isEqualTo: user.uid)
        .get();

    return snapshot.docs
        .map((doc) => FarmModel.fromJson(doc.data()))
        .toList();
  }

  static Future<FarmModel?> getFarmById(String farmId) async {
    final snapshot = await _firestore.collection('farms').doc(farmId).get();

    if (!snapshot.exists || snapshot.data() == null) {
      return null;
    }

    return FarmModel.fromJson(snapshot.data()!);
  }

  static Future<void> setActiveFarm(String farmId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    await _firestore.collection('users').doc(user.uid).update({
      'activeFarmId': farmId,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  static Future<void> deleteFarm(String farmId) async {
    await _firestore.collection('farms').doc(farmId).delete();
  }

  static String getFormattedFarmType(String farmType) {
    const Map<String, String> farmTypes = {
      'broiler': 'Broiler',
      'layer': 'Layer',
      'breeder': 'Breeder',
      'mixed': 'Mixed',
    };
    return farmTypes[farmType.toLowerCase()] ?? farmType;
  }
}
