/// Local cache service using Hive for offline persistence
///
/// Provides local caching for farms, flocks, and other data to enable offline functionality

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flock_sense/features/farms/domain/farm_model.dart';
import 'package:flock_sense/core/exceptions/app_exceptions.dart';

const String _farmsBoxKey = 'farms_cache';
const String _syncStatusBoxKey = 'sync_status';
const String _lastSyncKey = 'last_sync_timestamp';
// Reserved for future pending operations queue
// const String _pendingOperationsKey = 'pending_operations';

/// Local cache service for offline-first architecture
class CacheService {
  static final CacheService _instance = CacheService._internal();
  late Box<Map> _farmsBox;
  late Box<dynamic> _syncBox;
  bool _initialized = false;

  CacheService._internal();

  factory CacheService() {
    return _instance;
  }

  /// Initialize Hive and open boxes
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      await Hive.initFlutter();
      _farmsBox = await Hive.openBox<Map>(_farmsBoxKey);
      _syncBox = await Hive.openBox(_syncStatusBoxKey);
      _initialized = true;
      debugPrint('[CacheService] Initialized successfully');
    } catch (e) {
      debugPrint('[CacheService] Initialization error: $e');
      throw CacheException(
        'Failed to initialize cache service',
        originalException: e is Exception ? e : null,
      );
    }
  }

  /// Check if service is initialized
  bool get isInitialized => _initialized;

  // ========== FARM CACHING ==========

  /// Cache farms for a specific user
  Future<void> cacheFarms(String userId, List<FarmModel> farms) async {
    try {
      final key = 'farms_$userId';
      final farmsData = farms.map((f) => f.toJson()).toList();
      await _farmsBox.put(key, {
        'farms': farmsData,
        'cachedAt': DateTime.now().toIso8601String(),
      });
      await _updateSyncStatus(
        userId,
        _lastSyncKey,
        DateTime.now().toIso8601String(),
      );
      debugPrint(
        '[CacheService] Cached ${farms.length} farms for user $userId',
      );
    } catch (e) {
      debugPrint('[CacheService] Failed to cache farms: $e');
      throw CacheException(
        'Failed to cache farms',
        originalException: e is Exception ? e : null,
      );
    }
  }

  /// Get cached farms for a user
  Future<List<FarmModel>> getCachedFarms(String userId) async {
    try {
      final key = 'farms_$userId';
      final cached = _farmsBox.get(key);

      if (cached == null) {
        debugPrint('[CacheService] No cached farms found for user $userId');
        return [];
      }

      final farmsList = (cached['farms'] as List? ?? [])
          .cast<Map<String, dynamic>>();
      final farms = farmsList.map((f) => FarmModel.fromJson(f)).toList();
      debugPrint(
        '[CacheService] Retrieved ${farms.length} cached farms for user $userId',
      );
      return farms;
    } catch (e) {
      debugPrint('[CacheService] Failed to get cached farms: $e');
      throw CacheException(
        'Failed to retrieve cached farms',
        originalException: e is Exception ? e : null,
      );
    }
  }

  /// Cache a single farm
  Future<void> cacheFarm(String userId, FarmModel farm) async {
    try {
      final key = 'farm_${userId}_${farm.id}';
      await _farmsBox.put(key, farm.toJson());
      debugPrint('[CacheService] Cached farm ${farm.id} for user $userId');
    } catch (e) {
      debugPrint('[CacheService] Failed to cache farm: $e');
      throw CacheException(
        'Failed to cache farm',
        originalException: e is Exception ? e : null,
      );
    }
  }

  /// Get cached farm by ID
  Future<FarmModel?> getCachedFarm(String userId, String farmId) async {
    try {
      final key = 'farm_${userId}_$farmId';
      final cached = _farmsBox.get(key);

      if (cached == null) {
        debugPrint('[CacheService] No cached farm found: $farmId');
        return null;
      }

      final farm = FarmModel.fromJson(cached.cast<String, dynamic>());
      debugPrint('[CacheService] Retrieved cached farm: $farmId');
      return farm;
    } catch (e) {
      debugPrint('[CacheService] Failed to get cached farm: $e');
      throw CacheException(
        'Failed to retrieve cached farm',
        originalException: e is Exception ? e : null,
      );
    }
  }

  /// Delete cached farm
  Future<void> deleteCachedFarm(String userId, String farmId) async {
    try {
      final key = 'farm_${userId}_$farmId';
      await _farmsBox.delete(key);
      debugPrint('[CacheService] Deleted cached farm: $farmId');
    } catch (e) {
      debugPrint('[CacheService] Failed to delete cached farm: $e');
      throw CacheException(
        'Failed to delete cached farm',
        originalException: e is Exception ? e : null,
      );
    }
  }

  /// Clear all cached farms for a user
  Future<void> clearFarmCache(String userId) async {
    try {
      final key = 'farms_$userId';
      await _farmsBox.delete(key);
      debugPrint('[CacheService] Cleared farm cache for user $userId');
    } catch (e) {
      debugPrint('[CacheService] Failed to clear farm cache: $e');
      throw CacheException(
        'Failed to clear farm cache',
        originalException: e is Exception ? e : null,
      );
    }
  }

  // ========== PENDING OPERATIONS ==========

  /// Add a pending operation (for offline mode)
  Future<void> addPendingOperation({
    required String userId,
    required String operationType, // 'create', 'update', 'delete'
    required String resourceType, // 'farm', 'flock', etc.
    required String resourceId,
    required Map<String, dynamic> data,
  }) async {
    try {
      final key = 'pending_${userId}_$operationType';
      final operations = _syncBox.get(key, defaultValue: []) as List? ?? [];

      operations.add({
        'operationType': operationType,
        'resourceType': resourceType,
        'resourceId': resourceId,
        'data': data,
        'timestamp': DateTime.now().toIso8601String(),
      });

      await _syncBox.put(key, operations);
      debugPrint(
        '[CacheService] Added pending operation: $operationType $resourceType',
      );
    } catch (e) {
      debugPrint('[CacheService] Failed to add pending operation: $e');
      throw CacheException(
        'Failed to add pending operation',
        originalException: e is Exception ? e : null,
      );
    }
  }

  /// Get pending operations
  Future<List<Map<String, dynamic>>> getPendingOperations(String userId) async {
    try {
      final operations = <Map<String, dynamic>>[];

      // Get operations for different types
      for (final opType in ['create', 'update', 'delete']) {
        final key = 'pending_${userId}_$opType';
        final ops = _syncBox.get(key, defaultValue: []) as List? ?? [];
        operations.addAll(ops.cast<Map<String, dynamic>>());
      }

      debugPrint(
        '[CacheService] Retrieved ${operations.length} pending operations for user $userId',
      );
      return operations;
    } catch (e) {
      debugPrint('[CacheService] Failed to get pending operations: $e');
      throw CacheException(
        'Failed to get pending operations',
        originalException: e is Exception ? e : null,
      );
    }
  }

  /// Clear pending operations after successful sync
  Future<void> clearPendingOperations(String userId) async {
    try {
      for (final opType in ['create', 'update', 'delete']) {
        final key = 'pending_${userId}_$opType';
        await _syncBox.delete(key);
      }
      debugPrint('[CacheService] Cleared pending operations for user $userId');
    } catch (e) {
      debugPrint('[CacheService] Failed to clear pending operations: $e');
      throw CacheException(
        'Failed to clear pending operations',
        originalException: e is Exception ? e : null,
      );
    }
  }

  // ========== SYNC STATUS ==========

  /// Update sync status
  Future<void> _updateSyncStatus(
    String userId,
    String key,
    dynamic value,
  ) async {
    try {
      await _syncBox.put(key, value);
    } catch (e) {
      debugPrint('[CacheService] Failed to update sync status: $e');
    }
  }

  /// Get last sync time for user
  Future<DateTime?> getLastSyncTime(String userId) async {
    try {
      final key = 'last_sync_${userId}';
      final value = _syncBox.get(key);

      if (value == null) return null;

      return DateTime.parse(value as String);
    } catch (e) {
      debugPrint('[CacheService] Failed to get last sync time: $e');
      return null;
    }
  }

  /// Set last sync time
  Future<void> setLastSyncTime(String userId) async {
    try {
      final key = 'last_sync_${userId}';
      await _syncBox.put(key, DateTime.now().toIso8601String());
    } catch (e) {
      debugPrint('[CacheService] Failed to set last sync time: $e');
    }
  }

  /// Check if data needs sync
  Future<bool> shouldSync(
    String userId, {
    Duration syncInterval = const Duration(minutes: 5),
  }) async {
    try {
      final lastSync = await getLastSyncTime(userId);

      if (lastSync == null) {
        return true; // Never synced
      }

      final timeSinceSync = DateTime.now().difference(lastSync);
      return timeSinceSync > syncInterval;
    } catch (e) {
      debugPrint('[CacheService] Failed to check sync status: $e');
      return true; // Default to sync on error
    }
  }

  // ========== OFFLINE STATUS ==========

  /// Set offline mode status
  Future<void> setOfflineMode(bool isOffline) async {
    try {
      await _syncBox.put('offline_mode', isOffline);
      debugPrint('[CacheService] Set offline mode: $isOffline');
    } catch (e) {
      debugPrint('[CacheService] Failed to set offline mode: $e');
    }
  }

  /// Get offline mode status
  bool getOfflineMode() {
    try {
      return _syncBox.get('offline_mode', defaultValue: false) as bool;
    } catch (_) {
      return false;
    }
  }

  // ========== UTILITY METHODS ==========

  /// Clear all cache (careful!)
  Future<void> clearAll() async {
    try {
      await _farmsBox.clear();
      await _syncBox.clear();
      debugPrint('[CacheService] Cleared all cache');
    } catch (e) {
      debugPrint('[CacheService] Failed to clear all cache: $e');
      throw CacheException(
        'Failed to clear cache',
        originalException: e is Exception ? e : null,
      );
    }
  }

  /// Get cache size info
  Map<String, dynamic> getCacheInfo() {
    return {
      'farmsBoxSize': _farmsBox.length,
      'syncBoxSize': _syncBox.length,
      'totalEntries': _farmsBox.length + _syncBox.length,
      'isInitialized': _initialized,
    };
  }

  /// Dispose resources
  Future<void> dispose() async {
    try {
      await _farmsBox.close();
      await _syncBox.close();
      _initialized = false;
      debugPrint('[CacheService] Disposed');
    } catch (e) {
      debugPrint('[CacheService] Failed to dispose: $e');
    }
  }

  // ========== RAW KEY-VALUE STORAGE (used by SyncService) ==========

  /// Store any list under a plain key in the sync box.
  Future<void> setRawList(String key, List<dynamic> value) async {
    try {
      await _syncBox.put(key, value);
    } catch (e) {
      debugPrint('[CacheService] setRawList error for key $key: $e');
    }
  }

  /// Retrieve a list stored with [setRawList]. Returns [] if not found.
  Future<List<dynamic>> getRawList(String key) async {
    try {
      final val = _syncBox.get(key);
      if (val == null) return [];
      return (val as List).toList();
    } catch (e) {
      debugPrint('[CacheService] getRawList error for key $key: $e');
      return [];
    }
  }
}
