import 'package:firebase_auth/firebase_auth.dart';
import 'package:flock_sense/features/batches/domain/batch_model.dart';
import 'package:flock_sense/features/batches/data/batch_service.dart';
import 'package:flock_sense/features/daily_records/data/daily_record_service.dart';
import 'package:flock_sense/features/daily_records/domain/daily_record_model.dart';
import 'package:flock_sense/features/feed/data/feed_service.dart';
import 'package:flock_sense/features/feed/domain/feed_transaction_model.dart';
import 'package:flock_sense/features/farms/data/farm_service.dart';
import 'package:flock_sense/features/farms/domain/farm_model.dart';
import 'package:flock_sense/features/medicine/data/medicine_service.dart';
import 'package:flock_sense/features/medicine/domain/medicine_record_model.dart';
import 'package:flock_sense/features/reports/domain/report_data.dart';
import 'package:flock_sense/features/sheds/data/shed_service.dart';
import 'package:flock_sense/features/sheds/domain/shed_model.dart';
import 'package:flock_sense/features/sales/data/sales_service.dart';
import 'package:flock_sense/features/sales/domain/sales_record_model.dart';
import 'package:flock_sense/features/vaccine/data/vaccine_service.dart';
import 'package:flock_sense/features/vaccine/domain/vaccine_record_model.dart';

class ReportService {
  ReportService._();

  static Future<ReportData> loadReportData({
    required String farmId,
    required String batchId,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Not signed in.');

    final results = await Future.wait([
      FarmService.getUserFarms(),
      ShedService.getShedsByFarmId(farmId),
      BatchService.getBatchById(farmId, batchId),
      DailyRecordService.getAllDailyRecords(farmId: farmId, batchId: batchId),
      FeedService.getFeedTransactions(farmId: farmId, batchId: batchId),
      MedicineService.getMedicineRecords(farmId: farmId, batchId: batchId),
      VaccineService.getVaccineRecords(farmId: farmId, batchId: batchId),
      SalesService.getBirdSales(farmId: farmId, batchId: batchId),
    ]);

    final farms = results[0] as List<FarmModel>;
    final farm = farms.firstWhere(
      (f) => f.id == farmId,
      orElse: () => farms.first,
    );
    final sheds = results[1] as List<ShedModel>;
    final batch = results[2] as BatchModel?;
    if (batch == null) throw Exception('Batch not found.');

    final records = (results[3] as List<DailyRecordModel>)
      ..sort((a, b) => a.batchAgeDay.compareTo(b.batchAgeDay));
    final feeds = results[4] as List<FeedTransactionModel>;
    final meds = results[5] as List<MedicineRecordModel>;
    final vaccines = results[6] as List<VaccineRecordModel>;
    final sales = results[7] as List<SalesRecordModel>;

    return ReportData(
      farm: farm,
      batch: batch,
      sheds: sheds,
      dailyRecords: records,
      feedTransactions: feeds,
      medicineRecords: meds,
      vaccineRecords: vaccines,
      birdSales: sales,
      generatedAt: DateTime.now(),
    );
  }
}
