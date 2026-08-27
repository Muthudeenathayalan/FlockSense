import 'dart:convert';
import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:flock_sense/features/reports/domain/report_data.dart';
import 'package:flock_sense/features/reports/domain/report_types.dart';

class CsvGenerator {
  static Future<Uint8List> generateCsvReport({
    required ReportData data,
    required ReportType reportType,
  }) async {
    final dateFormat = DateFormat('yyyy-MM-dd');
    final rows = <List<dynamic>>[];

    // Header section
    rows.add(['FLOCKSENSE POULTRY REPORT', reportType.title]);
    rows.add(['Farm Name', data.farm.farmName]);
    rows.add(['Batch Name', data.batch.batchName]);
    rows.add([
      'Generated At',
      DateFormat('yyyy-MM-dd HH:mm').format(data.generatedAt),
    ]);
    rows.add([]);

    switch (reportType) {
      case ReportType.dailyRecords:
      case ReportType.growth:
      case ReportType.feed:
      case ReportType.water:
      case ReportType.mortality:
      case ReportType.completeFarm:
        rows.add([
          'Age (Day)',
          'Date',
          'Opening Birds',
          'Mortality',
          'Culls',
          'Feed Consumed (kg)',
          'Water Consumed (L)',
          'Avg Weight (g)',
          'FCR',
          'Notes',
        ]);
        for (final r in data.dailyRecords) {
          final fcr = r.avgWeightGrams > 0
              ? (r.feedConsumedKg / (r.avgWeightGrams / 1000.0))
                    .toStringAsFixed(2)
              : '-';
          rows.add([
            r.batchAgeDay,
            dateFormat.format(r.recordDate),
            r.openingBirds,
            r.mortalityCount,
            r.cullCount,
            r.feedConsumedKg,
            r.waterConsumedLiters,
            r.avgWeightGrams,
            fcr,
            r.notes ?? '',
          ]);
        }
        break;

      case ReportType.inventory:
        rows.add([
          'Item Name',
          'Category',
          'Available Stock',
          'Unit',
          'Min Threshold',
          'Cost Per Unit (₹)',
          'Supplier',
          'Expiration Date',
          'Low Stock Warning',
        ]);
        for (final item in data.inventoryItems) {
          rows.add([
            item.itemName,
            item.category,
            item.quantityAvailable,
            item.unit,
            item.minStockLevel,
            item.purchasePrice,
            item.supplier,
            item.expiryDate != null ? dateFormat.format(item.expiryDate!) : '-',
            item.isLowStock ? 'YES' : 'NO',
          ]);
        }
        break;

      case ReportType.finance:
        rows.add(['Category', 'Description', 'Amount (₹)']);
        rows.add(['Revenue', 'Bird Sales', data.totalRevenue]);
        rows.add(['Expense', 'Feed Cost', data.totalFeedKg * 42.0]);
        rows.add(['Expense', 'Chick Purchase', data.batch.totalBirds * 35.0]);
        rows.add([
          'Expense',
          'Medicines & Vaccines',
          data.totalExpenses -
              (data.totalFeedKg * 42.0) -
              (data.batch.totalBirds * 35.0),
        ]);
        rows.add(['Summary', 'Net Profit', data.netProfit]);
        break;

      default:
        rows.add(['Metric', 'Value']);
        rows.add(['Initial Birds', data.batch.totalBirds]);
        rows.add(['Total Mortality', data.totalMortality]);
        rows.add(['Livability (%)', data.liveabilityPct.toStringAsFixed(2)]);
        rows.add(['Total Feed (kg)', data.totalFeedKg.toStringAsFixed(1)]);
        rows.add(['Total Water (L)', data.totalWaterLiters.toStringAsFixed(1)]);
        rows.add(['Overall FCR', (data.overallFcr ?? 1.55).toStringAsFixed(2)]);
        rows.add([
          'Avg Body Weight (g)',
          (data.avgBodyWeightGrams ?? 0).toStringAsFixed(0),
        ]);
        rows.add(['EPEF Score', (data.pef ?? 0).toStringAsFixed(1)]);
        break;
    }

    final csvBuffer = StringBuffer();
    for (final row in rows) {
      final line = row
          .map((cell) {
            final str = cell?.toString() ?? '';
            if (str.contains(',') || str.contains('"') || str.contains('\n')) {
              return '"${str.replaceAll('"', '""')}"';
            }
            return str;
          })
          .join(',');
      csvBuffer.writeln(line);
    }

    return Uint8List.fromList(utf8.encode(csvBuffer.toString()));
  }
}
