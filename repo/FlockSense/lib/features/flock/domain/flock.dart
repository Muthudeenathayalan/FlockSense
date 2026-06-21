import 'package:cloud_firestore/cloud_firestore.dart';

class Flock {
  final String id;
  final String userId;
  final String farmId; // ✅ NEW: Flock now belongs to a specific farm
  final String name;
  final String birdType;
  final String breed;
  final DateTime placementDate;
  final int openingCount;
  final double? targetFcr;
  final int? expectedHarvestDay;
  final DateTime createdAt;
  final String status; // 'active', 'completed', 'archived'

  Flock({
    required this.id,
    required this.userId,
    required this.farmId,
    required this.name,
    required this.birdType,
    required this.breed,
    required this.placementDate,
    required this.openingCount,
    this.targetFcr,
    this.expectedHarvestDay,
    required this.createdAt,
    this.status = 'active',
  });

  factory Flock.fromMap(Map<String, dynamic> data, String id) {
    return Flock(
      id: id,
      userId: data['userId']?.toString() ?? '',
      farmId: data['farmId']?.toString() ?? '',
      name: data['name']?.toString() ?? '',
      birdType: data['birdType']?.toString() ?? '',
      breed: data['breed']?.toString() ?? '',
      placementDate: (data['placementDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      openingCount: (data['openingCount'] as int?) ?? 0,
      targetFcr: (data['targetFcr'] as num?)?.toDouble(),
      expectedHarvestDay: (data['expectedHarvestDay'] as int?),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: data['status']?.toString() ?? 'active',
    );
  }

  factory Flock.fromDocument(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    return Flock.fromMap(snapshot.data() ?? <String, dynamic>{}, snapshot.id);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'farmId': farmId,
      'name': name,
      'birdType': birdType,
      'breed': breed,
      'placementDate': Timestamp.fromDate(placementDate),
      'openingCount': openingCount,
      'targetFcr': targetFcr,
      'expectedHarvestDay': expectedHarvestDay,
      'createdAt': Timestamp.fromDate(createdAt),
      'status': status,
    };
  }

  Flock copyWith({
    String? id,
    String? userId,
    String? farmId,
    String? name,
    String? birdType,
    String? breed,
    DateTime? placementDate,
    int? openingCount,
    double? targetFcr,
    int? expectedHarvestDay,
    DateTime? createdAt,
    String? status,
  }) {
    return Flock(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      farmId: farmId ?? this.farmId,
      name: name ?? this.name,
      birdType: birdType ?? this.birdType,
      breed: breed ?? this.breed,
      placementDate: placementDate ?? this.placementDate,
      openingCount: openingCount ?? this.openingCount,
      targetFcr: targetFcr ?? this.targetFcr,
      expectedHarvestDay: expectedHarvestDay ?? this.expectedHarvestDay,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
    );
  }
}
