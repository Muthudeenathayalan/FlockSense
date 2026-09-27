import 'package:flutter_test/flutter_test.dart';
import 'package:flock_sense/features/batches/domain/batch_model.dart';
import 'package:flock_sense/features/daily_records/domain/daily_record_model.dart';
import 'package:flock_sense/features/notifications/data/models/notification_model.dart';
import 'package:flock_sense/features/notifications/data/services/data_anomaly_detector_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DataAnomalyDetectorService Comprehensive Anomaly Tests', () {
    final now = DateTime.now();

    final testBatch = BatchModel(
      id: 'batch_test_anomaly',
      farmId: 'farm_01',
      ownerId: 'user_01',
      batchName: 'Broiler Batch Beta',
      breedOrFlockType: 'Cobb 500',
      maleCount: 1000,
      femaleCount: 1000,
      totalBirds: 2000,
      currentBirds: 2000,
      hatchDate: now.subtract(const Duration(days: 15)),
      placementDate: now.subtract(const Duration(days: 14)), // Day 15
      status: 'active',
      createdAt: now,
      updatedAt: now,
    );

    test('Normal healthy telemetry generates zero false anomaly alerts', () async {
      final healthyRecord = DailyRecordModel(
        id: 'rec_healthy',
        farmId: 'farm_01',
        batchId: 'batch_test_anomaly',
        recordDate: now,
        batchAgeDay: 15,
        openingBirds: 2000,
        mortalityCount: 1, // 0.05% - normal
        cullCount: 0,
        adjustmentCount: 0,
        closingBirds: 1999,
        feedConsumedKg: 150.0, // Healthy ~75g/bird for Day 15
        waterConsumedLiters: 270.0, // 1.8:1 ratio
        avgWeightGrams: 520.0, // on target for Day 15
        medicineGiven: false,
        vaccineGiven: false,
        ownerId: 'user_01',
        createdAt: now,
        updatedAt: now,
        temperature: 25.0, // optimal
        humidity: 60.0,
      );

      final alerts = await DataAnomalyDetectorService.detectAndDispatchAnomalies(
        record: healthyRecord,
        farmId: 'farm_01',
        batchId: 'batch_test_anomaly',
        batch: testBatch,
      );

      expect(alerts, isEmpty);
    });

    test('Detects mortality spike (>= 1% of flock) as critical alert', () async {
      final spikeRecord = DailyRecordModel(
        id: 'rec_mort_spike',
        farmId: 'farm_01',
        batchId: 'batch_test_anomaly',
        recordDate: now,
        batchAgeDay: 15,
        openingBirds: 2000,
        mortalityCount: 30, // 1.5% mortality in 1 day!
        cullCount: 0,
        adjustmentCount: 0,
        closingBirds: 1970,
        feedConsumedKg: 140.0,
        waterConsumedLiters: 260.0,
        avgWeightGrams: 510.0,
        medicineGiven: false,
        vaccineGiven: false,
        ownerId: 'user_01',
        createdAt: now,
        updatedAt: now,
      );

      final alerts = await DataAnomalyDetectorService.detectAndDispatchAnomalies(
        record: spikeRecord,
        farmId: 'farm_01',
        batchId: 'batch_test_anomaly',
        batch: testBatch,
      );

      expect(alerts.any((a) => a.metadata?['anomalyType'] == 'mortality_spike'), isTrue);
      final alert = alerts.firstWhere((a) => a.metadata?['anomalyType'] == 'mortality_spike');
      expect(alert.priority, NotificationPriority.critical);
      expect(alert.body, contains('30 birds died today'));
      expect(alert.metadata?['recommendations'], isNotEmpty);
    });

    test('Detects sudden mortality surge compared to prior day', () async {
      final prior = DailyRecordModel(
        id: 'rec_prior_mort',
        farmId: 'farm_01',
        batchId: 'batch_test_anomaly',
        recordDate: now.subtract(const Duration(days: 1)),
        batchAgeDay: 14,
        openingBirds: 2000,
        mortalityCount: 2,
        cullCount: 0,
        adjustmentCount: 0,
        closingBirds: 1998,
        feedConsumedKg: 135.0,
        waterConsumedLiters: 250.0,
        avgWeightGrams: 470.0,
        medicineGiven: false,
        vaccineGiven: false,
        ownerId: 'user_01',
        createdAt: now,
        updatedAt: now,
      );

      final current = DailyRecordModel(
        id: 'rec_jump_mort',
        farmId: 'farm_01',
        batchId: 'batch_test_anomaly',
        recordDate: now,
        batchAgeDay: 15,
        openingBirds: 1998,
        mortalityCount: 14, // jumped from 2 to 14 (+12 dead)
        cullCount: 0,
        adjustmentCount: 0,
        closingBirds: 1984,
        feedConsumedKg: 130.0,
        waterConsumedLiters: 240.0,
        avgWeightGrams: 510.0,
        medicineGiven: false,
        vaccineGiven: false,
        ownerId: 'user_01',
        createdAt: now,
        updatedAt: now,
      );

      final alerts = await DataAnomalyDetectorService.detectAndDispatchAnomalies(
        record: current,
        farmId: 'farm_01',
        batchId: 'batch_test_anomaly',
        batch: testBatch,
        previousRecord: prior,
      );

      expect(alerts.any((a) => a.title.contains('Mortality')), isTrue);
    });

    test('Detects acute feed intake drop (>= 20% drop vs yesterday)', () async {
      final prior = DailyRecordModel(
        id: 'rec_feed_prior',
        farmId: 'farm_01',
        batchId: 'batch_test_anomaly',
        recordDate: now.subtract(const Duration(days: 1)),
        batchAgeDay: 14,
        openingBirds: 2000,
        mortalityCount: 1,
        cullCount: 0,
        adjustmentCount: 0,
        closingBirds: 1999,
        feedConsumedKg: 150.0,
        waterConsumedLiters: 270.0,
        avgWeightGrams: 480.0,
        medicineGiven: false,
        vaccineGiven: false,
        ownerId: 'user_01',
        createdAt: now,
        updatedAt: now,
      );

      // Dropped from 150kg to 100kg (33.3% plunge)
      final current = DailyRecordModel(
        id: 'rec_feed_drop',
        farmId: 'farm_01',
        batchId: 'batch_test_anomaly',
        recordDate: now,
        batchAgeDay: 15,
        openingBirds: 1999,
        mortalityCount: 2,
        cullCount: 0,
        adjustmentCount: 0,
        closingBirds: 1997,
        feedConsumedKg: 100.0,
        waterConsumedLiters: 190.0,
        avgWeightGrams: 490.0,
        medicineGiven: false,
        vaccineGiven: false,
        ownerId: 'user_01',
        createdAt: now,
        updatedAt: now,
      );

      final alerts = await DataAnomalyDetectorService.detectAndDispatchAnomalies(
        record: current,
        farmId: 'farm_01',
        batchId: 'batch_test_anomaly',
        batch: testBatch,
        previousRecord: prior,
      );

      expect(alerts.any((a) => a.metadata?['anomalyType'] == 'feed_intake_drop'), isTrue);
      final feedAlert = alerts.firstWhere((a) => a.metadata?['anomalyType'] == 'feed_intake_drop');
      expect(feedAlert.priority, NotificationPriority.critical);
      expect(feedAlert.title, contains('Severe Feed Intake Drop'));
    });

    test('Detects severe water drop and abnormal water-to-feed ratio', () async {
      final prior = DailyRecordModel(
        id: 'rec_water_prior',
        farmId: 'farm_01',
        batchId: 'batch_test_anomaly',
        recordDate: now.subtract(const Duration(days: 1)),
        batchAgeDay: 14,
        openingBirds: 2000,
        mortalityCount: 0,
        cullCount: 0,
        adjustmentCount: 0,
        closingBirds: 2000,
        feedConsumedKg: 140.0,
        waterConsumedLiters: 260.0,
        avgWeightGrams: 470.0,
        medicineGiven: false,
        vaccineGiven: false,
        ownerId: 'user_01',
        createdAt: now,
        updatedAt: now,
      );

      // Water drops from 260L to 120L (water-to-feed ratio is 120 / 130 = 0.92:1)
      final current = DailyRecordModel(
        id: 'rec_water_drop',
        farmId: 'farm_01',
        batchId: 'batch_test_anomaly',
        recordDate: now,
        batchAgeDay: 15,
        openingBirds: 2000,
        mortalityCount: 1,
        cullCount: 0,
        adjustmentCount: 0,
        closingBirds: 1999,
        feedConsumedKg: 130.0,
        waterConsumedLiters: 120.0,
        avgWeightGrams: 500.0,
        medicineGiven: false,
        vaccineGiven: false,
        ownerId: 'user_01',
        createdAt: now,
        updatedAt: now,
      );

      final alerts = await DataAnomalyDetectorService.detectAndDispatchAnomalies(
        record: current,
        farmId: 'farm_01',
        batchId: 'batch_test_anomaly',
        batch: testBatch,
        previousRecord: prior,
      );

      expect(alerts.any((a) => a.metadata?['anomalyType'] == 'water_intake_drop'), isTrue);
      expect(alerts.any((a) => a.metadata?['anomalyType'] == 'water_ratio_low'), isTrue);
    });

    test('Detects heat stress emergency (THI >= 80, Temp 35°C)', () async {
      final heatRecord = DailyRecordModel(
        id: 'rec_heat_alert',
        farmId: 'farm_01',
        batchId: 'batch_test_anomaly',
        recordDate: now,
        batchAgeDay: 15,
        openingBirds: 2000,
        mortalityCount: 2,
        cullCount: 0,
        adjustmentCount: 0,
        closingBirds: 1998,
        feedConsumedKg: 130.0,
        waterConsumedLiters: 320.0,
        avgWeightGrams: 510.0,
        medicineGiven: false,
        vaccineGiven: false,
        ownerId: 'user_01',
        createdAt: now,
        updatedAt: now,
        temperature: 35.0,
        humidity: 78.0,
      );

      final alerts = await DataAnomalyDetectorService.detectAndDispatchAnomalies(
        record: heatRecord,
        farmId: 'farm_01',
        batchId: 'batch_test_anomaly',
        batch: testBatch,
      );

      expect(alerts.any((a) => a.metadata?['anomalyType'] == 'heat_stress_emergency'), isTrue);
      final heatAlert = alerts.firstWhere((a) => a.metadata?['anomalyType'] == 'heat_stress_emergency');
      expect(heatAlert.priority, NotificationPriority.critical);
      expect(heatAlert.title, contains('HEAT STRESS EMERGENCY'));
    });

    test('Detects brooding chick chilling emergency (Day 3, Temp 24°C)', () async {
      final youngBatch = BatchModel(
        id: 'batch_young',
        farmId: 'farm_01',
        ownerId: 'user_01',
        batchName: 'Young Chicks Batch',
        breedOrFlockType: 'Ross 308',
        maleCount: 1000,
        femaleCount: 1000,
        totalBirds: 2000,
        currentBirds: 2000,
        hatchDate: now.subtract(const Duration(days: 3)),
        placementDate: now.subtract(const Duration(days: 2)), // Day 3
        status: 'active',
        createdAt: now,
        updatedAt: now,
      );

      final coldRecord = DailyRecordModel(
        id: 'rec_cold_chick',
        farmId: 'farm_01',
        batchId: 'batch_young',
        recordDate: now,
        batchAgeDay: 3,
        openingBirds: 2000,
        mortalityCount: 1,
        cullCount: 0,
        adjustmentCount: 0,
        closingBirds: 1999,
        feedConsumedKg: 40.0,
        waterConsumedLiters: 70.0,
        avgWeightGrams: 85.0,
        medicineGiven: false,
        vaccineGiven: false,
        ownerId: 'user_01',
        createdAt: now,
        updatedAt: now,
        temperature: 24.0, // Chilling! (Target is 32-33°C)
        humidity: 60.0,
      );

      final alerts = await DataAnomalyDetectorService.detectAndDispatchAnomalies(
        record: coldRecord,
        farmId: 'farm_01',
        batchId: 'batch_young',
        batch: youngBatch,
      );

      expect(alerts.any((a) => a.metadata?['anomalyType'] == 'chick_chilling'), isTrue);
      final coldAlert = alerts.firstWhere((a) => a.metadata?['anomalyType'] == 'chick_chilling');
      expect(coldAlert.priority, NotificationPriority.critical);
      expect(coldAlert.title, contains('Chick Chilling Emergency'));
    });

    test('Detects weight loss and clinical symptoms logged by user', () async {
      final prior = DailyRecordModel(
        id: 'rec_wt_prior',
        farmId: 'farm_01',
        batchId: 'batch_test_anomaly',
        recordDate: now.subtract(const Duration(days: 1)),
        batchAgeDay: 14,
        openingBirds: 2000,
        mortalityCount: 0,
        cullCount: 0,
        adjustmentCount: 0,
        closingBirds: 2000,
        feedConsumedKg: 140.0,
        waterConsumedLiters: 250.0,
        avgWeightGrams: 520.0,
        medicineGiven: false,
        vaccineGiven: false,
        ownerId: 'user_01',
        createdAt: now,
        updatedAt: now,
      );

      // Weight lost from 520g down to 480g (-40g) and symptoms noted
      final current = DailyRecordModel(
        id: 'rec_symptoms_loss',
        farmId: 'farm_01',
        batchId: 'batch_test_anomaly',
        recordDate: now,
        batchAgeDay: 15,
        openingBirds: 2000,
        mortalityCount: 4,
        cullCount: 0,
        adjustmentCount: 0,
        closingBirds: 1996,
        feedConsumedKg: 110.0,
        waterConsumedLiters: 200.0,
        avgWeightGrams: 480.0, // Loss!
        medicineGiven: false,
        vaccineGiven: false,
        symptoms: 'Bloody droppings, lethargy, ruffled feathers',
        ownerId: 'user_01',
        createdAt: now,
        updatedAt: now,
      );

      final alerts = await DataAnomalyDetectorService.detectAndDispatchAnomalies(
        record: current,
        farmId: 'farm_01',
        batchId: 'batch_test_anomaly',
        batch: testBatch,
        previousRecord: prior,
      );

      expect(alerts.any((a) => a.metadata?['anomalyType'] == 'weight_loss'), isTrue);
      expect(alerts.any((a) => a.metadata?['anomalyType'] == 'symptoms_reported'), isTrue);
      final symAlert = alerts.firstWhere((a) => a.metadata?['anomalyType'] == 'symptoms_reported');
      expect(symAlert.priority, NotificationPriority.critical);
      expect(symAlert.body, contains('Bloody droppings'));
    });

    test('Detects generator low fuel emergency (dgLevelLiters <= 20L)', () async {
      final dgRecord = DailyRecordModel(
        id: 'rec_dg_fuel',
        farmId: 'farm_01',
        batchId: 'batch_test_anomaly',
        recordDate: now,
        batchAgeDay: 15,
        openingBirds: 2000,
        mortalityCount: 1,
        cullCount: 0,
        adjustmentCount: 0,
        closingBirds: 1999,
        feedConsumedKg: 140.0,
        waterConsumedLiters: 250.0,
        avgWeightGrams: 510.0,
        medicineGiven: false,
        vaccineGiven: false,
        dgLevelLiters: 12.0, // Low fuel alert!
        ownerId: 'user_01',
        createdAt: now,
        updatedAt: now,
      );

      final alerts = await DataAnomalyDetectorService.detectAndDispatchAnomalies(
        record: dgRecord,
        farmId: 'farm_01',
        batchId: 'batch_test_anomaly',
        batch: testBatch,
      );

      expect(alerts.any((a) => a.metadata?['anomalyType'] == 'low_dg_fuel'), isTrue);
      final dgAlert = alerts.firstWhere((a) => a.metadata?['anomalyType'] == 'low_dg_fuel');
      expect(dgAlert.priority, NotificationPriority.critical);
      expect(dgAlert.title, contains('Critical Generator Fuel Alert'));
    });
  });
}
