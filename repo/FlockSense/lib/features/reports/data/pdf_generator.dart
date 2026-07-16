import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flock_sense/features/reports/domain/report_data.dart';

final kGreen = PdfColor.fromHex('#2E7D32');
final kGreenDark = PdfColor.fromHex('#173D24');
final kGold = PdfColor.fromHex('#D4A017');
final kRed = PdfColor.fromHex('#D9534F');
final kBlue = PdfColor.fromHex('#0284C7');
final kGrey = PdfColor.fromHex('#647067');
final kLightGrey = PdfColor.fromHex('#F4F7F2');
final kBorder = PdfColor.fromHex('#DCE5DC');

const Map<int, double> kSkmBodyWeightStdGrams = {
  1: 56,
  2: 70,
  3: 87,
  4: 106,
  5: 128,
  6: 152,
  7: 185,
  8: 220,
  9: 255,
  10: 290,
  11: 335,
  12: 387,
  13: 443,
  14: 500,
  15: 559,
  16: 618,
  17: 677,
  18: 736,
  19: 795,
  20: 854,
  21: 913,
  22: 993,
  23: 1073,
  24: 1153,
  25: 1233,
  26: 1313,
  27: 1394,
  28: 1475,
  29: 1566,
  30: 1658,
  31: 1749,
  32: 1840,
  33: 1931,
  34: 2023,
  35: 2115,
  36: 2206,
  37: 2296,
  38: 2387,
  39: 2477,
  40: 2568,
  41: 2659,
  42: 2750,
};

class PdfGenerator {
  PdfGenerator._();

  static Future<Uint8List> generateFarmRecord(ReportData data) async {
    final pdf = pw.Document();
    final regular = pw.Font.helvetica();
    final bold = pw.Font.helveticaBold();

    pdf.addPage(_pageOne(data, regular, bold));
    pdf.addPage(_pageTwo(data, regular, bold));
    pdf.addPage(_pageThree(data, regular, bold, 1, 3));
    pdf.addPage(_pageThree(data, regular, bold, 4, 6));
    pdf.addPage(_pageFive(data, regular, bold));
    pdf.addPage(_pageComplaints(data, regular, bold, 1));
    pdf.addPage(_pageComplaints(data, regular, bold, 2));
    pdf.addPage(_pageComplaints(data, regular, bold, 3));
    pdf.addPage(_pageFeedReceipts(data, regular, bold));
    pdf.addPage(_pageFeedTransfer(data, regular, bold));
    pdf.addPage(_pageMedicineDetails(data, regular, bold));
    pdf.addPage(_pageVaccineBatchDetails(data, regular, bold));
    pdf.addPage(_pageSalesDetails(data, regular, bold));
    pdf.addPage(_pageAdditionalNotes(data, regular, bold));
    pdf.addPage(_pagePerformanceSummary(data, regular, bold));

    return pdf.save();
  }

  static pw.Page _pageOne(ReportData data, pw.Font regular, pw.Font bold) {
    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(24),
      build: (context) => pw.Column(
        children: [
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: kGreen, width: 2),
            ),
            child: pw.Column(
              children: [
                pw.Text(
                  'SKM ANIMAL FEEDS AND FOODS (INDIA) PRIVATE LIMITED',
                  style: pw.TextStyle(font: bold, fontSize: 11, color: kGreen),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  'INTEGRATION CO-OFFICE',
                  style: pw.TextStyle(
                    font: bold,
                    fontSize: 8,
                    color: PdfColors.black,
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 20),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: kGreen),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(20)),
            ),
            child: pw.Text(
              'FARM RECORD',
              style: pw.TextStyle(font: bold, fontSize: 14, color: kGreen),
            ),
          ),
          pw.SizedBox(height: 12),
          _buildKeyValueTable(
            [
              ['Branch / Code', data.farm.district ?? '–'],
              ['Name of the Farmer', data.farm.farmerName ?? '–'],
              [
                'Address',
                data.farm.address.isNotEmpty ? data.farm.address : '–',
              ],
              ['Hatch Date', _fmt(data.batch.hatchDate)],
              ['Delivery / Placement Date', _fmt(data.batch.placementDate)],
              [
                'No. of Chicks Delivered',
                'Females: ${data.batch.femaleCount}  Males: ${data.batch.maleCount}  Total: ${data.batch.totalBirds}',
              ],
              ['Female', '${data.batch.femaleCount}'],
              ['Flock', data.batch.breedOrFlockType],
              ['Male', '${data.batch.maleCount}'],
              [
                'Day Old Chicks Avg. Wt.',
                data.batch.chickAvgWeight != null
                    ? '${data.batch.chickAvgWeight!.toStringAsFixed(1)} gm'
                    : '–',
              ],
              ['Hatchery Name', data.batch.hatcheryName ?? '–'],
              ['Supervisor Name', data.batch.supervisorName ?? '–'],
              ['Delivery Vehicle No.', data.batch.vehicleNumber ?? '–'],
            ],
            regular,
            bold,
          ),
        ],
      ),
    );
  }

  static pw.Page _pageTwo(ReportData data, pw.Font regular, pw.Font bold) {
    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(24),
      build: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'SHED DETAILS',
            style: pw.TextStyle(font: bold, fontSize: 12, color: kGreen),
          ),
          pw.SizedBox(height: 8),
          pw.Table(
            border: pw.TableBorder.all(color: kBorder),
            children: [
              pw.TableRow(
                decoration: pw.BoxDecoration(color: kGreen),
                children: ['Shed No.', 'Length', 'Width', 'Total Sq.ft']
                    .map((h) => _cell(h, bold: true, color: PdfColors.white))
                    .toList(),
              ),
              ...data.sheds.map(
                (shed) => pw.TableRow(
                  children: [
                    _cell(shed.name),
                    _cell(shed.lengthFt.toStringAsFixed(0)),
                    _cell(shed.widthFt.toStringAsFixed(0)),
                    _cell(shed.totalSqFt.toStringAsFixed(0)),
                  ],
                ),
              ),
              pw.TableRow(
                decoration: pw.BoxDecoration(color: kLightGrey),
                children: [
                  _cell('Total', bold: true),
                  _cell(''),
                  _cell(''),
                  _cell(
                    data.sheds
                        .fold(0.0, (sum, shed) => sum + shed.totalSqFt)
                        .toStringAsFixed(0),
                    bold: true,
                  ),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 16),
          pw.Text(
            'BROODING TEMPERATURE',
            style: pw.TextStyle(font: bold, fontSize: 10, color: kGreen),
          ),
          pw.SizedBox(height: 6),
          pw.Table(
            border: pw.TableBorder.all(color: kBorder),
            columnWidths: {
              0: const pw.FixedColumnWidth(40),
              1: const pw.FixedColumnWidth(60),
              2: const pw.FlexColumnWidth(),
              3: const pw.FlexColumnWidth(),
            },
            children: [
              pw.TableRow(
                decoration: pw.BoxDecoration(color: kGreen),
                children: ['Day', 'Time', 'Std Temp', 'Act Temp']
                    .map((h) => _cell(h, bold: true, color: PdfColors.white))
                    .toList(),
              ),
              ...List.generate(10, (index) {
                final day = index + 1;
                final stdTemp = day <= 2
                    ? '90°F'
                    : day <= 4
                    ? '88°F'
                    : day <= 6
                    ? '86°F'
                    : day <= 8
                    ? '84°F'
                    : '82°F';
                return pw.TableRow(
                  children: [
                    _cell('$day'),
                    _cell(''),
                    _cell(stdTemp),
                    _cell(''),
                  ],
                );
              }),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Page _pageThree(
    ReportData data,
    pw.Font regular,
    pw.Font bold,
    int startWeek,
    int endWeek,
  ) {
    final records = data.dailyRecords.toList()
      ..sort((a, b) => a.batchAgeDay.compareTo(b.batchAgeDay));

    return pw.Page(
      pageFormat: PdfPageFormat.a4.landscape,
      margin: const pw.EdgeInsets.all(16),
      build: (context) {
        final weekRows = <pw.TableRow>[];
        for (int week = startWeek; week <= endWeek; week++) {
          final startDay = (week - 1) * 7 + 1;
          final endDay = week * 7;
          final weekRecords = records
              .where(
                (record) =>
                    record.batchAgeDay >= startDay &&
                    record.batchAgeDay <= endDay,
              )
              .toList();
          if (weekRecords.isEmpty) {
            continue;
          }

          double cumFeed = 0;
          int cumMort = 0;
          weekRows.add(
            pw.TableRow(
              decoration: pw.BoxDecoration(color: kGreen),
              children:
                  [
                        'Date',
                        'Age',
                        'Stock',
                        'D.M',
                        'C.M',
                        'C.M%',
                        'Feed/Bird',
                        'Cum.Feed',
                        'Body Wt',
                        'FCR',
                      ]
                      .map(
                        (heading) => _cell(
                          heading,
                          bold: true,
                          color: PdfColors.white,
                          fontSize: 6,
                        ),
                      )
                      .toList(),
            ),
          );
          for (final record in weekRecords) {
            cumFeed += record.feedConsumedKg;
            cumMort += record.mortalityCount + record.cullCount;
            final cumMortPct = data.batch.totalBirds > 0
                ? (cumMort / data.batch.totalBirds * 100).toStringAsFixed(2)
                : '–';
            final feedPerBird = record.closingBirds > 0
                ? (record.feedConsumedKg * 1000 / record.closingBirds)
                      .toStringAsFixed(0)
                : '–';
            final cumFeedPerBird = record.closingBirds > 0
                ? (cumFeed * 1000 / record.closingBirds).toStringAsFixed(0)
                : '–';
            final stdWeight = kSkmBodyWeightStdGrams[record.batchAgeDay];
            final bodyWtCell = stdWeight != null
                ? 'A:${record.avgWeightGrams.toStringAsFixed(0)}\nS:${stdWeight.toStringAsFixed(0)}'
                : record.avgWeightGrams.toStringAsFixed(0);
            final fcrValue = record.avgWeightGrams > 0
                ? (cumFeed / (record.avgWeightGrams / 1000.0)).toStringAsFixed(
                    2,
                  )
                : '–';
            final rowColor = weekRecords.indexOf(record).isEven
                ? PdfColors.white
                : kLightGrey;

            weekRows.add(
              pw.TableRow(
                decoration: pw.BoxDecoration(color: rowColor),
                children: [
                  _cell(_fmtShort(record.recordDate)),
                  _cell('${record.batchAgeDay}'),
                  _cell('${record.closingBirds}'),
                  _cell('${record.mortalityCount}'),
                  _cell('$cumMort'),
                  _cell(cumMortPct),
                  _cell('${feedPerBird}g'),
                  _cell('${cumFeedPerBird}g'),
                  _cell(bodyWtCell),
                  _cell(fcrValue),
                ],
              ),
            );
          }
        }

        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              '${data.batch.batchName} — Weekly Performance',
              style: pw.TextStyle(font: bold, fontSize: 10, color: kGreen),
            ),
            pw.SizedBox(height: 6),
            pw.Table(
              border: pw.TableBorder.all(color: kBorder),
              columnWidths: {
                0: const pw.FixedColumnWidth(36),
                1: const pw.FixedColumnWidth(24),
                2: const pw.FixedColumnWidth(38),
                3: const pw.FixedColumnWidth(20),
                4: const pw.FixedColumnWidth(24),
                5: const pw.FixedColumnWidth(30),
                6: const pw.FixedColumnWidth(36),
                7: const pw.FixedColumnWidth(38),
                8: const pw.FixedColumnWidth(40),
                9: const pw.FixedColumnWidth(30),
              },
              children: weekRows,
            ),
          ],
        );
      },
    );
  }

  static pw.Page _pageFive(ReportData data, pw.Font regular, pw.Font bold) {
    final medicineRows = data.medicineRecords;
    final vaccineRows = data.vaccineRecords;

    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(24),
      build: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'VACCINATION / MEDICINE LOG',
            style: pw.TextStyle(font: bold, fontSize: 12, color: kGreen),
          ),
          pw.SizedBox(height: 10),
          pw.Text(
            'Medicine Log',
            style: pw.TextStyle(font: bold, fontSize: 10, color: kGreenDark),
          ),
          pw.SizedBox(height: 6),
          _buildSimpleTable(
            ['Date', 'Age', 'Medicine', 'Qty', 'Unit', 'Route'],
            medicineRows
                .map(
                  (m) => [
                    _fmtShort(m.date),
                    '${m.batchAgeDay}',
                    m.medicineName,
                    m.quantity.toStringAsFixed(1),
                    m.unit,
                    m.route ?? '–',
                  ],
                )
                .toList(),
          ),
          pw.SizedBox(height: 14),
          pw.Text(
            'Vaccination Log',
            style: pw.TextStyle(font: bold, fontSize: 10, color: kGreenDark),
          ),
          pw.SizedBox(height: 6),
          _buildSimpleTable(
            ['Date', 'Age', 'Vaccine', 'Type', 'Qty', 'Done By'],
            vaccineRows
                .map(
                  (v) => [
                    _fmtShort(v.date),
                    '${v.batchAgeDay}',
                    v.vaccineName,
                    v.vaccineType,
                    '${v.quantity} ${v.unit}',
                    v.doneBy ?? '–',
                  ],
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  static pw.Page _pageComplaints(
    ReportData data,
    pw.Font regular,
    pw.Font bold,
    int pageNumber,
  ) {
    final issues = data.dailyRecords
        .where(
          (record) =>
              (record.symptoms?.isNotEmpty ?? false) ||
              (record.notes?.isNotEmpty ?? false),
        )
        .map(
          (record) => [
            _fmtShort(record.recordDate),
            '${record.batchAgeDay}',
            record.symptoms ?? '–',
            record.notes ?? '–',
          ],
        )
        .toList();

    const rowsPerPage = 12;
    final pageItems = issues
        .skip((pageNumber - 1) * rowsPerPage)
        .take(rowsPerPage)
        .toList();
    final hasItems = pageItems.isNotEmpty;

    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(24),
      build: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'COMPLAINTS & SUGGESTIONS LOG',
            style: pw.TextStyle(font: bold, fontSize: 12, color: kGreen),
          ),
          pw.SizedBox(height: 10),
          _buildSimpleTable(
            ['Date', 'Age', 'Symptoms', 'Notes'],
            hasItems
                ? pageItems
                : [
                    ['-', '-', 'No entries', 'No entries'],
                  ],
          ),
          if (!hasItems) pw.SizedBox(height: 12),
          if (!hasItems)
            pw.Text(
              'No complaints or suggestions recorded for this page.',
              style: pw.TextStyle(color: kGrey, fontSize: 9),
            ),
        ],
      ),
    );
  }

  static pw.Page _pageFeedReceipts(
    ReportData data,
    pw.Font regular,
    pw.Font bold,
  ) {
    final receipts = data.feedTransactions
        .where((t) => t.transactionType == 'received')
        .toList();

    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(24),
      build: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'FEED RECEIPTS DETAILS',
            style: pw.TextStyle(font: bold, fontSize: 12, color: kGreen),
          ),
          pw.SizedBox(height: 10),
          _buildSimpleTable(
            [
              'S.No',
              'Date',
              'DC No.',
              'Feed Type',
              'Batch',
              'Bags',
              'Kg',
              'Cum Bags',
              'Cum Kg',
            ],
            receipts.asMap().entries.map((entry) {
              final transaction = entry.value;
              return [
                '${entry.key + 1}',
                _fmtShort(transaction.date),
                transaction.dcNumber ?? '–',
                transaction.feedType,
                transaction.batchNumber ?? '–',
                '${transaction.bags}',
                transaction.weightKg.toStringAsFixed(1),
                '${transaction.cumulativeBags}',
                transaction.cumulativeKg.toStringAsFixed(1),
              ];
            }).toList(),
          ),
        ],
      ),
    );
  }

  static pw.Page _pageFeedTransfer(
    ReportData data,
    pw.Font regular,
    pw.Font bold,
  ) {
    final transfers = data.feedTransactions
        .where(
          (t) =>
              t.transactionType == 'transferIn' ||
              t.transactionType == 'transferOut',
        )
        .toList();

    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(24),
      build: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'FEED TRANSFER IN / OUT',
            style: pw.TextStyle(font: bold, fontSize: 12, color: kGreen),
          ),
          pw.SizedBox(height: 10),
          _buildSimpleTable(
            ['S.No', 'Date', 'Type', 'Feed', 'Qty', 'From / To', 'Kg', 'Notes'],
            transfers.asMap().entries.map((entry) {
              final transaction = entry.value;
              return [
                '${entry.key + 1}',
                _fmtShort(transaction.date),
                transaction.transactionType ?? '–',
                transaction.feedType,
                '${transaction.bags}',
                transaction.destination ?? transaction.supplierName ?? '–',
                transaction.weightKg.toStringAsFixed(1),
                transaction.notes ?? '–',
              ];
            }).toList(),
          ),
        ],
      ),
    );
  }

  static pw.Page _pageMedicineDetails(
    ReportData data,
    pw.Font regular,
    pw.Font bold,
  ) {
    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(24),
      build: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'MEDICINE DETAILS',
            style: pw.TextStyle(font: bold, fontSize: 12, color: kGreen),
          ),
          pw.SizedBox(height: 10),
          _buildSimpleTable(
            [
              'S.No',
              'Date',
              'Age',
              'DC No.',
              'Medicine',
              'Qty',
              'Unit',
              'Value (₹)',
            ],
            data.medicineRecords.asMap().entries.map((entry) {
              final record = entry.value;
              return [
                '${entry.key + 1}',
                _fmtShort(record.date),
                '${record.batchAgeDay}',
                record.dcNumber ?? '–',
                record.medicineName,
                record.quantity.toStringAsFixed(1),
                record.unit,
                record.valueRs != null
                    ? '₹${record.valueRs!.toStringAsFixed(0)}'
                    : '–',
              ];
            }).toList(),
          ),
        ],
      ),
    );
  }

  static pw.Page _pageVaccineBatchDetails(
    ReportData data,
    pw.Font regular,
    pw.Font bold,
  ) {
    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(24),
      build: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'VACCINE BATCH NUMBER DETAILS',
            style: pw.TextStyle(font: bold, fontSize: 12, color: kGreen),
          ),
          pw.SizedBox(height: 10),
          _buildSimpleTable(
            [
              'S.No',
              'Date',
              'Age',
              'Vaccine',
              'Batch No.',
              'Qty',
              'Type',
              'Expiry',
              'Done By',
            ],
            data.vaccineRecords.asMap().entries.map((entry) {
              final record = entry.value;
              return [
                '${entry.key + 1}',
                _fmtShort(record.date),
                '${record.batchAgeDay}',
                record.vaccineName,
                record.batchNumber ?? '–',
                '${record.quantity} ${record.unit}',
                record.vaccineType,
                record.expiryDate != null ? _fmt(record.expiryDate!) : '–',
                record.doneBy ?? '–',
              ];
            }).toList(),
          ),
        ],
      ),
    );
  }

  static pw.Page _pageSalesDetails(
    ReportData data,
    pw.Font regular,
    pw.Font bold,
  ) {
    final totalBirdsSold = data.totalBirdsSold;
    final totalWeight = data.totalSaleWeightKg;
    final averageWeight = totalBirdsSold > 0
        ? (totalWeight / totalBirdsSold).toStringAsFixed(3)
        : '–';
    final totalValue = data.birdSales.fold(
      0.0,
      (sum, sale) => sum + sale.totalValue,
    );

    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(24),
      build: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'BIRD SALES DETAILS',
            style: pw.TextStyle(font: bold, fontSize: 12, color: kGreen),
          ),
          pw.SizedBox(height: 10),
          _buildSimpleTable(
            [
              'S.No',
              'Date',
              'DC No.',
              'Trader',
              'No. Birds',
              'Wt (kg)',
              'Avg Wt',
              'Amount (₹)',
            ],
            data.birdSales.asMap().entries.map((entry) {
              final sale = entry.value;
              final avg = sale.birdsSold > 0
                  ? (sale.averageWeightKg).toStringAsFixed(3)
                  : '–';
              return [
                '${entry.key + 1}',
                _fmtShort(sale.date),
                sale.vehicleNumber ?? '–',
                sale.customerName,
                '${sale.birdsSold}',
                sale.averageWeightKg.toStringAsFixed(1),
                avg,
                sale.totalValue.toStringAsFixed(0),
              ];
            }).toList(),
          ),
          pw.SizedBox(height: 14),
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: kBorder),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _cell('Final Summary', bold: true, fontSize: 9),
                pw.SizedBox(height: 6),
                _cell('Total birds sold: $totalBirdsSold'),
                _cell(
                  'Total sale weight: ${totalWeight.toStringAsFixed(1)} kg',
                ),
                _cell('Average sale weight: $averageWeight kg'),
                _cell('Total sales value: ₹${totalValue.toStringAsFixed(0)}'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Page _pageAdditionalNotes(
    ReportData data,
    pw.Font regular,
    pw.Font bold,
  ) {
    final recordNotes = data.dailyRecords
        .where((record) => record.notes?.isNotEmpty ?? false)
        .map(
          (record) =>
              'Day ${record.batchAgeDay} (${_fmtShort(record.recordDate)}): ${record.notes}',
        )
        .toList();
    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(24),
      build: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'ADDITIONAL NOTES',
            style: pw.TextStyle(font: bold, fontSize: 12, color: kGreen),
          ),
          pw.SizedBox(height: 10),
          _cell(
            data.farm.notes?.isNotEmpty ?? false
                ? 'Farm Notes: ${data.farm.notes}'
                : 'Farm Notes: –',
            fontSize: 8,
          ),
          pw.SizedBox(height: 10),
          _cell('Batch Notes: ${data.batch.notes ?? '–'}', fontSize: 8),
          pw.SizedBox(height: 14),
          pw.Text(
            'Daily record notes',
            style: pw.TextStyle(font: bold, fontSize: 10, color: kGreenDark),
          ),
          pw.SizedBox(height: 6),
          if (recordNotes.isEmpty)
            _cell('No daily record notes available.', fontSize: 8)
          else
            ...recordNotes.map(
              (note) => pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 6),
                child: _cell(note, fontSize: 8),
              ),
            ),
        ],
      ),
    );
  }

  static pw.Page _pagePerformanceSummary(
    ReportData data,
    pw.Font regular,
    pw.Font bold,
  ) {
    final rows = [
      ['1', 'No. of chicks supplied', '${data.batch.totalBirds}'],
      ['2', 'Total Mortality (Nos.)', '${data.totalMortality}'],
      [
        '3',
        'Total Mortality (%)',
        '${data.totalMortality > 0 && data.batch.totalBirds > 0 ? (data.totalMortality / data.batch.totalBirds * 100).toStringAsFixed(2) : '0.00'}%',
      ],
      ['4', 'Total Saleable birds', '${data.batch.currentBirds}'],
      [
        '5',
        'Total Sales Birds Wt.',
        '${data.totalSaleWeightKg.toStringAsFixed(1)} kg',
      ],
      [
        '6',
        'Total Feed Consumption',
        '${data.totalFeedKg.toStringAsFixed(1)} kg',
      ],
      [
        '7',
        'Total Feed Consumption/Bird',
        '${data.batch.totalBirds > 0 ? (data.totalFeedKg / data.batch.totalBirds * 1000).toStringAsFixed(0) : '–'} g/bird',
      ],
      ['8', 'Mean Age', '${data.meanAge} days'],
      [
        '9',
        'Avg. Weight',
        data.avgBodyWeightGrams != null
            ? '${data.avgBodyWeightGrams!.toStringAsFixed(0)} g'
            : '–',
      ],
      ['10', 'F.C.R', data.overallFcr?.toStringAsFixed(2) ?? '–'],
      ['11', 'Liveability %', '${data.liveabilityPct.toStringAsFixed(2)}%'],
      ['12', 'Chicks Placement Date', _fmt(data.batch.placementDate)],
      ['13', 'Hatch Date', _fmt(data.batch.hatchDate)],
      [
        '14',
        'Production Efficiency Factor',
        data.pef?.toStringAsFixed(1) ?? '–',
      ],
      ['15', 'Farm Area', '${data.farm.totalSqFt.toStringAsFixed(0)} sq ft'],
      ['16', 'Total Sheds', '${data.sheds.length}'],
      ['17', 'Breed / Flock Type', data.batch.breedOrFlockType],
      ['18', 'Hatchery', data.batch.hatcheryName ?? '–'],
      ['19', 'Report Generated', _fmt(data.generatedAt)],
    ];

    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(24),
      build: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'PERFORMANCE SUMMARY',
            style: pw.TextStyle(font: bold, fontSize: 12, color: kGreen),
          ),
          pw.SizedBox(height: 10),
          pw.Table(
            border: pw.TableBorder.all(color: kBorder),
            columnWidths: {
              0: const pw.FixedColumnWidth(30),
              1: const pw.FlexColumnWidth(2),
              2: const pw.FlexColumnWidth(1),
            },
            children: [
              pw.TableRow(
                decoration: pw.BoxDecoration(color: kGreen),
                children: ['S.No', 'Particulars', 'Value']
                    .map(
                      (value) =>
                          _cell(value, bold: true, color: PdfColors.white),
                    )
                    .toList(),
              ),
              ...rows.map(
                (row) => pw.TableRow(
                  decoration: pw.BoxDecoration(
                    color: rows.indexOf(row).isEven
                        ? PdfColors.white
                        : kLightGrey,
                  ),
                  children: [
                    _cell(row[0]),
                    _cell(row[1]),
                    _cell(row[2], bold: true),
                  ],
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 24),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
            children: [
              _signatureBlock('Farmer Sign.'),
              _signatureBlock('Supervisor Sign.'),
              _signatureBlock('Manager Sign.'),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _signatureBlock(String label) {
    return pw.Column(
      children: [
        pw.SizedBox(height: 32),
        pw.Container(width: 100, height: 0.5, color: PdfColors.black),
        pw.SizedBox(height: 4),
        pw.Text(
          label,
          style: pw.TextStyle(font: pw.Font.helveticaBold(), fontSize: 8),
        ),
      ],
    );
  }

  static pw.Widget _buildKeyValueTable(
    List<List<String>> rows,
    pw.Font regular,
    pw.Font bold,
  ) {
    return pw.Table(
      border: pw.TableBorder.all(color: kBorder),
      columnWidths: {
        0: const pw.FlexColumnWidth(1),
        1: const pw.FlexColumnWidth(2),
      },
      children: rows.map((row) {
        return pw.TableRow(
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: pw.Text(
                row[0],
                style: pw.TextStyle(font: bold, fontSize: 8, color: kGrey),
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: pw.Text(
                row[1],
                style: pw.TextStyle(font: regular, fontSize: 8),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  static pw.Widget _buildSimpleTable(
    List<String> headers,
    List<List<String>> rows,
  ) {
    return pw.Table(
      border: pw.TableBorder.all(color: kBorder),
      defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: kGreen),
          children: headers
              .map(
                (heading) => _cell(
                  heading,
                  bold: true,
                  color: PdfColors.white,
                  fontSize: 6,
                ),
              )
              .toList(),
        ),
        ...rows.map(
          (row) => pw.TableRow(
            decoration: pw.BoxDecoration(
              color: rows.indexOf(row).isEven ? PdfColors.white : kLightGrey,
            ),
            children: row.map((value) => _cell(value, fontSize: 6)).toList(),
          ),
        ),
      ],
    );
  }

  static pw.Widget _cell(
    String text, {
    bool bold = false,
    PdfColor? color,
    double fontSize = 7,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(4),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          font: bold ? pw.Font.helveticaBold() : pw.Font.helvetica(),
          fontSize: fontSize,
          color: color ?? PdfColors.black,
        ),
      ),
    );
  }

  static String _fmt(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

  static String _fmtShort(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';
}
