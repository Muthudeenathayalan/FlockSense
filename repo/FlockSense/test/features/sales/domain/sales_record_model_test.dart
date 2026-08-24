import 'package:flutter_test/flutter_test.dart';
import 'package:flock_sense/features/sales/domain/sales_record_model.dart';

void main() {
  group('SalesRecordModel Tests', () {
    final recordDate = DateTime(2026, 8, 22);

    test('constructs and serializes correctly', () {
      final sale = SalesRecordModel(
        id: 'sale-001',
        farmId: 'farm-01',
        batchId: 'batch-01',
        ownerId: 'user-01',
        createdAt: recordDate,
        updatedAt: recordDate,
        date: recordDate,
        batchAgeDay: 38,
        customerName: 'Premium Poultry Wholesalers',
        birdsSold: 2500,
        averageWeightKg: 2.35,
        pricePerBird: 195.0,
        totalValue: 487500.0,
        vehicleNumber: 'TN-01-AB-1234',
        notes: 'First lift of the batch',
      );

      expect(sale.birdsSold, 2500);
      expect(sale.totalValue, 487500.0);
      expect(sale.customerName, 'Premium Poultry Wholesalers');

      final json = sale.toJson();
      expect(json['id'], 'sale-001');
      expect(json['batchAgeDay'], 38);
      expect(json['vehicleNumber'], 'TN-01-AB-1234');
    });

    test('parses from JSON with string and number representations', () {
      final json = {
        'id': 'sale-002',
        'farmId': 'farm-01',
        'batchId': 'batch-01',
        'ownerId': 'user-01',
        'createdAt': '2026-08-22T10:00:00.000Z',
        'updatedAt': '2026-08-22T10:00:00.000Z',
        'date': '2026-08-22T10:00:00.000Z',
        'batchAgeDay': '39',
        'customerName': 'Local Market',
        'birdsSold': '1000',
        'averageWeightKg': '2.4',
        'pricePerBird': '200',
        'totalValue': '200000',
      };

      final sale = SalesRecordModel.fromJson(json);
      expect(sale.batchAgeDay, 39);
      expect(sale.birdsSold, 1000);
      expect(sale.averageWeightKg, 2.4);
      expect(sale.totalValue, 200000.0);
    });
  });
}
