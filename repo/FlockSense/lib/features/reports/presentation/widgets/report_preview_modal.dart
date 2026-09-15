import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:flock_sense/core/theme/app_colors.dart';
import 'package:flock_sense/features/reports/data/pdf_generator.dart';
import 'package:flock_sense/features/reports/data/report_export_handler.dart';
import 'package:flock_sense/features/reports/domain/report_data.dart';
import 'package:flock_sense/features/reports/domain/report_types.dart';
import 'package:flock_sense/features/reports/presentation/widgets/export_dialog.dart';

class ReportPreviewModal extends StatefulWidget {
  const ReportPreviewModal({
    super.key,
    required this.reportType,
    required this.data,
  });

  final ReportType reportType;
  final ReportData data;

  static Future<void> show(
    BuildContext context, {
    required ReportType reportType,
    required ReportData data,
  }) {
    return Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReportPreviewModal(reportType: reportType, data: data),
      ),
    );
  }

  @override
  State<ReportPreviewModal> createState() => _ReportPreviewModalState();
}

class _ReportPreviewModalState extends State<ReportPreviewModal>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  ExportFormat _selectedFormat = ExportFormat.pdf;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.reportType.title),
        backgroundColor: widget.reportType.color,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.insights_rounded), text: 'Technique Audit'),
            Tab(icon: Icon(Icons.picture_as_pdf_outlined), text: 'PDF Document'),
            Tab(icon: Icon(Icons.table_rows_outlined), text: 'Daily Records'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: 'Share Report',
            onPressed: () {
              ReportExportHandler.shareReport(
                data: widget.data,
                reportType: widget.reportType,
                format: _selectedFormat,
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.download_rounded),
            tooltip: 'Export',
            onPressed: () {
              ExportDialog.show(
                context,
                reportType: widget.reportType,
                data: widget.data,
              );
            },
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 1. Interactive Technique Audit Tab
          _buildTechniqueAuditView(),

          // 2. PDF Preview Tab
          PdfPreview(
            build: (format) => PdfGenerator.generatePdfForReportType(
              data: widget.data,
              reportType: widget.reportType,
            ),
            allowPrinting: true,
            allowSharing: true,
            canChangeOrientation: false,
            canChangePageFormat: false,
            loadingWidget: const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          ),

          // 3. Data Table Tab
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSummaryHeader(),
                const SizedBox(height: 16),
                _buildDataTable(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: const [
            BoxShadow(
              color: Color(0x10000000),
              blurRadius: 10,
              offset: Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: 8,
                  children: ExportFormat.values.map((fmt) {
                    final isSel = _selectedFormat == fmt;
                    return ChoiceChip(
                      selected: isSel,
                      label: Text(fmt.name.toUpperCase()),
                      selectedColor: widget.reportType.color,
                      labelStyle: TextStyle(
                        color: isSel ? Colors.white : AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                      onSelected: (_) => setState(() => _selectedFormat = fmt),
                    );
                  }).toList(),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  ReportExportHandler.shareReport(
                    data: widget.data,
                    reportType: widget.reportType,
                    format: _selectedFormat,
                  );
                },
                icon: const Icon(Icons.share, size: 16),
                label: Text('Share ${_selectedFormat.name.toUpperCase()}'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.reportType.color,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.data.farm.farmName,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Batch: ${widget.data.batch.batchName} • ${widget.data.dailyRecords.length} Records',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataTable() {
    if (widget.data.dailyRecords.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: const [
            Icon(
              Icons.assignment_outlined,
              size: 48,
              color: AppColors.textHint,
            ),
            SizedBox(height: 12),
            Text(
              'No daily telemetry records found for this batch.',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Start logging daily feed, water, and mortality in Daily Records to view telemetry history here.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(
              label: Text('Day', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            DataColumn(
              label: Text(
                'Date',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'Closing Birds',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'Mortality',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'Feed (kg)',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'Water (L)',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'Avg Wt (g)',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
          rows: widget.data.dailyRecords.map((r) {
            return DataRow(
              cells: [
                DataCell(Text('${r.batchAgeDay}')),
                DataCell(Text('${r.recordDate.month}/${r.recordDate.day}')),
                DataCell(Text('${r.closingBirds}')),
                DataCell(Text('${r.mortalityCount}')),
                DataCell(Text('${r.feedConsumedKg}')),
                DataCell(Text('${r.waterConsumedLiters}')),
                DataCell(Text('${r.avgWeightGrams}')),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildTechniqueAuditView() {
    final disadvantages = widget.data.techniqueDisadvantages;
    final advantages = widget.data.techniqueAdvantages;
    final leakage = widget.data.totalTechniqueFinancialLeakage;
    final benchmarks = widget.data.benchmarkMatrix;
    final actionPlan = widget.data.techniqueActionPlan;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAuditHeroCard(leakage, disadvantages.length),
          const SizedBox(height: 20),
          _buildDisadvantagesSection(disadvantages),
          const SizedBox(height: 20),
          if (advantages.isNotEmpty) ...[
            _buildAdvantagesSection(advantages),
            const SizedBox(height: 20),
          ],
          _buildBenchmarkSection(benchmarks),
          const SizedBox(height: 20),
          _buildActionPlanSection(actionPlan),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildAuditHeroCard(double leakage, int flawCount) {
    final score = widget.data.overallScore;
    final grade = widget.data.overallHealthGrade;
    final isGood = score >= 75;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isGood ? AppColors.primary.withValues(alpha: 0.3) : AppColors.warning.withValues(alpha: 0.4),
          width: 1.5,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.data.farm.farmName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Batch: ${widget.data.batch.batchName} • Day ${widget.data.meanAge} of Cycle',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isGood ? AppColors.greenTint : AppColors.amberTint,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isGood ? AppColors.primary : AppColors.warning,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      '$score / 100',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: isGood ? AppColors.primaryDeep : const Color(0xFFB45309),
                      ),
                    ),
                    Text(
                      grade.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: isGood ? AppColors.primaryDeep : const Color(0xFFB45309),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (leakage > 0)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.redTint,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.danger.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.money_off_rounded, color: AppColors.danger, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Estimated Technique Loss: ₹${leakage.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppColors.danger,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$flawCount technique flaw(s) identified. Correcting feeder height & water flow can recover this profit.',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Colors.red.shade900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.greenTint,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 28),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Optimal Farming Efficiency: ₹0 Profit Leakage',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primaryDeep,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Your feeding, hydration, and brooding techniques are aligned with elite commercial benchmarks.',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: AppColors.primaryDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDisadvantagesSection(List<FarmingTechniqueInsight> disadvantages) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.redTint,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.warning_amber_rounded, color: AppColors.danger, size: 18),
            ),
            const SizedBox(width: 8),
            const Text(
              'Disadvantages in Your Farming Technique',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          'Operational flaws currently depressing flock growth and wasting revenue.',
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 12),
        if (disadvantages.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: const Row(
              children: [
                Icon(Icons.thumb_up_rounded, color: AppColors.primary, size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'No critical farming disadvantages detected. Excellent flock management!',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                  ),
                ),
              ],
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: disadvantages.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final dis = disadvantages[index];
              final isCrit = dis.severity == 'Critical';

              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isCrit ? AppColors.danger.withValues(alpha: 0.4) : AppColors.warning.withValues(alpha: 0.4),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.borderLight,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            dis.category.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isCrit ? AppColors.redTint : AppColors.amberTint,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            dis.severity.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: isCrit ? AppColors.danger : const Color(0xFFB45309),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      dis.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Observed: ${dis.metricObserved}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.error_outline_rounded, color: AppColors.danger, size: 16),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            dis.techniqueFlaw,
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.greenTint.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.build_circle_outlined, color: AppColors.primary, size: 16),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Corrective Action: ${dis.correctiveAction}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryDeep,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (dis.financialImpactRs != null && dis.financialImpactRs! > 0) ...[
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.redTint,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Est. Financial Loss: ₹${dis.financialImpactRs!.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: AppColors.danger,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildAdvantagesSection(List<FarmingTechniqueInsight> advantages) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.greenTint,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.verified_rounded, color: AppColors.primary, size: 18),
            ),
            const SizedBox(width: 8),
            const Text(
              'Your Farming Strengths & Advantages',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          'Operational areas where your technique outperforms commercial averages.',
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 12),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: advantages.length,
          separatorBuilder: (context, index) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final adv = advantages[index];
            return Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 2),
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.greenTint,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check, color: AppColors.primary, size: 14),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          adv.title,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          adv.metricObserved,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryDeep,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          adv.techniqueFlaw,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildBenchmarkSection(List<Map<String, dynamic>> benchmarks) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.blueTint,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.compare_arrows_rounded, color: AppColors.info, size: 18),
            ),
            const SizedBox(width: 8),
            const Text(
              'Commercial Breed Standard Comparison',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          'How your farm compares against target Cobb 500 / Ross 308 standards.',
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: benchmarks.map((bm) {
              final isGood = bm['isGood'] as bool? ?? false;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: AppColors.borderLight)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 4,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            bm['metric'] as String,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Target: ${bm['target']}',
                            style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            bm['actual'] as String,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            bm['variance'] as String,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: isGood ? AppColors.primary : AppColors.danger,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isGood ? AppColors.greenTint : AppColors.amberTint,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            bm['status'] as String,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: isGood ? AppColors.primaryDeep : const Color(0xFFB45309),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildActionPlanSection(List<String> actionPlan) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.greenTint,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.checklist_rounded, color: AppColors.primary, size: 18),
            ),
            const SizedBox(width: 8),
            const Text(
              'Corrective Action Plan for Next 24-48 Hours',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          'Specific steps for the farmer to eliminate disadvantages and increase profit.',
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 12),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: actionPlan.length,
          separatorBuilder: (context, index) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final action = actionPlan[index];
            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryDeep,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      action,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

