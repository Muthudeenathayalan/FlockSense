import 'package:cloud_firestore/cloud_firestore.dart';

class Flock {
  final String id;
  final String name;
  final String birdType;
  final String breed;
  final DateTime placementDate;
  final int openingCount;
  final double? targetFcr;
  final int? expectedHarvestDay;
  final DateTime createdAt;

  Flock({
    required this.id,
    required this.name,
    required this.birdType,
    required this.breed,
    required this.placementDate,
    required this.openingCount,
    this.targetFcr,
    this.expectedHarvestDay,
    required this.createdAt,
  });

  factory Flock.fromMap(Map<String, dynamic> data, String id) {
    return Flock(
      id: id,
      name: data['name']?.toString() ?? '',
      birdType: data['birdType']?.toString() ?? '',
      breed: data['breed']?.toString() ?? '',
      placementDate: (data['placementDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      openingCount: (data['openingCount'] as int?) ?? 0,
      targetFcr: (data['targetFcr'] as num?)?.toDouble(),
      expectedHarvestDay: (data['expectedHarvestDay'] as int?),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  factory Flock.fromDocument(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    return Flock.fromMap(snapshot.data() ?? <String, dynamic>{}, snapshot.id);
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'birdType': birdType,
      'breed': breed,
      'placementDate': Timestamp.fromDate(placementDate),
      'openingCount': openingCount,
      'targetFcr': targetFcr,
      'expectedHarvestDay': expectedHarvestDay,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
