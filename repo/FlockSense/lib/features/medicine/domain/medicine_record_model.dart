import 'package:cloud_firestore/cloud_firestore.dart';

class MedicineRecordModel {
  const MedicineRecordModel({
    required this.id,
    required this.farmId,
    required this.batchId,
    required this.ownerId,
    required this.createdAt,
    required this.updatedAt,
    required this.date,
    required this.batchAgeDay,
    this.dcNumber,
    required this.medicineName,
    required this.quantity,
    required this.unit,
    this.valueRs,
    this.route,
    this.notes,
  });

  final String id;
  final String farmId;
  final String batchId;
  final String ownerId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime date;
  final int batchAgeDay;
  final String? dcNumber;
  final String medicineName;
  final double quantity;
  final String unit;
  final double? valueRs;
  final String? route;
  final String? notes;

  factory MedicineRecordModel.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is String && value.isNotEmpty) {
        return DateTime.tryParse(value) ?? DateTime.now();
      }
      return DateTime.now();
    }

    double parseDouble(dynamic value) {
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    int parseInt(dynamic value) {
      if (value is int) return value;
      if (value is double) return value.toInt();
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    return MedicineRecordModel(
      id: json['id'] as String? ?? '',
      farmId: json['farmId'] as String? ?? '',
      batchId: json['batchId'] as String? ?? '',
      ownerId: json['ownerId'] as String? ?? '',
      createdAt: parseDate(json['createdAt']),
      updatedAt: parseDate(json['updatedAt']),
      date: parseDate(json['date']),
      batchAgeDay: parseInt(json['batchAgeDay']),
      dcNumber: json['dcNumber'] as String?,
      medicineName: json['medicineName'] as String? ?? '',
      quantity: parseDouble(json['quantity']),
      unit: json['unit'] as String? ?? 'ml',
      valueRs: parseDouble(json['valueRs']),
      route: json['route'] as String?,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'farmId': farmId,
    'batchId': batchId,
    'ownerId': ownerId,
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': Timestamp.fromDate(updatedAt),
    'date': Timestamp.fromDate(date),
    'batchAgeDay': batchAgeDay,
    'dcNumber': dcNumber,
    'medicineName': medicineName,
    'quantity': quantity,
    'unit': unit,
    'valueRs': valueRs,
    'route': route,
    'notes': notes,
  };

  MedicineRecordModel copyWith({
    String? id,
    String? farmId,
    String? batchId,
    String? ownerId,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? date,
    int? batchAgeDay,
    String? dcNumber,
    String? medicineName,
    double? quantity,
    String? unit,
    double? valueRs,
    String? route,
    String? notes,
  }) {
    return MedicineRecordModel(
      id: id ?? this.id,
      farmId: farmId ?? this.farmId,
      batchId: batchId ?? this.batchId,
      ownerId: ownerId ?? this.ownerId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      date: date ?? this.date,
      batchAgeDay: batchAgeDay ?? this.batchAgeDay,
      dcNumber: dcNumber ?? this.dcNumber,
      medicineName: medicineName ?? this.medicineName,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      valueRs: valueRs ?? this.valueRs,
      route: route ?? this.route,
      notes: notes ?? this.notes,
    );
  }
}
