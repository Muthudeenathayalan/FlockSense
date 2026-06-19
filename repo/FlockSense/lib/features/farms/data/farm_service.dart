import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flock_sense/features/farms/domain/farm_model.dart';

class FarmService {
  FarmService._();

  static final _firestore = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  static String _generateFarmId() {
    return _firestore.collection('users').doc().collection('farms').doc().id;
  }

  /// Creates a farm in the user's subcollection: users/{uid}/farms/{farmId}
  /// 
  /// Firestore Path: users/{uid}/farms/{farmId}
  /// Required: User must be authenticated
  static Future<FarmModel> createFarm({
    required String farmName,
    required String farmType,
    required String flockType,
    required String address,
    required int birdCapacity,
    String? district,
    String? state,
    double? lengthFt,
    double? widthFt,
    String? notes,
  }) async {
    debugPrint('[FarmService.createFarm] Starting farm creation');
    final user = _auth.currentUser;
    debugPrint('[FarmService.createFarm] Current user: ${user?.uid}');
    if (user == null) {
      debugPrint('[FarmService.createFarm] Error: User not authenticated');
      throw FirebaseException(
        plugin: 'firebase_auth',
        message: 'You must be signed in before creating a farm.',
      );
    }

    final farmId = _generateFarmId();
    debugPrint('[FarmService.createFarm] Generated farmId: $farmId');
    debugPrint('[FarmService.createFarm] Firestore path: users/${user.uid}/farms/$farmId');
    debugPrint('[FarmService.createFarm] Farm data: name=$farmName, type=$farmType, flockType=$flockType, address=$address, capacity=$birdCapacity');

    // Save farm to user's subcollection: users/{uid}/farms/{farmId}
    // Firestore rules should restrict access to the owner (uid)
    try {
      await _firestore.collection('users').doc(user.uid).collection('farms').doc(farmId).set({
        'id': farmId,
        'userId': user.uid,
        'farmName': farmName,
        'farmType': farmType,
        'flockType': flockType,
        'address': address,
        'district': district,
        'state': state,
        'birdCapacity': birdCapacity,
        'lengthFt': lengthFt,
        'widthFt': widthFt,
        'notes': notes,
        'status': 'active',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('[FarmService.createFarm] Farm saved successfully to Firestore');
    } catch (e) {
      debugPrint('[FarmService.createFarm] Firestore write error: $e');
      rethrow;
    }

    return FarmModel(
      id: farmId,
      userId: user.uid,
      farmName: farmName,
      farmType: farmType,
      flockType: flockType,
      address: address,
      birdCapacity: birdCapacity,
      district: district,
      state: state,
      lengthFt: lengthFt,
      widthFt: widthFt,
      notes: notes,
      status: 'active',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Retrieves all farms for the current user from: users/{uid}/farms
  /// 
  /// Firestore Path: users/{uid}/farms
  /// Required: User must be authenticated
  static Future<List<FarmModel>> getUserFarms() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseException(
        plugin: 'firebase_auth',
        message: 'You must be signed in to retrieve farms.',
      );
    }

    final snapshot = await _firestore.collection('users').doc(user.uid).collection('farms').get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return FarmModel.fromJson({
        ...data,
        'userId': user.uid,
      });
    }).toList();
  }

  /// Retrieves a specific farm from the user's subcollection
  /// 
  /// Firestore Path: users/{uid}/farms/{farmId}
  static Future<FarmModel?> getFarmById(String farmId) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseException(
        plugin: 'firebase_auth',
        message: 'You must be signed in to retrieve a farm.',
      );
    }

    final snapshot = await _firestore.collection('users').doc(user.uid).collection('farms').doc(farmId).get();

    if (!snapshot.exists || snapshot.data() == null) {
      return null;
    }

    final data = snapshot.data()!;
    return FarmModel.fromJson({
      ...data,
      'userId': user.uid,
    });
  }

  /// Sets the active farm for the current user
  static Future<void> setActiveFarm(String farmId) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseException(
        plugin: 'firebase_auth',
        message: 'You must be signed in to set an active farm.',
      );
    }

    await _firestore.collection('users').doc(user.uid).update({
      'activeFarmId': farmId,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Deletes a farm from the user's subcollection
  /// 
  /// Firestore Path: users/{uid}/farms/{farmId}
  static Future<void> deleteFarm(String farmId) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseException(
        plugin: 'firebase_auth',
        message: 'You must be signed in to delete a farm.',
      );
    }

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('farms')
        .doc(farmId)
        .delete();
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

  /// Suggested Firestore Rules for owner-based subcollection:
  /// 
  /// match /users/{uid}/farms/{farmId} {
  ///   allow read, write: if request.auth.uid == uid;
  /// }
  /// 
  /// This ensures users can only access their own farms.
}
