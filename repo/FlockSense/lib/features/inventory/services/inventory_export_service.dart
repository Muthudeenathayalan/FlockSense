import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flock_sense/features/inventory/domain/inventory_item_model.dart';
import 'package:flock_sense/features/inventory/presentation/providers/inventory_providers.dart';

class InventoryExportService {
  static final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');
  static final NumberFormat _currencyFormat = NumberFormat.currency(
    symbol: '₹',
    decimalDigits: 2,
    locale: 'en_IN',
  );

  /// Generates a PDF report for Inventory items & statistics
  static Future<pw.Document> generateInventoryPdfReport({
    required List<InventoryItemModel> items,
    required InventoryStats stats,
    required String title,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => pw.Container(
          padding: const pw.EdgeInsets.only(bottom: 12),
          decoration: const pw.BoxDecoration(
            border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey400)),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'FlockSense — $title',
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
          pw.Text('Inventory Summary KPIs', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),

          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.green100),
                children: [
                  _cell('Total Feed Stock', isHeader: true),
                  _cell('Total Med Units', isHeader: true),
                  _cell('Total Vac Doses', isHeader: true),
                  _cell('Low Stock Items', isHeader: true),
                  _cell('Expired Items', isHeader: true),
                  _cell('Total Value', isHeader: true),
                ],
              ),
              pw.TableRow(
                children: [
                  _cell('${stats.totalFeedStockKg.toStringAsFixed(1)} kg'),
                  _cell('${stats.totalMedicineStockUnits.toStringAsFixed(0)}'),
                  _cell('${stats.totalVaccineStockDoses.toStringAsFixed(0)}'),
                  _cell('${stats.lowStockCount}'),
                  _cell('${stats.expiredCount}'),
                  _cell(_currencyFormat.format(stats.totalInventoryValue)),
                ],
              ),
            ],
          ),

          pw.SizedBox(height: 20),
          pw.Text('Inventory Item List (${items.length} items)', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),

          if (items.isEmpty)
            pw.Text('No items logged in inventory.', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700))
          else
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    _cell('Item Name', isHeader: true),
                    _cell('Category', isHeader: true),
                    _cell('Qty Available', isHeader: true),
                    _cell('Min Stock', isHeader: true),
                    _cell('Supplier', isHeader: true),
                    _cell('Unit Price', isHeader: true),
                    _cell('Total Value', isHeader: true),
                  ],
                ),
                ...items.map(
                  (item) => pw.TableRow(
                    children: [
                      _cell(item.itemName),
                      _cell(item.category),
                      _cell('${item.quantityAvailable} ${item.unit}'),
                      _cell('${item.minStockLevel} ${item.unit}'),
                      _cell(item.supplier),
                      _cell(_currencyFormat.format(item.purchasePrice)),
                      _cell(_currencyFormat.format(item.totalValue)),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );

    return pdf;
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

  /// Generates CSV data table report
  static String generateInventoryCsvReport(List<InventoryItemModel> items) {
    final sb = StringBuffer();
    sb.writeln('FlockSense Inventory Report');
    sb.writeln('Generated Date,${_dateFormat.format(DateTime.now())}');
    sb.writeln();

    sb.writeln('Item Name,Category,Brand,Supplier,Quantity Available,Unit,Min Stock Level,Purchase Date,Expiry Date,Purchase Price,Storage Location,Batch Number,Total Value,Low Stock,Expired');
    for (final item in items) {
      sb.writeln(
        '"${item.itemName}","${item.category}","${item.brand}","${item.supplier}",${item.quantityAvailable},"${item.unit}",${item.minStockLevel},"${_dateFormat.format(item.purchaseDate)}","${item.expiryDate != null ? _dateFormat.format(item.expiryDate!) : "N/A"}",${item.purchasePrice},"${item.storageLocation}","${item.batchNumber ?? ''}",${item.totalValue},${item.isLowStock},${item.isExpired}',
      );
    }

    return sb.toString();
  }

  /// Print or open PDF print preview
  static Future<void> printOrPreviewPdf({
    required BuildContext context,
    required List<InventoryItemModel> items,
    required InventoryStats stats,
    required String title,
  }) async {
    final pdf = await generateInventoryPdfReport(items: items, stats: stats, title: title);
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'FlockSense_Inventory_Report_${DateFormat("yyyyMMdd").format(DateTime.now())}.pdf',
    );
  }

  /// Share report via platform native share sheet
  static Future<void> shareReport({
    required BuildContext context,
    required List<InventoryItemModel> items,
    required InventoryStats stats,
    required String title,
  }) async {
    final pdf = await generateInventoryPdfReport(items: items, stats: stats, title: title);
    final bytes = await pdf.save();

    final tempDir = Directory.systemTemp;
    final file = File('${tempDir.path}/FlockSense_Inventory_${DateFormat("yyyyMMdd_HHmmss").format(DateTime.now())}.pdf');
    await file.writeAsBytes(bytes);

    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'application/pdf')],
      text: 'FlockSense Inventory Report — $title',
    );
  }
}
