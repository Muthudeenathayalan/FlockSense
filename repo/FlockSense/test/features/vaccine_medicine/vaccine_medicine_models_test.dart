import 'package:flutter_test/flutter_test.dart';
import 'package:flock_sense/features/medicine/domain/medicine_record_model.dart';
import 'package:flock_sense/features/vaccine/domain/vaccine_record_model.dart';

void main() {
  group('Vaccine & Medicine Record Tests', () {
    final testDate = DateTime(2026, 1, 10);
    final placementDate = DateTime(2026, 1, 1);

    test('validates vaccine dose quantity and application date bounds', () {
      expect(VaccineRecordModel.isValidQuantity(1000.0), isTrue);
      expect(VaccineRecordModel.isValidQuantity(0.0), isFalse);
      expect(VaccineRecordModel.isValidQuantity(-5.0), isFalse);

      expect(
        VaccineRecordModel.isValidApplicationDate(
          applicationDate: DateTime(2026, 1, 7),
          batchPlacementDate: placementDate,
        ),
        isTrue,
      );

      // Application date prior to placement date is invalid
      expect(
        VaccineRecordModel.isValidApplicationDate(
          applicationDate: DateTime(2025, 12, 25),
          batchPlacementDate: placementDate,
        ),
        isFalse,
      );
    });

    test('validates medicine dosage and financial value', () {
      expect(MedicineRecordModel.isValidQuantity(250.0), isTrue);
      expect(MedicineRecordModel.isValidQuantity(0.0), isFalse);
      expect(MedicineRecordModel.isValidQuantity(-10.0), isFalse);

      expect(MedicineRecordModel.isValidValue(1500.0), isTrue);
      expect(MedicineRecordModel.isValidValue(null), isTrue);
      expect(MedicineRecordModel.isValidValue(-50.0), isFalse);
    });

    test('serializes VaccineRecordModel round trip', () {
      final record = VaccineRecordModel(
        id: 'vac-1',
        farmId: 'f-1',
        batchId: 'b-1',
        ownerId: 'u-1',
        createdAt: testDate,
        updatedAt: testDate,
        date: testDate,
        batchAgeDay: 7,
        vaccineName: 'Lasota (ND + IB)',
        vaccineType: 'Live',
        batchNumber: 'LOT-9921',
        quantity: 5000,
        unit: 'Doses',
        route: 'Eye Drop',
        doneBy: 'Dr. Ramesh',
      );

      final json = record.toJson();
      expect(json['id'], 'vac-1');
      expect(json['vaccineName'], 'Lasota (ND + IB)');
      expect(json['batchAgeDay'], 7);

      final copy = VaccineRecordModel.fromJson(json);
      expect(copy.id, record.id);
      expect(copy.vaccineName, record.vaccineName);
      expect(copy.quantity, 5000.0);
    });

    test('serializes MedicineRecordModel round trip', () {
      final record = MedicineRecordModel(
        id: 'med-1',
        farmId: 'f-1',
        batchId: 'b-1',
        ownerId: 'u-1',
        createdAt: testDate,
        updatedAt: testDate,
        date: testDate,
        batchAgeDay: 12,
        medicineName: 'Enrofloxacin 10%',
        quantity: 500.0,
        unit: 'ml',
        valueRs: 850.0,
        route: 'Drinking Water',
      );

      final json = record.toJson();
      expect(json['id'], 'med-1');
      expect(json['medicineName'], 'Enrofloxacin 10%');

      final copy = MedicineRecordModel.fromJson(json);
      expect(copy.id, record.id);
      expect(copy.medicineName, record.medicineName);
      expect(copy.valueRs, 850.0);
    });
  });
}
