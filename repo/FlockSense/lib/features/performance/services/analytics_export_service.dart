import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flock_sense/features/performance/domain/growth_analytics_model.dart';

class AnalyticsExportService {
  static final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');
  static final NumberFormat _currencyFormat = NumberFormat.currency(
    symbol: '₹',
    decimalDigits: 2,
    locale: 'en_IN',
  );

  /// Generates a PDF document for the growth analytics report
  static Future<pw.Document> generatePdfReport(GrowthAnalyticsData data) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => pw.Container(
          alignment: pw.Alignment.centerLeft,
          padding: const pw.EdgeInsets.only(bottom: 12),
          decoration: const pw.BoxDecoration(
            border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey400)),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'FlockSense — Growth Analytics & Telemetry Report',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.green900,
                ),
              ),
              pw.Text(
                _dateFormat.format(DateTime.now()),
                style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
              ),
            ],
          ),
        ),
        footer: (context) => pw.Container(
          alignment: pw.Alignment.centerRight,
          margin: const pw.EdgeInsets.only(top: 12),
          child: pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
          ),
        ),
        build: (context) => [
          pw.SizedBox(height: 12),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Batch: ${data.activeBatch?.batchName ?? "All Batches"}',
                      style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
                    ),
                    pw.Text(
                      'Farm: ${data.activeFarm?.farmName ?? "All Farms"}',
                      style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey800),
                    ),
                    pw.Text(
                      'Flock Type: ${data.activeBatch?.breedOrFlockType ?? "Broiler"}',
                      style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey800),
                    ),
                  ],
                ),
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text('Current Age: ${data.currentAgeDays} Days',
                      style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                  pw.Text(
                    'Harvest Date: ${data.expectedHarvestDate != null ? _dateFormat.format(data.expectedHarvestDate!) : "N/A"}',
                    style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey800),
                  ),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 20),

          pw.Text('Summary KPI Metrics',
              style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),

          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            children: [
              _buildTableRow('Metric', 'Value', isHeader: true),
              _buildTableRow('Current Birds', '${data.currentBirds}'),
              _buildTableRow('Initial Birds', '${data.initialBirds}'),
              _buildTableRow('Mortality Count', '${data.mortalityCount}'),
              _buildTableRow('Mortality %', '${data.mortalityPercentage.toStringAsFixed(2)}%'),
              _buildTableRow('Average Weight', '${data.avgWeightKg.toStringAsFixed(2)} kg'),
              _buildTableRow('Average Daily Gain (ADG)', '${data.avgDailyGainGrams.toStringAsFixed(1)} g/day'),
              _buildTableRow('Feed Consumed', '${data.feedConsumedKg.toStringAsFixed(1)} kg'),
              _buildTableRow('Water Consumed', '${data.waterConsumedLiters.toStringAsFixed(1)} L'),
              _buildTableRow('Feed Conversion Ratio (FCR)', data.fcr.toStringAsFixed(2)),
              _buildTableRow('Medicine Cost', _currencyFormat.format(data.medicineCost)),
              _buildTableRow('Total Expenses', _currencyFormat.format(data.totalExpenses)),
              _buildTableRow('Estimated Revenue', _currencyFormat.format(data.estimatedRevenue)),
              _buildTableRow('Estimated Profit', _currencyFormat.format(data.estimatedProfit)),
            ],
          ),

          pw.SizedBox(height: 20),
          pw.Text('Daily Records Breakdown',
              style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),

          if (data.filteredRecords.isEmpty)
            pw.Text('No daily records logged for selected filter range.',
                style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700))
          else
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    _cell('Date', isHeader: true),
                    _cell('Age', isHeader: true),
                    _cell('Mortality', isHeader: true),
                    _cell('Feed (kg)', isHeader: true),
                    _cell('Water (L)', isHeader: true),
                    _cell('Avg Wt (g)', isHeader: true),
                  ],
                ),
                ...data.filteredRecords.take(30).map(
                      (r) => pw.TableRow(
                        children: [
                          _cell(_dateFormat.format(r.recordDate)),
                          _cell('Day ${r.batchAgeDay}'),
                          _cell('${r.mortalityCount}'),
                          _cell(r.feedConsumedKg.toStringAsFixed(1)),
                          _cell(r.waterConsumedLiters.toStringAsFixed(1)),
                          _cell(r.avgWeightGrams.toStringAsFixed(0)),
                        ],
                      ),
                    ),
              ],
            ),

          if (data.aiInsights.isNotEmpty) ...[
            pw.SizedBox(height: 20),
            pw.Text('Telemetry Insights',
                style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            ...data.aiInsights.map(
              (insight) => pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 4),
                child: pw.Text('• $insight', style: const pw.TextStyle(fontSize: 10)),
              ),
            ),
          ],
        ],
      ),
    );

    return pdf;
  }

  static pw.TableRow _buildTableRow(String label, String value, {bool isHeader = false}) {
    return pw.TableRow(
      decoration: isHeader ? const pw.BoxDecoration(color: PdfColors.green100) : null,
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.all(6),
          child: pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(6),
          child: pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }

  static pw.Widget _cell(String text, {bool isHeader = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 9,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  /// Generates CSV report string
  static String generateCsvReport(GrowthAnalyticsData data) {
    final sb = StringBuffer();
    sb.writeln('FlockSense Growth Analytics Report');
    sb.writeln('Generated Date,${_dateFormat.format(DateTime.now())}');
    sb.writeln('Farm,${data.activeFarm?.farmName ?? "All Farms"}');
    sb.writeln('Batch,${data.activeBatch?.batchName ?? "All Batches"}');
    sb.writeln();

    sb.writeln('SUMMARY METRICS');
    sb.writeln('Metric,Value');
    sb.writeln('Initial Birds,${data.initialBirds}');
    sb.writeln('Current Birds,${data.currentBirds}');
    sb.writeln('Mortality Count,${data.mortalityCount}');
    sb.writeln('Mortality %,${data.mortalityPercentage.toStringAsFixed(2)}%');
    sb.writeln('Average Weight (kg),${data.avgWeightKg.toStringAsFixed(2)}');
    sb.writeln('ADG (g/day),${data.avgDailyGainGrams.toStringAsFixed(1)}');
    sb.writeln('Feed Consumed (kg),${data.feedConsumedKg.toStringAsFixed(1)}');
    sb.writeln('Water Consumed (L),${data.waterConsumedLiters.toStringAsFixed(1)}');
    sb.writeln('FCR,${data.fcr.toStringAsFixed(2)}');
    sb.writeln('Medicine Cost (INR),${data.medicineCost}');
    sb.writeln('Total Expenses (INR),${data.totalExpenses}');
    sb.writeln('Estimated Revenue (INR),${data.estimatedRevenue}');
    sb.writeln('Estimated Profit (INR),${data.estimatedProfit}');
    sb.writeln();

    sb.writeln('DAILY RECORDS TELEMETRY');
    sb.writeln('Date,Age (Days),Opening Birds,Mortality,Closing Birds,Feed Consumed (kg),Water Consumed (L),Avg Weight (g)');
    for (final r in data.filteredRecords) {
      sb.writeln(
        '${_dateFormat.format(r.recordDate)},${r.batchAgeDay},${r.openingBirds},${r.mortalityCount},${r.closingBirds},${r.feedConsumedKg},${r.waterConsumedLiters},${r.avgWeightGrams}',
      );
    }

    return sb.toString();
  }

  /// Print or open PDF print preview
  static Future<void> printOrPreviewPdf(BuildContext context, GrowthAnalyticsData data) async {
    final pdf = await generatePdfReport(data);
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'FlockSense_Growth_Analytics_${DateFormat("yyyyMMdd").format(DateTime.now())}.pdf',
    );
  }

  /// Share report via platform native share sheet
  static Future<void> shareReport(BuildContext context, GrowthAnalyticsData data) async {
    final pdf = await generatePdfReport(data);
    final bytes = await pdf.save();

    final tempDir = Directory.systemTemp;
    final file = File('${tempDir.path}/FlockSense_Analytics_${DateFormat("yyyyMMdd_HHmmss").format(DateTime.now())}.pdf');
    await file.writeAsBytes(bytes);

    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'application/pdf')],
      text: 'FlockSense Growth Analytics Report — ${data.activeBatch?.batchName ?? "All Batches"}',
    );
  }
}
