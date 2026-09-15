import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
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
import 'package:flock_sense/features/reports/domain/report_types.dart';
import 'package:flock_sense/features/sheds/data/shed_service.dart';
import 'package:flock_sense/features/sales/data/sales_service.dart';
import 'package:flock_sense/features/sales/domain/sales_record_model.dart';
import 'package:flock_sense/features/vaccine/data/vaccine_service.dart';
import 'package:flock_sense/features/vaccine/domain/vaccine_record_model.dart';
import 'package:flock_sense/features/inventory/domain/inventory_item_model.dart';

class ReportService {
  ReportService._();

  static Future<ReportData> loadFilteredReportData({
    required ReportFilterState filter,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        return getFallbackReportData(filter: filter);
      }

      final farms = await FarmService.getUserFarms();
      if (farms.isEmpty) {
        return getFallbackReportData(filter: filter);
      }

      final targetFarm = filter.selectedFarmId != null
          ? farms.firstWhere(
              (f) => f.id == filter.selectedFarmId,
              orElse: () => farms.first,
            )
          : farms.first;

      final batches = await BatchService.getBatchesForFarm(targetFarm.id);
      final targetBatch = (filter.selectedBatchId != null && batches.isNotEmpty)
          ? batches.firstWhere(
              (b) => b.id == filter.selectedBatchId,
              orElse: () => batches.first,
            )
          : (batches.isNotEmpty
                ? batches.firstWhere(
                    (b) => b.status == 'active' || b.isActive,
                    orElse: () => batches.first,
                  )
                : BatchModel(
                    id: '',
                    farmId: targetFarm.id,
                    ownerId: user.uid,
                    batchName: 'No Batch Selected',
                    breedOrFlockType: 'Broiler',
                    maleCount: 0,
                    femaleCount: 0,
                    totalBirds: 0,
                    currentBirds: 0,
                    hatchDate: DateTime.now(),
                    placementDate: DateTime.now(),
                    status: 'active',
                    createdAt: DateTime.now(),
                    updatedAt: DateTime.now(),
                  ));

      final sheds = await ShedService.getShedsByFarmId(targetFarm.id);

      List<DailyRecordModel> records = [];
      List<FeedTransactionModel> feeds = [];
      List<MedicineRecordModel> meds = [];
      List<VaccineRecordModel> vaccines = [];
      List<SalesRecordModel> sales = [];
      List<InventoryItemModel> inventory = [];

      if (filter.selectedBatchId != null && targetBatch.id.isNotEmpty) {
        try {
          records = await DailyRecordService.getAllDailyRecords(
            farmId: targetFarm.id,
            batchId: targetBatch.id,
          );
        } catch (_) {}

        try {
          feeds = await FeedService.getFeedTransactions(
            farmId: targetFarm.id,
            batchId: targetBatch.id,
          );
        } catch (_) {}

        try {
          meds = await MedicineService.getMedicineRecords(
            farmId: targetFarm.id,
            batchId: targetBatch.id,
          );
        } catch (_) {}

        try {
          vaccines = await VaccineService.getVaccineRecords(
            farmId: targetFarm.id,
            batchId: targetBatch.id,
          );
        } catch (_) {}

        try {
          sales = await SalesService.getBirdSales(
            farmId: targetFarm.id,
            batchId: targetBatch.id,
          );
        } catch (_) {}
      } else if (batches.isNotEmpty) {
        // "All Batches" mode - aggregate telemetry across all batches of targetFarm
        for (final b in batches) {
          try {
            final recs = await DailyRecordService.getAllDailyRecords(
              farmId: targetFarm.id,
              batchId: b.id,
            );
            records.addAll(recs);
          } catch (_) {}

          try {
            final f = await FeedService.getFeedTransactions(
              farmId: targetFarm.id,
              batchId: b.id,
            );
            feeds.addAll(f);
          } catch (_) {}

          try {
            final m = await MedicineService.getMedicineRecords(
              farmId: targetFarm.id,
              batchId: b.id,
            );
            meds.addAll(m);
          } catch (_) {}

          try {
            final v = await VaccineService.getVaccineRecords(
              farmId: targetFarm.id,
              batchId: b.id,
            );
            vaccines.addAll(v);
          } catch (_) {}

          try {
            final s = await SalesService.getBirdSales(
              farmId: targetFarm.id,
              batchId: b.id,
            );
            sales.addAll(s);
          } catch (_) {}
        }
      }

      try {
        final invSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('farms')
            .doc(targetFarm.id)
            .collection('inventoryItems')
            .get();
        inventory = invSnapshot.docs
            .map((doc) => InventoryItemModel.fromJson(doc.data()))
            .toList();
      } catch (_) {}

      final startDate = filter.effectiveStartDate;
      final endDate = filter.effectiveEndDate;

      if (startDate != null || endDate != null) {
        records = records.where((r) {
          if (startDate != null && r.recordDate.isBefore(startDate)) {
            return false;
          }
          if (endDate != null && r.recordDate.isAfter(endDate)) return false;
          return true;
        }).toList();
      }

      records.sort((a, b) => a.batchAgeDay.compareTo(b.batchAgeDay));

      return ReportData(
        farm: targetFarm,
        batch: targetBatch,
        farms: farms,
        batches: batches.isNotEmpty ? batches : [targetBatch],
        sheds: sheds,
        dailyRecords: records,
        feedTransactions: feeds,
        medicineRecords: meds,
        vaccineRecords: vaccines,
        birdSales: sales,
        inventoryItems: inventory,
        generatedAt: DateTime.now(),
      );
    } catch (e) {
      debugPrint('ReportService.loadFilteredReportData exception: $e');
      return getFallbackReportData(filter: filter);
    }
  }

  static Future<ReportData> loadReportData({
    required String farmId,
    required String batchId,
  }) async {
    return loadFilteredReportData(
      filter: ReportFilterState(
        selectedFarmId: farmId,
        selectedBatchId: batchId,
        datePreset: DateRangePreset.allTime,
      ),
    );
  }

  static ReportData getFallbackReportData({ReportFilterState? filter}) {
    final now = DateTime.now();
    final farm = FarmModel(
      id: '',
      userId: '',
      ownerId: '',
      farmName: 'No Farm Selected',
      farmerName: '',
      farmType: 'EC',
      flockType: 'Broiler',
      address: '',
      lengthFt: 0,
      widthFt: 0,
      totalSqFt: 0,
      createdAt: now,
      updatedAt: now,
    );

    final batch = BatchModel(
      id: '',
      farmId: '',
      ownerId: '',
      batchName: 'No Batch Selected',
      breedOrFlockType: 'Broiler',
      maleCount: 0,
      femaleCount: 0,
      totalBirds: 0,
      currentBirds: 0,
      hatchDate: now,
      placementDate: now,
      status: 'active',
      createdAt: now,
      updatedAt: now,
    );

    return ReportData(
      farm: farm,
      batch: batch,
      farms: const [],
      batches: const [],
      sheds: const [],
      dailyRecords: const [],
      feedTransactions: const [],
      medicineRecords: const [],
      vaccineRecords: const [],
      birdSales: const [],
      inventoryItems: const [],
      generatedAt: now,
    );
  }
}
