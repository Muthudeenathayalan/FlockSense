import 'package:flock_sense/features/batches/domain/batch_model.dart';
import 'package:flock_sense/features/daily_records/domain/daily_record_model.dart';
import 'package:flock_sense/features/feed/domain/feed_transaction_model.dart';
import 'package:flock_sense/features/farms/domain/farm_model.dart';
import 'package:flock_sense/features/medicine/domain/medicine_record_model.dart';
import 'package:flock_sense/features/sheds/domain/shed_model.dart';
import 'package:flock_sense/features/sales/domain/sales_record_model.dart';
import 'package:flock_sense/features/vaccine/domain/vaccine_record_model.dart';

typedef BirdSaleModel = SalesRecordModel;

class ReportData {
  const ReportData({
    required this.farm,
    required this.batch,
    required this.sheds,
    required this.dailyRecords,
    required this.feedTransactions,
    required this.medicineRecords,
    required this.vaccineRecords,
    required this.birdSales,
    required this.generatedAt,
  });

  final FarmModel farm;
  final BatchModel batch;
  final List<ShedModel> sheds;
  final List<DailyRecordModel> dailyRecords;
  final List<FeedTransactionModel> feedTransactions;
  final List<MedicineRecordModel> medicineRecords;
  final List<VaccineRecordModel> vaccineRecords;
  final List<BirdSaleModel> birdSales;
  final DateTime generatedAt;

  int get totalMortality => dailyRecords.fold(
    0,
    (sum, record) => sum + record.mortalityCount + record.cullCount,
  );

  double get totalFeedKg => feedTransactions.fold(
    0.0,
    (sum, transaction) => sum + transaction.weightKg,
  );

  int get totalBirdsSold =>
      birdSales.fold(0, (sum, sale) => sum + sale.birdsSold);

  double get totalSaleWeightKg => birdSales.fold(
    0.0,
    (sum, sale) => sum + sale.averageWeightKg * sale.birdsSold,
  );

  double get liveabilityPct {
    if (batch.totalBirds <= 0) return 0;
    return ((batch.totalBirds - totalMortality) / batch.totalBirds) * 100;
  }

  double? get overallFcr {
    final lastRec = _latestRecord;
    if (lastRec == null || lastRec.avgWeightGrams <= 0) return null;
    return totalFeedKg / (lastRec.avgWeightGrams / 1000.0);
  }

  double? get avgBodyWeightGrams {
    final lastRec = _latestRecord;
    if (lastRec == null || lastRec.avgWeightGrams <= 0) return null;
    return lastRec.avgWeightGrams;
  }

  int get meanAge {
    final lastRec = _latestRecord;
    return lastRec?.batchAgeDay ?? 0;
  }

  double? get pef {
    final fcr = overallFcr;
    final wtKg = avgBodyWeightGrams != null
        ? avgBodyWeightGrams! / 1000.0
        : null;
    final age = meanAge;
    if (fcr == null || wtKg == null || age <= 0 || fcr <= 0) return null;
    return (liveabilityPct * wtKg) / (age * fcr) * 100;
  }

  DailyRecordModel? get _latestRecord {
    if (dailyRecords.isEmpty) return null;
    return dailyRecords.reduce(
      (current, next) =>
          current.batchAgeDay >= next.batchAgeDay ? current : next,
    );
  }
}
