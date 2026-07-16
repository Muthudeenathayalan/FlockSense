import 'package:cloud_firestore/cloud_firestore.dart';

class SalesRecordModel {
  const SalesRecordModel({
    required this.id,
    required this.farmId,
    required this.batchId,
    required this.ownerId,
    required this.createdAt,
    required this.updatedAt,
    required this.date,
    required this.batchAgeDay,
    required this.customerName,
    required this.birdsSold,
    required this.averageWeightKg,
    required this.pricePerBird,
    required this.totalValue,
    this.vehicleNumber,
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
  final String customerName;
  final int birdsSold;
  final double averageWeightKg;
  final double pricePerBird;
  final double totalValue;
  final String? vehicleNumber;
  final String? notes;

  factory SalesRecordModel.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is String && value.isNotEmpty) {
        return DateTime.tryParse(value) ?? DateTime.now();
      }
      return DateTime.now();
    }

    int parseInt(dynamic value) {
      if (value is int) return value;
      if (value is double) return value.toInt();
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    double parseDouble(dynamic value) {
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    return SalesRecordModel(
      id: json['id'] as String? ?? '',
      farmId: json['farmId'] as String? ?? '',
      batchId: json['batchId'] as String? ?? '',
      ownerId: json['ownerId'] as String? ?? '',
      createdAt: parseDate(json['createdAt']),
      updatedAt: parseDate(json['updatedAt']),
      date: parseDate(json['date']),
      batchAgeDay: parseInt(json['batchAgeDay']),
      customerName: json['customerName'] as String? ?? '',
      birdsSold: parseInt(json['birdsSold']),
      averageWeightKg: parseDouble(json['averageWeightKg']),
      pricePerBird: parseDouble(json['pricePerBird']),
      totalValue: parseDouble(json['totalValue']),
      vehicleNumber: json['vehicleNumber'] as String?,
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
    'customerName': customerName,
    'birdsSold': birdsSold,
    'averageWeightKg': averageWeightKg,
    'pricePerBird': pricePerBird,
    'totalValue': totalValue,
    'vehicleNumber': vehicleNumber,
    'notes': notes,
  };
}
