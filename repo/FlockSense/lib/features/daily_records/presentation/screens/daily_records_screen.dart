import 'package:flutter/material.dart';
import 'package:flock_sense/core/theme/app_colors.dart';
import 'package:flock_sense/core/theme/app_design.dart';
import 'package:flock_sense/features/batches/data/batch_service.dart';
import 'package:flock_sense/features/batches/domain/batch_model.dart';
import 'package:flock_sense/features/daily_records/data/daily_record_service.dart';
import 'package:flock_sense/features/daily_records/domain/daily_record_model.dart';
import 'package:flock_sense/features/daily_records/presentation/screens/daily_record_form_screen.dart';
import 'package:flock_sense/features/performance/presentation/screens/batch_performance_screen.dart';
import 'package:flock_sense/features/performance/presentation/screens/daily_record_detail_screen.dart';

class DailyRecordsScreen extends StatefulWidget {
  const DailyRecordsScreen({
    super.key,
    required this.farmId,
    required this.batchId,
    this.batchName,
  });

  final String farmId;
  final String batchId;
  final String? batchName;

  @override
  State<DailyRecordsScreen> createState() => _DailyRecordsScreenState();
}

class _DailyRecordsScreenState extends State<DailyRecordsScreen> {
  BatchModel? _batch;

  @override
  void initState() {
    super.initState();
    _loadBatch();
  }

  Future<void> _loadBatch() async {
    try {
      final batch = await BatchService.getBatchById(
        widget.farmId,
        widget.batchId,
      );
      if (!mounted) return;
      setState(() => _batch = batch);
    } catch (_) {
      if (!mounted) return;
      setState(() => _batch = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        titleTextStyle: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Daily Records',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
            Text(
              widget.batchName ?? 'Batch',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.show_chart_outlined),
            onPressed: _batch == null
                ? null
                : () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BatchPerformanceScreen(
                        farmId: widget.farmId,
                        batchId: widget.batchId,
                        batchName: widget.batchName ?? 'Batch',
                        batch: _batch!,
                      ),
                    ),
                  ),
          ),
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () async {
              final todayRecord = await DailyRecordService.getDailyRecordByDate(
                farmId: widget.farmId,
                batchId: widget.batchId,
                recordDate: DateTime.now(),
              );
              if (!context.mounted) return;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DailyRecordFormScreen(
                    farmId: widget.farmId,
                    batchId: widget.batchId,
                    batchName: widget.batchName,
                    existingRecord: todayRecord,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<List<DailyRecordModel>>(
        stream: DailyRecordService.watchDailyRecords(
          farmId: widget.farmId,
          batchId: widget.batchId,
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          final records = snapshot.data ?? [];
          if (records.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        gradient: AppDesign.actionGreen,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.calendar_today_outlined,
                        size: 36,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'No daily records yet',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Start tracking mortality, feed, water, health, and weight.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: records.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) => _DailyRecordCard(
              record: records[index],
              batchName: widget.batchName,
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final todayRecord = await DailyRecordService.getDailyRecordByDate(
            farmId: widget.farmId,
            batchId: widget.batchId,
            recordDate: DateTime.now(),
          );
          if (!context.mounted) return;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => DailyRecordFormScreen(
                farmId: widget.farmId,
                batchId: widget.batchId,
                batchName: widget.batchName,
                existingRecord: todayRecord,
              ),
            ),
          );
        },
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text(
          'Add Daily Record',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class _DailyRecordCard extends StatelessWidget {
  const _DailyRecordCard({required this.record, required this.batchName});

  final DailyRecordModel record;
  final String? batchName;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DailyRecordDetailScreen(
            record: record,
            batchName: batchName ?? 'Batch',
          ),
        ),
      ),
      child: Container(
        decoration: AppDesign.cardDecoration,
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDate(record.recordDate),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF7EC),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Day ${record.batchAgeDay}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              childAspectRatio: 1.75,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              children: [
                _RecordValue(
                  label: 'Mortality',
                  value: record.mortalityCount.toString(),
                ),
                _RecordValue(
                  label: 'Feed',
                  value: '${record.feedConsumedKg.toStringAsFixed(1)} kg',
                ),
                _RecordValue(
                  label: 'Avg weight',
                  value: '${record.avgWeightGrams.toStringAsFixed(0)} g',
                ),
                _RecordValue(
                  label: 'Closing birds',
                  value: record.closingBirds.toString(),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'View full details →',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

class _RecordValue extends StatelessWidget {
  const _RecordValue({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F7F0),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
