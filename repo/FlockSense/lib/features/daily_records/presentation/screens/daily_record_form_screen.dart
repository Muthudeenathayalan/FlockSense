import 'package:flutter/material.dart';
import 'package:flock_sense/features/daily_records/domain/daily_record_model.dart';
import 'package:flock_sense/features/daily_records/presentation/screens/daily_records_dashboard_screen.dart';

class DailyRecordFormScreen extends StatelessWidget {
  const DailyRecordFormScreen({
    super.key,
    required this.farmId,
    required this.batchId,
    this.batchName,
    this.existingRecord,
  });

  final String farmId;
  final String batchId;
  final String? batchName;
  final DailyRecordModel? existingRecord;

  @override
  Widget build(BuildContext context) {
    return DailyRecordsDashboardScreen(
      initialFarmId: farmId,
      initialBatchId: batchId,
      existingRecord: existingRecord,
    );
  }
}
