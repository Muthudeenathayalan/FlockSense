import 'package:cloud_firestore/cloud_firestore.dart';

class DailyRecord {
  final String id;
  final String flockId;
  final String date;
  final int openingCount;
  final int mortality;
  final int culls;
  final int closingCount;
  final double feedConsumedKg;
  final double? avgWeightGrams;
  final DateTime createdAt;

  DailyRecord({
    required this.id,
    required this.flockId,
    required this.date,
    required this.openingCount,
    required this.mortality,
    required this.culls,
    required this.closingCount,
    required this.feedConsumedKg,
    this.avgWeightGrams,
    required this.createdAt,
  });

  factory DailyRecord.fromMap(Map<String, dynamic> data, String id) {
    return DailyRecord(
      id: id,
      flockId: data['flockId']?.toString() ?? '',
      date: data['date']?.toString() ?? '',
      openingCount: (data['openingCount'] as int?) ?? 0,
      mortality: (data['mortality'] as int?) ?? 0,
      culls: (data['culls'] as int?) ?? 0,
      closingCount: (data['closingCount'] as int?) ?? 0,
      feedConsumedKg: (data['feedConsumedKg'] as num?)?.toDouble() ?? 0.0,
      avgWeightGrams: (data['avgWeightGrams'] as num?)?.toDouble(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  factory DailyRecord.fromDocument(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    return DailyRecord.fromMap(snapshot.data() ?? <String, dynamic>{}, snapshot.id);
  }

  Map<String, dynamic> toJson() {
    return {
      'flockId': flockId,
      'date': date,
      'openingCount': openingCount,
      'mortality': mortality,
      'culls': culls,
      'closingCount': closingCount,
      'feedConsumedKg': feedConsumedKg,
      'avgWeightGrams': avgWeightGrams,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
