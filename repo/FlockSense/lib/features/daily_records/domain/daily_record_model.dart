import 'package:cloud_firestore/cloud_firestore.dart';

class DailyRecordModel {
  const DailyRecordModel({
    required this.id,
    required this.farmId,
    required this.batchId,
    required this.recordDate,
    required this.batchAgeDay,
    required this.openingBirds,
    required this.mortalityCount,
    required this.cullCount,
    required this.adjustmentCount,
    required this.closingBirds,
    required this.feedConsumedKg,
    required this.waterConsumedLiters,
    required this.avgWeightGrams,
    required this.medicineGiven,
    this.medicineName,
    required this.vaccineGiven,
    this.vaccineName,
    this.symptoms,
    this.notes,
    required this.ownerId,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String farmId;
  final String batchId;
  final DateTime recordDate;
  final int batchAgeDay;
  final int openingBirds;
  final int mortalityCount;
  final int cullCount;
  final int adjustmentCount;
  final int closingBirds;
  final double feedConsumedKg;
  final double waterConsumedLiters;
  final double avgWeightGrams;
  final bool medicineGiven;
  final String? medicineName;
  final bool vaccineGiven;
  final String? vaccineName;
  final String? symptoms;
  final String? notes;
  final String ownerId;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory DailyRecordModel.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic v) {
      if (v is Timestamp) return v.toDate();
      if (v is String && v.isNotEmpty) {
        return DateTime.tryParse(v) ?? _parseDateString(v) ?? DateTime.now();
      }
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

    final recordDate = parseDate(
      json['recordDate'] ?? json['recordDateString'] ?? json['date'],
    );
    final openingBirds = parseInt(json['openingBirds']);
    final mortalityCount = parseInt(json['mortalityCount']);
    final cullCount = parseInt(json['cullCount']);
    final adjustmentCount = parseInt(json['adjustmentCount']);
    final closingBirds = parseInt(json['closingBirds']) != 0
        ? parseInt(json['closingBirds'])
        : openingBirds - mortalityCount - cullCount + adjustmentCount;

    return DailyRecordModel(
      id: json['id'] as String? ?? '',
      farmId: json['farmId'] as String? ?? '',
      batchId: json['batchId'] as String? ?? '',
      recordDate: recordDate,
      batchAgeDay: parseInt(json['batchAgeDay']),
      openingBirds: openingBirds,
      mortalityCount: mortalityCount,
      cullCount: cullCount,
      adjustmentCount: adjustmentCount,
      closingBirds: closingBirds,
      feedConsumedKg: parseDouble(json['feedConsumedKg']),
      waterConsumedLiters: parseDouble(json['waterConsumedLiters']),
      avgWeightGrams: parseDouble(json['avgWeightGrams']),
      medicineGiven: json['medicineGiven'] as bool? ?? false,
      medicineName: json['medicineName'] as String?,
      vaccineGiven: json['vaccineGiven'] as bool? ?? false,
      vaccineName: json['vaccineName'] as String?,
      symptoms: json['symptoms'] as String?,
      notes: json['notes'] as String?,
      ownerId: json['ownerId'] as String? ?? '',
      createdAt: parseDate(json['createdAt']),
      updatedAt: parseDate(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'farmId': farmId,
    'batchId': batchId,
    'recordDate': _formatRecordDate(recordDate),
    'batchAgeDay': batchAgeDay,
    'openingBirds': openingBirds,
    'mortalityCount': mortalityCount,
    'cullCount': cullCount,
    'adjustmentCount': adjustmentCount,
    'closingBirds': closingBirds,
    'feedConsumedKg': feedConsumedKg,
    'waterConsumedLiters': waterConsumedLiters,
    'avgWeightGrams': avgWeightGrams,
    'medicineGiven': medicineGiven,
    'medicineName': medicineName,
    'vaccineGiven': vaccineGiven,
    'vaccineName': vaccineName,
    'symptoms': symptoms,
    'notes': notes,
    'ownerId': ownerId,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  static String _formatRecordDate(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  static DateTime? _parseDateString(String value) {
    try {
      final parts = value.split('-');
      if (parts.length == 3) {
        final year = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        final day = int.parse(parts[2]);
        return DateTime(year, month, day);
      }
    } catch (_) {
      return null;
    }
    return null;
  }
}
