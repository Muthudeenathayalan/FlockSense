import 'package:flutter_test/flutter_test.dart';
import 'package:flock_sense/features/reports/data/report_service.dart';
import 'package:flock_sense/features/reports/data/report_history_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ReportService Authentic User Data Tests', () {
    test('getFallbackReportData returns clean empty model with zero synthetic items', () {
      final fallback = ReportService.getFallbackReportData();

      expect(fallback.farm.id, isEmpty);
      expect(fallback.farm.farmName, 'No Farm Selected');
      expect(fallback.batch.id, isEmpty);
      expect(fallback.batch.totalBirds, 0);
      expect(fallback.batch.currentBirds, 0);
      expect(fallback.farms, isEmpty);
      expect(fallback.batches, isEmpty);
      expect(fallback.sheds, isEmpty);
      expect(fallback.dailyRecords, isEmpty);
      expect(fallback.feedTransactions, isEmpty);
      expect(fallback.medicineRecords, isEmpty);
      expect(fallback.vaccineRecords, isEmpty);
      expect(fallback.birdSales, isEmpty);
      expect(fallback.inventoryItems, isEmpty);
      expect(fallback.totalMortality, 0);
      expect(fallback.totalFeedKg, 0.0);
      expect(fallback.totalBirdsSold, 0);
      expect(fallback.totalRevenue, 0.0);
    });

    test('ReportHistoryService returns empty list when no user history has been recorded', () async {
      final history = await ReportHistoryService.getHistory();
      expect(history, isEmpty);
    });
  });
}
