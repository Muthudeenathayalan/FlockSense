import 'package:cloud_firestore/cloud_firestore.dart';

class FeedTransactionModel {
  FeedTransactionModel({
    required this.id,
    required this.farmId,
    required this.batchId,
    required this.ownerId,
    required this.createdAt,
    required this.updatedAt,
    DateTime? date,
    DateTime? transactionDate,
    String? dcNumber,
    required String feedType,
    String? batchNumber,
    String? feedBatchNumber,
    int bags = 0,
    double? weightKg,
    double? weightPerBagKg,
    int? cumulativeBags,
    double? cumulativeKg,
    double? totalKg,
    String? supplierName,
    String? supplierOrSource,
    String? notes,
    String? transactionType,
    String? destination,
    double? costPerKg,
    double? totalCost,
  }) : date = date ?? transactionDate ?? DateTime.now(),
       dcNumber = dcNumber?.trim(),
       feedType = feedType.trim(),
       batchNumber = batchNumber ?? feedBatchNumber,
       bags = bags,
       weightKg =
           weightKg ??
           (bags > 0 && (weightPerBagKg ?? 0) > 0
               ? bags * (weightPerBagKg ?? 0)
               : (totalKg ?? 0)),
       cumulativeBags = cumulativeBags ?? bags,
       cumulativeKg = cumulativeKg ?? (totalKg ?? (weightKg ?? 0)),
       supplierName = supplierName ?? supplierOrSource,
       notes = notes?.trim(),
       transactionType = transactionType ?? 'received',
       destination = destination?.trim(),
       costPerKg = costPerKg ?? 0,
       totalCost = totalCost ?? 0;

  final String id;
  final String farmId;
  final String batchId;
  final String ownerId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime date;
  final String? dcNumber;
  final String feedType;
  final String? batchNumber;
  final int bags;
  final double weightKg;
  final int cumulativeBags;
  final double cumulativeKg;
  final String? supplierName;
  final String? notes;
  final String transactionType;
  final String? destination;
  final double costPerKg;
  final double totalCost;

  DateTime get transactionDate => date;
  String? get feedBatchNumber => batchNumber;
  double get weightPerBagKg => bags > 0 ? weightKg / bags : 0;
  double get totalKg => weightKg;
  String? get supplierOrSource => supplierName;

  factory FeedTransactionModel.fromJson(Map<String, dynamic> json) {
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

    final legacyDate = json['transactionDate'] ?? json['date'];
    final feedType = (json['feedType'] as String? ?? '').trim();
    final bagCount = parseInt(json['bags']);
    final parsedWeightKg = parseDouble(json['weightKg']);
    final parsedWeightPerBag = parseDouble(json['weightPerBagKg']);
    final resolvedWeight = parsedWeightKg > 0
        ? parsedWeightKg
        : (bagCount > 0 && parsedWeightPerBag > 0
              ? bagCount * parsedWeightPerBag
              : parseDouble(json['totalKg']));

    return FeedTransactionModel(
      id: json['id'] as String? ?? '',
      farmId: json['farmId'] as String? ?? '',
      batchId: json['batchId'] as String? ?? '',
      ownerId: json['ownerId'] as String? ?? '',
      createdAt: parseDate(json['createdAt']),
      updatedAt: parseDate(json['updatedAt']),
      date: parseDate(legacyDate),
      dcNumber: json['dcNumber'] as String?,
      feedType: feedType,
      batchNumber:
          json['batchNumber'] as String? ?? json['feedBatchNumber'] as String?,
      bags: bagCount,
      weightKg: resolvedWeight,
      cumulativeBags: parseInt(json['cumulativeBags']),
      cumulativeKg: parseDouble(json['cumulativeKg']),
      supplierName:
          json['supplierName'] as String? ??
          json['supplierOrSource'] as String?,
      notes: json['notes'] as String?,
      transactionType: json['transactionType'] as String? ?? 'received',
      destination: json['destination'] as String?,
      costPerKg: parseDouble(json['costPerKg']),
      totalCost: parseDouble(json['totalCost']),
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
    'transactionDate': Timestamp.fromDate(date),
    'dcNumber': dcNumber,
    'feedType': feedType,
    'batchNumber': batchNumber,
    'feedBatchNumber': batchNumber,
    'bags': bags,
    'weightKg': weightKg,
    'weightPerBagKg': weightPerBagKg,
    'cumulativeBags': cumulativeBags,
    'cumulativeKg': cumulativeKg,
    'totalKg': totalKg,
    'supplierName': supplierName,
    'supplierOrSource': supplierName,
    'notes': notes,
    'transactionType': transactionType,
    'destination': destination,
    'costPerKg': costPerKg,
    'totalCost': totalCost,
  };

  FeedTransactionModel copyWith({
    String? id,
    String? farmId,
    String? batchId,
    String? ownerId,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? date,
    String? dcNumber,
    String? feedType,
    String? batchNumber,
    int? bags,
    double? weightKg,
    int? cumulativeBags,
    double? cumulativeKg,
    String? supplierName,
    String? notes,
    String? transactionType,
    String? destination,
    double? costPerKg,
    double? totalCost,
  }) {
    return FeedTransactionModel(
      id: id ?? this.id,
      farmId: farmId ?? this.farmId,
      batchId: batchId ?? this.batchId,
      ownerId: ownerId ?? this.ownerId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      date: date ?? this.date,
      dcNumber: dcNumber ?? this.dcNumber,
      feedType: feedType ?? this.feedType,
      batchNumber: batchNumber ?? this.batchNumber,
      bags: bags ?? this.bags,
      weightKg: weightKg ?? this.weightKg,
      cumulativeBags: cumulativeBags ?? this.cumulativeBags,
      cumulativeKg: cumulativeKg ?? this.cumulativeKg,
      supplierName: supplierName ?? this.supplierName,
      notes: notes ?? this.notes,
      transactionType: transactionType ?? this.transactionType,
      destination: destination ?? this.destination,
      costPerKg: costPerKg ?? this.costPerKg,
      totalCost: totalCost ?? this.totalCost,
    );
  }
}
