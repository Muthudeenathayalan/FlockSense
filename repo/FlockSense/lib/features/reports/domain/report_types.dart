import 'package:flutter/material.dart';

enum ReportType {
  farm,
  batch,
  dailyRecords,
  growth,
  feed,
  water,
  mortality,
  vaccination,
  medicine,
  inventory,
  finance,
  completeFarm,
}

extension ReportTypeX on ReportType {
  String get title {
    switch (this) {
      case ReportType.farm:
        return 'Farm Report';
      case ReportType.batch:
        return 'Batch Report';
      case ReportType.dailyRecords:
        return 'Daily Records Report';
      case ReportType.growth:
        return 'Growth Report';
      case ReportType.feed:
        return 'Feed Consumption Report';
      case ReportType.water:
        return 'Water Consumption Report';
      case ReportType.mortality:
        return 'Mortality Report';
      case ReportType.vaccination:
        return 'Vaccination Report';
      case ReportType.medicine:
        return 'Medicine Report';
      case ReportType.inventory:
        return 'Inventory Report';
      case ReportType.finance:
        return 'Finance Report';
      case ReportType.completeFarm:
        return 'Complete Farm Report';
    }
  }

  String get description {
    switch (this) {
      case ReportType.farm:
        return 'Farm information, active batches, bird count, feed, water & mortality';
      case ReportType.batch:
        return 'Placement, harvest, age, bird count, feed, water, meds & FCR';
      case ReportType.dailyRecords:
        return 'Complete log of feed, water, mortality, weight & vaccines';
      case ReportType.growth:
        return 'Weight growth curves, FCR trends, bird population & summary';
      case ReportType.feed:
        return 'Total feed consumed, feed types, weekly usage & FCR';
      case ReportType.water:
        return 'Water intake in liters, water-to-feed ratio & daily breakdown';
      case ReportType.mortality:
        return 'Daily mortality count, culls, mortality % & livability %';
      case ReportType.vaccination:
        return 'Completed & scheduled vaccines, age, dosage & route';
      case ReportType.medicine:
        return 'Medicine usage, treatment reasons, dosage & total cost';
      case ReportType.inventory:
        return 'Feed, medicine & vaccine stock levels, low stock & expiring items';
      case ReportType.finance:
        return 'Income, expenses, profit, expense breakdown & revenue trend';
      case ReportType.completeFarm:
        return 'Comprehensive master report combining all farm & batch telemetry';
    }
  }

  IconData get icon {
    switch (this) {
      case ReportType.farm:
        return Icons.home_work_outlined;
      case ReportType.batch:
        return Icons.pets_outlined;
      case ReportType.dailyRecords:
        return Icons.assignment_outlined;
      case ReportType.growth:
        return Icons.show_chart_outlined;
      case ReportType.feed:
        return Icons.restaurant_outlined;
      case ReportType.water:
        return Icons.water_drop_outlined;
      case ReportType.mortality:
        return Icons.heart_broken_outlined;
      case ReportType.vaccination:
        return Icons.vaccines_outlined;
      case ReportType.medicine:
        return Icons.medication_outlined;
      case ReportType.inventory:
        return Icons.inventory_2_outlined;
      case ReportType.finance:
        return Icons.account_balance_wallet_outlined;
      case ReportType.completeFarm:
        return Icons.summarize_outlined;
    }
  }

  Color get color {
    switch (this) {
      case ReportType.farm:
        return const Color(0xFF1B6B8A);
      case ReportType.batch:
        return const Color(0xFF2E7D32);
      case ReportType.dailyRecords:
        return const Color(0xFFE65100);
      case ReportType.growth:
        return const Color(0xFF6A1B9A);
      case ReportType.feed:
        return const Color(0xFFD84315);
      case ReportType.water:
        return const Color(0xFF0288D1);
      case ReportType.mortality:
        return const Color(0xFFC62828);
      case ReportType.vaccination:
        return const Color(0xFF00838F);
      case ReportType.medicine:
        return const Color(0xFFAD1457);
      case ReportType.inventory:
        return const Color(0xFF4A148C);
      case ReportType.finance:
        return const Color(0xFF2E7D32);
      case ReportType.completeFarm:
        return const Color(0xFF1A237E);
    }
  }
}

enum ExportFormat {
  pdf,
  excel,
  csv,
}

extension ExportFormatX on ExportFormat {
  String get label {
    switch (this) {
      case ExportFormat.pdf:
        return 'PDF Document';
      case ExportFormat.excel:
        return 'Excel (.xlsx)';
      case ExportFormat.csv:
        return 'CSV Spreadsheet';
    }
  }

  String get extension {
    switch (this) {
      case ExportFormat.pdf:
        return '.pdf';
      case ExportFormat.excel:
        return '.xlsx';
      case ExportFormat.csv:
        return '.csv';
    }
  }

  IconData get icon {
    switch (this) {
      case ExportFormat.pdf:
        return Icons.picture_as_pdf;
      case ExportFormat.excel:
        return Icons.table_chart;
      case ExportFormat.csv:
        return Icons.description;
    }
  }
}

enum DateRangePreset {
  today,
  last7Days,
  last30Days,
  custom,
}

extension DateRangePresetX on DateRangePreset {
  String get label {
    switch (this) {
      case DateRangePreset.today:
        return 'Today';
      case DateRangePreset.last7Days:
        return 'Last 7 Days';
      case DateRangePreset.last30Days:
        return 'Last 30 Days';
      case DateRangePreset.custom:
        return 'Custom Range';
    }
  }
}

class ReportFilterState {
  const ReportFilterState({
    this.selectedFarmId,
    this.selectedBatchId,
    this.datePreset = DateRangePreset.last30Days,
    this.customStartDate,
    this.customEndDate,
    this.searchQuery = '',
  });

  final String? selectedFarmId;
  final String? selectedBatchId;
  final DateRangePreset datePreset;
  final DateTime? customStartDate;
  final DateTime? customEndDate;
  final String searchQuery;

  ReportFilterState copyWith({
    String? selectedFarmId,
    String? selectedBatchId,
    DateRangePreset? datePreset,
    DateTime? customStartDate,
    DateTime? customEndDate,
    String? searchQuery,
    bool clearFarm = false,
    bool clearBatch = false,
  }) {
    return ReportFilterState(
      selectedFarmId: clearFarm ? null : (selectedFarmId ?? this.selectedFarmId),
      selectedBatchId: clearBatch ? null : (selectedBatchId ?? this.selectedBatchId),
      datePreset: datePreset ?? this.datePreset,
      customStartDate: customStartDate ?? this.customStartDate,
      customEndDate: customEndDate ?? this.customEndDate,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  DateTime? get effectiveStartDate {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    switch (datePreset) {
      case DateRangePreset.today:
        return today;
      case DateRangePreset.last7Days:
        return today.subtract(const Duration(days: 7));
      case DateRangePreset.last30Days:
        return today.subtract(const Duration(days: 30));
      case DateRangePreset.custom:
        return customStartDate;
    }
  }

  DateTime? get effectiveEndDate {
    final now = DateTime.now();
    switch (datePreset) {
      case DateRangePreset.today:
      case DateRangePreset.last7Days:
      case DateRangePreset.last30Days:
        return now;
      case DateRangePreset.custom:
        return customEndDate ?? now;
    }
  }
}

class ReportHistoryItem {
  const ReportHistoryItem({
    required this.id,
    required this.reportType,
    required this.reportTitle,
    required this.farmName,
    required this.batchName,
    required this.format,
    required this.generatedAt,
    required this.fileSizeKb,
    this.filePath,
  });

  final String id;
  final ReportType reportType;
  final String reportTitle;
  final String farmName;
  final String batchName;
  final ExportFormat format;
  final DateTime generatedAt;
  final double fileSizeKb;
  final String? filePath;

  Map<String, dynamic> toJson() => {
        'id': id,
        'reportType': reportType.name,
        'reportTitle': reportTitle,
        'farmName': farmName,
        'batchName': batchName,
        'format': format.name,
        'generatedAt': generatedAt.toIso8601String(),
        'fileSizeKb': fileSizeKb,
        'filePath': filePath,
      };

  factory ReportHistoryItem.fromJson(Map<String, dynamic> json) {
    return ReportHistoryItem(
      id: json['id'] as String? ?? '',
      reportType: ReportType.values.firstWhere(
        (e) => e.name == json['reportType'],
        orElse: () => ReportType.completeFarm,
      ),
      reportTitle: json['reportTitle'] as String? ?? 'Report',
      farmName: json['farmName'] as String? ?? 'All Farms',
      batchName: json['batchName'] as String? ?? 'All Batches',
      format: ExportFormat.values.firstWhere(
        (e) => e.name == json['format'],
        orElse: () => ExportFormat.pdf,
      ),
      generatedAt: DateTime.tryParse(json['generatedAt'] as String? ?? '') ??
          DateTime.now(),
      fileSizeKb: (json['fileSizeKb'] as num?)?.toDouble() ?? 0.0,
      filePath: json['filePath'] as String?,
    );
  }
}
