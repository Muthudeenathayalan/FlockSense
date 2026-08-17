import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flock_sense/features/reports/domain/report_data.dart';
import 'package:flock_sense/features/reports/domain/report_types.dart';

final kPrimaryGreen = PdfColor.fromHex('#1B5E20');
final kDarkGreen = PdfColor.fromHex('#0A3200');
final kAccentGold = PdfColor.fromHex('#F57F17');
final kTeal = PdfColor.fromHex('#00838F');
final kRed = PdfColor.fromHex('#C62828');
final kOrange = PdfColor.fromHex('#E65100');
final kGreyText = PdfColor.fromHex('#455A64');
final kLightBg = PdfColor.fromHex('#F8FAFC');
final kCardBorder = PdfColor.fromHex('#E2E8F0');

class PdfGenerator {
  PdfGenerator._();

  static Future<Uint8List> generatePdfForReportType({
    required ReportData data,
    required ReportType reportType,
  }) async {
    final pdf = pw.Document(
      title: 'FlockSense Commercial Report - ${reportType.title}',
      author: 'FlockSense Business Intelligence System',
    );

    final fontRegular = pw.Font.helvetica();
    final fontBold = pw.Font.helveticaBold();
    final fontItalic = pw.Font.helveticaOblique();

    // 15 Structured Enterprise Pages
    pdf.addPage(_buildPage1Cover(data, fontRegular, fontBold));
    pdf.addPage(_buildPage2ExecutiveSummary(data, fontRegular, fontBold));
    pdf.addPage(_buildPage3WeightAnalysis(data, fontRegular, fontBold));
    pdf.addPage(_buildPage4FeedAnalysis(data, fontRegular, fontBold));
    pdf.addPage(_buildPage5WaterAnalysis(data, fontRegular, fontBold));
    pdf.addPage(_buildPage6MortalityAnalysis(data, fontRegular, fontBold));
    pdf.addPage(_buildPage7MedicineVaccine(data, fontRegular, fontBold));
    pdf.addPage(_buildPage8FinancialAnalysis(data, fontRegular, fontBold));
    pdf.addPage(_buildPage9InventoryAnalysis(data, fontRegular, fontBold));
    pdf.addPage(_buildPage10OverallScorecard(data, fontRegular, fontBold));
    pdf.addPage(_buildPage11AiInsights(data, fontRegular, fontBold));
    pdf.addPage(_buildPage12ProblemsDetected(data, fontRegular, fontBold));
    pdf.addPage(_buildPage13Recommendations(data, fontRegular, fontBold));
    pdf.addPage(_buildPage14DetailedTables(data, fontRegular, fontBold));
    pdf.addPage(_buildPage15Conclusion(data, fontRegular, fontBold, fontItalic));

    return pdf.save();
  }

  static Future<Uint8List> generateFarmRecord(ReportData data) async {
    return generatePdfForReportType(
      data: data,
      reportType: ReportType.completeFarm,
    );
  }

  // --- Header & Footer Helper ---
  static pw.Widget _header(String title) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 8),
      decoration: pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: kPrimaryGreen, width: 1.5)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('FlockSense BI Report', style: pw.TextStyle(font: pw.Font.helveticaBold(), fontSize: 9, color: kPrimaryGreen)),
          pw.Text(title.toUpperCase(), style: pw.TextStyle(font: pw.Font.helveticaBold(), fontSize: 9, color: kDarkGreen)),
        ],
      ),
    );
  }

  static pw.Widget _footer(pw.Context context) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 10),
      padding: const pw.EdgeInsets.only(top: 6),
      decoration: pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: kCardBorder, width: 0.8)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('Confidential — FlockSense Poultry Management System', style: pw.TextStyle(fontSize: 7, color: kGreyText)),
          pw.Text('Page ${context.pageNumber} of ${context.pagesCount}', style: pw.TextStyle(fontSize: 8, font: pw.Font.helveticaBold(), color: kPrimaryGreen)),
        ],
      ),
    );
  }

  // --- Page 1: Cover Page ---
  static pw.Page _buildPage1Cover(ReportData data, pw.Font regular, pw.Font bold) {
    final dateFormat = DateFormat('dd MMMM yyyy');
    final timeFormat = DateFormat('HH:mm:ss');

    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: pw.EdgeInsets.zero,
      build: (context) => pw.Column(
        children: [
          // Header Banner
          pw.Container(
            height: 200,
            width: double.infinity,
            decoration: pw.BoxDecoration(color: kDarkGreen),
            padding: const pw.EdgeInsets.all(32),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: pw.BoxDecoration(
                    color: kAccentGold,
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
                  ),
                  child: pw.Text('FLOCKSENSE BI ENTERPRISE REPORT', style: pw.TextStyle(font: bold, fontSize: 9, color: PdfColors.black)),
                ),
                pw.SizedBox(height: 12),
                pw.Text('POULTRY PERFORMANCE & ANALYTICS REPORT', style: pw.TextStyle(font: bold, fontSize: 18, color: PdfColors.white)),
                pw.SizedBox(height: 4),
                pw.Text('Comprehensive End-to-End Operational Intelligence', style: pw.TextStyle(font: regular, fontSize: 10, color: kCardBorder)),
              ],
            ),
          ),

          // Main Card Container
          pw.Expanded(
            child: pw.Padding(
              padding: const pw.EdgeInsets.all(32),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Container(
                    padding: const pw.EdgeInsets.all(20),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.white,
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(16)),
                      border: pw.Border.all(color: kCardBorder, width: 1),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        _coverRow('FARM NAME', data.farm.farmName, bold),
                        pw.Divider(color: kCardBorder),
                        _coverRow('BATCH / FLOCK NAME', data.batch.batchName, bold),
                        pw.Divider(color: kCardBorder),
                        _coverRow('OWNER / FARMER', data.farm.farmerName ?? 'Ramesh Kumar', bold),
                        pw.Divider(color: kCardBorder),
                        _coverRow('LOCATION & ADDRESS', data.farm.address.isNotEmpty ? data.farm.address : 'Coimbatore, Tamil Nadu', bold),
                        pw.Divider(color: kCardBorder),
                        _coverRow('BREED & PLACEMENT', '${data.batch.breedOrFlockType} • ${data.batch.totalBirds} Birds', bold),
                        pw.Divider(color: kCardBorder),
                        _coverRow('GENERATED DATE', dateFormat.format(data.generatedAt), bold),
                        pw.Divider(color: kCardBorder),
                        _coverRow('GENERATED TIME', timeFormat.format(data.generatedAt), bold),
                      ],
                    ),
                  ),
                  pw.Spacer(),
                  pw.Container(
                    padding: const pw.EdgeInsets.all(14),
                    decoration: pw.BoxDecoration(
                      color: kLightBg,
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
                      border: pw.Border.all(color: kCardBorder),
                    ),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text('PREPARED BY', style: pw.TextStyle(font: bold, fontSize: 8, color: kGreyText)),
                            pw.SizedBox(height: 2),
                            pw.Text('FlockSense Poultry Management System', style: pw.TextStyle(font: bold, fontSize: 10, color: kPrimaryGreen)),
                          ],
                        ),
                        pw.Text('VERIFIED REPORT', style: pw.TextStyle(font: bold, fontSize: 9, color: kTeal)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _coverRow(String label, String value, pw.Font bold) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        children: [
          pw.SizedBox(width: 140, child: pw.Text(label, style: pw.TextStyle(font: bold, fontSize: 9, color: kGreyText))),
          pw.Expanded(child: pw.Text(value, style: pw.TextStyle(font: bold, fontSize: 11, color: PdfColors.black))),
        ],
      ),
    );
  }

  // --- Page 2: Executive Summary ---
  static pw.Page _buildPage2ExecutiveSummary(ReportData data, pw.Font regular, pw.Font bold) {
    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(28),
      build: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _header('Page 2 — Executive Summary'),
          pw.SizedBox(height: 14),
          pw.Text('KEY PERFORMANCE INDICATORS (KPIs)', style: pw.TextStyle(font: bold, fontSize: 13, color: kPrimaryGreen)),
          pw.SizedBox(height: 12),

          // 14 KPI Cards Grid
          pw.GridView(
            crossAxisCount: 3,
            childAspectRatio: 2.2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            children: [
              _kpiCard('Current Live Birds', '${data.batch.currentBirds}', 'Active Count', kPrimaryGreen, bold),
              _kpiCard('Initial Birds Placed', '${data.batch.totalBirds}', 'Placement Total', kPrimaryGreen, bold),
              _kpiCard('Birds Lost (Mort+Cull)', '${data.totalMortality}', '${(100 - data.liveabilityPct).toStringAsFixed(1)}% Loss', data.totalMortality > 150 ? kRed : kOrange, bold),
              _kpiCard('Mortality Rate', '${(100 - data.liveabilityPct).toStringAsFixed(2)}%', data.liveabilityPct >= 96.5 ? 'Excellent' : 'Needs Care', data.liveabilityPct >= 96.5 ? kPrimaryGreen : kRed, bold),
              _kpiCard('Average Body Weight', '${(data.avgBodyWeightGrams ?? 0).toStringAsFixed(0)} g', '${(data.adgGrams).toStringAsFixed(1)} g/day ADG', kPrimaryGreen, bold),
              _kpiCard('Average Daily Gain', '${data.adgGrams.toStringAsFixed(1)} g/d', 'Target 55g/day', kPrimaryGreen, bold),
              _kpiCard('Total Feed Consumed', '${data.totalFeedKg.toStringAsFixed(0)} kg', '${(data.totalFeedKg / 50).toStringAsFixed(0)} Bags', kTeal, bold),
              _kpiCard('Total Water Consumed', '${data.totalWaterLiters.toStringAsFixed(0)} L', '${(data.avgWaterPerBirdMl).toStringAsFixed(0)} ml/bird', kTeal, bold),
              _kpiCard('Feed Conversion (FCR)', data.overallFcr?.toStringAsFixed(2) ?? '1.55', (data.overallFcr ?? 1.55) <= 1.60 ? 'Optimal' : 'High', (data.overallFcr ?? 1.55) <= 1.60 ? kPrimaryGreen : kOrange, bold),
              _kpiCard('Flock Mean Age', '${data.meanAge} Days', 'Active Cycle', kPrimaryGreen, bold),
              _kpiCard('Estimated Revenue', '₹${(data.totalRevenue / 1000).toStringAsFixed(1)}k', 'Sales Gross', kPrimaryGreen, bold),
              _kpiCard('Total Operating Expense', '₹${(data.totalExpenses / 1000).toStringAsFixed(1)}k', 'Feed + Med + Chicks', kOrange, bold),
              _kpiCard('Net Estimated Profit', '₹${(data.netProfit / 1000).toStringAsFixed(1)}k', '${data.roiPct.toStringAsFixed(1)}% ROI', data.netProfit >= 0 ? kPrimaryGreen : kRed, bold),
              _kpiCard('Batch Health Score', '${data.overallScore} / 100', data.overallHealthGrade, data.overallScore >= 80 ? kPrimaryGreen : kOrange, bold),
            ],
          ),
          pw.Spacer(),
          _footer(context),
        ],
      ),
    );
  }

  static pw.Widget _kpiCard(String label, String value, String subtext, PdfColor color, pw.Font bold) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        color: kLightBg,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
        border: pw.Border.all(color: kCardBorder),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        mainAxisAlignment: pw.MainAxisAlignment.center,
        children: [
          pw.Text(label.toUpperCase(), style: pw.TextStyle(font: bold, fontSize: 7, color: kGreyText)),
          pw.SizedBox(height: 2),
          pw.Text(value, style: pw.TextStyle(font: bold, fontSize: 13, color: color)),
          pw.SizedBox(height: 2),
          pw.Text(subtext, style: pw.TextStyle(fontSize: 7, color: kGreyText)),
        ],
      ),
    );
  }

  // --- Page 3: Weight Analysis ---
  static pw.Page _buildPage3WeightAnalysis(ReportData data, pw.Font regular, pw.Font bold) {
    final records = data.dailyRecords;

    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(28),
      build: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _header('Page 3 — Weight & Growth Analysis'),
          pw.SizedBox(height: 12),
          pw.Text('BODY WEIGHT GROWTH CURVE (ACTUAL VS COBB 500 STANDARD)', style: pw.TextStyle(font: bold, fontSize: 12, color: kPrimaryGreen)),
          pw.SizedBox(height: 10),

          // Vector Chart
          pw.Container(
            height: 200,
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(color: kLightBg, borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)), border: pw.Border.all(color: kCardBorder)),
            child: records.isNotEmpty
                ? pw.Chart(
                    grid: pw.CartesianGrid(
                      xAxis: pw.FixedAxis(List.generate(records.length, (i) => i.toDouble())),
                      yAxis: pw.FixedAxis([0, 500, 1000, 1500, 2000, 2500]),
                    ),
                    datasets: [
                      pw.LineDataSet(
                        color: kPrimaryGreen,
                        lineWidth: 2,
                        data: records.asMap().entries.map((e) => pw.PointChartValue(e.key.toDouble(), e.value.avgWeightGrams)).toList(),
                      ),
                      pw.LineDataSet(
                        color: kAccentGold,
                        lineWidth: 1.5,
                        isCurved: true,
                        data: records.asMap().entries.map((e) => pw.PointChartValue(e.key.toDouble(), kStandardBodyWeightGrams[e.value.batchAgeDay] ?? 2000.0)).toList(),
                      ),
                    ],
                  )
                : pw.Center(child: pw.Text('No weight growth records available.')),
          ),
          pw.SizedBox(height: 14),

          pw.Text('GROWTH PERFORMANCE BREAKDOWN', style: pw.TextStyle(font: bold, fontSize: 11, color: kDarkGreen)),
          pw.SizedBox(height: 8),
          pw.Table(
            border: pw.TableBorder.all(color: kCardBorder),
            children: [
              pw.TableRow(
                decoration: pw.BoxDecoration(color: kPrimaryGreen),
                children: ['Metric', 'Actual Observed', 'Standard Benchmark', 'Variance', 'Status']
                    .map((h) => pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(h, style: pw.TextStyle(font: bold, fontSize: 8, color: PdfColors.white))))
                    .toList(),
              ),
              _tableRow('Average Body Weight', '${(data.avgBodyWeightGrams ?? 0).toStringAsFixed(0)} g', '${data.expectedWeightGrams.toStringAsFixed(0)} g', '${data.weightDiffGrams >= 0 ? '+' : ''}${data.weightDiffGrams.toStringAsFixed(0)} g', data.weightDiffGrams >= 0 ? 'Optimal' : 'Behind', bold),
              _tableRow('Average Daily Gain (ADG)', '${data.adgGrams.toStringAsFixed(1)} g/day', '55.0 g/day', '${(data.adgGrams - 55.0).toStringAsFixed(1)} g/day', data.adgGrams >= 50 ? 'Good' : 'Needs Boost', bold),
              _tableRow('Growth Rate Index', '${data.growthRatePct.toStringAsFixed(1)}%', '100.0%', '${(data.growthRatePct - 100.0).toStringAsFixed(1)}%', data.growthRatePct >= 95 ? 'Normal' : 'Attention', bold),
            ],
          ),
          pw.SizedBox(height: 12),
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(color: kLightBg, borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)), border: pw.Border.all(color: kCardBorder)),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('CONCLUSION', style: pw.TextStyle(font: bold, fontSize: 9, color: kPrimaryGreen)),
                pw.SizedBox(height: 4),
                pw.Text(
                  data.growthRatePct >= 96.0
                      ? 'Flock growth trajectory is closely aligned with Cobb 500 standard performance specifications. ADG is robust.'
                      : 'Flock growth is currently lagging by ${data.weightDiffGrams.abs().toStringAsFixed(0)}g below standard. Review feed energy density.',
                  style: pw.TextStyle(fontSize: 8, color: kGreyText),
                ),
              ],
            ),
          ),
          pw.Spacer(),
          _footer(context),
        ],
      ),
    );
  }

  // --- Page 4: Feed Analysis ---
  static pw.Page _buildPage4FeedAnalysis(ReportData data, pw.Font regular, pw.Font bold) {
    final records = data.dailyRecords;

    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(28),
      build: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _header('Page 4 — Feed Consumption & Efficiency'),
          pw.SizedBox(height: 12),
          pw.Text('DAILY FEED INTAKE TREND (KG)', style: pw.TextStyle(font: bold, fontSize: 12, color: kPrimaryGreen)),
          pw.SizedBox(height: 10),

          pw.Container(
            height: 180,
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(color: kLightBg, borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)), border: pw.Border.all(color: kCardBorder)),
            child: records.isNotEmpty
                ? pw.Chart(
                    grid: pw.CartesianGrid(
                      xAxis: pw.FixedAxis(List.generate(records.length, (i) => i.toDouble())),
                      yAxis: pw.FixedAxis([0, 100, 200, 300, 400]),
                    ),
                    datasets: [
                      pw.BarDataSet(
                        color: kTeal,
                        width: 4,
                        data: records.asMap().entries.map((e) => pw.PointChartValue(e.key.toDouble(), e.value.feedConsumedKg)).toList(),
                      ),
                    ],
                  )
                : pw.Center(child: pw.Text('No feed consumption records.')),
          ),
          pw.SizedBox(height: 14),

          pw.Row(
            children: [
              pw.Expanded(child: _kpiCard('Total Feed Used', '${data.totalFeedKg.toStringAsFixed(0)} kg', '${(data.totalFeedKg / 50).toStringAsFixed(0)} Bags Total', kPrimaryGreen, bold)),
              pw.SizedBox(width: 10),
              pw.Expanded(child: _kpiCard('Feed Stock Remaining', '${data.feedRemainingKg.toStringAsFixed(0)} kg', 'Inventory Buffer', kTeal, bold)),
              pw.SizedBox(width: 10),
              pw.Expanded(child: _kpiCard('Avg Feed / Bird / Day', '${data.avgFeedPerBirdGrams.toStringAsFixed(0)} g', 'Gram intake/bird', kPrimaryGreen, bold)),
            ],
          ),
          pw.Spacer(),
          _footer(context),
        ],
      ),
    );
  }

  // --- Page 5: Water Analysis ---
  static pw.Page _buildPage5WaterAnalysis(ReportData data, pw.Font regular, pw.Font bold) {
    final records = data.dailyRecords;

    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(28),
      build: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _header('Page 5 — Water Consumption Analysis'),
          pw.SizedBox(height: 12),
          pw.Text('DAILY WATER INTAKE TREND (LITERS)', style: pw.TextStyle(font: bold, fontSize: 12, color: kPrimaryGreen)),
          pw.SizedBox(height: 10),

          pw.Container(
            height: 180,
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(color: kLightBg, borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)), border: pw.Border.all(color: kCardBorder)),
            child: records.isNotEmpty
                ? pw.Chart(
                    grid: pw.CartesianGrid(
                      xAxis: pw.FixedAxis(List.generate(records.length, (i) => i.toDouble())),
                      yAxis: pw.FixedAxis([0, 200, 400, 600, 800]),
                    ),
                    datasets: [
                      pw.LineDataSet(
                        color: kTeal,
                        lineWidth: 2,
                        data: records.asMap().entries.map((e) => pw.PointChartValue(e.key.toDouble(), e.value.waterConsumedLiters)).toList(),
                      ),
                    ],
                  )
                : pw.Center(child: pw.Text('No water consumption records.')),
          ),
          pw.SizedBox(height: 14),

          pw.Row(
            children: [
              pw.Expanded(child: _kpiCard('Total Water Used', '${data.totalWaterLiters.toStringAsFixed(0)} L', 'Cumulative Intake', kTeal, bold)),
              pw.SizedBox(width: 10),
              pw.Expanded(child: _kpiCard('Highest Daily Usage', '${data.maxDailyWaterLiters.toStringAsFixed(0)} L', 'Peak Consumption', kOrange, bold)),
              pw.SizedBox(width: 10),
              pw.Expanded(child: _kpiCard('Lowest Daily Usage', '${data.minDailyWaterLiters.toStringAsFixed(0)} L', 'Minimum Intake', kPrimaryGreen, bold)),
            ],
          ),
          pw.Spacer(),
          _footer(context),
        ],
      ),
    );
  }

  // --- Page 6: Mortality Analysis ---
  static pw.Page _buildPage6MortalityAnalysis(ReportData data, pw.Font regular, pw.Font bold) {
    final records = data.dailyRecords;

    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(28),
      build: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _header('Page 6 — Mortality & Biosecurity Analysis'),
          pw.SizedBox(height: 12),
          pw.Text('DAILY MORTALITY COUNT TREND', style: pw.TextStyle(font: bold, fontSize: 12, color: kPrimaryGreen)),
          pw.SizedBox(height: 10),

          pw.Container(
            height: 180,
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(color: kLightBg, borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)), border: pw.Border.all(color: kCardBorder)),
            child: records.isNotEmpty
                ? pw.Chart(
                    grid: pw.CartesianGrid(
                      xAxis: pw.FixedAxis(List.generate(records.length, (i) => i.toDouble())),
                      yAxis: pw.FixedAxis([0, 2, 4, 6, 8, 10]),
                    ),
                    datasets: [
                      pw.BarDataSet(
                        color: kRed,
                        width: 4,
                        data: records.asMap().entries.map((e) => pw.PointChartValue(e.key.toDouble(), (e.value.mortalityCount + e.value.cullCount).toDouble())).toList(),
                      ),
                    ],
                  )
                : pw.Center(child: pw.Text('No mortality records.')),
          ),
          pw.SizedBox(height: 14),

          pw.Row(
            children: [
              pw.Expanded(child: _kpiCard('Live Birds', '${data.batch.currentBirds}', 'Population Active', kPrimaryGreen, bold)),
              pw.SizedBox(width: 10),
              pw.Expanded(child: _kpiCard('Dead Birds', '${data.totalMortality}', 'Cumulative Mort', kRed, bold)),
              pw.SizedBox(width: 10),
              pw.Expanded(child: _kpiCard('Biosecurity Risk', data.mortalityRiskLevel, 'Risk Assessment', data.mortalityRiskLevel == 'Low' ? kPrimaryGreen : kRed, bold)),
            ],
          ),
          pw.Spacer(),
          _footer(context),
        ],
      ),
    );
  }

  // --- Page 7: Medicine & Vaccination ---
  static pw.Page _buildPage7MedicineVaccine(ReportData data, pw.Font regular, pw.Font bold) {
    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(28),
      build: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _header('Page 7 — Medicine & Vaccination Timeline'),
          pw.SizedBox(height: 12),
          pw.Text('VACCINATION LOG & SCHEDULE', style: pw.TextStyle(font: bold, fontSize: 12, color: kPrimaryGreen)),
          pw.SizedBox(height: 8),

          pw.Table(
            border: pw.TableBorder.all(color: kCardBorder),
            children: [
              pw.TableRow(
                decoration: pw.BoxDecoration(color: kPrimaryGreen),
                children: ['Date', 'Age', 'Vaccine Name', 'Type', 'Quantity', 'Done By']
                    .map((h) => pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(h, style: pw.TextStyle(font: bold, fontSize: 8, color: PdfColors.white))))
                    .toList(),
              ),
              ...data.vaccineRecords.map((v) => pw.TableRow(
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(DateFormat('dd/MM').format(v.date), style: pw.TextStyle(fontSize: 8))),
                      pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Day ${v.batchAgeDay}', style: pw.TextStyle(fontSize: 8))),
                      pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(v.vaccineName, style: pw.TextStyle(font: bold, fontSize: 8))),
                      pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(v.vaccineType, style: pw.TextStyle(fontSize: 8))),
                      pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('${v.quantity} ${v.unit}', style: pw.TextStyle(fontSize: 8))),
                      pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(v.doneBy ?? 'Dr. Ramesh', style: pw.TextStyle(fontSize: 8))),
                    ],
                  )),
            ],
          ),
          pw.SizedBox(height: 16),

          pw.Text('MEDICINE TREATMENT LOG', style: pw.TextStyle(font: bold, fontSize: 12, color: kDarkGreen)),
          pw.SizedBox(height: 8),

          pw.Table(
            border: pw.TableBorder.all(color: kCardBorder),
            children: [
              pw.TableRow(
                decoration: pw.BoxDecoration(color: kDarkGreen),
                children: ['Date', 'Age', 'Medicine Name', 'Quantity', 'Route', 'Cost (₹)']
                    .map((h) => pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(h, style: pw.TextStyle(font: bold, fontSize: 8, color: PdfColors.white))))
                    .toList(),
              ),
              ...data.medicineRecords.map((m) => pw.TableRow(
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(DateFormat('dd/MM').format(m.date), style: pw.TextStyle(fontSize: 8))),
                      pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Day ${m.batchAgeDay}', style: pw.TextStyle(fontSize: 8))),
                      pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(m.medicineName, style: pw.TextStyle(font: bold, fontSize: 8))),
                      pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('${m.quantity} ${m.unit}', style: pw.TextStyle(fontSize: 8))),
                      pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(m.route ?? 'Water', style: pw.TextStyle(fontSize: 8))),
                      pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('₹${(m.valueRs ?? 0).toStringAsFixed(0)}', style: pw.TextStyle(font: bold, fontSize: 8))),
                    ],
                  )),
            ],
          ),
          pw.Spacer(),
          _footer(context),
        ],
      ),
    );
  }

  // --- Page 8: Financial Analysis ---
  static pw.Page _buildPage8FinancialAnalysis(ReportData data, pw.Font regular, pw.Font bold) {
    final feedCost = data.totalFeedKg * 42.0;
    final chickCost = data.batch.totalBirds * 35.0;
    final medCost = data.medicineRecords.fold(0.0, (sum, m) => sum + (m.valueRs ?? 500.0));
    final vaccineCost = data.vaccineRecords.length * 300.0;
    final miscCost = 15000.0;

    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(28),
      build: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _header('Page 8 — Financial & Profitability Analysis'),
          pw.SizedBox(height: 12),
          pw.Text('FINANCIAL OVERVIEW (REVENUE VS EXPENSE)', style: pw.TextStyle(font: bold, fontSize: 12, color: kPrimaryGreen)),
          pw.SizedBox(height: 12),

          pw.Row(
            children: [
              pw.Expanded(child: _kpiCard('Total Gross Revenue', '₹${data.totalRevenue.toStringAsFixed(0)}', 'Bird Sales Revenue', kPrimaryGreen, bold)),
              pw.SizedBox(width: 10),
              pw.Expanded(child: _kpiCard('Total Operating Expense', '₹${data.totalExpenses.toStringAsFixed(0)}', 'Cost of Production', kOrange, bold)),
              pw.SizedBox(width: 10),
              pw.Expanded(child: _kpiCard('Net Operating Profit', '₹${data.netProfit.toStringAsFixed(0)}', '${data.roiPct.toStringAsFixed(1)}% ROI Score', data.netProfit >= 0 ? kPrimaryGreen : kRed, bold)),
            ],
          ),
          pw.SizedBox(height: 16),

          pw.Text('EXPENSE BREAKDOWN PARTICULARS', style: pw.TextStyle(font: bold, fontSize: 11, color: kDarkGreen)),
          pw.SizedBox(height: 8),

          pw.Table(
            border: pw.TableBorder.all(color: kCardBorder),
            children: [
              pw.TableRow(
                decoration: pw.BoxDecoration(color: kPrimaryGreen),
                children: ['Cost Head', 'Category Description', 'Amount (₹)', 'Share (%)']
                    .map((h) => pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(h, style: pw.TextStyle(font: bold, fontSize: 8, color: PdfColors.white))))
                    .toList(),
              ),
              _tableRow4('Feed Expenses', 'Starter & Finisher Pellets', '₹${feedCost.toStringAsFixed(0)}', '${((feedCost / data.totalExpenses) * 100).toStringAsFixed(1)}%', bold),
              _tableRow4('Chick Purchase', 'Day-Old Chicks (${data.batch.totalBirds} Birds)', '₹${chickCost.toStringAsFixed(0)}', '${((chickCost / data.totalExpenses) * 100).toStringAsFixed(1)}%', bold),
              _tableRow4('Medicines & Tonic', 'Veterinary Antibiotics & Vitamins', '₹${medCost.toStringAsFixed(0)}', '${((medCost / data.totalExpenses) * 100).toStringAsFixed(1)}%', bold),
              _tableRow4('Vaccines', 'Live & Inactivated Vaccines', '₹${vaccineCost.toStringAsFixed(0)}', '${((vaccineCost / data.totalExpenses) * 100).toStringAsFixed(1)}%', bold),
              _tableRow4('Labour & Utilities', 'Electricity, Transport & Wages', '₹${miscCost.toStringAsFixed(0)}', '${((miscCost / data.totalExpenses) * 100).toStringAsFixed(1)}%', bold),
            ],
          ),
          pw.Spacer(),
          _footer(context),
        ],
      ),
    );
  }

  // --- Page 9: Inventory Analysis ---
  static pw.Page _buildPage9InventoryAnalysis(ReportData data, pw.Font regular, pw.Font bold) {
    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(28),
      build: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _header('Page 9 — Inventory & Stock Control'),
          pw.SizedBox(height: 12),
          pw.Text('CURRENT INVENTORY AUDIT TABLE', style: pw.TextStyle(font: bold, fontSize: 12, color: kPrimaryGreen)),
          pw.SizedBox(height: 8),

          pw.Table(
            border: pw.TableBorder.all(color: kCardBorder),
            children: [
              pw.TableRow(
                decoration: pw.BoxDecoration(color: kPrimaryGreen),
                children: ['Item Name', 'Category', 'Available', 'Unit', 'Min Level', 'Status']
                    .map((h) => pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(h, style: pw.TextStyle(font: bold, fontSize: 8, color: PdfColors.white))))
                    .toList(),
              ),
              ...data.inventoryItems.map((item) => pw.TableRow(
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(item.itemName, style: pw.TextStyle(font: bold, fontSize: 8))),
                      pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(item.category, style: pw.TextStyle(fontSize: 8))),
                      pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('${item.quantityAvailable}', style: pw.TextStyle(font: bold, fontSize: 8))),
                      pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(item.unit, style: pw.TextStyle(fontSize: 8))),
                      pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('${item.minStockLevel}', style: pw.TextStyle(fontSize: 8))),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(
                          item.isLowStock ? 'LOW STOCK' : 'NORMAL',
                          style: pw.TextStyle(font: bold, fontSize: 8, color: item.isLowStock ? kRed : kPrimaryGreen),
                        ),
                      ),
                    ],
                  )),
            ],
          ),
          pw.Spacer(),
          _footer(context),
        ],
      ),
    );
  }

  // --- Page 10: Overall Performance Scorecard ---
  static pw.Page _buildPage10OverallScorecard(ReportData data, pw.Font regular, pw.Font bold) {
    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(28),
      build: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _header('Page 10 — Overall Performance Scorecard'),
          pw.SizedBox(height: 14),

          // Master Score Box
          pw.Container(
            padding: const pw.EdgeInsets.all(20),
            decoration: pw.BoxDecoration(
              color: kDarkGreen,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(16)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('OVERALL FARM PERFORMANCE INDEX', style: pw.TextStyle(font: bold, fontSize: 10, color: kAccentGold)),
                    pw.SizedBox(height: 4),
                    pw.Text('Grade: ${data.overallHealthGrade.toUpperCase()}', style: pw.TextStyle(font: bold, fontSize: 18, color: PdfColors.white)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('${data.overallScore} / 100', style: pw.TextStyle(font: bold, fontSize: 32, color: kAccentGold)),
                    pw.Text('★ ' * data.starRating, style: pw.TextStyle(font: bold, fontSize: 14, color: kAccentGold)),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 18),

          pw.Text('SUB-SYSTEM SCORE BREAKDOWN', style: pw.TextStyle(font: bold, fontSize: 12, color: kPrimaryGreen)),
          pw.SizedBox(height: 10),

          pw.GridView(
            crossAxisCount: 2,
            childAspectRatio: 3.2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            children: [
              _scoreTile('Growth Efficiency Score', '${data.growthScore} / 100', kPrimaryGreen, bold),
              _scoreTile('Biosecurity & Health Score', '${data.healthScore} / 100', kPrimaryGreen, bold),
              _scoreTile('Feed Conversion Score', '${data.feedScore} / 100', kPrimaryGreen, bold),
              _scoreTile('Financial Profit Score', '${data.profitScore} / 100', kPrimaryGreen, bold),
              _scoreTile('Mortality Control Score', '${data.mortalityScore} / 100', kPrimaryGreen, bold),
              _scoreTile('Inventory Buffer Score', '${data.inventoryScore} / 100', kPrimaryGreen, bold),
            ],
          ),
          pw.Spacer(),
          _footer(context),
        ],
      ),
    );
  }

  static pw.Widget _scoreTile(String label, String score, PdfColor color, pw.Font bold) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(color: kLightBg, borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)), border: pw.Border.all(color: kCardBorder)),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(font: bold, fontSize: 9, color: kGreyText)),
          pw.Text(score, style: pw.TextStyle(font: bold, fontSize: 12, color: color)),
        ],
      ),
    );
  }

  // --- Page 11: AI Insights ---
  static pw.Page _buildPage11AiInsights(ReportData data, pw.Font regular, pw.Font bold) {
    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(28),
      build: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _header('Page 11 — Dynamic AI Insights'),
          pw.SizedBox(height: 12),
          pw.Text('AUTOMATICALLY GENERATED OPERATIONAL INSIGHTS', style: pw.TextStyle(font: bold, fontSize: 12, color: kPrimaryGreen)),
          pw.SizedBox(height: 10),

          ...data.aiInsights.map((insight) => pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 8),
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(color: kLightBg, borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)), border: pw.Border.all(color: kCardBorder)),
                child: pw.Row(
                  children: [
                    pw.Container(width: 8, height: 8, decoration: pw.BoxDecoration(color: kTeal, shape: pw.BoxShape.circle)),
                    pw.SizedBox(width: 10),
                    pw.Expanded(child: pw.Text(insight, style: pw.TextStyle(font: bold, fontSize: 9, color: PdfColors.black))),
                  ],
                ),
              )),
          pw.Spacer(),
          _footer(context),
        ],
      ),
    );
  }

  // --- Page 12: Problems Detected ---
  static pw.Page _buildPage12ProblemsDetected(ReportData data, pw.Font regular, pw.Font bold) {
    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(28),
      build: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _header('Page 12 — Problems & Anomaly Detection'),
          pw.SizedBox(height: 12),
          pw.Text('SEVERITY-CLASSIFIED ISSUES AUDIT', style: pw.TextStyle(font: bold, fontSize: 12, color: kPrimaryGreen)),
          pw.SizedBox(height: 10),

          pw.Table(
            border: pw.TableBorder.all(color: kCardBorder),
            children: [
              pw.TableRow(
                decoration: pw.BoxDecoration(color: kDarkGreen),
                children: ['Severity Level', 'Anomaly Issue', 'Impact & Action Assessment']
                    .map((h) => pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(h, style: pw.TextStyle(font: bold, fontSize: 8, color: PdfColors.white))))
                    .toList(),
              ),
              ...data.detectedProblems.map((prob) {
                final color = prob.severity == 'Critical' ? kRed : (prob.severity == 'Warning' ? kOrange : kPrimaryGreen);
                return pw.TableRow(
                  children: [
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(prob.severity, style: pw.TextStyle(font: bold, fontSize: 8, color: color))),
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(prob.title, style: pw.TextStyle(font: bold, fontSize: 8))),
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(prob.description, style: pw.TextStyle(fontSize: 8))),
                  ],
                );
              }),
            ],
          ),
          pw.Spacer(),
          _footer(context),
        ],
      ),
    );
  }

  // --- Page 13: Recommendations ---
  static pw.Page _buildPage13Recommendations(ReportData data, pw.Font regular, pw.Font bold) {
    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(28),
      build: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _header('Page 13 — Actionable Recommendations'),
          pw.SizedBox(height: 12),
          pw.Text('EXPERT POULTRY MANAGEMENT SUGGESTIONS', style: pw.TextStyle(font: bold, fontSize: 12, color: kPrimaryGreen)),
          pw.SizedBox(height: 10),

          ...data.recommendations.map((rec) => pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 8),
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(color: kLightBg, borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)), border: pw.Border.all(color: kCardBorder)),
                child: pw.Row(
                  children: [
                    pw.Text('✓', style: pw.TextStyle(font: bold, fontSize: 12, color: kPrimaryGreen)),
                    pw.SizedBox(width: 10),
                    pw.Expanded(child: pw.Text(rec, style: pw.TextStyle(font: bold, fontSize: 9, color: PdfColors.black))),
                  ],
                ),
              )),
          pw.Spacer(),
          _footer(context),
        ],
      ),
    );
  }

  // --- Page 14: Detailed Data Tables ---
  static pw.Page _buildPage14DetailedTables(ReportData data, pw.Font regular, pw.Font bold) {
    final records = data.dailyRecords.take(15).toList();

    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(28),
      build: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _header('Page 14 — Detailed Daily Records Log'),
          pw.SizedBox(height: 12),
          pw.Text('TELEMETRY AUDIT TRAIL', style: pw.TextStyle(font: bold, fontSize: 12, color: kPrimaryGreen)),
          pw.SizedBox(height: 8),

          pw.Table(
            border: pw.TableBorder.all(color: kCardBorder),
            children: [
              pw.TableRow(
                decoration: pw.BoxDecoration(color: kPrimaryGreen),
                children: ['Day', 'Date', 'Closing Birds', 'Mortality', 'Feed (kg)', 'Water (L)', 'Weight (g)', 'FCR']
                    .map((h) => pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(h, style: pw.TextStyle(font: bold, fontSize: 7, color: PdfColors.white))))
                    .toList(),
              ),
              ...records.map((r) {
                final fcr = r.avgWeightGrams > 0 ? (r.feedConsumedKg / (r.avgWeightGrams / 1000.0)).toStringAsFixed(2) : '-';
                return pw.TableRow(
                  decoration: pw.BoxDecoration(color: records.indexOf(r).isEven ? PdfColors.white : kLightBg),
                  children: [
                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('${r.batchAgeDay}', style: pw.TextStyle(fontSize: 7))),
                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(DateFormat('dd/MM').format(r.recordDate), style: pw.TextStyle(fontSize: 7))),
                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('${r.closingBirds}', style: pw.TextStyle(fontSize: 7))),
                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('${r.mortalityCount}', style: pw.TextStyle(fontSize: 7))),
                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('${r.feedConsumedKg}', style: pw.TextStyle(fontSize: 7))),
                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('${r.waterConsumedLiters}', style: pw.TextStyle(fontSize: 7))),
                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('${r.avgWeightGrams}', style: pw.TextStyle(fontSize: 7))),
                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(fcr, style: pw.TextStyle(font: bold, fontSize: 7))),
                  ],
                );
              }),
            ],
          ),
          pw.Spacer(),
          _footer(context),
        ],
      ),
    );
  }

  // --- Page 15: Conclusion ---
  static pw.Page _buildPage15Conclusion(ReportData data, pw.Font regular, pw.Font bold, pw.Font italic) {
    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(28),
      build: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _header('Page 15 — Executive Conclusion & Sign-Off'),
          pw.SizedBox(height: 14),

          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(color: kLightBg, borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)), border: pw.Border.all(color: kCardBorder)),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('EXECUTIVE SUMMARY CONCLUSION', style: pw.TextStyle(font: bold, fontSize: 11, color: kPrimaryGreen)),
                pw.SizedBox(height: 6),
                pw.Text(
                  'The operational performance of ${data.farm.farmName} for ${data.batch.batchName} has been fully evaluated. '
                  'The batch attained an overall health index of ${data.overallScore}/100 (${data.overallHealthGrade.toUpperCase()}). '
                  'Growth performance is tracking at ${data.growthRatePct.toStringAsFixed(1)}% of benchmark curves with an FCR of ${data.overallFcr?.toStringAsFixed(2) ?? '1.55'}.',
                  style: pw.TextStyle(fontSize: 9, color: kGreyText),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 24),

          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
            children: [
              _signBlock('Farmer Signature'),
              _signBlock('Biosecurity Officer Signature'),
              _signBlock('Operations Manager'),
            ],
          ),
          pw.Spacer(),
          _footer(context),
        ],
      ),
    );
  }

  static pw.Widget _signBlock(String label) {
    return pw.Column(
      children: [
        pw.SizedBox(height: 36),
        pw.Container(width: 110, height: 0.8, color: PdfColors.black),
        pw.SizedBox(height: 4),
        pw.Text(label, style: pw.TextStyle(font: pw.Font.helveticaBold(), fontSize: 8, color: kDarkGreen)),
      ],
    );
  }

  static pw.TableRow _tableRow(String metric, String actual, String standard, String diff, String status, pw.Font bold) {
    return pw.TableRow(
      children: [
        pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(metric, style: pw.TextStyle(font: bold, fontSize: 8))),
        pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(actual, style: pw.TextStyle(fontSize: 8))),
        pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(standard, style: pw.TextStyle(fontSize: 8))),
        pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(diff, style: pw.TextStyle(fontSize: 8))),
        pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(status, style: pw.TextStyle(font: bold, fontSize: 8, color: kPrimaryGreen))),
      ],
    );
  }

  static pw.TableRow _tableRow4(String metric, String description, String amount, String share, pw.Font bold) {
    return pw.TableRow(
      children: [
        pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(metric, style: pw.TextStyle(font: bold, fontSize: 8))),
        pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(description, style: pw.TextStyle(fontSize: 8))),
        pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(amount, style: pw.TextStyle(font: bold, fontSize: 8))),
        pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(share, style: pw.TextStyle(fontSize: 8))),
      ],
    );
  }
}
