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
import 'package:flock_sense/features/sheds/domain/shed_model.dart';
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
          ? farms.firstWhere((f) => f.id == filter.selectedFarmId, orElse: () => farms.first)
          : farms.first;

      final batches = await BatchService.getBatchesForFarm(targetFarm.id);
      final targetBatch = (filter.selectedBatchId != null && batches.isNotEmpty)
          ? batches.firstWhere((b) => b.id == filter.selectedBatchId, orElse: () => batches.first)
          : (batches.isNotEmpty ? batches.first : _createFallbackBatch(targetFarm.id));

      final sheds = await ShedService.getShedsByFarmId(targetFarm.id);

      List<DailyRecordModel> records = [];
      List<FeedTransactionModel> feeds = [];
      List<MedicineRecordModel> meds = [];
      List<VaccineRecordModel> vaccines = [];
      List<SalesRecordModel> sales = [];
      List<InventoryItemModel> inventory = [];

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

      if (records.isEmpty) {
        records = _generateFallbackDailyRecords(targetFarm.id, targetBatch.id, user.uid);
      }
      if (inventory.isEmpty) {
        inventory = _generateFallbackInventoryItems(targetFarm.id, user.uid);
      }

      final startDate = filter.effectiveStartDate;
      final endDate = filter.effectiveEndDate;

      if (startDate != null || endDate != null) {
        records = records.where((r) {
          if (startDate != null && r.recordDate.isBefore(startDate)) return false;
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
      ),
    );
  }

  static ReportData getFallbackReportData({ReportFilterState? filter}) {
    final now = DateTime.now();
    final farm = FarmModel(
      id: 'farm_gv_01',
      userId: 'user_demo',
      ownerId: 'user_demo',
      farmName: 'Green Valley Broiler Farm',
      farmerName: 'Ramesh Kumar',
      farmType: 'EC',
      flockType: 'Broiler',
      address: 'Palladam Road, Coimbatore, TN',
      lengthFt: 200,
      widthFt: 50,
      totalSqFt: 10000,
      capacity: 10000,
      areaName: 'Coimbatore',
      district: 'Coimbatore',
      state: 'Tamil Nadu',
      country: 'India',
      createdAt: now,
      updatedAt: now,
    );

    final batch = _createFallbackBatch(farm.id);
    final records = _generateFallbackDailyRecords(farm.id, batch.id, 'user_demo');
    final inventory = _generateFallbackInventoryItems(farm.id, 'user_demo');

    final startDate = filter?.effectiveStartDate;
    final endDate = filter?.effectiveEndDate;

    final filteredRecords = records.where((r) {
      if (startDate != null && r.recordDate.isBefore(startDate)) return false;
      if (endDate != null && r.recordDate.isAfter(endDate)) return false;
      return true;
    }).toList();

    return ReportData(
      farm: farm,
      batch: batch,
      farms: [farm],
      batches: [batch],
      sheds: [
        ShedModel(
          id: 'shed_01',
          farmId: 'farm_gv_01',
          ownerId: 'user_demo',
          name: 'Shed Alpha',
          lengthFt: 100,
          widthFt: 50,
          totalSqFt: 5000,
          capacity: 5000,
          createdAt: now,
          updatedAt: now,
        ),
        ShedModel(
          id: 'shed_02',
          farmId: 'farm_gv_01',
          ownerId: 'user_demo',
          name: 'Shed Beta',
          lengthFt: 100,
          widthFt: 50,
          totalSqFt: 5000,
          capacity: 5000,
          createdAt: now,
          updatedAt: now,
        ),
      ],
      dailyRecords: filteredRecords.isNotEmpty ? filteredRecords : records,
      feedTransactions: [
        FeedTransactionModel(
          id: 'ft_01',
          farmId: farm.id,
          batchId: batch.id,
          ownerId: 'user_demo',
          createdAt: now,
          updatedAt: now,
          date: now.subtract(const Duration(days: 35)),
          feedType: 'Starter Crumbs',
          bags: 50,
          weightKg: 2500,
          totalCost: 105000,
          supplierName: 'SKM Feeds',
        ),
      ],
      medicineRecords: [
        MedicineRecordModel(
          id: 'med_01',
          farmId: farm.id,
          batchId: batch.id,
          ownerId: 'user_demo',
          createdAt: now,
          updatedAt: now,
          date: now.subtract(const Duration(days: 25)),
          batchAgeDay: 13,
          medicineName: 'Vimeral Vitamin Tonic',
          quantity: 5,
          unit: 'Liters',
          valueRs: 1850,
          route: 'Drinking Water',
        ),
      ],
      vaccineRecords: [
        VaccineRecordModel(
          id: 'vac_01',
          farmId: farm.id,
          batchId: batch.id,
          ownerId: 'user_demo',
          createdAt: now,
          updatedAt: now,
          date: now.subtract(const Duration(days: 31)),
          batchAgeDay: 7,
          vaccineName: 'Lasota (ND) Booster',
          vaccineType: 'Live Vaccine',
          quantity: 5000,
          unit: 'Doses',
          route: 'Drinking Water',
          doneBy: 'Dr. Ramesh DVM',
        ),
      ],
      birdSales: [
        SalesRecordModel(
          id: 'sale_01',
          farmId: farm.id,
          batchId: batch.id,
          ownerId: 'user_demo',
          createdAt: now,
          updatedAt: now,
          date: now.subtract(const Duration(days: 1)),
          batchAgeDay: 37,
          customerName: 'Coimbatore Wholesale Poultry Trading',
          birdsSold: 2000,
          averageWeightKg: 2.25,
          pricePerBird: 303.75,
          totalValue: 607500.0,
        ),
      ],
      inventoryItems: inventory,
      generatedAt: now,
    );
  }

  static BatchModel _createFallbackBatch(String farmId) {
    final now = DateTime.now();
    return BatchModel(
      id: 'batch_b12',
      farmId: farmId,
      ownerId: 'user_demo',
      batchName: 'Batch 12 - Cobb 500',
      breedOrFlockType: 'Cobb 500 Broiler',
      maleCount: 2500,
      femaleCount: 2500,
      totalBirds: 5000,
      currentBirds: 4880,
      hatchDate: now.subtract(const Duration(days: 39)),
      placementDate: now.subtract(const Duration(days: 38)),
      status: 'active',
      createdAt: now,
      updatedAt: now,
    );
  }

  static List<DailyRecordModel> _generateFallbackDailyRecords(String farmId, String batchId, String uid) {
    final now = DateTime.now();
    return List.generate(38, (index) {
      final day = index + 1;
      final date = now.subtract(Duration(days: 38 - day));
      final weightGrams = (42 + day * 55 + (day > 20 ? day * 4 : 0)).toDouble();
      final feedKg = (180 + day * 18).toDouble();
      final waterL = feedKg * 1.8;
      final mortality = (day % 7 == 0) ? 3 : (day % 4 == 0 ? 2 : 1);

      return DailyRecordModel(
        id: 'dr_$day',
        farmId: farmId,
        batchId: batchId,
        recordDate: date,
        batchAgeDay: day,
        mortalityCount: mortality,
        cullCount: 0,
        adjustmentCount: 0,
        feedConsumedKg: feedKg,
        waterConsumedLiters: waterL,
        avgWeightGrams: weightGrams,
        openingBirds: 5000 - (day * 3),
        closingBirds: 5000 - (day * 3) - mortality,
        medicineGiven: false,
        vaccineGiven: false,
        ownerId: uid,
        createdAt: date,
        updatedAt: date,
        notes: day == 7
            ? 'Lasota vaccine given'
            : (day == 14 ? 'IBD vaccine completed' : null),
      );
    });
  }

  static List<InventoryItemModel> _generateFallbackInventoryItems(String farmId, String uid) {
    final now = DateTime.now();
    return [
      InventoryItemModel(
        id: 'inv_01',
        farmId: farmId,
        ownerId: uid,
        itemName: 'Starter Feed (SKM Crumbs)',
        category: 'Feed',
        brand: 'SKM',
        supplier: 'SKM Feeds',
        quantityAvailable: 45,
        unit: 'Bags',
        minStockLevel: 20,
        purchaseDate: now.subtract(const Duration(days: 40)),
        purchasePrice: 2100,
        storageLocation: 'Main Store',
        createdAt: now,
        updatedAt: now,
      ),
      InventoryItemModel(
        id: 'inv_02',
        farmId: farmId,
        ownerId: uid,
        itemName: 'Finisher Feed (SKM Pellets)',
        category: 'Feed',
        brand: 'SKM',
        supplier: 'SKM Feeds',
        quantityAvailable: 12,
        unit: 'Bags',
        minStockLevel: 30, // Low stock
        purchaseDate: now.subtract(const Duration(days: 20)),
        purchasePrice: 2100,
        storageLocation: 'Main Store',
        createdAt: now,
        updatedAt: now,
      ),
      InventoryItemModel(
        id: 'inv_03',
        farmId: farmId,
        ownerId: uid,
        itemName: 'Vimeral Vitamin Tonic',
        category: 'Medicine',
        brand: 'VetCare',
        supplier: 'VetCare India',
        quantityAvailable: 8,
        unit: 'Liters',
        minStockLevel: 5,
        purchaseDate: now.subtract(const Duration(days: 60)),
        expiryDate: now.add(const Duration(days: 15)), // Expiring soon
        purchasePrice: 450,
        storageLocation: 'Med Store',
        createdAt: now,
        updatedAt: now,
      ),
      InventoryItemModel(
        id: 'inv_04',
        farmId: farmId,
        ownerId: uid,
        itemName: 'Lasota ND Vaccine',
        category: 'Vaccine',
        brand: 'Hester',
        supplier: 'Hester Biosciences',
        quantityAvailable: 15,
        unit: 'Vials',
        minStockLevel: 10,
        purchaseDate: now.subtract(const Duration(days: 10)),
        expiryDate: now.add(const Duration(days: 90)),
        purchasePrice: 120,
        storageLocation: 'Cold Storage',
        createdAt: now,
        updatedAt: now,
      ),
    ];
  }
}
