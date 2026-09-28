import 'package:flutter_test/flutter_test.dart';
import 'package:flock_sense/features/reports/data/pdf_generator.dart';
import 'package:flock_sense/features/reports/data/report_service.dart';
import 'package:flock_sense/features/reports/domain/report_types.dart';
import 'package:flock_sense/features/farms/domain/farm_model.dart';
import 'package:flock_sense/features/batches/domain/batch_model.dart';
import 'package:flock_sense/features/daily_records/domain/daily_record_model.dart';
import 'package:flock_sense/features/reports/domain/report_data.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PdfGenerator NaN Assertion Tests', () {
    test('generatePdfForReportType with fallback empty data', () async {
      final fallback = ReportService.getFallbackReportData();
      final pdfBytes = await PdfGenerator.generatePdfForReportType(
        data: fallback,
        reportType: ReportType.completeFarm,
      );
      expect(pdfBytes, isNotEmpty);
    });

    test('generatePdfForReportType with Day 1 record and 0 weight', () async {
      final now = DateTime.now();
      final farm = FarmModel(
        id: 'farm_1',
        userId: 'owner_1',
        ownerId: 'owner_1',
        farmName: 'Test Farm',
        farmType: 'Broiler',
        flockType: 'Commercial',
        address: 'Test Address',
        lengthFt: 100,
        widthFt: 30,
        totalSqFt: 3000,
        createdAt: now,
        updatedAt: now,
      );
      final batch = BatchModel(
        id: 'batch_1',
        farmId: 'farm_1',
        ownerId: 'owner_1',
        batchName: 'Batch 1',
        hatchDate: now,
        placementDate: now,
        maleCount: 500,
        femaleCount: 500,
        totalBirds: 1000,
        currentBirds: 1000,
        breedOrFlockType: 'Cobb 500',
        createdAt: now,
        updatedAt: now,
      );
      final dailyRecord = DailyRecordModel(
        id: 'rec_1',
        farmId: 'farm_1',
        batchId: 'batch_1',
        recordDate: now,
        batchAgeDay: 1,
        openingBirds: 1000,
        mortalityCount: 0,
        cullCount: 0,
        adjustmentCount: 0,
        closingBirds: 1000,
        feedConsumedKg: 20.0,
        waterConsumedLiters: 40.0,
        avgWeightGrams: 0.0, // 0 weight
        medicineGiven: false,
        vaccineGiven: false,
        ownerId: 'owner_1',
        createdAt: now,
        updatedAt: now,
      );
      final data = ReportData(
        farm: farm,
        batch: batch,
        farms: [farm],
        batches: [batch],
        sheds: [],
        dailyRecords: [dailyRecord],
        feedTransactions: [],
        medicineRecords: [],
        vaccineRecords: [],
        birdSales: [],
        inventoryItems: [],
        generatedAt: now,
      );

      final pdfBytes = await PdfGenerator.generatePdfForReportType(
        data: data,
        reportType: ReportType.completeFarm,
      );
      expect(pdfBytes, isNotEmpty);
    });
  });
}
