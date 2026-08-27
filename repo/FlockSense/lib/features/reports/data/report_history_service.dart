import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flock_sense/features/reports/domain/report_types.dart';

class ReportHistoryService {
  static const String _keyHistory = 'flocksense_report_history_v1';

  static Future<List<ReportHistoryItem>> getHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_keyHistory);
      if (jsonString == null || jsonString.isEmpty) {
        return _getInitialDefaultHistory();
      }
      final List<dynamic> list = jsonDecode(jsonString);
      return list
          .map(
            (item) => ReportHistoryItem.fromJson(item as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      return _getInitialDefaultHistory();
    }
  }

  static Future<void> saveHistoryItem(ReportHistoryItem item) async {
    try {
      final current = await getHistory();
      current.insert(0, item);
      if (current.length > 50) {
        current.removeLast();
      }
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(current.map((e) => e.toJson()).toList());
      await prefs.setString(_keyHistory, jsonString);
    } catch (_) {}
  }

  static Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyHistory);
  }

  static List<ReportHistoryItem> _getInitialDefaultHistory() {
    final now = DateTime.now();
    return [
      ReportHistoryItem(
        id: 'rec_101',
        reportType: ReportType.completeFarm,
        reportTitle: 'Complete Farm Report',
        farmName: 'Green Valley Poultry',
        batchName: 'Batch 12 - Broiler',
        format: ExportFormat.pdf,
        generatedAt: now.subtract(const Duration(hours: 2)),
        fileSizeKb: 485.2,
      ),
      ReportHistoryItem(
        id: 'rec_102',
        reportType: ReportType.growth,
        reportTitle: 'Growth Report',
        farmName: 'Green Valley Poultry',
        batchName: 'Batch 12 - Broiler',
        format: ExportFormat.excel,
        generatedAt: now.subtract(const Duration(days: 1, hours: 4)),
        fileSizeKb: 124.5,
      ),
      ReportHistoryItem(
        id: 'rec_103',
        reportType: ReportType.finance,
        reportTitle: 'Finance Report',
        farmName: 'Sunrise Agro Farm',
        batchName: 'Batch 09 - Layer',
        format: ExportFormat.csv,
        generatedAt: now.subtract(const Duration(days: 2)),
        fileSizeKb: 68.1,
      ),
    ];
  }
}
