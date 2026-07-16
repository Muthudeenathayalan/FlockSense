import 'package:cloud_firestore/cloud_firestore.dart';

class VaccineRecordModel {
  const VaccineRecordModel({
    required this.id,
    required this.farmId,
    required this.batchId,
    required this.ownerId,
    required this.createdAt,
    required this.updatedAt,
    required this.date,
    required this.batchAgeDay,
    required this.vaccineName,
    required this.vaccineType,
    this.batchNumber,
    this.expiryDate,
    required this.quantity,
    required this.unit,
    required this.route,
    this.doneBy,
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
  final String vaccineName;
  final String vaccineType;
  final String? batchNumber;
  final DateTime? expiryDate;
  final double quantity;
  final String unit;
  final String route;
  final String? doneBy;
  final String? notes;

  factory VaccineRecordModel.fromJson(Map<String, dynamic> json) {
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

    return VaccineRecordModel(
      id: json['id'] as String? ?? '',
      farmId: json['farmId'] as String? ?? '',
      batchId: json['batchId'] as String? ?? '',
      ownerId: json['ownerId'] as String? ?? '',
      createdAt: parseDate(json['createdAt']),
      updatedAt: parseDate(json['updatedAt']),
      date: parseDate(json['date']),
      batchAgeDay: parseInt(json['batchAgeDay']),
      vaccineName: json['vaccineName'] as String? ?? '',
      vaccineType: json['vaccineType'] as String? ?? 'Other',
      batchNumber: json['batchNumber'] as String?,
      expiryDate: json['expiryDate'] == null
          ? null
          : parseDate(json['expiryDate']),
      quantity: parseDouble(json['quantity']),
      unit: json['unit'] as String? ?? 'ml',
      route: json['route'] as String? ?? 'Injection',
      doneBy: json['doneBy'] as String?,
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
    'vaccineName': vaccineName,
    'vaccineType': vaccineType,
    'batchNumber': batchNumber,
    'expiryDate': expiryDate == null ? null : Timestamp.fromDate(expiryDate!),
    'quantity': quantity,
    'unit': unit,
    'route': route,
    'doneBy': doneBy,
    'notes': notes,
  };

  VaccineRecordModel copyWith({
    String? id,
    String? farmId,
    String? batchId,
    String? ownerId,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? date,
    int? batchAgeDay,
    String? vaccineName,
    String? vaccineType,
    String? batchNumber,
    DateTime? expiryDate,
    double? quantity,
    String? unit,
    String? route,
    String? doneBy,
    String? notes,
  }) {
    return VaccineRecordModel(
      id: id ?? this.id,
      farmId: farmId ?? this.farmId,
      batchId: batchId ?? this.batchId,
      ownerId: ownerId ?? this.ownerId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      date: date ?? this.date,
      batchAgeDay: batchAgeDay ?? this.batchAgeDay,
      vaccineName: vaccineName ?? this.vaccineName,
      vaccineType: vaccineType ?? this.vaccineType,
      batchNumber: batchNumber ?? this.batchNumber,
      expiryDate: expiryDate ?? this.expiryDate,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      route: route ?? this.route,
      doneBy: doneBy ?? this.doneBy,
      notes: notes ?? this.notes,
    );
  }
}
