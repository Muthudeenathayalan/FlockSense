import 'package:cloud_firestore/cloud_firestore.dart';

class WeightRecordModel {
  const WeightRecordModel({
    required this.id,
    required this.userId,
    required this.farmId,
    required this.batchId,
    required this.recordDate,
    required this.averageWeight,
    required this.unit,
    this.sampleCount,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String userId;
  final String farmId;
  final String batchId;
  final DateTime recordDate;
  final double averageWeight;
  final String unit; // 'grams' or 'kilograms'
  final int? sampleCount;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory WeightRecordModel.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic v) {
      if (v is Timestamp) return v.toDate();
      if (v is String && v.isNotEmpty) {
        return DateTime.tryParse(v) ?? DateTime.now();
      }
      return DateTime.now();
    }

    double parseDouble(dynamic v) {
      if (v is double) return v;
      if (v is int) return v.toDouble();
      if (v is String) return double.tryParse(v) ?? 0.0;
      return 0.0;
    }

    int? parseInt(dynamic v) {
      if (v is int) return v;
      if (v is double) return v.toInt();
      if (v is String) {
        final parsed = int.tryParse(v);
        return parsed;
      }
      return null;
    }

    return WeightRecordModel(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      farmId: json['farmId'] as String? ?? '',
      batchId: json['batchId'] as String? ?? '',
      recordDate: parseDate(json['recordDate']),
      averageWeight: parseDouble(json['averageWeight']),
      unit: json['unit'] as String? ?? 'grams',
      sampleCount: parseInt(json['sampleCount']),
      notes: json['notes'] as String?,
      createdAt: parseDate(json['createdAt']),
      updatedAt: parseDate(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'farmId': farmId,
    'batchId': batchId,
    'recordDate': _formatRecordDate(recordDate),
    'averageWeight': averageWeight,
    'unit': unit,
    'sampleCount': sampleCount,
    'notes': notes,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  static String _formatRecordDate(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
