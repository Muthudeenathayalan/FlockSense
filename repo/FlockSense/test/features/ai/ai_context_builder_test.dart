import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flock_sense/features/ai/data/services/ai_context_builder.dart';
import 'package:flock_sense/features/ai/data/services/gemini_service.dart';
import 'package:flock_sense/features/batches/domain/batch_model.dart';
import 'package:flock_sense/features/daily_records/domain/daily_record_model.dart';
import 'package:flock_sense/features/farms/domain/farm_model.dart';
import 'package:flock_sense/features/inventory/domain/inventory_item_model.dart';
import 'package:flock_sense/features/medicine/domain/medicine_record_model.dart';
import 'package:flock_sense/features/reports/domain/report_data.dart';
import 'package:flock_sense/features/sales/domain/sales_record_model.dart';
import 'package:flock_sense/features/sheds/domain/shed_model.dart';
import 'package:flock_sense/features/vaccine/domain/vaccine_record_model.dart';

class _AllowRealHttpOverrides extends HttpOverrides {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = _AllowRealHttpOverrides();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('AiContextBuilder & Firebase Ingestion Tests', () {
    test('formatReportDataToPromptContext returns no-data message when empty', () {
      final now = DateTime.now();
      final emptyReport = ReportData(
        farm: FarmModel(
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
        ),
        batch: BatchModel(
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
        ),
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

      final prompt = AiContextBuilder.formatReportDataToPromptContext(emptyReport);
      expect(prompt.contains('NO ACTIVE FARM OR FLOCK DATA LOGGED IN FIREBASE'), isTrue);
      expect(prompt.contains('User currently has 0 registered farms'), isTrue);
    });

    test('formatReportDataToPromptContext comprehensively extracts all Firebase telemetry', () {
      final now = DateTime.now();
      final farm1 = FarmModel(
        id: 'farm_1',
        userId: 'u123',
        ownerId: 'u123',
        farmName: 'Green Valley Facility',
        farmerName: 'Muthu Deenathayalan',
        farmType: 'Environment Controlled (EC)',
        flockType: 'Broiler',
        address: 'Coimbatore, Tamil Nadu',
        lengthFt: 400,
        widthFt: 50,
        totalSqFt: 20000,
        createdAt: now,
        updatedAt: now,
      );

      final farm2 = FarmModel(
        id: 'farm_2',
        userId: 'u123',
        ownerId: 'u123',
        farmName: 'Highland Farm',
        farmerName: 'Muthu Deenathayalan',
        farmType: 'Open Sided',
        flockType: 'Broiler',
        address: 'Pollachi, Tamil Nadu',
        lengthFt: 250,
        widthFt: 40,
        totalSqFt: 10000,
        createdAt: now,
        updatedAt: now,
      );

      final batch = BatchModel(
        id: 'batch_cobb500',
        farmId: 'farm_1',
        ownerId: 'u123',
        batchName: 'Cobb 500 Batch Alpha',
        breedOrFlockType: 'Cobb 500',
        maleCount: 5000,
        femaleCount: 5000,
        totalBirds: 10000,
        currentBirds: 9750,
        hatchDate: now.subtract(const Duration(days: 28)),
        placementDate: now.subtract(const Duration(days: 28)),
        status: 'active',
        createdAt: now,
        updatedAt: now,
      );

      final records = <DailyRecordModel>[
        DailyRecordModel(
          id: 'rec_day28',
          farmId: 'farm_1',
          batchId: 'batch_cobb500',
          recordDate: now,
          batchAgeDay: 28,
          openingBirds: 9760,
          mortalityCount: 10,
          cullCount: 0,
          adjustmentCount: 0,
          closingBirds: 9750,
          feedConsumedKg: 1250,
          waterConsumedLiters: 2600,
          avgWeightGrams: 1520,
          medicineGiven: true,
          vaccineGiven: false,
          ownerId: 'u123',
          temperature: 28.5,
          humidity: 62.0,
          weather: 'Humid & Sunny',
          notes: 'Flock lively, tunnel ventilation operational',
          createdAt: now,
          updatedAt: now,
        ),
      ];

      final vaccines = <VaccineRecordModel>[
        VaccineRecordModel(
          id: 'vac_1',
          farmId: 'farm_1',
          batchId: 'batch_cobb500',
          ownerId: 'u123',
          vaccineName: 'Gumboro (IBD) Intermediate',
          vaccineType: 'Live',
          batchAgeDay: 14,
          quantity: 10,
          unit: 'vials',
          route: 'Drinking Water',
          date: now.subtract(const Duration(days: 14)),
          createdAt: now,
          updatedAt: now,
        ),
      ];

      final medicines = <MedicineRecordModel>[
        MedicineRecordModel(
          id: 'med_1',
          farmId: 'farm_1',
          batchId: 'batch_cobb500',
          ownerId: 'u123',
          medicineName: 'Electrolytes & Vitamin C',
          batchAgeDay: 25,
          quantity: 2,
          unit: 'kg',
          date: now.subtract(const Duration(days: 3)),
          createdAt: now,
          updatedAt: now,
        ),
      ];

      final sheds = <ShedModel>[
        ShedModel(
          id: 'shed_1',
          farmId: 'farm_1',
          ownerId: 'u123',
          name: 'Broiler House 1',
          capacity: 10000,
          lengthFt: 400,
          widthFt: 50,
          totalSqFt: 20000,
          createdAt: now,
          updatedAt: now,
        ),
      ];

      final inventory = <InventoryItemModel>[
        InventoryItemModel(
          id: 'inv_feed',
          farmId: 'farm_1',
          ownerId: 'u123',
          itemName: 'Broiler Finisher Feed',
          category: 'Feed',
          brand: 'FeedCo',
          supplier: 'Tamil Agro',
          unit: 'bags',
          quantityAvailable: 4,
          minStockLevel: 10,
          purchaseDate: now,
          purchasePrice: 1850,
          storageLocation: 'Shed 1 Store',
          createdAt: now,
          updatedAt: now,
        ),
      ];

      final sales = <SalesRecordModel>[
        SalesRecordModel(
          id: 'sale_1',
          farmId: 'farm_1',
          batchId: 'batch_cobb500',
          ownerId: 'u123',
          date: now.subtract(const Duration(days: 1)),
          batchAgeDay: 28,
          customerName: 'Tamil Nadu Poultry Traders',
          birdsSold: 250,
          averageWeightKg: 1.52,
          pricePerBird: 167.2,
          totalValue: 41800,
          createdAt: now,
          updatedAt: now,
          notes: 'Early thinning sale',
        ),
      ];

      final reportData = ReportData(
        farm: farm1,
        batch: batch,
        farms: [farm1, farm2],
        batches: [batch],
        sheds: sheds,
        dailyRecords: records,
        feedTransactions: const [],
        medicineRecords: medicines,
        vaccineRecords: vaccines,
        birdSales: sales,
        inventoryItems: inventory,
        generatedAt: now,
      );

      final promptContext = AiContextBuilder.formatReportDataToPromptContext(reportData);

      // Verify all telemetry dimensions are rendered into prompt
      expect(promptContext.contains('Green Valley Facility'), isTrue);
      expect(promptContext.contains('Muthu Deenathayalan'), isTrue);
      expect(promptContext.contains('Highland Farm'), isTrue);
      expect(promptContext.contains('Cobb 500 Batch Alpha'), isTrue);
      expect(promptContext.contains('9750 birds'), isTrue);
      expect(promptContext.contains('28 Days') || promptContext.contains('Day 28'), isTrue);
      expect(promptContext.contains('1520g') || promptContext.contains('1520'), isTrue);
      expect(promptContext.contains('28.5°C'), isTrue);
      expect(promptContext.contains('62.0% RH') || promptContext.contains('62% RH'), isTrue);
      expect(promptContext.contains('Gumboro'), isTrue);
      expect(promptContext.contains('Electrolytes'), isTrue);
      expect(promptContext.contains('Broiler Finisher Feed'), isTrue);
      expect(promptContext.contains('Broiler House 1'), isTrue);
      expect(promptContext.contains('250 birds harvested and sold'), isTrue);
    });

    test('Live Gemini accurately analyzes Firebase telemetry values', () async {
      const liveSnapshot = '''=== FLOCKSENSE REAL-TIME FIREBASE FARM TELEMETRY ===
Farmer/Account: Muthu Deenathayalan
Active Farm: Green Valley Facility [Environment Controlled (EC)]
Active Batch/Flock: Cobb 500 Batch Alpha [Breed: Cobb 500, Status: active]
Flock Population: Initial Placed=10000 birds | Current Live=9750 birds | Mean Age=28 Days
Mortality Analytics: Cumulative Loss=250 birds (2.50% mortality rate | Liveability: 97.50% | Risk Level: Low)
Body Weight & Growth: Current Avg=1520g | Breed Standard=1475g (+45g ahead of standard) | ADG=54.3g/day
Feed & Water Efficiency: Total Feed Consumed=23500kg | Estimated FCR=1.58 | Daily Feed/Bird=128g | Total Water Intake=48000L
Recent Daily Telemetry Logs (from Firebase):
 - Day 28: Live=9750, Mort=10, Culls=0, Feed=1250kg, Water=2600L, AvgWt=1520g | Env: [Temp: 28.5°C, RH: 62% RH] | Notes: "Flock active"
=== END OF LIVE FIREBASE CONTEXT ===''';

      final response = await GeminiService.generateResponse(
        prompt: 'According to my Firebase telemetry, what is my flock age, current live bird count, and is my weight ahead or behind standard? Answer in 2 short sentences.',
        contextSnapshot: liveSnapshot,
      );

      expect(response.isNotEmpty, isTrue);
      // Gemini should recognize 28 days, 9,750 birds, and ahead of standard (+45g)
      final lower = response.toLowerCase();
      expect(lower.contains('28'), isTrue);
      expect(lower.contains('9,750') || lower.contains('9750'), isTrue);
      expect(lower.contains('ahead'), isTrue);
    });
  });
}
