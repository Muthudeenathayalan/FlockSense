import 'package:cloud_firestore/cloud_firestore.dart';

class StockMovementModel {
  final String id;
  final String inventoryItemId;
  final String farmId;
  final String ownerId;
  final String action; // 'increase', 'reduce', 'transfer'
  final double quantity;
  final String reason; // 'purchase', 'feedUsed', 'medicineUsed', 'vaccination', 'damaged', 'expired', 'transfer', 'adjustment', 'other'
  final DateTime date;
  final String? supplier;
  final String? invoiceNumber;
  final String? targetLocation;
  final String? userName;
  final String? notes;
  final DateTime createdAt;

  const StockMovementModel({
    required this.id,
    required this.inventoryItemId,
    required this.farmId,
    required this.ownerId,
    required this.action,
    required this.quantity,
    required this.reason,
    required this.date,
    this.supplier,
    this.invoiceNumber,
    this.targetLocation,
    this.userName,
    this.notes,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'inventoryItemId': inventoryItemId,
      'farmId': farmId,
      'ownerId': ownerId,
      'action': action,
      'quantity': quantity,
      'reason': reason,
      'date': Timestamp.fromDate(date),
      'supplier': supplier,
      'invoiceNumber': invoiceNumber,
      'targetLocation': targetLocation,
      'userName': userName,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory StockMovementModel.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic v) {
      if (v is Timestamp) return v.toDate();
      if (v is String && v.isNotEmpty) {
        return DateTime.tryParse(v) ?? DateTime.now();
      }
      return DateTime.now();
    }

    return StockMovementModel(
      id: json['id'] as String? ?? '',
      inventoryItemId: json['inventoryItemId'] as String? ?? '',
      farmId: json['farmId'] as String? ?? '',
      ownerId: json['ownerId'] as String? ?? '',
      action: json['action'] as String? ?? 'increase',
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0.0,
      reason: json['reason'] as String? ?? 'other',
      date: parseDate(json['date']),
      supplier: json['supplier'] as String?,
      invoiceNumber: json['invoiceNumber'] as String?,
      targetLocation: json['targetLocation'] as String?,
      userName: json['userName'] as String?,
      notes: json['notes'] as String?,
      createdAt: parseDate(json['createdAt']),
    );
  }
}
