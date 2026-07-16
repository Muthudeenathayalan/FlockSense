import 'package:cloud_firestore/cloud_firestore.dart';

class FarmModel {
  final String id;
  final String userId;
  final String? ownerId;
  final String farmName;
  final String? farmerName;
  final String farmType; // 'EC' | 'Open'
  final String flockType; // Legacy field, optional in new minimal wizard.
  final String address;
  final String? areaName;
  final double lengthFt;
  final double widthFt;
  final double totalSqFt;
  final String sizeUnit;
  final int? capacity;
  final String? district;
  final String? state;
  final String? country;
  final String? phoneNumber;
  final String? notes;
  final bool isLocationAuto;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  const FarmModel({
    required this.id,
    required this.userId,
    required this.farmName,
    required this.farmType,
    required this.flockType,
    required this.address,
    required this.lengthFt,
    required this.widthFt,
    required this.totalSqFt,
    required this.createdAt,
    required this.updatedAt,
    this.sizeUnit = 'ft',
    this.ownerId,
    this.farmerName,
    this.areaName,
    this.capacity,
    this.district,
    this.state,
    this.country,
    this.phoneNumber,
    this.notes,
    this.isLocationAuto = true,
    this.status = 'active',
  });

  String? get ownerName => farmerName;
  String? get phone => phoneNumber;
  String? get location => areaName;
  double get farmArea => totalSqFt;
  bool get isActive => status == 'active';

  factory FarmModel.fromJson(Map<String, dynamic> json) {
    DateTime _parseDate(dynamic v) {
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

    int parseInt(dynamic v) {
      if (v is int) return v;
      if (v is double) return v.toInt();
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    }

    final lengthFt = parseDouble(json['lengthFt'] ?? json['length'] ?? 0.0);
    final widthFt = parseDouble(json['widthFt'] ?? json['width'] ?? 0.0);
    final totalSqFt = parseDouble(
      json['totalSqFt'] ??
          (lengthFt > 0 && widthFt > 0 ? lengthFt * widthFt : 0.0),
    );

    return FarmModel(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      ownerId: json['ownerId'] as String? ?? json['userId'] as String?,
      farmName: json['farmName'] as String? ?? '',
      farmerName: json['farmerName'] as String? ?? json['ownerName'] as String?,
      farmType: json['farmType'] as String? ?? '',
      flockType: json['flockType'] as String? ?? 'Broiler',
      address: json['address'] as String? ?? '',
      lengthFt: lengthFt,
      widthFt: widthFt,
      totalSqFt: totalSqFt,
      sizeUnit: json['sizeUnit'] as String? ?? 'ft',
      areaName: json['areaName'] as String? ?? json['location'] as String?,
      capacity: parseInt(
        json['capacity'] ??
            json['birdCapacity'] ??
            json['physicalCapacity'] ??
            0,
      ),
      district: json['district'] as String?,
      state: json['state'] as String?,
      country: json['country'] as String?,
      phoneNumber: json['phoneNumber'] as String? ?? json['phone'] as String?,
      notes: json['notes'] as String?,
      isLocationAuto: json['isLocationAuto'] as bool? ?? true,
      status: json['status'] as String? ?? 'active',
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'ownerId': ownerId,
    'farmName': farmName,
    'farmerName': farmerName,
    'farmType': farmType,
    'flockType': flockType,
    'address': address,
    'areaName': areaName,
    'lengthFt': lengthFt,
    'widthFt': widthFt,
    'totalSqFt': totalSqFt,
    'sizeUnit': sizeUnit,
    'capacity': capacity,
    'district': district,
    'state': state,
    'country': country,
    'phoneNumber': phoneNumber,
    'notes': notes,
    'isLocationAuto': isLocationAuto,
    'status': status,
    'ownerName': farmerName,
    'phone': phoneNumber,
    'location': areaName,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  FarmModel copyWith({
    String? id,
    String? userId,
    String? ownerId,
    String? farmName,
    String? farmerName,
    String? farmType,
    String? flockType,
    String? address,
    double? lengthFt,
    double? widthFt,
    double? totalSqFt,
    String? sizeUnit,
    int? capacity,
    String? areaName,
    String? district,
    String? state,
    String? country,
    String? phoneNumber,
    String? notes,
    bool? isLocationAuto,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => FarmModel(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    ownerId: ownerId ?? this.ownerId,
    farmName: farmName ?? this.farmName,
    farmerName: farmerName ?? this.farmerName,
    farmType: farmType ?? this.farmType,
    flockType: flockType ?? this.flockType,
    address: address ?? this.address,
    lengthFt: lengthFt ?? this.lengthFt,
    widthFt: widthFt ?? this.widthFt,
    totalSqFt: totalSqFt ?? this.totalSqFt,
    sizeUnit: sizeUnit ?? this.sizeUnit,
    capacity: capacity ?? this.capacity,
    areaName: areaName ?? this.areaName,
    district: district ?? this.district,
    state: state ?? this.state,
    country: country ?? this.country,
    phoneNumber: phoneNumber ?? this.phoneNumber,
    notes: notes ?? this.notes,
    isLocationAuto: isLocationAuto ?? this.isLocationAuto,
    status: status ?? this.status,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}
