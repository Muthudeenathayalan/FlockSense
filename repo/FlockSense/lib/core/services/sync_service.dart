import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flock_sense/core/services/cache_service.dart';

/// Operation types the queue can store
enum PendingOpType { farmCreate, farmUpdate, farmDelete, shedCreate, shedUpdate, shedDelete }

/// A single queued write that needs to be sent to Firestore when online.
class PendingOperation {
  final String id;
  final PendingOpType type;
  final String path;          // Firestore document path
  final Map<String, dynamic> data;
  final DateTime queuedAt;
  final int retryCount;

  const PendingOperation({
    required this.id,
    required this.type,
    required this.path,
    required this.data,
    required this.queuedAt,
    this.retryCount = 0,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'path': path,
    'data': data,
    'queuedAt': queuedAt.toIso8601String(),
    'retryCount': retryCount,
  };

  factory PendingOperation.fromJson(Map<String, dynamic> json) {
    return PendingOperation(
      id: json['id'] as String,
      type: PendingOpType.values.firstWhere((e) => e.name == json['type']),
      path: json['path'] as String,
      data: Map<String, dynamic>.from(json['data'] as Map),
      queuedAt: DateTime.parse(json['queuedAt'] as String),
      retryCount: json['retryCount'] as int? ?? 0,
    );
  }

  PendingOperation withRetry() => PendingOperation(
    id: id, type: type, path: path, data: data, queuedAt: queuedAt, retryCount: retryCount + 1,
  );
}

/// Manages offline write queue and syncs it to Firestore when connectivity
/// is restored.
///
/// HOW OFFLINE WORKS END-TO-END
/// ─────────────────────────────
/// 1. Firestore SDK's built-in disk persistence (enabled in main.dart) lets
///    `set()` / `update()` / `delete()` calls succeed immediately even when
///    offline. Those writes are stored in a local SQLite file by the SDK and
///    replayed automatically in the background once the device reconnects.
///    This alone covers the *happy path*: users create/edit farms, sheds,
///    and batches while offline; the changes silently land in Firestore a
///    few seconds after they come back online, with no code in this app
///    needing to do anything.
///
/// 2. Firestore transactions (`runTransaction`), however, *require* a server
///    round-trip and FAIL offline. That is why farm_service.dart's
///    `createFarm` previously used `runTransaction` for the atomic
///    farm-doc + user-doc write: offline users would hit a hard error. The
///    fixed version (Phase 0) replaced the transaction with two sequential
///    `set()` calls (both with `merge: true`), which queue locally and
///    replay automatically.
///
/// 3. This SyncService sits on top of that as a lightweight coordinator:
///    - It holds a queue of operations that carry semantic meaning (e.g.
///      "the user queued a farm update at 14:32") that you can surface in
///      UI as a pending-write badge or sync status banner.
///    - When connectivity is confirmed, it drains the queue by issuing real
///      Firestore writes (which at that point the SDK sends to the server).
///    - It is intentionally thin: it does NOT duplicate the SDK's replay
///      logic; it only tracks the *application-level* queue so the UI can
///      tell the user "3 changes pending sync" rather than showing a spinner
///      indefinitely.
class SyncService {
  SyncService._();
  static final SyncService _instance = SyncService._();
  factory SyncService() => _instance;

  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final _cache = CacheService();

  static const _queueKey = 'pending_ops';
  static const _maxRetries = 3;

  final _pendingCountController = StreamController<int>.broadcast();
  /// Emits the current number of queued-but-unsynced operations.
  Stream<int> get pendingCountStream => _pendingCountController.stream;

  List<PendingOperation> _queue = [];

  /// Call once after CacheService.initialize() in main.dart.
  Future<void> initialize() async {
    await _loadQueue();
    debugPrint('[SyncService] Initialized. Pending ops: ${_queue.length}');
  }

  Future<void> _loadQueue() async {
    try {
      final raw = await _cache.getRawList(_queueKey);
      _queue = raw
          .map((e) => PendingOperation.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      _pendingCountController.add(_queue.length);
    } catch (e) {
      debugPrint('[SyncService] Queue load error (starting empty): $e');
      _queue = [];
    }
  }

  Future<void> _saveQueue() async {
    try {
      await _cache.setRawList(_queueKey, _queue.map((o) => o.toJson()).toList());
      _pendingCountController.add(_queue.length);
    } catch (e) {
      debugPrint('[SyncService] Queue save error: $e');
    }
  }

  /// Add a write to the pending queue (called by FarmService / ShedService
  /// when they detect they're offline).
  Future<void> enqueue(PendingOperation op) async {
    _queue.add(op);
    await _saveQueue();
    debugPrint('[SyncService] Enqueued ${op.type.name}: ${op.path}. Queue size: ${_queue.length}');
  }

  /// Called by connectivityProvider listener in main_shell_screen when
  /// the device comes back online.
  Future<void> syncPendingOperations() async {
    if (_queue.isEmpty) return;
    final user = _auth.currentUser;
    if (user == null) return;

    debugPrint('[SyncService] Starting sync of ${_queue.length} pending operations');

    final failed = <PendingOperation>[];

    for (final op in List<PendingOperation>.from(_queue)) {
      try {
        await _executeOperation(op);
        debugPrint('[SyncService] Synced ${op.type.name}: ${op.path}');
      } catch (e) {
        debugPrint('[SyncService] Failed to sync ${op.type.name}: $e');
        if (op.retryCount < _maxRetries) {
          failed.add(op.withRetry());
        } else {
          debugPrint('[SyncService] Dropping op after $_maxRetries retries: ${op.path}');
        }
      }
    }

    _queue = failed;
    await _saveQueue();
    debugPrint('[SyncService] Sync complete. ${failed.length} ops still pending.');
  }

  Future<void> _executeOperation(PendingOperation op) async {
    final ref = _firestore.doc(op.path);
    switch (op.type) {
      case PendingOpType.farmCreate:
      case PendingOpType.farmUpdate:
      case PendingOpType.shedCreate:
      case PendingOpType.shedUpdate:
        await ref.set(op.data, SetOptions(merge: true));
        break;
      case PendingOpType.farmDelete:
      case PendingOpType.shedDelete:
        await ref.delete();
        break;
    }
  }

  int get pendingCount => _queue.length;
  bool get hasPending => _queue.isNotEmpty;
}
