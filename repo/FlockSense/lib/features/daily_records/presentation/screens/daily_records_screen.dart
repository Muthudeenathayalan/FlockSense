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
        backgroundColor: AppColors.primaryDark,
        foregroundColor: Colors.white,
        elevation: 0,
        titleTextStyle: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Daily Records',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white),
            ),
            Text(
              widget.batchName ?? 'Batch',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white70,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.show_chart_outlined, color: Colors.white),
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
            icon: const Icon(Icons.add_rounded, color: Colors.white),
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
            separatorBuilder: (_, _) => const SizedBox(height: 12),
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
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: const [
            BoxShadow(
              color: Color(0x060F172A),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header band
            Container(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF14532D), Color(0xFF15803D)],
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatDateFull(record.recordDate),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Day ${record.batchAgeDay}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Stats grid
            Padding(
              padding: const EdgeInsets.all(12),
              child: GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                childAspectRatio: 2.0,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                children: [
                  _RecordValue(
                    label: 'Mortality',
                    value: record.mortalityCount.toString(),
                    icon: Icons.warning_amber_rounded,
                    iconColor: const Color(0xFFEF4444),
                    tint: const Color(0xFFFEE2E2),
                  ),
                  _RecordValue(
                    label: 'Feed',
                    value: '${record.feedConsumedKg.toStringAsFixed(1)} kg',
                    icon: Icons.inventory_2_outlined,
                    iconColor: const Color(0xFF2563EB),
                    tint: const Color(0xFFDBEAFE),
                  ),
                  _RecordValue(
                    label: 'Avg Weight',
                    value: '${record.avgWeightGrams.toStringAsFixed(0)} g',
                    icon: Icons.monitor_weight_outlined,
                    iconColor: const Color(0xFFF59E0B),
                    tint: const Color(0xFFFEF3C7),
                  ),
                  _RecordValue(
                    label: 'Live Birds',
                    value: record.closingBirds.toString(),
                    icon: Icons.egg_outlined,
                    iconColor: const Color(0xFF16A34A),
                    tint: const Color(0xFFDCFCE7),
                  ),
                ],
              ),
            ),
            // Footer
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'View full details',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.arrow_forward_rounded, size: 14, color: AppColors.primary),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateFull(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

class _RecordValue extends StatelessWidget {
  const _RecordValue({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.tint,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: tint,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 17),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: iconColor.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: iconColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
