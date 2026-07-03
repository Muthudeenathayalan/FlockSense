import 'package:cloud_firestore/cloud_firestore.dart';

class ShedModel {
  final String id;
  final String farmId;
  final String ownerId;
  final String name;
  final double lengthFt;
  final double widthFt;
  final double totalSqFt;
  final int? capacity;
  final String? notes;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ShedModel({
    required this.id,
    required this.farmId,
    required this.ownerId,
    required this.name,
    required this.lengthFt,
    required this.widthFt,
    required this.totalSqFt,
    required this.createdAt,
    required this.updatedAt,
    this.capacity,
    this.notes,
    this.status = 'active',
  });

  String get shedName => name;

  int get physicalCapacity => capacity ?? 0;

  double get areaSqFt => totalSqFt;

  factory ShedModel.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic v) {
      if (v is Timestamp) return v.toDate();
      if (v is String) return DateTime.tryParse(v) ?? DateTime.now();
      return DateTime.now();
    }

    double parseDouble(dynamic v) {
      if (v is double) return v;
      if (v is int) return v.toDouble();
      if (v is String) return double.tryParse(v) ?? 0.0;
      return 0.0;
    }

    int? parseCapacity(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      if (v is double) return v.toInt();
      if (v is String) return int.tryParse(v);
      return null;
    }

    final lengthFt = parseDouble(json['lengthFt'] ?? json['length'] ?? json['length_ft']);
    final widthFt = parseDouble(json['widthFt'] ?? json['width'] ?? json['width_ft']);
    final totalSqFt = parseDouble(json['totalSqFt'] ?? json['areaSqFt'] ?? json['areaFt']);

    return ShedModel(
      id: json['id'] as String? ?? '',
      farmId: json['farmId'] as String? ?? '',
      ownerId: json['ownerId'] as String? ?? json['userId'] as String? ?? '',
      name: json['name'] as String? ?? json['shedName'] as String? ?? '',
      lengthFt: lengthFt,
      widthFt: widthFt,
      totalSqFt: totalSqFt > 0 ? totalSqFt : lengthFt * widthFt,
      capacity: parseCapacity(json['capacity'] ?? json['physicalCapacity'] ?? json['birdCapacity']),
      notes: json['notes'] as String?,
      status: json['status'] as String? ?? 'active',
      createdAt: parseDate(json['createdAt']),
      updatedAt: parseDate(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'farmId': farmId,
        'ownerId': ownerId,
        'name': name,
        'shedName': name,
        'lengthFt': lengthFt,
        'widthFt': widthFt,
        'totalSqFt': totalSqFt,
        'capacity': capacity,
        'notes': notes,
        'status': status,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  ShedModel copyWith({
    String? name,
    double? lengthFt,
    double? widthFt,
    int? capacity,
    String? notes,
    String? status,
  }) {
    final newLength = lengthFt ?? this.lengthFt;
    final newWidth = widthFt ?? this.widthFt;
    return ShedModel(
      id: id,
      farmId: farmId,
      ownerId: ownerId,
      name: name ?? this.name,
      lengthFt: newLength,
      widthFt: newWidth,
      totalSqFt: newLength * newWidth,
      capacity: capacity ?? this.capacity,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
