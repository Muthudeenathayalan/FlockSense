import 'package:cloud_firestore/cloud_firestore.dart';

class FarmModel {
  FarmModel({
    required this.id,
    required this.userId,
    required this.farmName,
    required this.farmType,
    required this.flockType,
    required this.address,
    required this.birdCapacity,
    required this.createdAt,
    required this.updatedAt,
    this.district,
    this.state,
    this.lengthFt,
    this.widthFt,
    this.notes,
    this.status = 'active',
  });

  final String id;
  final String userId;
  final String farmName;
  final String farmType; // EC / Open
  final String flockType; // Broiler / Layer / Breeder / Mixed
  final String address;
  final int birdCapacity;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? district;
  final String? state;
  final double? lengthFt;
  final double? widthFt;
  final String? notes;
  final String status;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
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
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory FarmModel.fromJson(Map<String, dynamic> json) {
    return FarmModel(
      id: (json['id'] ?? json['farmId']) as String,
      userId: (json['userId'] ?? json['ownerId']) as String,
      farmName: (json['farmName'] ?? '') as String,
      farmType: (json['farmType'] ?? '') as String,
      flockType: (json['flockType'] ?? '') as String,
      address: (json['address'] ?? json['location'] ?? '') as String,
      birdCapacity: _parseInt(json['birdCapacity'] ?? json['totalCapacity']),
      createdAt: _parseDateTime(json['createdAt']),
      updatedAt: _parseDateTime(json['updatedAt']),
      district: json['district'] as String?,
      state: json['state'] as String?,
      lengthFt: _parseDouble(json['lengthFt'] ?? json['lengthFeet']),
      widthFt: _parseDouble(json['widthFt'] ?? json['widthFeet']),
      notes: json['notes'] as String? ?? json['description'] as String?,
      status: json['status'] as String? ?? 'active',
    );
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value is DateTime) return value;
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.parse(value);
    return DateTime.now();
  }

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static double? _parseDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  FarmModel copyWith({
    String? id,
    String? userId,
    String? farmName,
    String? farmType,
    String? flockType,
    String? address,
    int? birdCapacity,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? district,
    String? state,
    double? lengthFt,
    double? widthFt,
    String? notes,
    String? status,
  }) {
    return FarmModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      farmName: farmName ?? this.farmName,
      farmType: farmType ?? this.farmType,
      flockType: flockType ?? this.flockType,
      address: address ?? this.address,
      birdCapacity: birdCapacity ?? this.birdCapacity,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      district: district ?? this.district,
      state: state ?? this.state,
      lengthFt: lengthFt ?? this.lengthFt,
      widthFt: widthFt ?? this.widthFt,
      notes: notes ?? this.notes,
      status: status ?? this.status,
    );
  }
}
