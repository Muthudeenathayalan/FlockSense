import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flock_sense/features/reports/data/csv_generator.dart';
import 'package:flock_sense/features/reports/data/excel_generator.dart';
import 'package:flock_sense/features/reports/data/pdf_generator.dart';
import 'package:flock_sense/features/reports/data/report_history_service.dart';
import 'package:flock_sense/features/reports/domain/report_data.dart';
import 'package:flock_sense/features/reports/domain/report_types.dart';

class ReportExportHandler {
  static Future<Uint8List> generateBytes({
    required ReportData data,
    required ReportType reportType,
    required ExportFormat format,
  }) async {
    switch (format) {
      case ExportFormat.pdf:
        return PdfGenerator.generatePdfForReportType(
          data: data,
          reportType: reportType,
        );
      case ExportFormat.excel:
        return ExcelGenerator.generateExcelReport(
          data: data,
          reportType: reportType,
        );
      case ExportFormat.csv:
        return CsvGenerator.generateCsvReport(
          data: data,
          reportType: reportType,
        );
    }
  }

  static Future<File> generateAndSaveFile({
    required ReportData data,
    required ReportType reportType,
    required ExportFormat format,
  }) async {
    final bytes = await generateBytes(
      data: data,
      reportType: reportType,
      format: format,
    );

    final dir = await getTemporaryDirectory();
    final sanitizedTitle = reportType.title.replaceAll(' ', '_').toLowerCase();
    final filename = 'flocksense_${sanitizedTitle}_${DateTime.now().millisecondsSinceEpoch}${format.extension}';
    final file = File('${dir.path}/$filename');
    await file.writeAsBytes(bytes, flush: true);

    // Save to history
    final historyItem = ReportHistoryItem(
      id: 'rep_${DateTime.now().millisecondsSinceEpoch}',
      reportType: reportType,
      reportTitle: reportType.title,
      farmName: data.farm.farmName,
      batchName: data.batch.batchName,
      format: format,
      generatedAt: DateTime.now(),
      fileSizeKb: (bytes.lengthInBytes / 1024.0),
      filePath: file.path,
    );

    await ReportHistoryService.saveHistoryItem(historyItem);

    return file;
  }

  static Future<void> shareReport({
    required ReportData data,
    required ReportType reportType,
    required ExportFormat format,
  }) async {
    final file = await generateAndSaveFile(
      data: data,
      reportType: reportType,
      format: format,
    );

    final xFile = XFile(
      file.path,
      name: file.path.split('/').last,
      mimeType: _getMimeType(format),
    );

    // ignore: deprecated_member_use
    await Share.shareXFiles(
      [xFile],
      text: 'FlockSense ${reportType.title} - ${data.farm.farmName}',
    );
  }

  static String _getMimeType(ExportFormat format) {
    switch (format) {
      case ExportFormat.pdf:
        return 'application/pdf';
      case ExportFormat.excel:
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case ExportFormat.csv:
        return 'text/csv';
    }
  }
}
