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
    if (user == null) {
      throw AuthException('You must be signed in before creating a farm.');
    }

    try {
      // Sanitize all inputs
      final sanitized = InputSanitizer.sanitizeFarmData(
        farmName: farmName,
        farmType: farmType,
        flockType: flockType,
        address: address,
        birdCapacity: birdCapacity.toString(),
        district: district,
        state: state,
        lengthFt: lengthFt?.toString(),
        widthFt: widthFt?.toString(),
        notes: notes,
      );

      // Validate sanitized data
      if (!InputSanitizer.isValidFarmName(sanitized['farmName'])) {
        throw ValidationException('Farm name must be between 2 and 100 characters');
      }
      if (!InputSanitizer.isValidAddress(sanitized['address'])) {
        throw ValidationException('Address must be between 5 and 200 characters');
      }
      if (!InputSanitizer.isValidBirdCapacity(sanitized['birdCapacity'].toString())) {
        throw ValidationException('Bird capacity must be a positive number');
      }

      final farmId = _generateFarmId();
      debugPrint('[FarmService.createFarm] Generated farmId: $farmId');

      // Use a transaction to atomically create farm AND update user doc
      await _firestore.runTransaction((transaction) async {
        final farmRef = _firestore.collection('users').doc(user.uid).collection('farms').doc(farmId);
        final userRef = _firestore.collection('users').doc(user.uid);

        // Get the current user document to check if this is the first farm
        final userSnapshot = await transaction.get(userRef);
        final isFirstFarm = !userSnapshot.exists || 
            (userSnapshot.data()?['hasFarm'] as bool? ?? false) == false;

        // Set farm document
        transaction.set(farmRef, {
          'id': farmId,
          'userId': user.uid,
          'farmName': sanitized['farmName'],
          'farmType': sanitized['farmType'],
          'flockType': sanitized['flockType'],
          'address': sanitized['address'],
          'district': sanitized['district'],
          'state': sanitized['state'],
          'birdCapacity': sanitized['birdCapacity'],
          'lengthFt': sanitized['lengthFt'],
          'widthFt': sanitized['widthFt'],
          'notes': sanitized['notes'],
          'status': 'active',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // Update user document with farm flags
        transaction.set(
          userRef,
          {
            'hasFarm': true,
            if (isFirstFarm) 'activeFarmId': farmId,
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      });

      debugPrint('[FarmService.createFarm] Farm created successfully');

      // Log the operation
      await _auditService.logFarmCreate(
        farmId: farmId,
        farmName: sanitized['farmName'],
        farmType: sanitized['farmType'],
        additionalData: {
          'flockType': sanitized['flockType'],
          'birdCapacity': sanitized['birdCapacity'],
        },
      );

      // Cache the farm
      final farm = FarmModel(
        id: farmId,
        userId: user.uid,
        farmName: sanitized['farmName'],
        farmType: sanitized['farmType'],
        flockType: sanitized['flockType'],
        address: sanitized['address'],
        birdCapacity: sanitized['birdCapacity'],
        district: sanitized['district'] as String?,
        state: sanitized['state'] as String?,
        lengthFt: sanitized['lengthFt'] as double?,
        widthFt: sanitized['widthFt'] as double?,
        notes: sanitized['notes'] as String?,
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

  /// Retrieves all farms for the current user
  /// Tries cache first, then Firestore, with automatic cache update
  static Future<List<FarmModel>> getUserFarms({bool forceRefresh = false}) async {
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
            debugPrint('[FarmService.getUserFarms] Returning ${cached.length} farms from cache');
            return cached;
          }
        } catch (e) {
          debugPrint('[FarmService.getUserFarms] Cache error, falling back to Firestore: $e');
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
        return FarmModel.fromJson({
          ...data,
          'userId': user.uid,
        });
      }).toList();

      // Update cache
      await _cacheService.cacheFarms(user.uid, farms);
      debugPrint('[FarmService.getUserFarms] Fetched ${farms.length} farms from Firestore');

      return farms;
    } on AppException {
      rethrow;
    } catch (e) {
      throw ExceptionMapper.mapException(e);
    }
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
          debugPrint('[FarmService.getFarmById] Returning farm from cache: $farmId');
          return cached;
        }
      } catch (e) {
        debugPrint('[FarmService.getFarmById] Cache error, falling back to Firestore: $e');
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
      final farm = FarmModel.fromJson({
        ...data,
        'userId': user.uid,
      });

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

      // Use a transaction to atomically delete farm and update user doc if needed
      await _firestore.runTransaction((transaction) async {
        final farmRef = _firestore.collection('users').doc(user.uid).collection('farms').doc(farmId);
        final userRef = _firestore.collection('users').doc(user.uid);

        // Get farm to log the deletion
        final farmSnapshot = await transaction.get(farmRef);
        farmName = farmSnapshot.get('farmName') as String?;

        // Get user to check if deleted farm is the active one
        final userSnapshot = await transaction.get(userRef);
        final activeFarmId = userSnapshot.get('activeFarmId') as String?;

        // Delete the farm
        transaction.delete(farmRef);

        // If this was the active farm, clear the reference
        if (activeFarmId == farmId) {
          transaction.update(userRef, {
            'activeFarmId': null,
            'updatedAt': FieldValue.serverTimestamp(),
          });
          debugPrint('[FarmService.deleteFarm] Cleared activeFarmId since deleted farm was active');
        }
      });

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
    const Map<String, String> farmTypes = {
      'broiler': 'Broiler',
      'layer': 'Layer',
      'breeder': 'Breeder',
      'mixed': 'Mixed',
    };
    return farmTypes[farmType.toLowerCase()] ?? farmType;
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
