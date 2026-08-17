import 'package:cloud_firestore/cloud_firestore.dart';

class FinanceBudgetModel {
  final String id;
  final String farmId;
  final String monthYear; // Format: 'YYYY-MM'
  final double monthlyBudget;
  final double feedBudget;
  final double medicineBudget;
  final DateTime updatedAt;

  const FinanceBudgetModel({
    required this.id,
    required this.farmId,
    required this.monthYear,
    this.monthlyBudget = 150000.0,
    this.feedBudget = 100000.0,
    this.medicineBudget = 20000.0,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'farmId': farmId,
      'monthYear': monthYear,
      'monthlyBudget': monthlyBudget,
      'feedBudget': feedBudget,
      'medicineBudget': medicineBudget,
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory FinanceBudgetModel.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String && val.isNotEmpty) {
        return DateTime.tryParse(val) ?? DateTime.now();
      }
      return DateTime.now();
    }

    double parseDouble(dynamic val) {
      if (val is num) return val.toDouble();
      if (val is String) return double.tryParse(val) ?? 0.0;
      return 0.0;
    }

    return FinanceBudgetModel(
      id: json['id'] as String? ?? '',
      farmId: json['farmId'] as String? ?? '',
      monthYear: json['monthYear'] as String? ?? '2026-08',
      monthlyBudget: parseDouble(json['monthlyBudget']),
      feedBudget: parseDouble(json['feedBudget']),
      medicineBudget: parseDouble(json['medicineBudget']),
      updatedAt: parseDate(json['updatedAt']),
    );
  }
}
