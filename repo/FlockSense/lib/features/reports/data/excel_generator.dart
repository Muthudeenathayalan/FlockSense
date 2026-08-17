import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:flock_sense/features/reports/domain/report_data.dart';
import 'package:flock_sense/features/reports/domain/report_types.dart';

class ExcelGenerator {
  static Future<Uint8List> generateExcelReport({
    required ReportData data,
    required ReportType reportType,
  }) async {
    final excel = Excel.createExcel();
    final dateFormat = DateFormat('yyyy-MM-dd');
    final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 0);

    // 1. Summary Worksheet
    final Sheet summarySheet = excel['Summary'];
    excel.setDefaultSheet('Summary');

    summarySheet.appendRow([TextCellValue('FLOCKSENSE POULTRY REPORT')]);
    summarySheet.appendRow([TextCellValue('Report Type:'), TextCellValue(reportType.title)]);
    summarySheet.appendRow([TextCellValue('Farm Name:'), TextCellValue(data.farm.farmName)]);
    summarySheet.appendRow([TextCellValue('Batch Name:'), TextCellValue(data.batch.batchName)]);
    summarySheet.appendRow([TextCellValue('Breed:'), TextCellValue(data.batch.breedOrFlockType)]);
    summarySheet.appendRow([TextCellValue('Generated At:'), TextCellValue(DateFormat('yyyy-MM-dd HH:mm').format(data.generatedAt))]);
    summarySheet.appendRow([TextCellValue('')]);

    summarySheet.appendRow([TextCellValue('METRIC'), TextCellValue('VALUE')]);
    summarySheet.appendRow([TextCellValue('Initial Birds'), IntCellValue(data.batch.totalBirds)]);
    summarySheet.appendRow([TextCellValue('Total Mortality'), IntCellValue(data.totalMortality)]);
    summarySheet.appendRow([TextCellValue('Livability (%)'), DoubleCellValue(double.parse(data.liveabilityPct.toStringAsFixed(2)))]);
    summarySheet.appendRow([TextCellValue('Total Feed Consumed (kg)'), DoubleCellValue(double.parse(data.totalFeedKg.toStringAsFixed(1)))]);
    summarySheet.appendRow([TextCellValue('Total Water Consumed (L)'), DoubleCellValue(double.parse(data.totalWaterLiters.toStringAsFixed(1)))]);
    summarySheet.appendRow([TextCellValue('Overall FCR'), DoubleCellValue(double.parse((data.overallFcr ?? 1.55).toStringAsFixed(2)))]);
    summarySheet.appendRow([TextCellValue('Avg Body Weight (g)'), DoubleCellValue(double.parse((data.avgBodyWeightGrams ?? 0).toStringAsFixed(0)))]);
    summarySheet.appendRow([TextCellValue('Performance Index (EPEF)'), DoubleCellValue(double.parse((data.pef ?? 0).toStringAsFixed(1)))]);
    summarySheet.appendRow([TextCellValue('Total Revenue'), TextCellValue(currencyFormat.format(data.totalRevenue))]);
    summarySheet.appendRow([TextCellValue('Total Expenses'), TextCellValue(currencyFormat.format(data.totalExpenses))]);
    summarySheet.appendRow([TextCellValue('Net Profit'), TextCellValue(currencyFormat.format(data.netProfit))]);

    // 2. Daily Records Worksheet
    final Sheet dailySheet = excel['Daily Records'];
    dailySheet.appendRow([
      TextCellValue('Day'),
      TextCellValue('Date'),
      TextCellValue('Opening Birds'),
      TextCellValue('Mortality'),
      TextCellValue('Culls'),
      TextCellValue('Feed (kg)'),
      TextCellValue('Water (L)'),
      TextCellValue('Avg Weight (g)'),
      TextCellValue('Notes'),
    ]);

    for (final r in data.dailyRecords) {
      dailySheet.appendRow([
        IntCellValue(r.batchAgeDay),
        TextCellValue(dateFormat.format(r.recordDate)),
        IntCellValue(r.openingBirds),
        IntCellValue(r.mortalityCount),
        IntCellValue(r.cullCount),
        DoubleCellValue(r.feedConsumedKg),
        DoubleCellValue(r.waterConsumedLiters),
        DoubleCellValue(r.avgWeightGrams),
        TextCellValue(r.notes ?? ''),
      ]);
    }

    // 3. Inventory Worksheet
    final Sheet inventorySheet = excel['Inventory'];
    inventorySheet.appendRow([
      TextCellValue('Item Name'),
      TextCellValue('Category'),
      TextCellValue('Stock Available'),
      TextCellValue('Unit'),
      TextCellValue('Min Threshold'),
      TextCellValue('Unit Cost (₹)'),
      TextCellValue('Supplier'),
      TextCellValue('Status'),
    ]);

    for (final item in data.inventoryItems) {
      String status = 'Normal';
      if (item.isLowStock) status = 'LOW STOCK';
      inventorySheet.appendRow([
        TextCellValue(item.itemName),
        TextCellValue(item.category),
        DoubleCellValue(item.quantityAvailable),
        TextCellValue(item.unit),
        DoubleCellValue(item.minStockLevel),
        DoubleCellValue(item.purchasePrice),
        TextCellValue(item.supplier),
        TextCellValue(status),
      ]);
    }

    // 4. Finance Worksheet
    final Sheet financeSheet = excel['Finance'];
    financeSheet.appendRow([
      TextCellValue('Category'),
      TextCellValue('Description'),
      TextCellValue('Amount (₹)'),
    ]);
    financeSheet.appendRow([TextCellValue('Revenue'), TextCellValue('Bird Sales'), DoubleCellValue(data.totalRevenue)]);
    financeSheet.appendRow([TextCellValue('Expense'), TextCellValue('Feed Cost'), DoubleCellValue(data.totalFeedKg * 42.0)]);
    financeSheet.appendRow([TextCellValue('Expense'), TextCellValue('Chick Purchase'), DoubleCellValue(data.batch.totalBirds * 35.0)]);
    financeSheet.appendRow([TextCellValue('Expense'), TextCellValue('Medicine & Vaccine'), DoubleCellValue(data.totalExpenses - (data.totalFeedKg * 42.0) - (data.batch.totalBirds * 35.0))]);
    financeSheet.appendRow([TextCellValue('Summary'), TextCellValue('Net Profit'), DoubleCellValue(data.netProfit)]);

    final bytes = excel.encode();
    return Uint8List.fromList(bytes ?? []);
  }
}
