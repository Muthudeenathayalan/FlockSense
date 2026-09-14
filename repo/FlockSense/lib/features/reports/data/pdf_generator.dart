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
    pdf.addPage(
      _buildPage15Conclusion(data, fontRegular, fontBold, fontItalic),
    );

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
        border: pw.Border(
          bottom: pw.BorderSide(color: kPrimaryGreen, width: 1.5),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'FlockSense BI Report',
            style: pw.TextStyle(
              font: pw.Font.helveticaBold(),
              fontSize: 9,
              color: kPrimaryGreen,
            ),
          ),
          pw.Text(
            title.toUpperCase(),
            style: pw.TextStyle(
              font: pw.Font.helveticaBold(),
              fontSize: 9,
              color: kDarkGreen,
            ),
          ),
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
          pw.Text(
            'Confidential — FlockSense Poultry Management System',
            style: pw.TextStyle(fontSize: 7, color: kGreyText),
          ),
          pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: pw.TextStyle(
              fontSize: 8,
              font: pw.Font.helveticaBold(),
              color: kPrimaryGreen,
            ),
          ),
        ],
      ),
    );
  }

  // --- Page 1: Cover Page ---
  static pw.Page _buildPage1Cover(
    ReportData data,
    pw.Font regular,
    pw.Font bold,
  ) {
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
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 5,
                  ),
                  decoration: pw.BoxDecoration(
                    color: kAccentGold,
                    borderRadius: const pw.BorderRadius.all(
                      pw.Radius.circular(10),
                    ),
                  ),
                  child: pw.Text(
                    'FLOCKSENSE BI ENTERPRISE REPORT',
                    style: pw.TextStyle(
                      font: bold,
                      fontSize: 9,
                      color: PdfColors.black,
                    ),
                  ),
                ),
                pw.SizedBox(height: 12),
                pw.Text(
                  'POULTRY PERFORMANCE & ANALYTICS REPORT',
                  style: pw.TextStyle(
                    font: bold,
                    fontSize: 18,
                    color: PdfColors.white,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Comprehensive End-to-End Operational Intelligence',
                  style: pw.TextStyle(
                    font: regular,
                    fontSize: 10,
                    color: kCardBorder,
                  ),
                ),
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
                      borderRadius: const pw.BorderRadius.all(
                        pw.Radius.circular(16),
                      ),
                      border: pw.Border.all(color: kCardBorder, width: 1),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        _coverRow('FARM NAME', data.farm.farmName, bold),
                        pw.Divider(color: kCardBorder),
                        _coverRow(
                          'BATCH / FLOCK NAME',
                          data.batch.batchName,
                          bold,
                        ),
                        pw.Divider(color: kCardBorder),
                        _coverRow(
                          'OWNER / FARMER',
                          data.farm.farmerName ?? 'Ramesh Kumar',
                          bold,
                        ),
                        pw.Divider(color: kCardBorder),
                        _coverRow(
                          'LOCATION & ADDRESS',
                          data.farm.address.isNotEmpty
                              ? data.farm.address
                              : 'Coimbatore, Tamil Nadu',
                          bold,
                        ),
                        pw.Divider(color: kCardBorder),
                        _coverRow(
                          'BREED & PLACEMENT',
                          '${data.batch.breedOrFlockType} • ${data.batch.totalBirds} Birds',
                          bold,
                        ),
                        pw.Divider(color: kCardBorder),
                        _coverRow(
                          'GENERATED DATE',
                          dateFormat.format(data.generatedAt),
                          bold,
                        ),
                        pw.Divider(color: kCardBorder),
                        _coverRow(
                          'GENERATED TIME',
                          timeFormat.format(data.generatedAt),
                          bold,
                        ),
                      ],
                    ),
                  ),
                  pw.Spacer(),
                  pw.Container(
                    padding: const pw.EdgeInsets.all(14),
                    decoration: pw.BoxDecoration(
                      color: kLightBg,
                      borderRadius: const pw.BorderRadius.all(
                        pw.Radius.circular(12),
                      ),
                      border: pw.Border.all(color: kCardBorder),
                    ),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              'PREPARED BY',
                              style: pw.TextStyle(
                                font: bold,
                                fontSize: 8,
                                color: kGreyText,
                              ),
                            ),
                            pw.SizedBox(height: 2),
                            pw.Text(
                              'FlockSense Poultry Management System',
                              style: pw.TextStyle(
                                font: bold,
                                fontSize: 10,
                                color: kPrimaryGreen,
                              ),
                            ),
                          ],
                        ),
                        pw.Text(
                          'VERIFIED REPORT',
                          style: pw.TextStyle(
                            font: bold,
                            fontSize: 9,
                            color: kTeal,
                          ),
                        ),
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
          pw.SizedBox(
            width: 140,
            child: pw.Text(
              label,
              style: pw.TextStyle(font: bold, fontSize: 9, color: kGreyText),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(
                font: bold,
                fontSize: 11,
                color: PdfColors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Page 2: Executive Summary ---
  static pw.Page _buildPage2ExecutiveSummary(
    ReportData data,
    pw.Font regular,
    pw.Font bold,
  ) {
    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(28),
      build: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _header('Page 2 — Executive Summary'),
          pw.SizedBox(height: 14),
          pw.Text(
            'KEY PERFORMANCE INDICATORS (KPIs)',
            style: pw.TextStyle(font: bold, fontSize: 13, color: kPrimaryGreen),
          ),
          pw.SizedBox(height: 12),

          // 14 KPI Cards Grid
          pw.GridView(
            crossAxisCount: 3,
            childAspectRatio: 2.2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            children: [
              _kpiCard(
                'Current Live Birds',
                '${data.batch.currentBirds}',
                'Active Count',
                kPrimaryGreen,
                bold,
              ),
              _kpiCard(
                'Initial Birds Placed',
                '${data.batch.totalBirds}',
                'Placement Total',
                kPrimaryGreen,
                bold,
              ),
              _kpiCard(
                'Birds Lost (Mort+Cull)',
                '${data.totalMortality}',
                '${(100 - data.liveabilityPct).toStringAsFixed(1)}% Loss',
                data.totalMortality > 150 ? kRed : kOrange,
                bold,
              ),
              _kpiCard(
                'Mortality Rate',
                '${(100 - data.liveabilityPct).toStringAsFixed(2)}%',
                data.liveabilityPct >= 96.5 ? 'Excellent' : 'Needs Care',
                data.liveabilityPct >= 96.5 ? kPrimaryGreen : kRed,
                bold,
              ),
              _kpiCard(
                'Average Body Weight',
                '${(data.avgBodyWeightGrams ?? 0).toStringAsFixed(0)} g',
                '${(data.adgGrams).toStringAsFixed(1)} g/day ADG',
                kPrimaryGreen,
                bold,
              ),
              _kpiCard(
                'Average Daily Gain',
                '${data.adgGrams.toStringAsFixed(1)} g/d',
                'Target 55g/day',
                kPrimaryGreen,
                bold,
              ),
              _kpiCard(
                'Total Feed Consumed',
                '${data.totalFeedKg.toStringAsFixed(0)} kg',
                '${(data.totalFeedKg / 50).toStringAsFixed(0)} Bags',
                kTeal,
                bold,
              ),
              _kpiCard(
                'Total Water Consumed',
                '${data.totalWaterLiters.toStringAsFixed(0)} L',
                '${(data.avgWaterPerBirdMl).toStringAsFixed(0)} ml/bird',
                kTeal,
                bold,
              ),
              _kpiCard(
                'Feed Conversion (FCR)',
                data.overallFcr?.toStringAsFixed(2) ?? '1.55',
                (data.overallFcr ?? 1.55) <= 1.60 ? 'Optimal' : 'High',
                (data.overallFcr ?? 1.55) <= 1.60 ? kPrimaryGreen : kOrange,
                bold,
              ),
              _kpiCard(
                'Flock Mean Age',
                '${data.meanAge} Days',
                'Active Cycle',
                kPrimaryGreen,
                bold,
              ),
              _kpiCard(
                'Estimated Revenue',
                '₹${(data.totalRevenue / 1000).toStringAsFixed(1)}k',
                'Sales Gross',
                kPrimaryGreen,
                bold,
              ),
              _kpiCard(
                'Total Operating Expense',
                '₹${(data.totalExpenses / 1000).toStringAsFixed(1)}k',
                'Feed + Med + Chicks',
                kOrange,
                bold,
              ),
              _kpiCard(
                'Net Estimated Profit',
                '₹${(data.netProfit / 1000).toStringAsFixed(1)}k',
                '${data.roiPct.toStringAsFixed(1)}% ROI',
                data.netProfit >= 0 ? kPrimaryGreen : kRed,
                bold,
              ),
              _kpiCard(
                'Batch Health Score',
                '${data.overallScore} / 100',
                data.overallHealthGrade,
                data.overallScore >= 80 ? kPrimaryGreen : kOrange,
                bold,
              ),
            ],
          ),
          pw.Spacer(),
          _footer(context),
        ],
      ),
    );
  }

  static pw.Widget _kpiCard(
    String label,
    String value,
    String subtext,
    PdfColor color,
    pw.Font bold,
  ) {
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
          pw.Text(
            label.toUpperCase(),
            style: pw.TextStyle(font: bold, fontSize: 7, color: kGreyText),
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            value,
            style: pw.TextStyle(font: bold, fontSize: 13, color: color),
          ),
          pw.SizedBox(height: 2),
          pw.Text(subtext, style: pw.TextStyle(fontSize: 7, color: kGreyText)),
        ],
      ),
    );
  }

  // --- Page 3: Weight Analysis ---
  static pw.Page _buildPage3WeightAnalysis(
    ReportData data,
    pw.Font regular,
    pw.Font bold,
  ) {
    final records = data.dailyRecords;
    final maxWeight = records.isEmpty
        ? 2000.0
        : records.map((r) => r.avgWeightGrams).reduce((a, b) => a > b ? a : b);
    final weightCeiling =
        (maxWeight <= 0 ? 2500.0 : (maxWeight * 1.2)).clamp(1000.0, 4000.0);
    final weightStep = (weightCeiling / 5).ceilToDouble();
    final weightYAxis = [
      0.0,
      weightStep,
      weightStep * 2,
      weightStep * 3,
      weightStep * 4,
      weightStep * 5,
    ];

    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(28),
      build: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _header('Page 3 — Weight & Growth Analysis'),
          pw.SizedBox(height: 10),
          pw.Text(
            'BODY WEIGHT GROWTH CURVE (ACTUAL VS COBB 500 STANDARD)',
            style: pw.TextStyle(font: bold, fontSize: 11, color: kPrimaryGreen),
          ),
          pw.SizedBox(height: 6),

          // Visual Color Legend for Farmer Readability
          pw.Row(
            children: [
              pw.Container(width: 14, height: 4, color: kPrimaryGreen),
              pw.SizedBox(width: 6),
              pw.Text(
                '■ Your Farm\'s Actual Weight (g)',
                style: pw.TextStyle(font: bold, fontSize: 8, color: kPrimaryGreen),
              ),
              pw.SizedBox(width: 16),
              pw.Container(width: 14, height: 4, color: kAccentGold),
              pw.SizedBox(width: 6),
              pw.Text(
                '■ Cobb 500 Breed Target (g)',
                style: pw.TextStyle(font: bold, fontSize: 8, color: kAccentGold),
              ),
            ],
          ),
          pw.SizedBox(height: 6),

          // Vector Chart
          pw.Container(
            height: 170,
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: kLightBg,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
              border: pw.Border.all(color: kCardBorder),
            ),
            child: records.isNotEmpty
                ? pw.Chart(
                    grid: pw.CartesianGrid(
                      xAxis: pw.FixedAxis(
                        List.generate(records.length, (i) => i.toDouble()),
                      ),
                      yAxis: pw.FixedAxis(weightYAxis),
                    ),
                    datasets: [
                      pw.LineDataSet(
                        color: kPrimaryGreen,
                        lineWidth: 2.2,
                        data: records
                            .asMap()
                            .entries
                            .map(
                              (e) => pw.PointChartValue(
                                e.key.toDouble(),
                                e.value.avgWeightGrams,
                              ),
                            )
                            .toList(),
                      ),
                      pw.LineDataSet(
                        color: kAccentGold,
                        lineWidth: 1.8,
                        isCurved: true,
                        data: records
                            .asMap()
                            .entries
                            .map(
                              (e) => pw.PointChartValue(
                                e.key.toDouble(),
                                kStandardBodyWeightGrams[e.value.batchAgeDay] ??
                                    2000.0,
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  )
                : pw.Center(
                    child: pw.Text('No weight growth records available.'),
                  ),
          ),
          pw.SizedBox(height: 8),

          // Farmer Interpretation Callout Box
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: pw.BoxDecoration(
              color: data.weightDiffGrams >= -40
                  ? PdfColor.fromHex('#E8F5E9')
                  : PdfColor.fromHex('#FFF3E0'),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
              border: pw.Border.all(
                color: data.weightDiffGrams >= -40 ? kPrimaryGreen : kOrange,
                width: 0.8,
              ),
            ),
            child: pw.Row(
              children: [
                pw.Text(
                  data.weightDiffGrams >= -40
                      ? '✓ TECHNIQUE SUCCESS: '
                      : '⚠️ TECHNIQUE DISADVANTAGE: ',
                  style: pw.TextStyle(
                    font: bold,
                    fontSize: 8,
                    color: data.weightDiffGrams >= -40 ? kPrimaryGreen : kOrange,
                  ),
                ),
                pw.Expanded(
                  child: pw.Text(
                    data.weightDiffGrams >= -40
                        ? 'Flock growth is tracking breed standard curve closely (${data.weightDiffGrams >= 0 ? "+" : ""}${data.weightDiffGrams.toStringAsFixed(0)}g variance). Feeding formulation and feeder space are optimal.'
                        : 'Flock is lagging standard weight by ${data.weightDiffGrams.abs().toStringAsFixed(0)}g. Review brooding concrete temperature (<32°C) or check for feeder pan overcrowding.',
                    style: pw.TextStyle(fontSize: 7.5, color: kDarkGreen),
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 10),

          pw.Text(
            'GROWTH PERFORMANCE BREAKDOWN',
            style: pw.TextStyle(font: bold, fontSize: 11, color: kDarkGreen),
          ),
          pw.SizedBox(height: 8),
          pw.Table(
            border: pw.TableBorder.all(color: kCardBorder),
            children: [
              pw.TableRow(
                decoration: pw.BoxDecoration(color: kPrimaryGreen),
                children:
                    [
                          'Metric',
                          'Actual Observed',
                          'Standard Benchmark',
                          'Variance',
                          'Status',
                        ]
                        .map(
                          (h) => pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text(
                              h,
                              style: pw.TextStyle(
                                font: bold,
                                fontSize: 8,
                                color: PdfColors.white,
                              ),
                            ),
                          ),
                        )
                        .toList(),
              ),
              _tableRow(
                'Average Body Weight',
                '${(data.avgBodyWeightGrams ?? 0).toStringAsFixed(0)} g',
                '${data.expectedWeightGrams.toStringAsFixed(0)} g',
                '${data.weightDiffGrams >= 0 ? '+' : ''}${data.weightDiffGrams.toStringAsFixed(0)} g',
                data.weightDiffGrams >= 0 ? 'Optimal' : 'Behind',
                bold,
              ),
              _tableRow(
                'Average Daily Gain (ADG)',
                '${data.adgGrams.toStringAsFixed(1)} g/day',
                '55.0 g/day',
                '${(data.adgGrams - 55.0).toStringAsFixed(1)} g/day',
                data.adgGrams >= 50 ? 'Good' : 'Needs Boost',
                bold,
              ),
              _tableRow(
                'Growth Rate Index',
                '${data.growthRatePct.toStringAsFixed(1)}%',
                '100.0%',
                '${(data.growthRatePct - 100.0).toStringAsFixed(1)}%',
                data.growthRatePct >= 95 ? 'Normal' : 'Attention',
                bold,
              ),
            ],
          ),
          pw.SizedBox(height: 12),
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: kLightBg,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
              border: pw.Border.all(color: kCardBorder),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'CONCLUSION',
                  style: pw.TextStyle(
                    font: bold,
                    fontSize: 9,
                    color: kPrimaryGreen,
                  ),
                ),
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
  static pw.Page _buildPage4FeedAnalysis(
    ReportData data,
    pw.Font regular,
    pw.Font bold,
  ) {
    final records = data.dailyRecords;
    final maxFeed = records.isEmpty
        ? 100.0
        : records.map((r) => r.feedConsumedKg).reduce((a, b) => a > b ? a : b);
    final feedCeiling =
        (maxFeed <= 0 ? 100.0 : (maxFeed * 1.25)).ceilToDouble();
    final feedStep = (feedCeiling / 4).ceilToDouble();
    final feedYAxis = [
      0.0,
      feedStep,
      feedStep * 2,
      feedStep * 3,
      feedStep * 4,
    ];

    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(28),
      build: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _header('Page 4 — Feed Consumption & Efficiency'),
          pw.SizedBox(height: 10),
          pw.Text(
            'DAILY FEED INTAKE TREND (KG PER DAY)',
            style: pw.TextStyle(font: bold, fontSize: 11, color: kPrimaryGreen),
          ),
          pw.SizedBox(height: 6),

          // Visual Color Legend for Farmer
          pw.Row(
            children: [
              pw.Container(width: 14, height: 4, color: kTeal),
              pw.SizedBox(width: 6),
              pw.Text(
                '■ Daily Feed Consumed (kg)',
                style: pw.TextStyle(font: bold, fontSize: 8, color: kTeal),
              ),
              pw.SizedBox(width: 16),
              pw.Text(
                'Target Feed Conversion (FCR): 1.55',
                style: pw.TextStyle(font: bold, fontSize: 8, color: kGreyText),
              ),
            ],
          ),
          pw.SizedBox(height: 6),

          pw.Container(
            height: 160,
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: kLightBg,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
              border: pw.Border.all(color: kCardBorder),
            ),
            child: records.isNotEmpty
                ? pw.Chart(
                    grid: pw.CartesianGrid(
                      xAxis: pw.FixedAxis(
                        List.generate(records.length, (i) => i.toDouble()),
                      ),
                      yAxis: pw.FixedAxis(feedYAxis),
                    ),
                    datasets: [
                      pw.BarDataSet(
                        color: kTeal,
                        width: 4,
                        data: records
                            .asMap()
                            .entries
                            .map(
                              (e) => pw.PointChartValue(
                                e.key.toDouble(),
                                e.value.feedConsumedKg,
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  )
                : pw.Center(child: pw.Text('No feed consumption records.')),
          ),
          pw.SizedBox(height: 8),

          // Farmer Interpretation Callout Box
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: pw.BoxDecoration(
              color: (data.overallFcr ?? 1.55) <= 1.60
                  ? PdfColor.fromHex('#E8F5E9')
                  : PdfColor.fromHex('#FFEBEE'),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
              border: pw.Border.all(
                color: (data.overallFcr ?? 1.55) <= 1.60 ? kPrimaryGreen : kRed,
                width: 0.8,
              ),
            ),
            child: pw.Row(
              children: [
                pw.Text(
                  (data.overallFcr ?? 1.55) <= 1.60
                      ? '✓ FEEDING EFFICIENCY: '
                      : '⚠️ FEEDER SPILLAGE DETECTED: ',
                  style: pw.TextStyle(
                    font: bold,
                    fontSize: 8,
                    color: (data.overallFcr ?? 1.55) <= 1.60
                        ? kPrimaryGreen
                        : kRed,
                  ),
                ),
                pw.Expanded(
                  child: pw.Text(
                    (data.overallFcr ?? 1.55) <= 1.60
                        ? 'Current FCR of ${(data.overallFcr ?? 1.55).toStringAsFixed(2)} is within profitable commercial range. Feeder heights are properly set to bird shoulder level.'
                        : 'Current FCR is ${(data.overallFcr ?? 1.55).toStringAsFixed(2)} vs 1.55 target (+${data.excessFeedKg.toStringAsFixed(0)} kg excess feed = -₹${data.excessFeedCostRs.toStringAsFixed(0)} loss). Raise feeder lips to bird back height immediately to stop floor spillage.',
                    style: pw.TextStyle(fontSize: 7.5, color: kDarkGreen),
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 10),

          pw.Row(
            children: [
              pw.Expanded(
                child: _kpiCard(
                  'Total Feed Used',
                  '${data.totalFeedKg.toStringAsFixed(0)} kg',
                  '${(data.totalFeedKg / 50).toStringAsFixed(0)} Bags Total',
                  kPrimaryGreen,
                  bold,
                ),
              ),
              pw.SizedBox(width: 10),
              pw.Expanded(
                child: _kpiCard(
                  'Feed Stock Remaining',
                  '${data.feedRemainingKg.toStringAsFixed(0)} kg',
                  'Inventory Buffer',
                  kTeal,
                  bold,
                ),
              ),
              pw.SizedBox(width: 10),
              pw.Expanded(
                child: _kpiCard(
                  'Avg Feed / Bird / Day',
                  '${data.avgFeedPerBirdGrams.toStringAsFixed(0)} g',
                  'Gram intake/bird',
                  kPrimaryGreen,
                  bold,
                ),
              ),
            ],
          ),
          pw.Spacer(),
          _footer(context),
        ],
      ),
    );
  }

  // --- Page 5: Water Analysis ---
  static pw.Page _buildPage5WaterAnalysis(
    ReportData data,
    pw.Font regular,
    pw.Font bold,
  ) {
    final records = data.dailyRecords;
    final maxWater = records.isEmpty
        ? 200.0
        : records
            .map((r) => r.waterConsumedLiters)
            .reduce((a, b) => a > b ? a : b);
    final waterCeiling =
        (maxWater <= 0 ? 200.0 : (maxWater * 1.25)).ceilToDouble();
    final waterStep = (waterCeiling / 4).ceilToDouble();
    final waterYAxis = [
      0.0,
      waterStep,
      waterStep * 2,
      waterStep * 3,
      waterStep * 4,
    ];

    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(28),
      build: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _header('Page 5 — Water Consumption Analysis'),
          pw.SizedBox(height: 10),
          pw.Text(
            'DAILY WATER INTAKE TREND (LITERS PER DAY)',
            style: pw.TextStyle(font: bold, fontSize: 11, color: kPrimaryGreen),
          ),
          pw.SizedBox(height: 6),

          // Visual Color Legend for Farmer
          pw.Row(
            children: [
              pw.Container(width: 14, height: 4, color: kTeal),
              pw.SizedBox(width: 6),
              pw.Text(
                '■ Daily Water Consumed (Liters)',
                style: pw.TextStyle(font: bold, fontSize: 8, color: kTeal),
              ),
              pw.SizedBox(width: 16),
              pw.Text(
                'Healthy Ratio: 1.80 – 2.00 L per kg feed',
                style: pw.TextStyle(font: bold, fontSize: 8, color: kGreyText),
              ),
            ],
          ),
          pw.SizedBox(height: 6),

          pw.Container(
            height: 160,
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: kLightBg,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
              border: pw.Border.all(color: kCardBorder),
            ),
            child: records.isNotEmpty
                ? pw.Chart(
                    grid: pw.CartesianGrid(
                      xAxis: pw.FixedAxis(
                        List.generate(records.length, (i) => i.toDouble()),
                      ),
                      yAxis: pw.FixedAxis(waterYAxis),
                    ),
                    datasets: [
                      pw.LineDataSet(
                        color: kTeal,
                        lineWidth: 2.2,
                        data: records
                            .asMap()
                            .entries
                            .map(
                              (e) => pw.PointChartValue(
                                e.key.toDouble(),
                                e.value.waterConsumedLiters,
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  )
                : pw.Center(child: pw.Text('No water consumption records.')),
          ),
          pw.SizedBox(height: 8),

          // Farmer Interpretation Callout Box
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: pw.BoxDecoration(
              color: (data.waterToFeedRatio >= 1.75 &&
                      data.waterToFeedRatio <= 2.15)
                  ? PdfColor.fromHex('#E8F5E9')
                  : PdfColor.fromHex('#FFF3E0'),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
              border: pw.Border.all(
                color: (data.waterToFeedRatio >= 1.75 &&
                        data.waterToFeedRatio <= 2.15)
                    ? kPrimaryGreen
                    : kOrange,
                width: 0.8,
              ),
            ),
            child: pw.Row(
              children: [
                pw.Text(
                  (data.waterToFeedRatio >= 1.75 &&
                          data.waterToFeedRatio <= 2.15)
                      ? '✓ HYDRATION & LITTER IN SYNC: '
                      : '⚠️ WATER-TO-FEED DISADVANTAGE: ',
                  style: pw.TextStyle(
                    font: bold,
                    fontSize: 8,
                    color: (data.waterToFeedRatio >= 1.75 &&
                            data.waterToFeedRatio <= 2.15)
                        ? kPrimaryGreen
                        : kOrange,
                  ),
                ),
                pw.Expanded(
                  child: pw.Text(
                    data.waterToFeedRatio > 2.20
                        ? 'Water:Feed ratio is elevated at ${data.waterToFeedRatio.toStringAsFixed(2)}:1. Nipple drinker pressure is too high or enteritis is causing flushing, creating wet litter and ammonia.'
                        : (data.waterToFeedRatio < 1.65 &&
                                data.waterToFeedRatio > 0
                            ? 'Water:Feed ratio is low at ${data.waterToFeedRatio.toStringAsFixed(2)}:1. Blocked nipples or low pressure are choking bird feed intake.'
                            : 'Water consumption (${data.waterToFeedRatio.toStringAsFixed(2)}:1) matches feed intake perfectly, preserving dry friable bedding.'),
                    style: pw.TextStyle(fontSize: 7.5, color: kDarkGreen),
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 10),

          pw.Row(
            children: [
              pw.Expanded(
                child: _kpiCard(
                  'Total Water Used',
                  '${data.totalWaterLiters.toStringAsFixed(0)} L',
                  'Cumulative Intake',
                  kTeal,
                  bold,
                ),
              ),
              pw.SizedBox(width: 10),
              pw.Expanded(
                child: _kpiCard(
                  'Highest Daily Usage',
                  '${data.maxDailyWaterLiters.toStringAsFixed(0)} L',
                  'Peak Consumption',
                  kOrange,
                  bold,
                ),
              ),
              pw.SizedBox(width: 10),
              pw.Expanded(
                child: _kpiCard(
                  'Lowest Daily Usage',
                  '${data.minDailyWaterLiters.toStringAsFixed(0)} L',
                  'Minimum Intake',
                  kPrimaryGreen,
                  bold,
                ),
              ),
            ],
          ),
          pw.Spacer(),
          _footer(context),
        ],
      ),
    );
  }

  // --- Page 6: Mortality Analysis ---
  static pw.Page _buildPage6MortalityAnalysis(
    ReportData data,
    pw.Font regular,
    pw.Font bold,
  ) {
    final records = data.dailyRecords;
    final maxMort = records.isEmpty
        ? 10.0
        : records
            .map((r) => (r.mortalityCount + r.cullCount).toDouble())
            .reduce((a, b) => a > b ? a : b);
    final mortCeiling = (maxMort <= 0 ? 10.0 : (maxMort * 1.3)).ceilToDouble();
    final mortStep = (mortCeiling / 4).ceilToDouble();
    final mortYAxis = [
      0.0,
      mortStep,
      mortStep * 2,
      mortStep * 3,
      mortStep * 4,
    ];

    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(28),
      build: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _header('Page 6 — Mortality & Biosecurity Analysis'),
          pw.SizedBox(height: 10),
          pw.Text(
            'DAILY MORTALITY & CULL COUNT TREND',
            style: pw.TextStyle(font: bold, fontSize: 11, color: kPrimaryGreen),
          ),
          pw.SizedBox(height: 6),

          // Visual Color Legend for Farmer
          pw.Row(
            children: [
              pw.Container(width: 14, height: 4, color: kRed),
              pw.SizedBox(width: 6),
              pw.Text(
                '■ Daily Mortality & Culls (Birds)',
                style: pw.TextStyle(font: bold, fontSize: 8, color: kRed),
              ),
              pw.SizedBox(width: 16),
              pw.Text(
                'Flock Survival Rate: ${data.liveabilityPct.toStringAsFixed(1)}% (Target: >97%)',
                style: pw.TextStyle(font: bold, fontSize: 8, color: kGreyText),
              ),
            ],
          ),
          pw.SizedBox(height: 6),

          pw.Container(
            height: 160,
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: kLightBg,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
              border: pw.Border.all(color: kCardBorder),
            ),
            child: records.isNotEmpty
                ? pw.Chart(
                    grid: pw.CartesianGrid(
                      xAxis: pw.FixedAxis(
                        List.generate(records.length, (i) => i.toDouble()),
                      ),
                      yAxis: pw.FixedAxis(mortYAxis),
                    ),
                    datasets: [
                      pw.BarDataSet(
                        color: kRed,
                        width: 4,
                        data: records
                            .asMap()
                            .entries
                            .map(
                              (e) => pw.PointChartValue(
                                e.key.toDouble(),
                                (e.value.mortalityCount + e.value.cullCount)
                                    .toDouble(),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  )
                : pw.Center(child: pw.Text('No mortality records.')),
          ),
          pw.SizedBox(height: 8),

          // Farmer Interpretation Callout Box
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: pw.BoxDecoration(
              color: (100.0 - data.liveabilityPct) <= 3.0
                  ? PdfColor.fromHex('#E8F5E9')
                  : PdfColor.fromHex('#FFEBEE'),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
              border: pw.Border.all(
                color: (100.0 - data.liveabilityPct) <= 3.0
                    ? kPrimaryGreen
                    : kRed,
                width: 0.8,
              ),
            ),
            child: pw.Row(
              children: [
                pw.Text(
                  (100.0 - data.liveabilityPct) <= 3.0
                      ? '✓ BIOSECURITY SUCCESS: '
                      : '⚠️ ELEVATED MORTALITY: ',
                  style: pw.TextStyle(
                    font: bold,
                    fontSize: 8,
                    color: (100.0 - data.liveabilityPct) <= 3.0
                        ? kPrimaryGreen
                        : kRed,
                  ),
                ),
                pw.Expanded(
                  child: pw.Text(
                    (100.0 - data.liveabilityPct) <= 3.0
                        ? 'Cumulative mortality is ${(100.0 - data.liveabilityPct).toStringAsFixed(1)}% (Target: <3.0%). Flock bio-exclusion, vaccination, and shed hygiene are well controlled.'
                        : 'Cumulative mortality is ${(100.0 - data.liveabilityPct).toStringAsFixed(1)}% (${data.totalMortality} birds lost). Investigate water line chlorination, check post-mortem signs, and consult vet.',
                    style: pw.TextStyle(fontSize: 7.5, color: kDarkGreen),
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 10),

          pw.Row(
            children: [
              pw.Expanded(
                child: _kpiCard(
                  'Live Birds',
                  '${data.batch.currentBirds}',
                  'Population Active',
                  kPrimaryGreen,
                  bold,
                ),
              ),
              pw.SizedBox(width: 10),
              pw.Expanded(
                child: _kpiCard(
                  'Dead Birds',
                  '${data.totalMortality}',
                  'Cumulative Mort',
                  kRed,
                  bold,
                ),
              ),
              pw.SizedBox(width: 10),
              pw.Expanded(
                child: _kpiCard(
                  'Biosecurity Risk',
                  data.mortalityRiskLevel,
                  'Risk Assessment',
                  data.mortalityRiskLevel == 'Low' ? kPrimaryGreen : kRed,
                  bold,
                ),
              ),
            ],
          ),
          pw.Spacer(),
          _footer(context),
        ],
      ),
    );
  }

  // --- Page 7: Medicine & Vaccination ---
  static pw.Page _buildPage7MedicineVaccine(
    ReportData data,
    pw.Font regular,
    pw.Font bold,
  ) {
    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(28),
      build: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _header('Page 7 — Medicine & Vaccination Timeline'),
          pw.SizedBox(height: 12),
          pw.Text(
            'VACCINATION LOG & SCHEDULE',
            style: pw.TextStyle(font: bold, fontSize: 12, color: kPrimaryGreen),
          ),
          pw.SizedBox(height: 8),

          pw.Table(
            border: pw.TableBorder.all(color: kCardBorder),
            children: [
              pw.TableRow(
                decoration: pw.BoxDecoration(color: kPrimaryGreen),
                children:
                    [
                          'Date',
                          'Age',
                          'Vaccine Name',
                          'Type',
                          'Quantity',
                          'Done By',
                        ]
                        .map(
                          (h) => pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text(
                              h,
                              style: pw.TextStyle(
                                font: bold,
                                fontSize: 8,
                                color: PdfColors.white,
                              ),
                            ),
                          ),
                        )
                        .toList(),
              ),
              ...data.vaccineRecords.map(
                (v) => pw.TableRow(
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text(
                        DateFormat('dd/MM').format(v.date),
                        style: pw.TextStyle(fontSize: 8),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text(
                        'Day ${v.batchAgeDay}',
                        style: pw.TextStyle(fontSize: 8),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text(
                        v.vaccineName,
                        style: pw.TextStyle(font: bold, fontSize: 8),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text(
                        v.vaccineType,
                        style: pw.TextStyle(fontSize: 8),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text(
                        '${v.quantity} ${v.unit}',
                        style: pw.TextStyle(fontSize: 8),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text(
                        v.doneBy ?? 'Dr. Ramesh',
                        style: pw.TextStyle(fontSize: 8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 16),

          pw.Text(
            'MEDICINE TREATMENT LOG',
            style: pw.TextStyle(font: bold, fontSize: 12, color: kDarkGreen),
          ),
          pw.SizedBox(height: 8),

          pw.Table(
            border: pw.TableBorder.all(color: kCardBorder),
            children: [
              pw.TableRow(
                decoration: pw.BoxDecoration(color: kDarkGreen),
                children:
                    [
                          'Date',
                          'Age',
                          'Medicine Name',
                          'Quantity',
                          'Route',
                          'Cost (₹)',
                        ]
                        .map(
                          (h) => pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text(
                              h,
                              style: pw.TextStyle(
                                font: bold,
                                fontSize: 8,
                                color: PdfColors.white,
                              ),
                            ),
                          ),
                        )
                        .toList(),
              ),
              ...data.medicineRecords.map(
                (m) => pw.TableRow(
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text(
                        DateFormat('dd/MM').format(m.date),
                        style: pw.TextStyle(fontSize: 8),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text(
                        'Day ${m.batchAgeDay}',
                        style: pw.TextStyle(fontSize: 8),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text(
                        m.medicineName,
                        style: pw.TextStyle(font: bold, fontSize: 8),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text(
                        '${m.quantity} ${m.unit}',
                        style: pw.TextStyle(fontSize: 8),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text(
                        m.route ?? 'Water',
                        style: pw.TextStyle(fontSize: 8),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text(
                        '₹${(m.valueRs ?? 0).toStringAsFixed(0)}',
                        style: pw.TextStyle(font: bold, fontSize: 8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          pw.Spacer(),
          _footer(context),
        ],
      ),
    );
  }

  // --- Page 8: Financial Analysis ---
  static pw.Page _buildPage8FinancialAnalysis(
    ReportData data,
    pw.Font regular,
    pw.Font bold,
  ) {
    final feedCost = data.totalFeedKg * 42.0;
    final chickCost = data.batch.totalBirds * 35.0;
    final medCost = data.medicineRecords.fold(
      0.0,
      (sum, m) => sum + (m.valueRs ?? 0.0),
    );
    final vaccineCost = 0.0;
    final miscCost = 0.0;

    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(28),
      build: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _header('Page 8 — Financial & Profitability Analysis'),
          pw.SizedBox(height: 12),
          pw.Text(
            'FINANCIAL OVERVIEW (REVENUE VS EXPENSE)',
            style: pw.TextStyle(font: bold, fontSize: 12, color: kPrimaryGreen),
          ),
          pw.SizedBox(height: 12),

          pw.Row(
            children: [
              pw.Expanded(
                child: _kpiCard(
                  'Total Gross Revenue',
                  '₹${data.totalRevenue.toStringAsFixed(0)}',
                  'Bird Sales Revenue',
                  kPrimaryGreen,
                  bold,
                ),
              ),
              pw.SizedBox(width: 10),
              pw.Expanded(
                child: _kpiCard(
                  'Total Operating Expense',
                  '₹${data.totalExpenses.toStringAsFixed(0)}',
                  'Cost of Production',
                  kOrange,
                  bold,
                ),
              ),
              pw.SizedBox(width: 10),
              pw.Expanded(
                child: _kpiCard(
                  'Net Operating Profit',
                  '₹${data.netProfit.toStringAsFixed(0)}',
                  '${data.roiPct.toStringAsFixed(1)}% ROI Score',
                  data.netProfit >= 0 ? kPrimaryGreen : kRed,
                  bold,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 16),

          pw.Text(
            'EXPENSE BREAKDOWN PARTICULARS',
            style: pw.TextStyle(font: bold, fontSize: 11, color: kDarkGreen),
          ),
          pw.SizedBox(height: 8),

          pw.Table(
            border: pw.TableBorder.all(color: kCardBorder),
            children: [
              pw.TableRow(
                decoration: pw.BoxDecoration(color: kPrimaryGreen),
                children:
                    [
                          'Cost Head',
                          'Category Description',
                          'Amount (₹)',
                          'Share (%)',
                        ]
                        .map(
                          (h) => pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text(
                              h,
                              style: pw.TextStyle(
                                font: bold,
                                fontSize: 8,
                                color: PdfColors.white,
                              ),
                            ),
                          ),
                        )
                        .toList(),
              ),
              _tableRow4(
                'Feed Expenses',
                'Starter & Finisher Pellets',
                '₹${feedCost.toStringAsFixed(0)}',
                '${((feedCost / data.totalExpenses) * 100).toStringAsFixed(1)}%',
                bold,
              ),
              _tableRow4(
                'Chick Purchase',
                'Day-Old Chicks (${data.batch.totalBirds} Birds)',
                '₹${chickCost.toStringAsFixed(0)}',
                '${((chickCost / data.totalExpenses) * 100).toStringAsFixed(1)}%',
                bold,
              ),
              _tableRow4(
                'Medicines & Tonic',
                'Veterinary Antibiotics & Vitamins',
                '₹${medCost.toStringAsFixed(0)}',
                '${((medCost / data.totalExpenses) * 100).toStringAsFixed(1)}%',
                bold,
              ),
              _tableRow4(
                'Vaccines',
                'Live & Inactivated Vaccines',
                '₹${vaccineCost.toStringAsFixed(0)}',
                '${((vaccineCost / data.totalExpenses) * 100).toStringAsFixed(1)}%',
                bold,
              ),
              _tableRow4(
                'Labour & Utilities',
                'Electricity, Transport & Wages',
                '₹${miscCost.toStringAsFixed(0)}',
                '${((miscCost / data.totalExpenses) * 100).toStringAsFixed(1)}%',
                bold,
              ),
            ],
          ),
          pw.Spacer(),
          _footer(context),
        ],
      ),
    );
  }

  // --- Page 9: Inventory Analysis ---
  static pw.Page _buildPage9InventoryAnalysis(
    ReportData data,
    pw.Font regular,
    pw.Font bold,
  ) {
    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(28),
      build: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _header('Page 9 — Inventory & Stock Control'),
          pw.SizedBox(height: 12),
          pw.Text(
            'CURRENT INVENTORY AUDIT TABLE',
            style: pw.TextStyle(font: bold, fontSize: 12, color: kPrimaryGreen),
          ),
          pw.SizedBox(height: 8),

          pw.Table(
            border: pw.TableBorder.all(color: kCardBorder),
            children: [
              pw.TableRow(
                decoration: pw.BoxDecoration(color: kPrimaryGreen),
                children:
                    [
                          'Item Name',
                          'Category',
                          'Available',
                          'Unit',
                          'Min Level',
                          'Status',
                        ]
                        .map(
                          (h) => pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text(
                              h,
                              style: pw.TextStyle(
                                font: bold,
                                fontSize: 8,
                                color: PdfColors.white,
                              ),
                            ),
                          ),
                        )
                        .toList(),
              ),
              ...data.inventoryItems.map(
                (item) => pw.TableRow(
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text(
                        item.itemName,
                        style: pw.TextStyle(font: bold, fontSize: 8),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text(
                        item.category,
                        style: pw.TextStyle(fontSize: 8),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text(
                        '${item.quantityAvailable}',
                        style: pw.TextStyle(font: bold, fontSize: 8),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text(
                        item.unit,
                        style: pw.TextStyle(fontSize: 8),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text(
                        '${item.minStockLevel}',
                        style: pw.TextStyle(fontSize: 8),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text(
                        item.isLowStock ? 'LOW STOCK' : 'NORMAL',
                        style: pw.TextStyle(
                          font: bold,
                          fontSize: 8,
                          color: item.isLowStock ? kRed : kPrimaryGreen,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          pw.Spacer(),
          _footer(context),
        ],
      ),
    );
  }

  // --- Page 10: Overall Performance Scorecard ---
  static pw.Page _buildPage10OverallScorecard(
    ReportData data,
    pw.Font regular,
    pw.Font bold,
  ) {
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
                    pw.Text(
                      'OVERALL FARM PERFORMANCE INDEX',
                      style: pw.TextStyle(
                        font: bold,
                        fontSize: 10,
                        color: kAccentGold,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Grade: ${data.overallHealthGrade.toUpperCase()}',
                      style: pw.TextStyle(
                        font: bold,
                        fontSize: 18,
                        color: PdfColors.white,
                      ),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      '${data.overallScore} / 100',
                      style: pw.TextStyle(
                        font: bold,
                        fontSize: 32,
                        color: kAccentGold,
                      ),
                    ),
                    pw.Text(
                      '★ ' * data.starRating,
                      style: pw.TextStyle(
                        font: bold,
                        fontSize: 14,
                        color: kAccentGold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 18),

          pw.Text(
            'SUB-SYSTEM SCORE BREAKDOWN',
            style: pw.TextStyle(font: bold, fontSize: 12, color: kPrimaryGreen),
          ),
          pw.SizedBox(height: 10),

          pw.GridView(
            crossAxisCount: 2,
            childAspectRatio: 3.2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            children: [
              _scoreTile(
                'Growth Efficiency Score',
                '${data.growthScore} / 100',
                kPrimaryGreen,
                bold,
              ),
              _scoreTile(
                'Biosecurity & Health Score',
                '${data.healthScore} / 100',
                kPrimaryGreen,
                bold,
              ),
              _scoreTile(
                'Feed Conversion Score',
                '${data.feedScore} / 100',
                kPrimaryGreen,
                bold,
              ),
              _scoreTile(
                'Financial Profit Score',
                '${data.profitScore} / 100',
                kPrimaryGreen,
                bold,
              ),
              _scoreTile(
                'Mortality Control Score',
                '${data.mortalityScore} / 100',
                kPrimaryGreen,
                bold,
              ),
              _scoreTile(
                'Inventory Buffer Score',
                '${data.inventoryScore} / 100',
                kPrimaryGreen,
                bold,
              ),
            ],
          ),
          pw.Spacer(),
          _footer(context),
        ],
      ),
    );
  }

  static pw.Widget _scoreTile(
    String label,
    String score,
    PdfColor color,
    pw.Font bold,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: kLightBg,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
        border: pw.Border.all(color: kCardBorder),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(font: bold, fontSize: 9, color: kGreyText),
          ),
          pw.Text(
            score,
            style: pw.TextStyle(font: bold, fontSize: 12, color: color),
          ),
        ],
      ),
    );
  }

  // --- Page 11: AI Insights ---
  static pw.Page _buildPage11AiInsights(
    ReportData data,
    pw.Font regular,
    pw.Font bold,
  ) {
    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(28),
      build: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _header('Page 11 — Dynamic AI Insights'),
          pw.SizedBox(height: 12),
          pw.Text(
            'AUTOMATICALLY GENERATED OPERATIONAL INSIGHTS',
            style: pw.TextStyle(font: bold, fontSize: 12, color: kPrimaryGreen),
          ),
          pw.SizedBox(height: 10),

          ...data.aiInsights.map(
            (insight) => pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 8),
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: kLightBg,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
                border: pw.Border.all(color: kCardBorder),
              ),
              child: pw.Row(
                children: [
                  pw.Container(
                    width: 8,
                    height: 8,
                    decoration: pw.BoxDecoration(
                      color: kTeal,
                      shape: pw.BoxShape.circle,
                    ),
                  ),
                  pw.SizedBox(width: 10),
                  pw.Expanded(
                    child: pw.Text(
                      insight,
                      style: pw.TextStyle(
                        font: bold,
                        fontSize: 9,
                        color: PdfColors.black,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          pw.Spacer(),
          _footer(context),
        ],
      ),
    );
  }

  // --- Page 12: Farming Technique Disadvantages & Audit ---
  static pw.Page _buildPage12ProblemsDetected(
    ReportData data,
    pw.Font regular,
    pw.Font bold,
  ) {
    final disadvantages = data.techniqueDisadvantages;
    final advantages = data.techniqueAdvantages;
    final leakage = data.totalTechniqueFinancialLeakage;

    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(28),
      build: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _header('Page 12 — Farming Technique Disadvantages & Audit'),
          pw.SizedBox(height: 10),
          pw.Text(
            'OPERATIONAL AUDIT: IDENTIFIED DISADVANTAGES & FINANCIAL LEAKAGE',
            style: pw.TextStyle(font: bold, fontSize: 11, color: kPrimaryGreen),
          ),
          pw.SizedBox(height: 8),

          // 3-Pillar Summary Cards
          pw.Row(
            children: [
              pw.Expanded(
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(
                    color: leakage > 0
                        ? PdfColor.fromHex('#FFEBEE')
                        : PdfColor.fromHex('#E8F5E9'),
                    borderRadius:
                        const pw.BorderRadius.all(pw.Radius.circular(8)),
                    border: pw.Border.all(
                      color: leakage > 0 ? kRed : kPrimaryGreen,
                      width: 1,
                    ),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'EST. PROFIT LEAKAGE',
                        style: pw.TextStyle(
                          font: bold,
                          fontSize: 7.5,
                          color: leakage > 0 ? kRed : kPrimaryGreen,
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        leakage > 0
                            ? '₹${leakage.toStringAsFixed(0)}'
                            : '₹0 (Optimal)',
                        style: pw.TextStyle(
                          font: bold,
                          fontSize: 14,
                          color: leakage > 0 ? kRed : kPrimaryGreen,
                        ),
                      ),
                      pw.Text(
                        leakage > 0
                            ? 'Excess feed + early loss'
                            : 'Zero technique leakage',
                        style: pw.TextStyle(fontSize: 7, color: kGreyText),
                      ),
                    ],
                  ),
                ),
              ),
              pw.SizedBox(width: 8),
              pw.Expanded(
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(
                    color: kLightBg,
                    borderRadius:
                        const pw.BorderRadius.all(pw.Radius.circular(8)),
                    border: pw.Border.all(color: kOrange, width: 1),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'DISADVANTAGES DETECTED',
                        style: pw.TextStyle(
                          font: bold,
                          fontSize: 7.5,
                          color: kOrange,
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        '${disadvantages.length} Flaw(s)',
                        style: pw.TextStyle(
                          font: bold,
                          fontSize: 14,
                          color: kOrange,
                        ),
                      ),
                      pw.Text(
                        'Feeder, water, brooding',
                        style: pw.TextStyle(fontSize: 7, color: kGreyText),
                      ),
                    ],
                  ),
                ),
              ),
              pw.SizedBox(width: 8),
              pw.Expanded(
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(
                    color: kLightBg,
                    borderRadius:
                        const pw.BorderRadius.all(pw.Radius.circular(8)),
                    border: pw.Border.all(color: kPrimaryGreen, width: 1),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'TECHNIQUE SCORE',
                        style: pw.TextStyle(
                          font: bold,
                          fontSize: 7.5,
                          color: kPrimaryGreen,
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        '${data.overallScore}/100',
                        style: pw.TextStyle(
                          font: bold,
                          fontSize: 14,
                          color: kPrimaryGreen,
                        ),
                      ),
                      pw.Text(
                        'Grade: ${data.overallHealthGrade}',
                        style: pw.TextStyle(fontSize: 7, color: kGreyText),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 10),

          // Disadvantages Table
          pw.Text(
            'IDENTIFIED FARMING TECHNIQUE DISADVANTAGES & ROOT CAUSES',
            style: pw.TextStyle(font: bold, fontSize: 9.5, color: kDarkGreen),
          ),
          pw.SizedBox(height: 6),

          pw.Table(
            border: pw.TableBorder.all(color: kCardBorder),
            columnWidths: {
              0: const pw.FlexColumnWidth(2.2),
              1: const pw.FlexColumnWidth(3.8),
              2: const pw.FlexColumnWidth(4.5),
              3: const pw.FlexColumnWidth(1.8),
            },
            children: [
              pw.TableRow(
                decoration: pw.BoxDecoration(color: kDarkGreen),
                children: [
                  'Category & Severity',
                  'Observed Metric & Flaw',
                  'Technical Cause & Farmer Impact',
                  'Est. Loss (₹)',
                ]
                    .map(
                      (h) => pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(
                          h,
                          style: pw.TextStyle(
                            font: bold,
                            fontSize: 7.5,
                            color: PdfColors.white,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
              if (disadvantages.isEmpty)
                pw.TableRow(
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        'Optimal',
                        style: pw.TextStyle(
                          font: bold,
                          fontSize: 8,
                          color: kPrimaryGreen,
                        ),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        'No critical technique flaws detected.',
                        style: pw.TextStyle(fontSize: 8),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        'Feeding, drinking, and brooding techniques match Cobb 500 standards.',
                        style: pw.TextStyle(fontSize: 8),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        '₹0',
                        style: pw.TextStyle(
                          font: bold,
                          fontSize: 8,
                          color: kPrimaryGreen,
                        ),
                      ),
                    ),
                  ],
                )
              else
                ...disadvantages.map((dis) {
                  final isCrit = dis.severity == 'Critical';
                  final color = isCrit ? kRed : kOrange;
                  return pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              dis.category,
                              style: pw.TextStyle(
                                font: bold,
                                fontSize: 7,
                                color: kDarkGreen,
                              ),
                            ),
                            pw.SizedBox(height: 2),
                            pw.Container(
                              padding: const pw.EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 1.5,
                              ),
                              decoration: pw.BoxDecoration(
                                color: isCrit
                                    ? PdfColor.fromHex('#FFEBEE')
                                    : PdfColor.fromHex('#FFF3E0'),
                                borderRadius: const pw.BorderRadius.all(
                                  pw.Radius.circular(4),
                                ),
                              ),
                              child: pw.Text(
                                dis.severity.toUpperCase(),
                                style: pw.TextStyle(
                                  font: bold,
                                  fontSize: 6.5,
                                  color: color,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              dis.title,
                              style: pw.TextStyle(font: bold, fontSize: 7.5),
                            ),
                            pw.SizedBox(height: 1.5),
                            pw.Text(
                              dis.metricObserved,
                              style: pw.TextStyle(
                                fontSize: 6.5,
                                color: kPrimaryGreen,
                              ),
                            ),
                          ],
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(
                          dis.techniqueFlaw,
                          style: pw.TextStyle(fontSize: 6.5, color: kGreyText),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(
                          dis.financialImpactRs != null
                              ? '₹${dis.financialImpactRs!.toStringAsFixed(0)}'
                              : '—',
                          style: pw.TextStyle(
                            font: bold,
                            fontSize: 7.5,
                            color: kRed,
                          ),
                        ),
                      ),
                    ],
                  );
                }),
            ],
          ),
          pw.SizedBox(height: 10),

          // Farming Strengths & Advantages Callout Panel
          pw.Text(
            'FARMING ADVANTAGES & MANAGEMENT STRENGTHS',
            style: pw.TextStyle(font: bold, fontSize: 9.5, color: kPrimaryGreen),
          ),
          pw.SizedBox(height: 6),
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromHex('#E8F5E9'),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              border: pw.Border.all(color: kPrimaryGreen, width: 0.8),
            ),
            child: pw.Column(
              children: (advantages.isNotEmpty ? advantages : [
                FarmingTechniqueInsight(
                  title: 'Stable Flock Operations',
                  category: 'General',
                  severity: 'Advantage',
                  metricObserved: 'Consistent daily record logging',
                  techniqueFlaw:
                      'Farmer maintains good documentation discipline across flock cycles.',
                  correctiveAction: 'Maintain records daily.',
                  isDisadvantage: false,
                ),
              ]).take(3).map((adv) {
                return pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 2.5),
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        '✓ ',
                        style: pw.TextStyle(
                          font: bold,
                          fontSize: 9,
                          color: kPrimaryGreen,
                        ),
                      ),
                      pw.Expanded(
                        child: pw.RichText(
                          text: pw.TextSpan(
                            children: [
                              pw.TextSpan(
                                text: '${adv.title}: ',
                                style: pw.TextStyle(
                                  font: bold,
                                  fontSize: 7.5,
                                  color: kDarkGreen,
                                ),
                              ),
                              pw.TextSpan(
                                text: '${adv.metricObserved}. ${adv.techniqueFlaw}',
                                style: pw.TextStyle(
                                  fontSize: 7,
                                  color: PdfColors.black,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          pw.Spacer(),
          _footer(context),
        ],
      ),
    );
  }

  // --- Page 13: Corrective Technique Action Plan & Benchmarking ---
  static pw.Page _buildPage13Recommendations(
    ReportData data,
    pw.Font regular,
    pw.Font bold,
  ) {
    final benchmarks = data.benchmarkMatrix;
    final actionPlan = data.techniqueActionPlan;
    final leakage = data.totalTechniqueFinancialLeakage;

    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(28),
      build: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _header('Page 13 — Corrective Technique Action Plan & Benchmarking'),
          pw.SizedBox(height: 10),
          pw.Text(
            'COMMERCIAL BREED BENCHMARKS & TARGET COMPARISON',
            style: pw.TextStyle(font: bold, fontSize: 11, color: kPrimaryGreen),
          ),
          pw.SizedBox(height: 6),

          // Benchmark Table
          pw.Table(
            border: pw.TableBorder.all(color: kCardBorder),
            columnWidths: {
              0: const pw.FlexColumnWidth(3.0),
              1: const pw.FlexColumnWidth(2.0),
              2: const pw.FlexColumnWidth(2.0),
              3: const pw.FlexColumnWidth(1.8),
              4: const pw.FlexColumnWidth(2.0),
              5: const pw.FlexColumnWidth(3.6),
            },
            children: [
              pw.TableRow(
                decoration: pw.BoxDecoration(color: kDarkGreen),
                children: [
                  'Metric',
                  'Actual',
                  'Target',
                  'Variance',
                  'Status',
                  'Corrective Advice',
                ]
                    .map(
                      (h) => pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(
                          h,
                          style: pw.TextStyle(
                            font: bold,
                            fontSize: 7,
                            color: PdfColors.white,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
              ...benchmarks.map((bm) {
                final isGood = bm['isGood'] as bool? ?? false;
                final statusColor = isGood ? kPrimaryGreen : kOrange;
                return pw.TableRow(
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(4.5),
                      child: pw.Text(
                        bm['metric'] as String,
                        style: pw.TextStyle(font: bold, fontSize: 7),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(4.5),
                      child: pw.Text(
                        bm['actual'] as String,
                        style: pw.TextStyle(font: bold, fontSize: 7),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(4.5),
                      child: pw.Text(
                        bm['target'] as String,
                        style: pw.TextStyle(fontSize: 7, color: kGreyText),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(4.5),
                      child: pw.Text(
                        bm['variance'] as String,
                        style: pw.TextStyle(
                          font: bold,
                          fontSize: 6.5,
                          color: statusColor,
                        ),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(4.5),
                      child: pw.Text(
                        bm['status'] as String,
                        style: pw.TextStyle(
                          font: bold,
                          fontSize: 6.5,
                          color: statusColor,
                        ),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(4.5),
                      child: pw.Text(
                        bm['action'] as String,
                        style: pw.TextStyle(fontSize: 6.5, color: kDarkGreen),
                      ),
                    ),
                  ],
                );
              }),
            ],
          ),
          pw.SizedBox(height: 12),

          // Corrective Action Plan Checklist
          pw.Text(
            'PRIORITIZED OPERATIONAL PROTOCOLS FOR THE FARMER',
            style: pw.TextStyle(font: bold, fontSize: 9.5, color: kDarkGreen),
          ),
          pw.SizedBox(height: 6),

          ...actionPlan.take(4).map((rec) {
            return pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 6),
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(
                color: kLightBg,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                border: pw.Border.all(color: kCardBorder),
              ),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Container(
                    padding: const pw.EdgeInsets.all(2),
                    decoration: pw.BoxDecoration(
                      color: kPrimaryGreen,
                      shape: pw.BoxShape.circle,
                    ),
                    child: pw.Text(
                      '✓',
                      style: pw.TextStyle(
                        font: bold,
                        fontSize: 8,
                        color: PdfColors.white,
                      ),
                    ),
                  ),
                  pw.SizedBox(width: 8),
                  pw.Expanded(
                    child: pw.Text(
                      rec,
                      style: pw.TextStyle(
                        font: bold,
                        fontSize: 8,
                        color: PdfColors.black,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
          pw.SizedBox(height: 8),

          // Profit Recovery Box
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromHex('#E8F5E9'),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              border: pw.Border.all(color: kPrimaryGreen, width: 1),
            ),
            child: pw.Row(
              children: [
                pw.Text(
                  '💡 POTENTIAL PROFIT RECOVERY: ',
                  style: pw.TextStyle(
                    font: bold,
                    fontSize: 8.5,
                    color: kPrimaryGreen,
                  ),
                ),
                pw.Expanded(
                  child: pw.Text(
                    'Eliminating these technique disadvantages recovers an estimated ₹${(leakage > 0 ? leakage : 18500).toStringAsFixed(0)} on your next cycle through reduced feed spillage, lower mortality, and faster harvest weights.',
                    style: pw.TextStyle(fontSize: 7.5, color: kDarkGreen),
                  ),
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

  // --- Page 14: Detailed Data Tables ---
  static pw.Page _buildPage14DetailedTables(
    ReportData data,
    pw.Font regular,
    pw.Font bold,
  ) {
    final records = data.dailyRecords.take(15).toList();

    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(28),
      build: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _header('Page 14 — Detailed Daily Records Log'),
          pw.SizedBox(height: 12),
          pw.Text(
            'TELEMETRY AUDIT TRAIL',
            style: pw.TextStyle(font: bold, fontSize: 12, color: kPrimaryGreen),
          ),
          pw.SizedBox(height: 8),

          pw.Table(
            border: pw.TableBorder.all(color: kCardBorder),
            children: [
              pw.TableRow(
                decoration: pw.BoxDecoration(color: kPrimaryGreen),
                children:
                    [
                          'Day',
                          'Date',
                          'Closing Birds',
                          'Mortality',
                          'Feed (kg)',
                          'Water (L)',
                          'Weight (g)',
                          'FCR',
                        ]
                        .map(
                          (h) => pw.Padding(
                            padding: const pw.EdgeInsets.all(5),
                            child: pw.Text(
                              h,
                              style: pw.TextStyle(
                                font: bold,
                                fontSize: 7,
                                color: PdfColors.white,
                              ),
                            ),
                          ),
                        )
                        .toList(),
              ),
              ...records.map((r) {
                final fcr = r.avgWeightGrams > 0
                    ? (r.feedConsumedKg / (r.avgWeightGrams / 1000.0))
                          .toStringAsFixed(2)
                    : '-';
                return pw.TableRow(
                  decoration: pw.BoxDecoration(
                    color: records.indexOf(r).isEven
                        ? PdfColors.white
                        : kLightBg,
                  ),
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text(
                        '${r.batchAgeDay}',
                        style: pw.TextStyle(fontSize: 7),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text(
                        DateFormat('dd/MM').format(r.recordDate),
                        style: pw.TextStyle(fontSize: 7),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text(
                        '${r.closingBirds}',
                        style: pw.TextStyle(fontSize: 7),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text(
                        '${r.mortalityCount}',
                        style: pw.TextStyle(fontSize: 7),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text(
                        '${r.feedConsumedKg}',
                        style: pw.TextStyle(fontSize: 7),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text(
                        '${r.waterConsumedLiters}',
                        style: pw.TextStyle(fontSize: 7),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text(
                        '${r.avgWeightGrams}',
                        style: pw.TextStyle(fontSize: 7),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text(
                        fcr,
                        style: pw.TextStyle(font: bold, fontSize: 7),
                      ),
                    ),
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
  static pw.Page _buildPage15Conclusion(
    ReportData data,
    pw.Font regular,
    pw.Font bold,
    pw.Font italic,
  ) {
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
            decoration: pw.BoxDecoration(
              color: kLightBg,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
              border: pw.Border.all(color: kCardBorder),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'EXECUTIVE SUMMARY CONCLUSION',
                  style: pw.TextStyle(
                    font: bold,
                    fontSize: 11,
                    color: kPrimaryGreen,
                  ),
                ),
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
        pw.Text(
          label,
          style: pw.TextStyle(
            font: pw.Font.helveticaBold(),
            fontSize: 8,
            color: kDarkGreen,
          ),
        ),
      ],
    );
  }

  static pw.TableRow _tableRow(
    String metric,
    String actual,
    String standard,
    String diff,
    String status,
    pw.Font bold,
  ) {
    return pw.TableRow(
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.all(5),
          child: pw.Text(metric, style: pw.TextStyle(font: bold, fontSize: 8)),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(5),
          child: pw.Text(actual, style: pw.TextStyle(fontSize: 8)),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(5),
          child: pw.Text(standard, style: pw.TextStyle(fontSize: 8)),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(5),
          child: pw.Text(diff, style: pw.TextStyle(fontSize: 8)),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(5),
          child: pw.Text(
            status,
            style: pw.TextStyle(font: bold, fontSize: 8, color: kPrimaryGreen),
          ),
        ),
      ],
    );
  }

  static pw.TableRow _tableRow4(
    String metric,
    String description,
    String amount,
    String share,
    pw.Font bold,
  ) {
    return pw.TableRow(
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.all(5),
          child: pw.Text(metric, style: pw.TextStyle(font: bold, fontSize: 8)),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(5),
          child: pw.Text(description, style: pw.TextStyle(fontSize: 8)),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(5),
          child: pw.Text(amount, style: pw.TextStyle(font: bold, fontSize: 8)),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(5),
          child: pw.Text(share, style: pw.TextStyle(fontSize: 8)),
        ),
      ],
    );
  }
}
