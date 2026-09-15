import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flock_sense/features/reports/data/batch_completion_report_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('BatchCompletionReportService Tests', () {
    test('isAutoDownloadEnabled returns null initially and responds to setAutoDownloadEnabled', () async {
      expect(await BatchCompletionReportService.isAutoDownloadEnabled(), isNull);

      await BatchCompletionReportService.setAutoDownloadEnabled(true);
      expect(await BatchCompletionReportService.isAutoDownloadEnabled(), isTrue);

      await BatchCompletionReportService.setAutoDownloadEnabled(false);
      expect(await BatchCompletionReportService.isAutoDownloadEnabled(), isFalse);
    });

    test('hasBatchReportBeenDownloaded tracks completed downloads cleanly', () async {
      const batchId = 'batch_harvest_99';
      expect(await BatchCompletionReportService.hasBatchReportBeenDownloaded(batchId), isFalse);

      await BatchCompletionReportService.markBatchReportDownloaded(batchId);
      expect(await BatchCompletionReportService.hasBatchReportBeenDownloaded(batchId), isTrue);

      // Verify idempotency
      await BatchCompletionReportService.markBatchReportDownloaded(batchId);
      expect(await BatchCompletionReportService.hasBatchReportBeenDownloaded(batchId), isTrue);
    });
  });
}
