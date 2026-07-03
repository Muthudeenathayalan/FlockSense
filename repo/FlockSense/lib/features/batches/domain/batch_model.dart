import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a batch of birds in a farm
/// 
/// Path: users/{uid}/farms/{farmId}/batches/{batchId}
class BatchModel {
  final String id;
  final String farmId;
  final String? shedId;
  final String ownerId;
  final String batchName;
  final DateTime hatchDate;
  final DateTime placementDate;
  final int maleCount;
  final int femaleCount;
  final int totalBirds;
  final int currentBirds;
  final String breedOrFlockType;
  final double? chickAvgWeight;
  final String? hatcheryName;
  final String? supervisorName;
  final String? vehicleNumber;
  final String status;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const BatchModel({
    required this.id,
    required this.farmId,
    this.shedId,
    required this.ownerId,
    required this.batchName,
    required this.hatchDate,
    required this.placementDate,
    required this.maleCount,
    required this.femaleCount,
    required this.totalBirds,
    required this.currentBirds,
    required this.breedOrFlockType,
    required this.createdAt,
    required this.updatedAt,
    this.chickAvgWeight,
    this.hatcheryName,
    this.supervisorName,
    this.vehicleNumber,
    this.status = 'active',
    this.notes,
  });

  factory BatchModel.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic v) {
      if (v is Timestamp) return v.toDate();
      if (v is String) return DateTime.tryParse(v) ?? DateTime.now();
      return DateTime.now();
    }

    int parseInt(dynamic v) {
      if (v is int) return v;
      if (v is double) return v.toInt();
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    }

    double parseDouble(dynamic v) {
      if (v is double) return v;
      if (v is int) return v.toDouble();
      if (v is String) return double.tryParse(v) ?? 0.0;
      return 0.0;
    }

    final maleCount = parseInt(json['maleCount'] ?? json['roosterCount'] ?? json['males']);
    final femaleCount = parseInt(json['femaleCount'] ?? json['henCount'] ?? json['females']);
    final totalBirds = parseInt(json['totalBirds'] ?? maleCount + femaleCount);
    final currentBirds = parseInt(json['currentBirds'] ?? totalBirds);

    return BatchModel(
      id: json['id'] as String? ?? '',
      farmId: json['farmId'] as String? ?? '',
      shedId: json['shedId'] as String?,
      ownerId: json['ownerId'] as String? ?? json['userId'] as String? ?? '',
      batchName: json['batchName'] as String? ?? json['name'] as String? ?? '',
      hatchDate: parseDate(json['hatchDate']),
      placementDate: parseDate(json['placementDate']),
      maleCount: maleCount,
      femaleCount: femaleCount,
      totalBirds: totalBirds,
      currentBirds: currentBirds,
      breedOrFlockType: json['breedOrFlockType'] as String? ?? json['flockType'] as String? ?? '',
      chickAvgWeight: json['chickAvgWeight'] != null ? parseDouble(json['chickAvgWeight']) : null,
      hatcheryName: json['hatcheryName'] as String?,
      supervisorName: json['supervisorName'] as String?,
      vehicleNumber: json['vehicleNumber'] as String?,
      status: json['status'] as String? ?? 'active',
      notes: json['notes'] as String?,
      createdAt: parseDate(json['createdAt']),
      updatedAt: parseDate(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'farmId': farmId,
        'shedId': shedId,
        'ownerId': ownerId,
        'batchName': batchName,
        'hatchDate': hatchDate.toIso8601String(),
        'placementDate': placementDate.toIso8601String(),
        'maleCount': maleCount,
        'femaleCount': femaleCount,
        'totalBirds': totalBirds,
        'currentBirds': currentBirds,
        'breedOrFlockType': breedOrFlockType,
        'chickAvgWeight': chickAvgWeight,
        'hatcheryName': hatcheryName,
        'supervisorName': supervisorName,
        'vehicleNumber': vehicleNumber,
        'status': status,
        'notes': notes,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  BatchModel copyWith({
    String? id,
    String? farmId,
    String? shedId,
    String? ownerId,
    String? batchName,
    DateTime? hatchDate,
    DateTime? placementDate,
    int? maleCount,
    int? femaleCount,
    int? totalBirds,
    int? currentBirds,
    String? breedOrFlockType,
    double? chickAvgWeight,
    String? hatcheryName,
    String? supervisorName,
    String? vehicleNumber,
    String? status,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    final newMale = maleCount ?? this.maleCount;
    final newFemale = femaleCount ?? this.femaleCount;
    final newTotal = totalBirds ?? newMale + newFemale;
    final newCurrent = currentBirds ?? this.currentBirds;
    return BatchModel(
      id: id ?? this.id,
      farmId: farmId ?? this.farmId,
      shedId: shedId ?? this.shedId,
      ownerId: ownerId ?? this.ownerId,
      batchName: batchName ?? this.batchName,
      hatchDate: hatchDate ?? this.hatchDate,
      placementDate: placementDate ?? this.placementDate,
      maleCount: newMale,
      femaleCount: newFemale,
      totalBirds: newTotal,
      currentBirds: newCurrent,
      breedOrFlockType: breedOrFlockType ?? this.breedOrFlockType,
      chickAvgWeight: chickAvgWeight ?? this.chickAvgWeight,
      hatcheryName: hatcheryName ?? this.hatcheryName,
      supervisorName: supervisorName ?? this.supervisorName,
      vehicleNumber: vehicleNumber ?? this.vehicleNumber,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Represents bird allocation to a specific shed within a batch
class ShedAllocation {
  final String shedId;
  final int birdCount;
  final DateTime startDate;
  final DateTime? endDate;

  const ShedAllocation({
    required this.shedId,
    required this.birdCount,
    required this.startDate,
    this.endDate,
  });

  factory ShedAllocation.fromJson(Map<String, dynamic> json) {
    DateTime parseDateValue(dynamic v) {
      if (v is Timestamp) return v.toDate();
      if (v is String) return DateTime.tryParse(v) ?? DateTime.now();
      return DateTime.now();
    }

    int parseIntValue(dynamic v) {
      if (v is int) return v;
      if (v is double) return v.toInt();
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    }

    return ShedAllocation(
      shedId: json['shedId'] as String? ?? '',
      birdCount: parseIntValue(json['birdCount']),
      startDate: parseDateValue(json['startDate']),
      endDate:
          json['endDate'] != null ? parseDateValue(json['endDate']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'shedId': shedId,
        'birdCount': birdCount,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate?.toIso8601String(),
      };

  ShedAllocation copyWith({
    String? shedId,
    int? birdCount,
    DateTime? startDate,
    DateTime? endDate,
  }) =>
      ShedAllocation(
        shedId: shedId ?? this.shedId,
        birdCount: birdCount ?? this.birdCount,
        startDate: startDate ?? this.startDate,
        endDate: endDate ?? this.endDate,
      );
}
