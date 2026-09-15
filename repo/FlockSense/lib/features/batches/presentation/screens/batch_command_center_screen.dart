import 'package:flutter/material.dart';
import 'package:flock_sense/core/theme/app_colors.dart';
import 'package:flock_sense/core/theme/app_design.dart';
import 'package:flock_sense/features/batches/data/batch_service.dart';
import 'package:flock_sense/features/batches/domain/batch_model.dart';
import 'package:flock_sense/features/daily_records/presentation/screens/daily_record_form_screen.dart';
import 'package:flock_sense/features/daily_records/presentation/screens/daily_records_screen.dart';
import 'package:flock_sense/features/feed/presentation/screens/feed_records_screen.dart';
import 'package:flock_sense/features/medicine/presentation/screens/medicine_records_screen.dart';
import 'package:flock_sense/features/performance/presentation/screens/batch_performance_screen.dart';
import 'package:flock_sense/features/reports/presentation/screens/reports_screen.dart';
import 'package:flock_sense/features/sales/presentation/screens/bird_sales_screen.dart';
import 'package:flock_sense/features/vaccine/presentation/screens/vaccine_records_screen.dart';
import 'package:flock_sense/features/reports/data/batch_completion_report_service.dart';
import 'package:flock_sense/core/widgets/app_dialog.dart';

class BatchCommandCenterScreen extends StatefulWidget {
  const BatchCommandCenterScreen({
    super.key,
    required this.farmId,
    required this.batchId,
    required this.batchName,
  });
  final String farmId, batchId, batchName;

  @override
  State<BatchCommandCenterScreen> createState() =>
      _BatchCommandCenterScreenState();
}

class _BatchCommandCenterScreenState extends State<BatchCommandCenterScreen> {
  BatchModel? _batch;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final b = await BatchService.getBatchById(widget.farmId, widget.batchId);
      if (mounted)
        setState(() {
          _batch = b;
          _loading = false;
        });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _deleteBatch() async {
    final confirmed = await AppDialog.confirm(
      context: context,
      title: 'Delete Batch',
      message:
          'Are you sure you want to delete "${widget.batchName}" and all associated daily records? This action cannot be undone.',
      confirmLabel: 'Delete',
      isDanger: true,
      icon: Icons.delete_outline_rounded,
    );
    if (!confirmed || !mounted) return;

    try {
      await BatchService.deleteBatch(widget.farmId, widget.batchId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Batch "${widget.batchName}" deleted'),
          backgroundColor: AppColors.primary,
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete batch: $e'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  Future<void> _completeBatch(BatchModel b) async {
    final confirmed = await AppDialog.confirm(
      context: context,
      title: 'Complete Flock Cycle',
      message:
          'Mark "${widget.batchName}" as completed/harvested? This will finalize the flock cycle.',
      confirmLabel: 'Complete Batch',
      icon: Icons.check_circle_outline_rounded,
    );
    if (!confirmed || !mounted) return;

    try {
      await BatchService.updateBatch(widget.farmId, widget.batchId, {'status': 'completed'});
      if (!mounted) return;
      await BatchCompletionReportService.promptAndHandleBatchCompletion(
        context: context,
        farmId: widget.farmId,
        batchId: widget.batchId,
        batchName: widget.batchName,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to complete batch: $e'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  int get _ageDays => _batch != null
      ? DateTime.now().difference(_batch!.placementDate).inDays
      : 0;
  String get _fmtDate => _batch != null
      ? '${_batch!.placementDate.day}/${_batch!.placementDate.month}/${_batch!.placementDate.year}'
      : '-';

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<BatchModel?>(
      stream: BatchService.watchBatch(widget.farmId, widget.batchId),
      builder: (context, snapshot) {
        final b = snapshot.data ?? _batch;
        final ageDays = b != null
            ? DateTime.now().difference(b.placementDate).inDays
            : _ageDays;
        final fmtDate = b != null
            ? '${b.placementDate.day}/${b.placementDate.month}/${b.placementDate.year}'
            : _fmtDate;

        return Scaffold(
          backgroundColor: AppColors.background,
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            titleTextStyle: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
            title: Text(widget.batchName),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                onPressed: _load,
              ),
              if (b != null && b.status == 'active')
                IconButton(
                  icon: const Icon(Icons.check_circle_outline_rounded, color: Colors.white),
                  tooltip: 'Finish / Harvest Batch',
                  onPressed: () => _completeBatch(b),
                ),
              if (b != null && b.status != 'active')
                IconButton(
                  icon: const Icon(Icons.download_rounded, color: Colors.white),
                  tooltip: 'Save Report to Phone',
                  onPressed: () => BatchCompletionReportService.promptAndHandleBatchCompletion(
                    context: context,
                    farmId: widget.farmId,
                    batchId: widget.batchId,
                    batchName: widget.batchName,
                    forcePrompt: true,
                  ),
                ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, color: Colors.white),
                tooltip: 'Delete Batch',
                onPressed: _deleteBatch,
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: AppDesign.headerGreenGradient,
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: -40,
                      right: -40,
                      child: Container(
                        width: 200,
                        height: 200,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0x1AFFFFFF),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -20,
                      left: -10,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0x12FFFFFF),
                        ),
                      ),
                    ),
                    if (!_loading && b != null)
                      Positioned(
                        bottom: 16,
                        left: 16,
                        right: 16,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                AppDesign.statusChip(
                                  b.status == 'active' ? 'Day $ageDays' : 'Closed / Harvested',
                                  const Color(0x1AFFFFFF),
                                  textColor: Colors.white,
                                ),
                                const SizedBox(width: 8),
                                AppDesign.statusChip(
                                  b.breedOrFlockType,
                                  const Color(0x33D4A017),
                                  textColor: Colors.white,
                                ),
                                const Spacer(),
                                AppDesign.statusChip(
                                  b.status.toUpperCase(),
                                  b.status == 'active'
                                      ? const Color(0x1A10B981)
                                      : const Color(0x1AD4A017),
                                  textColor: Colors.white,
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: AppDesign.headerStat(
                                    'Live Birds',
                                    '${b.currentBirds}',
                                    Icons.pets_rounded,
                                  ),
                                ),
                                Expanded(
                                  child: AppDesign.headerStat(
                                    'Male',
                                    '${b.maleCount}',
                                    Icons.male_rounded,
                                  ),
                                ),
                                Expanded(
                                  child: AppDesign.headerStat(
                                    'Female',
                                    '${b.femaleCount}',
                                    Icons.female_rounded,
                                  ),
                                ),
                                Expanded(
                                  child: AppDesign.headerStat(
                                    'Placed',
                                    fmtDate,
                                    Icons.calendar_today_rounded,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: _loading
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (b != null)
                          Row(
                            children: [
                              Expanded(
                                child: AppDesign.miniStatCard(
                                  icon: Icons.pets_rounded,
                                  iconColor: AppColors.primary,
                                  value: '${b.totalBirds}',
                                  label: 'Total Birds',
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: AppDesign.miniStatCard(
                                  icon: Icons.scale_outlined,
                                  iconColor: AppColors.gold,
                                  value: b.chickAvgWeight != null
                                      ? '${b.chickAvgWeight!.toStringAsFixed(1)}g'
                                      : '-',
                                  label: 'DOC Wt',
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: AppDesign.miniStatCard(
                                  icon: Icons.business_outlined,
                                  iconColor: AppColors.ocean,
                                  value: b.hatcheryName ?? '-',
                                  label: 'Hatchery',
                                ),
                              ),
                            ],
                          ),
                        if (b != null && b.status != 'active')
                          Container(
                            margin: const EdgeInsets.only(top: 14),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0FDF4),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFBBF7D0)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryLight,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.verified_rounded,
                                    color: AppColors.primary,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Batch Harvested & Completed',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFF14532D),
                                        ),
                                      ),
                                      Text(
                                        '15-Page End-to-End Audit PDF Ready',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Color(0xFF166534),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                ElevatedButton.icon(
                                  onPressed: () =>
                                      BatchCompletionReportService
                                          .promptAndHandleBatchCompletion(
                                            context: context,
                                            farmId: widget.farmId,
                                            batchId: widget.batchId,
                                            batchName: widget.batchName,
                                            forcePrompt: true,
                                          ),
                                  icon: const Icon(
                                    Icons.download_rounded,
                                    size: 14,
                                  ),
                                  label: const Text('Save PDF'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 8,
                                    ),
                                    textStyle: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 20),
                        AppDesign.sectionTitle('Quick Actions'),
                        GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 4,
                          childAspectRatio: 0.8,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          children: [
                            AppDesign.actionButton(
                              icon: Icons.assignment_outlined,
                              label: 'Daily Records',
                              gradient: AppDesign.actionGreen,
                              onTap: () {
                                if (b == null) return;
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => DailyRecordFormScreen(
                                      farmId: widget.farmId,
                                      batchId: widget.batchId,
                                    ),
                                  ),
                                );
                              },
                            ),
                            AppDesign.actionButton(
                              icon: Icons.list_alt_outlined,
                              label: 'View Records',
                              gradient: AppDesign.actionTeal,
                              onTap: () {
                                if (b == null) return;
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => DailyRecordsScreen(
                                      farmId: widget.farmId,
                                      batchId: widget.batchId,
                                      batchName: widget.batchName,
                                    ),
                                  ),
                                );
                              },
                            ),
                            AppDesign.actionButton(
                              icon: Icons.inventory_outlined,
                              label: 'Feed Log',
                              gradient: AppDesign.actionGold,
                              onTap: () {
                                if (b == null) return;
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => FeedRecordsScreen(
                                      farmId: widget.farmId,
                                      batchId: widget.batchId,
                                      batchName: widget.batchName,
                                    ),
                                  ),
                                );
                              },
                            ),
                            AppDesign.actionButton(
                              icon: Icons.medication_outlined,
                              label: 'Medicine',
                              gradient: AppDesign.actionRed,
                              onTap: () {
                                if (b == null) return;
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => MedicineRecordsScreen(
                                      farmId: widget.farmId,
                                      batchId: widget.batchId,
                                      batchName: widget.batchName,
                                    ),
                                  ),
                                );
                              },
                            ),
                            AppDesign.actionButton(
                              icon: Icons.vaccines_outlined,
                              label: 'Vaccination',
                              gradient: AppDesign.actionPurple,
                              onTap: () {
                                if (b == null) return;
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => VaccineRecordsScreen(
                                      farmId: widget.farmId,
                                      batchId: widget.batchId,
                                      batchName: widget.batchName,
                                    ),
                                  ),
                                );
                              },
                            ),
                            AppDesign.actionButton(
                              icon: Icons.scale_outlined,
                              label: 'Bird Sales',
                              gradient: AppDesign.actionBlue,
                              onTap: () {
                                if (b == null) return;
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => BirdSalesScreen(
                                      farmId: widget.farmId,
                                      batchId: widget.batchId,
                                      batchName: widget.batchName,
                                    ),
                                  ),
                                );
                              },
                            ),
                            AppDesign.actionButton(
                              icon: Icons.bar_chart_outlined,
                              label: 'Performance',
                              gradient: AppDesign.actionDarkTeal,
                              onTap: () {
                                if (b == null) return;
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => BatchPerformanceScreen(
                                      farmId: widget.farmId,
                                      batchId: widget.batchId,
                                      batchName: widget.batchName,
                                      batch: b,
                                    ),
                                  ),
                                );
                              },
                            ),
                            AppDesign.actionButton(
                              icon: Icons.picture_as_pdf_outlined,
                              label: 'Reports',
                              gradient: AppDesign.actionDarkRed,
                              onTap: () {
                                if (b == null) return;
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ReportsScreen(
                                      farmId: widget.farmId,
                                      batchId: widget.batchId,
                                      batchName: widget.batchName,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        AppDesign.sectionTitle('Batch Details'),
                        if (b != null)
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: AppDesign.cardDecoration,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AppDesign.infoRow(
                                  'Hatch Date',
                                  '${b.hatchDate.day}/${b.hatchDate.month}/${b.hatchDate.year}',
                                ),
                                if (b.supervisorName != null &&
                                    b.supervisorName!.isNotEmpty)
                                  AppDesign.infoRow(
                                    'Supervisor',
                                    b.supervisorName!,
                                  ),
                                if (b.vehicleNumber != null &&
                                    b.vehicleNumber!.isNotEmpty)
                                  AppDesign.infoRow(
                                    'Vehicle',
                                    b.vehicleNumber!,
                                  ),
                                if (b.hatcheryName != null &&
                                    b.hatcheryName!.isNotEmpty)
                                  AppDesign.infoRow(
                                    'Hatchery',
                                    b.hatcheryName!,
                                  ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
