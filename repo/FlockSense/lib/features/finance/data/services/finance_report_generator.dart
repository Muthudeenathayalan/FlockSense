import 'dart:io';
import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:flock_sense/features/finance/data/models/finance_transaction_model.dart';
import 'package:flock_sense/features/reports/domain/report_types.dart';

class FinanceReportGenerator {
  FinanceReportGenerator._();

  static Future<Uint8List> generatePdfReport({
    required List<FinanceTransactionModel> transactions,
    required String title,
    required String farmName,
  }) async {
    final pdf = pw.Document(title: title);
    final fontBold = pw.Font.helveticaBold();
    final fontRegular = pw.Font.helvetica();

    final totalIncome = transactions
        .where((t) => t.type == FinanceTransactionType.income)
        .fold(0.0, (sum, t) => sum + t.totalAmount);
    final totalExpense = transactions
        .where((t) => t.type == FinanceTransactionType.expense)
        .fold(0.0, (sum, t) => sum + t.totalAmount);
    final netProfit = totalIncome - totalExpense;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Header Banner
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(color: PdfColor.fromHex('#1B5E20')),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'FLOCKSENSE FINANCE & BI REPORT',
                        style: pw.TextStyle(
                          font: fontBold,
                          fontSize: 14,
                          color: PdfColors.white,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        title.toUpperCase(),
                        style: pw.TextStyle(
                          font: fontRegular,
                          fontSize: 10,
                          color: PdfColor.fromHex('#E2E8F0'),
                        ),
                      ),
                    ],
                  ),
                  pw.Text(
                    DateFormat('dd MMM yyyy').format(DateTime.now()),
                    style: pw.TextStyle(
                      font: fontBold,
                      fontSize: 10,
                      color: PdfColors.white,
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 16),

            // Summary Cards
            pw.Row(
              children: [
                pw.Expanded(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(10),
                    decoration: pw.BoxDecoration(
                      color: PdfColor.fromHex('#F8FAFC'),
                      border: pw.Border.all(color: PdfColor.fromHex('#CBD5E1')),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'TOTAL REVENUE',
                          style: pw.TextStyle(
                            font: fontBold,
                            fontSize: 8,
                            color: PdfColor.fromHex('#455A64'),
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          '₹${totalIncome.toStringAsFixed(0)}',
                          style: pw.TextStyle(
                            font: fontBold,
                            fontSize: 14,
                            color: PdfColor.fromHex('#1B5E20'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                pw.SizedBox(width: 10),
                pw.Expanded(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(10),
                    decoration: pw.BoxDecoration(
                      color: PdfColor.fromHex('#F8FAFC'),
                      border: pw.Border.all(color: PdfColor.fromHex('#CBD5E1')),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'TOTAL EXPENSES',
                          style: pw.TextStyle(
                            font: fontBold,
                            fontSize: 8,
                            color: PdfColor.fromHex('#455A64'),
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          '₹${totalExpense.toStringAsFixed(0)}',
                          style: pw.TextStyle(
                            font: fontBold,
                            fontSize: 14,
                            color: PdfColor.fromHex('#E65100'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                pw.SizedBox(width: 10),
                pw.Expanded(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(10),
                    decoration: pw.BoxDecoration(
                      color: PdfColor.fromHex('#F8FAFC'),
                      border: pw.Border.all(color: PdfColor.fromHex('#CBD5E1')),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'NET OPERATING PROFIT',
                          style: pw.TextStyle(
                            font: fontBold,
                            fontSize: 8,
                            color: PdfColor.fromHex('#455A64'),
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          '₹${netProfit.toStringAsFixed(0)}',
                          style: pw.TextStyle(
                            font: fontBold,
                            fontSize: 14,
                            color: netProfit >= 0
                                ? PdfColor.fromHex('#1B5E20')
                                : PdfColor.fromHex('#C62828'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 18),

            pw.Text(
              'TRANSACTION AUDIT LEDGER',
              style: pw.TextStyle(
                font: fontBold,
                fontSize: 11,
                color: PdfColor.fromHex('#0A3200'),
              ),
            ),
            pw.SizedBox(height: 8),

            // Ledger Table
            pw.Table(
              border: pw.TableBorder.all(color: PdfColor.fromHex('#CBD5E1')),
              children: [
                pw.TableRow(
                  decoration: pw.BoxDecoration(
                    color: PdfColor.fromHex('#1B5E20'),
                  ),
                  children:
                      [
                            'Date',
                            'Type',
                            'Category',
                            'Party/Customer',
                            'Invoice',
                            'Amount (₹)',
                            'Status',
                          ]
                          .map(
                            (h) => pw.Padding(
                              padding: const pw.EdgeInsets.all(6),
                              child: pw.Text(
                                h,
                                style: pw.TextStyle(
                                  font: fontBold,
                                  fontSize: 8,
                                  color: PdfColors.white,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                ),
                ...transactions
                    .take(25)
                    .map(
                      (t) => pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(5),
                            child: pw.Text(
                              DateFormat('dd/MM/yy').format(t.date),
                              style: pw.TextStyle(fontSize: 8),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(5),
                            child: pw.Text(
                              t.type.name.toUpperCase(),
                              style: pw.TextStyle(
                                font: fontBold,
                                fontSize: 8,
                                color: t.type == FinanceTransactionType.income
                                    ? PdfColor.fromHex('#1B5E20')
                                    : PdfColor.fromHex('#E65100'),
                              ),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(5),
                            child: pw.Text(
                              t.category,
                              style: pw.TextStyle(fontSize: 8),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(5),
                            child: pw.Text(
                              t.customerOrSupplier,
                              style: pw.TextStyle(fontSize: 8),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(5),
                            child: pw.Text(
                              t.invoiceNumber,
                              style: pw.TextStyle(fontSize: 8),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(5),
                            child: pw.Text(
                              '₹${t.totalAmount.toStringAsFixed(0)}',
                              style: pw.TextStyle(font: fontBold, fontSize: 8),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(5),
                            child: pw.Text(
                              t.paymentStatus.name.toUpperCase(),
                              style: pw.TextStyle(fontSize: 8),
                            ),
                          ),
                        ],
                      ),
                    ),
              ],
            ),
            pw.Spacer(),
            pw.Container(
              padding: const pw.EdgeInsets.only(top: 8),
              decoration: pw.BoxDecoration(
                border: pw.Border(
                  top: pw.BorderSide(color: PdfColor.fromHex('#CBD5E1')),
                ),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Confidential — FlockSense Financial Analytics Engine',
                    style: pw.TextStyle(
                      fontSize: 8,
                      color: PdfColor.fromHex('#455A64'),
                    ),
                  ),
                  pw.Text(
                    'Verified Report',
                    style: pw.TextStyle(
                      font: fontBold,
                      fontSize: 8,
                      color: PdfColor.fromHex('#1B5E20'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    return pdf.save();
  }

  static String generateCsvReport(List<FinanceTransactionModel> transactions) {
    final buffer = StringBuffer();
    buffer.writeln(
      'Transaction ID,Date,Type,Category,Party/Customer,Quantity,UnitPrice,TotalAmount,PaidAmount,PendingAmount,PaymentStatus,PaymentMethod,InvoiceNumber',
    );

    for (final t in transactions) {
      final dateStr = DateFormat('yyyy-MM-dd').format(t.date);
      buffer.writeln(
        '"${t.id}","$dateStr","${t.type.name}","${t.category}","${t.customerOrSupplier}",${t.quantity},${t.unitPrice},${t.totalAmount},${t.paidAmount},${t.pendingAmount},"${t.paymentStatus.name}","${t.paymentMethod}","${t.invoiceNumber}"',
      );
    }

    return buffer.toString();
  }

  static Future<void> shareReport({
    required List<FinanceTransactionModel> transactions,
    required String title,
    required String farmName,
    required ExportFormat format,
  }) async {
    final dir = await getTemporaryDirectory();
    final time = DateTime.now().millisecondsSinceEpoch;
    late File file;

    if (format == ExportFormat.pdf) {
      final bytes = await generatePdfReport(
        transactions: transactions,
        title: title,
        farmName: farmName,
      );
      file = File('${dir.path}/flocksense_finance_$time.pdf');
      await file.writeAsBytes(bytes, flush: true);
    } else {
      final csv = generateCsvReport(transactions);
      final ext = format == ExportFormat.excel ? '.csv' : '.csv';
      file = File('${dir.path}/flocksense_finance_$time$ext');
      await file.writeAsString(csv, flush: true);
    }

    final xFile = XFile(file.path, name: file.path.split('/').last);

    // ignore: deprecated_member_use
    await Share.shareXFiles([
      xFile,
    ], text: 'FlockSense Finance Report - $farmName');
  }
}
