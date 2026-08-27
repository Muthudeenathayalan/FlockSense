import 'package:cloud_firestore/cloud_firestore.dart';

class InventoryItemModel {
  final String id;
  final String farmId;
  final String ownerId;
  final String itemName;
  final String category; // 'Feed', 'Medicine', 'Vaccines', 'Equipment'
  final String brand;
  final String supplier;
  final double quantityAvailable;
  final String unit; // 'kg', 'Liters', 'Bags', 'Doses', 'Pieces', 'Units'
  final double minStockLevel;
  final DateTime purchaseDate;
  final DateTime? expiryDate;
  final double purchasePrice;
  final double? sellingPrice;
  final String storageLocation;
  final String? batchNumber;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const InventoryItemModel({
    required this.id,
    required this.farmId,
    required this.ownerId,
    required this.itemName,
    required this.category,
    required this.brand,
    required this.supplier,
    required this.quantityAvailable,
    required this.unit,
    required this.minStockLevel,
    required this.purchaseDate,
    this.expiryDate,
    required this.purchasePrice,
    this.sellingPrice,
    required this.storageLocation,
    this.batchNumber,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isLowStock => quantityAvailable <= minStockLevel;

  bool get isExpired {
    if (expiryDate == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final exp = DateTime(expiryDate!.year, expiryDate!.month, expiryDate!.day);
    return exp.isBefore(today);
  }

  bool get isExpiringIn7Days {
    if (expiryDate == null || isExpired) return false;
    final diff = expiryDate!.difference(DateTime.now()).inDays;
    return diff >= 0 && diff <= 7;
  }

  bool get isExpiringIn30Days {
    if (expiryDate == null || isExpired) return false;
    final diff = expiryDate!.difference(DateTime.now()).inDays;
    return diff >= 0 && diff <= 30;
  }

  double get totalValue => quantityAvailable * purchasePrice;

  /// Validates stock quantity (cannot be negative).
  static bool isValidQuantity(double quantity) => quantity >= 0;

  /// Validates price (cannot be negative).
  static bool isValidPrice(double price) => price >= 0;

  /// Calculates new stock balance given movement type ('in' or 'out').
  static double calculateNewBalance({
    required double currentStock,
    required double quantity,
    required String type,
  }) {
    if (type.toLowerCase() == 'in' || type.toLowerCase() == 'addition') {
      return currentStock + quantity;
    } else {
      final balance = currentStock - quantity;
      return balance >= 0 ? balance : 0.0;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'farmId': farmId,
      'ownerId': ownerId,
      'itemName': itemName,
      'category': category,
      'brand': brand,
      'supplier': supplier,
      'quantityAvailable': quantityAvailable,
      'unit': unit,
      'minStockLevel': minStockLevel,
      'purchaseDate': Timestamp.fromDate(purchaseDate),
      'expiryDate': expiryDate != null ? Timestamp.fromDate(expiryDate!) : null,
      'purchasePrice': purchasePrice,
      'sellingPrice': sellingPrice,
      'storageLocation': storageLocation,
      'batchNumber': batchNumber,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory InventoryItemModel.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic v) {
      if (v is Timestamp) return v.toDate();
      if (v is String && v.isNotEmpty) {
        return DateTime.tryParse(v) ?? DateTime.now();
      }
      return DateTime.now();
    }

    return InventoryItemModel(
      id: json['id'] as String? ?? '',
      farmId: json['farmId'] as String? ?? '',
      ownerId: json['ownerId'] as String? ?? '',
      itemName: json['itemName'] as String? ?? 'Unnamed Item',
      category: json['category'] as String? ?? 'Equipment',
      brand: json['brand'] as String? ?? '',
      supplier: json['supplier'] as String? ?? '',
      quantityAvailable: (json['quantityAvailable'] as num?)?.toDouble() ?? 0.0,
      unit: json['unit'] as String? ?? 'Units',
      minStockLevel: (json['minStockLevel'] as num?)?.toDouble() ?? 0.0,
      purchaseDate: parseDate(json['purchaseDate']),
      expiryDate: json['expiryDate'] != null
          ? parseDate(json['expiryDate'])
          : null,
      purchasePrice: (json['purchasePrice'] as num?)?.toDouble() ?? 0.0,
      sellingPrice: (json['sellingPrice'] as num?)?.toDouble(),
      storageLocation: json['storageLocation'] as String? ?? 'Main Store',
      batchNumber: json['batchNumber'] as String?,
      notes: json['notes'] as String?,
      createdAt: parseDate(json['createdAt']),
      updatedAt: parseDate(json['updatedAt']),
    );
  }

  InventoryItemModel copyWith({
    String? id,
    String? farmId,
    String? ownerId,
    String? itemName,
    String? category,
    String? brand,
    String? supplier,
    double? quantityAvailable,
    String? unit,
    double? minStockLevel,
    DateTime? purchaseDate,
    DateTime? expiryDate,
    double? purchasePrice,
    double? sellingPrice,
    String? storageLocation,
    String? batchNumber,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return InventoryItemModel(
      id: id ?? this.id,
      farmId: farmId ?? this.farmId,
      ownerId: ownerId ?? this.ownerId,
      itemName: itemName ?? this.itemName,
      category: category ?? this.category,
      brand: brand ?? this.brand,
      supplier: supplier ?? this.supplier,
      quantityAvailable: quantityAvailable ?? this.quantityAvailable,
      unit: unit ?? this.unit,
      minStockLevel: minStockLevel ?? this.minStockLevel,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      expiryDate: expiryDate ?? this.expiryDate,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      storageLocation: storageLocation ?? this.storageLocation,
      batchNumber: batchNumber ?? this.batchNumber,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
