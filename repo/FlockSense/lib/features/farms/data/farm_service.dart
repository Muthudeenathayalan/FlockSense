import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flock_sense/features/farms/domain/farm_model.dart';
import 'package:flock_sense/core/exceptions/app_exceptions.dart';
import 'package:flock_sense/core/utils/input_sanitizer.dart';
import 'package:flock_sense/core/services/audit_service.dart';
import 'package:flock_sense/core/services/cache_service.dart';

/// Service for managing farm operations with enhanced error handling, validation, and caching
class FarmService {
  FarmService._();

  static final _firestore = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;
  static final _auditService = AuditService();
  static final _cacheService = CacheService();

  /// Generates a new unique farm ID using Firestore's built-in ID generation.
  static String _generateFarmId() {
    return _firestore.collection('_temp').doc().id;
  }

  /// Creates a farm in the user's subcollection: users/{uid}/farms/{farmId}
  ///
  /// This method:
  /// 1. Validates and sanitizes all inputs
  /// 2. Uses a Firestore transaction to atomically create farm and update user doc
  /// 3. Logs the operation for audit trail
  /// 4. Updates local cache
  ///
  /// Firestore Path: users/{uid}/farms/{farmId}
  /// Required: User must be authenticated
  static Future<FarmModel> createFarm({
    required String farmName,
    required String farmType,
    String flockType = 'Broiler',
    String address = '',
    String? areaName,
    String? district,
    String? state,
    String? country,
    String? farmerName,
    String? phoneNumber,
    String? notes,
    double lengthFt = 0,
    double widthFt = 0,
    double? totalSqFt,
    String sizeUnit = 'ft',
    bool isLocationAuto = true,
    int? capacity,
  }) async {
    debugPrint('[FarmService.createFarm] Starting farm creation');

    final user = _auth.currentUser;
    if (user == null) {
      throw AuthException('You must be signed in before creating a farm.');
    }

    try {
      // Validate inputs
      if (!InputSanitizer.isValidFarmName(farmName)) {
        throw ValidationException(
          'Farm name must be between 2 and 100 characters',
        );
      }
      if (farmType.trim().isEmpty) {
        throw ValidationException('Farm type is required.');
      }

      final farmId = _generateFarmId();
      debugPrint('[FarmService.createFarm] Generated farmId: $farmId');

      final farmRef = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('farms')
          .doc(farmId);
      final userRef = _firestore.collection('users').doc(user.uid);
      final userSnapshot = await userRef.get();
      final isFirstFarm =
          !userSnapshot.exists ||
          (userSnapshot.data()?['hasFarm'] as bool? ?? false) == false;
      final resolvedTotalSqFt = (totalSqFt != null && totalSqFt > 0)
          ? totalSqFt
          : lengthFt * widthFt;

      final batch = _firestore.batch();
      batch.set(farmRef, {
        'id': farmId,
        'userId': user.uid,
        'ownerId': user.uid,
        'farmName': farmName,
        'farmerName': farmerName,
        'farmType': farmType,
        'flockType': flockType,
        'address': address,
        'areaName': areaName,
        'lengthFt': lengthFt,
        'widthFt': widthFt,
        'totalSqFt': resolvedTotalSqFt,
        'sizeUnit': sizeUnit,
        'capacity': capacity,
        'district': district,
        'state': state,
        'country': country,
        'phoneNumber': phoneNumber,
        'notes': notes,
        'isLocationAuto': isLocationAuto,
        'status': 'active',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      batch.set(userRef, {
        'hasFarm': true,
        if (isFirstFarm) 'activeFarmId': farmId,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await batch.commit();

      debugPrint('[FarmService.createFarm] Farm created successfully');

      // Log the operation
      await _auditService.logFarmCreate(
        farmId: farmId,
        farmName: farmName,
        farmType: farmType,
        additionalData: {'flockType': flockType},
      );

      // Cache the farm
      final farm = FarmModel(
        id: farmId,
        userId: user.uid,
        ownerId: user.uid,
        farmName: farmName,
        farmerName: farmerName,
        farmType: farmType,
        flockType: flockType,
        address: address,
        lengthFt: lengthFt,
        widthFt: widthFt,
        totalSqFt: resolvedTotalSqFt,
        areaName: areaName,
        capacity: capacity,
        district: district,
        state: state,
        country: country,
        sizeUnit: sizeUnit,
        phoneNumber: phoneNumber,
        notes: notes,
        isLocationAuto: isLocationAuto,
        status: 'active',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _cacheService.cacheFarm(user.uid, farm);

      return farm;
    } on AppException {
      await _auditService.logOperation(
        operation: AuditOperation.farmCreate,
        resourceType: 'Farm',
        success: false,
        errorMessage: 'Farm creation failed',
      );
      rethrow;
    } catch (e) {
      final mappedException = ExceptionMapper.mapException(e);
      await _auditService.logOperation(
        operation: AuditOperation.farmCreate,
        resourceType: 'Farm',
        success: false,
        errorMessage: mappedException.message,
      );
      throw mappedException;
    }
  }

  /// Updates an existing farm with minimal wizard details.
  static Future<FarmModel> updateFarm({
    required String farmId,
    required String farmName,
    required String farmType,
    String? areaName,
    String? district,
    String? state,
    String? country,
    String address = '',
    required double lengthFt,
    required double widthFt,
    String sizeUnit = 'ft',
    bool isLocationAuto = true,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw AuthException('You must be signed in before updating a farm.');
    }
    if (!InputSanitizer.isValidFarmName(farmName)) {
      throw ValidationException(
        'Farm name must be between 2 and 100 characters',
      );
    }
    if (farmType.trim().isEmpty) {
      throw ValidationException('Farm type is required.');
    }

    final farmRef = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('farms')
        .doc(farmId);

    final totalSqFt = lengthFt * widthFt;

    await farmRef.set({
      'farmName': farmName,
      'farmType': farmType,
      'address': address,
      'areaName': areaName,
      'district': district,
      'state': state,
      'country': country,
      'lengthFt': lengthFt,
      'widthFt': widthFt,
      'totalSqFt': totalSqFt,
      'sizeUnit': sizeUnit,
      'isLocationAuto': isLocationAuto,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    final updated = await getFarmById(farmId);
    if (updated == null) {
      throw NotFoundException('Farm not found with ID: $farmId');
    }
    await _cacheService.cacheFarm(user.uid, updated);
    return updated;
  }

  /// Updates farm status (active/inactive).
  static Future<void> setFarmStatus({
    required String farmId,
    required bool isActive,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw AuthException('You must be signed in before updating farm status.');
    }

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('farms')
        .doc(farmId)
        .set({
          'status': isActive ? 'active' : 'inactive',
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

    final userRef = _firestore.collection('users').doc(user.uid);
    if (!isActive) {
      final userSnap = await userRef.get();
      if (userSnap.data()?['activeFarmId'] == farmId) {
        await userRef.set({'activeFarmId': null}, SetOptions(merge: true));
      }
    }
  }

  /// Retrieves all farms for the current user
  /// Tries cache first, then Firestore, with automatic cache update
  static Future<List<FarmModel>> getUserFarms({
    bool forceRefresh = false,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw AuthException('You must be signed in to retrieve farms.');
    }

    try {
      // Check if we should use cache
      if (!forceRefresh) {
        try {
          final cached = await _cacheService.getCachedFarms(user.uid);
          if (cached.isNotEmpty) {
            debugPrint(
              '[FarmService.getUserFarms] Returning ${cached.length} farms from cache',
            );
            return cached;
          }
        } catch (e) {
          debugPrint(
            '[FarmService.getUserFarms] Cache error, falling back to Firestore: $e',
          );
        }
      }

      // Fetch from Firestore
      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('farms')
          .orderBy('createdAt', descending: true)
          .get();

      final farms = snapshot.docs.map((doc) {
        final data = doc.data();
        return FarmModel.fromJson({...data, 'userId': user.uid});
      }).toList();

      // Update cache
      await _cacheService.cacheFarms(user.uid, farms);
      debugPrint(
        '[FarmService.getUserFarms] Fetched ${farms.length} farms from Firestore',
      );

      return farms;
    } on AppException {
      rethrow;
    } catch (e) {
      throw ExceptionMapper.mapException(e);
    }
  }

  /// Returns the total area across all farms owned by the user.
  static Future<double> getUserFarmArea(String uid) async {
    final farmSnapshot = await _firestore
        .collection('users')
        .doc(uid)
        .collection('farms')
        .get();
    if (farmSnapshot.docs.isEmpty) return 0.0;
    return farmSnapshot.docs.fold<double>(0.0, (acc, farmDoc) {
      final data = farmDoc.data();
      final length = _parseDouble(data['lengthFt'] ?? data['length'] ?? 0.0);
      final width = _parseDouble(data['widthFt'] ?? data['width'] ?? 0.0);
      final total = _parseDouble(data['totalSqFt'] ?? (length * width));
      return acc + total;
    });
  }

  static double _parseDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  /// Real-time farm stream for the signed-in user.
  /// Uses Firestore snapshots so the UI updates immediately.
  static Stream<List<FarmModel>> watchFarms(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('farms')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => FarmModel.fromJson({...doc.data(), 'userId': uid}))
              .toList(),
        );
  }

  /// Real-time farm stream for the currently signed-in user.
  static Stream<List<FarmModel>> watchUserFarms() {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();
    return watchFarms(user.uid);
  }

  /// Retrieves a specific farm by ID
  static Future<FarmModel?> getFarmById(String farmId) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw AuthException('You must be signed in to retrieve a farm.');
    }

    try {
      // Try cache first
      try {
        final cached = await _cacheService.getCachedFarm(user.uid, farmId);
        if (cached != null) {
          debugPrint(
            '[FarmService.getFarmById] Returning farm from cache: $farmId',
          );
          return cached;
        }
      } catch (e) {
        debugPrint(
          '[FarmService.getFarmById] Cache error, falling back to Firestore: $e',
        );
      }

      // Fetch from Firestore
      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('farms')
          .doc(farmId)
          .get();

      if (!snapshot.exists || snapshot.data() == null) {
        throw NotFoundException('Farm not found with ID: $farmId');
      }

      final data = snapshot.data()!;
      final farm = FarmModel.fromJson({...data, 'userId': user.uid});

      // Cache it
      await _cacheService.cacheFarm(user.uid, farm);

      return farm;
    } on AppException {
      rethrow;
    } catch (e) {
      throw ExceptionMapper.mapException(e);
    }
  }

  /// Sets the active farm for the current user
  /// Uses set(merge: true) for robustness
  static Future<void> setActiveFarm(String farmId) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw AuthException('You must be signed in to set an active farm.');
    }

    try {
      debugPrint('[FarmService.setActiveFarm] Setting activeFarmId=$farmId');

      await _firestore.collection('users').doc(user.uid).set({
        'activeFarmId': farmId,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await _auditService.logOperation(
        operation: AuditOperation.farmActivate,
        resourceType: 'Farm',
        resourceId: farmId,
        changes: {'activeFarmId': farmId},
      );

      debugPrint('[FarmService.setActiveFarm] Active farm set successfully');
    } on AppException {
      rethrow;
    } catch (e) {
      throw ExceptionMapper.mapException(e);
    }
  }

  /// Deletes a farm from the user's subcollection
  /// Also clears activeFarmId if this was the active farm
  static Future<void> deleteFarm(String farmId) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw AuthException('You must be signed in to delete a farm.');
    }

    try {
      debugPrint('[FarmService.deleteFarm] Deleting farm $farmId');

      String? farmName;

      final farmRef = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('farms')
          .doc(farmId);
      final userRef = _firestore.collection('users').doc(user.uid);

      final farmSnapshot = await farmRef.get();
      farmName = farmSnapshot.get('farmName') as String?;

      final batch = _firestore.batch();
      final userSnapshot = await userRef.get();
      final activeFarmId = userSnapshot.get('activeFarmId') as String?;

      batch.delete(farmRef);
      if (activeFarmId == farmId) {
        batch.update(userRef, {
          'activeFarmId': null,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        debugPrint(
          '[FarmService.deleteFarm] Cleared activeFarmId since deleted farm was active',
        );
      }
      await batch.commit();

      // Log the deletion
      await _auditService.logFarmDelete(
        farmId: farmId,
        farmName: farmName ?? 'Unknown',
      );

      // Clear cache
      await _cacheService.deleteCachedFarm(user.uid, farmId);

      debugPrint('[FarmService.deleteFarm] Farm deleted successfully');
    } on AppException {
      rethrow;
    } catch (e) {
      throw ExceptionMapper.mapException(e);
    }
  }

  /// Formats farm type for display
  static String getFormattedFarmType(String farmType) {
    const Map<String, String> farmTypes = {'ec': 'EC', 'open': 'Open'};
    return farmTypes[farmType.toLowerCase()] ?? farmType;
  }

  /// Get raw user document for reading activeFarmId etc.
  static Future<Map<String, dynamic>?> getUserDoc(String uid) async {
    try {
      final snap = await _firestore.collection('users').doc(uid).get();
      return snap.data();
    } catch (_) {
      return null;
    }
  }

  /// Clears all local cache
  static Future<void> clearCache() async {
    try {
      await _cacheService.clearAll();
      debugPrint('[FarmService] Cache cleared');
    } catch (e) {
      debugPrint('[FarmService] Failed to clear cache: $e');
    }
  }
}
