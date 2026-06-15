class FarmModel {
  FarmModel({
    required this.farmId,
    required this.ownerId,
    required this.farmName,
    required this.location,
    required this.farmType,
    required this.totalCapacity,
    required this.createdAt,
    required this.updatedAt,
  });

  final String farmId;
  final String ownerId;
  final String farmName;
  final String location;
  final String farmType;
  final int totalCapacity;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, dynamic> toJson() {
    return {
      'farmId': farmId,
      'ownerId': ownerId,
      'farmName': farmName,
      'location': location,
      'farmType': farmType,
      'totalCapacity': totalCapacity,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory FarmModel.fromJson(Map<String, dynamic> json) {
    return FarmModel(
      farmId: json['farmId'] as String,
      ownerId: json['ownerId'] as String,
      farmName: json['farmName'] as String,
      location: json['location'] as String,
      farmType: json['farmType'] as String,
      totalCapacity: json['totalCapacity'] as int,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  FarmModel copyWith({
    String? farmId,
    String? ownerId,
    String? farmName,
    String? location,
    String? farmType,
    int? totalCapacity,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FarmModel(
      farmId: farmId ?? this.farmId,
      ownerId: ownerId ?? this.ownerId,
      farmName: farmName ?? this.farmName,
      location: location ?? this.location,
      farmType: farmType ?? this.farmType,
      totalCapacity: totalCapacity ?? this.totalCapacity,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
