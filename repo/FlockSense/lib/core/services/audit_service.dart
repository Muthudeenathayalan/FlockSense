/// Audit logging service for FlockSense
///
/// Tracks all important operations for compliance and debugging

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Enum for audit operation types
enum AuditOperation {
  farmCreate,
  farmUpdate,
  farmDelete,
  flockCreate,
  flockUpdate,
  flockDelete,
  farmActivate,
  userLogin,
  userLogout,
  userRegister,
  dataSync,
  dataExport,
  settingsChange,
  permissionChange,
}

/// Audit log entry
class AuditLog {
  final String id;
  final String userId;
  final AuditOperation operation;
  final String operationName;
  final String resourceType;
  final String? resourceId;
  final Map<String, dynamic>? changes;
  final bool success;
  final String? errorMessage;
  final DateTime timestamp;
  final String? ipAddress;
  final String? deviceInfo;

  AuditLog({
    required this.id,
    required this.userId,
    required this.operation,
    required this.operationName,
    required this.resourceType,
    this.resourceId,
    this.changes,
    this.success = true,
    this.errorMessage,
    required this.timestamp,
    this.ipAddress,
    this.deviceInfo,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'operation': operationName,
    'resourceType': resourceType,
    'resourceId': resourceId,
    'changes': changes,
    'success': success,
    'errorMessage': errorMessage,
    'timestamp': Timestamp.fromDate(timestamp),
    'ipAddress': ipAddress,
    'deviceInfo': deviceInfo,
  };
}

/// Service for audit logging
class AuditService {
  static final AuditService _instance = AuditService._internal();
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  AuditService._internal();

  factory AuditService() {
    return _instance;
  }

  /// Log an operation
  Future<void> logOperation({
    required AuditOperation operation,
    required String resourceType,
    String? resourceId,
    Map<String, dynamic>? changes,
    bool success = true,
    String? errorMessage,
  }) async {
    try {
      final userId = _auth.currentUser?.uid ?? 'anonymous';
      final auditLog = AuditLog(
        id: _firestore.collection('audit_logs').doc().id,
        userId: userId,
        operation: operation,
        operationName: _getOperationName(operation),
        resourceType: resourceType,
        resourceId: resourceId,
        changes: changes,
        success: success,
        errorMessage: errorMessage,
        timestamp: DateTime.now(),
      );

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('audit_logs')
          .doc(auditLog.id)
          .set(auditLog.toJson());

      debugPrint(
        '[AuditService] Logged: ${auditLog.operationName} on $resourceType${resourceId != null ? '($resourceId)' : ''} - Success: $success',
      );
    } catch (e) {
      debugPrint('[AuditService] Failed to log operation: $e');
      // Don't throw - audit logging shouldn't crash the app
    }
  }

  /// Log farm creation
  Future<void> logFarmCreate({
    required String farmId,
    required String farmName,
    required String farmType,
    Map<String, dynamic>? additionalData,
  }) async {
    await logOperation(
      operation: AuditOperation.farmCreate,
      resourceType: 'Farm',
      resourceId: farmId,
      changes: {'farmName': farmName, 'farmType': farmType, ...?additionalData},
    );
  }

  /// Log farm update
  Future<void> logFarmUpdate({
    required String farmId,
    required Map<String, dynamic> changes,
  }) async {
    await logOperation(
      operation: AuditOperation.farmUpdate,
      resourceType: 'Farm',
      resourceId: farmId,
      changes: changes,
    );
  }

  /// Log farm deletion
  Future<void> logFarmDelete({
    required String farmId,
    required String farmName,
  }) async {
    await logOperation(
      operation: AuditOperation.farmDelete,
      resourceType: 'Farm',
      resourceId: farmId,
      changes: {'farmName': farmName},
    );
  }

  /// Log flock creation
  Future<void> logFlockCreate({
    required String flockId,
    required String farmId,
    required String flockName,
    required String birdType,
  }) async {
    await logOperation(
      operation: AuditOperation.flockCreate,
      resourceType: 'Flock',
      resourceId: flockId,
      changes: {'farmId': farmId, 'flockName': flockName, 'birdType': birdType},
    );
  }

  /// Log data sync
  Future<void> logDataSync({
    required int recordsSynced,
    required bool success,
    String? errorMessage,
  }) async {
    await logOperation(
      operation: AuditOperation.dataSync,
      resourceType: 'Database',
      changes: {'recordsSynced': recordsSynced},
      success: success,
      errorMessage: errorMessage,
    );
  }

  /// Get operation name from enum
  static String _getOperationName(AuditOperation operation) {
    switch (operation) {
      case AuditOperation.farmCreate:
        return 'Farm Created';
      case AuditOperation.farmUpdate:
        return 'Farm Updated';
      case AuditOperation.farmDelete:
        return 'Farm Deleted';
      case AuditOperation.flockCreate:
        return 'Flock Created';
      case AuditOperation.flockUpdate:
        return 'Flock Updated';
      case AuditOperation.flockDelete:
        return 'Flock Deleted';
      case AuditOperation.farmActivate:
        return 'Farm Activated';
      case AuditOperation.userLogin:
        return 'User Login';
      case AuditOperation.userLogout:
        return 'User Logout';
      case AuditOperation.userRegister:
        return 'User Registered';
      case AuditOperation.dataSync:
        return 'Data Sync';
      case AuditOperation.dataExport:
        return 'Data Export';
      case AuditOperation.settingsChange:
        return 'Settings Changed';
      case AuditOperation.permissionChange:
        return 'Permission Changed';
    }
  }

  /// Get audit logs for current user
  Future<List<AuditLog>> getUserAuditLogs({
    int limit = 100,
    DateTime? startDate,
  }) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return [];

      var query = _firestore
          .collection('users')
          .doc(userId)
          .collection('audit_logs')
          .orderBy('timestamp', descending: true)
          .limit(limit);

      if (startDate != null) {
        query = query.where(
          'timestamp',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
        );
      }

      final snapshot = await query.get();
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return AuditLog(
          id: doc.id,
          userId: data['userId'] as String,
          operation: AuditOperation.dataSync, // Placeholder
          operationName: data['operation'] as String,
          resourceType: data['resourceType'] as String,
          resourceId: data['resourceId'] as String?,
          changes: data['changes'] as Map<String, dynamic>?,
          success: data['success'] as bool? ?? true,
          errorMessage: data['errorMessage'] as String?,
          timestamp: (data['timestamp'] as Timestamp).toDate(),
        );
      }).toList();
    } catch (e) {
      debugPrint('[AuditService] Failed to get audit logs: $e');
      return [];
    }
  }
}
