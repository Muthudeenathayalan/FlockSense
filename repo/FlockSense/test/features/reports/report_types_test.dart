import 'package:flutter_test/flutter_test.dart';
import 'package:flock_sense/features/reports/domain/report_types.dart';

void main() {
  group('Report Types & Filter Tests', () {
    final now = DateTime(2026, 8, 27, 14, 30);

    test('validates date ranges correctly', () {
      final validFilter = ReportFilterState(
        datePreset: DateRangePreset.custom,
        customStartDate: DateTime(2026, 8, 1),
        customEndDate: DateTime(2026, 8, 20),
      );
      expect(validFilter.isValidDateRange, isTrue);

      final invalidFilter = ReportFilterState(
        datePreset: DateRangePreset.custom,
        customStartDate: DateTime(2026, 8, 25),
        customEndDate: DateTime(2026, 8, 10),
      );
      expect(invalidFilter.isValidDateRange, isFalse);

      final presetFilter = const ReportFilterState(
        datePreset: DateRangePreset.last30Days,
      );
      expect(presetFilter.isValidDateRange, isTrue);
    });

    test('generates sanitized and deterministic export file names', () {
      final fileName = ReportFilterState.formatExportFilename(
        reportTitle: 'Daily Performance & Growth',
        farmName: 'Shed 1 & 2 Farm',
        extension: 'pdf',
        timestamp: now,
      );

      expect(fileName, contains('daily_performance___growth'));
      expect(fileName, contains('shed_1___2_farm'));
      expect(fileName, endsWith('20260827_1430.pdf'));
    });

    test('serializes ReportHistoryItem to and from json', () {
      final item = ReportHistoryItem(
        id: 'hist-1',
        reportType: ReportType.growth,
        reportTitle: 'Growth Summary',
        farmName: 'Green Valley',
        batchName: 'Batch 101',
        format: ExportFormat.pdf,
        generatedAt: now,
        fileSizeKb: 245.5,
      );

      final json = item.toJson();
      expect(json['id'], 'hist-1');
      expect(json['reportType'], 'growth');
      expect(json['format'], 'pdf');

      final copy = ReportHistoryItem.fromJson(json);
      expect(copy.id, item.id);
      expect(copy.reportType, ReportType.growth);
      expect(copy.format, ExportFormat.pdf);
      expect(copy.fileSizeKb, 245.5);
    });
  });
}
